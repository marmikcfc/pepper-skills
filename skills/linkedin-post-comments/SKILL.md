---
name: linkedin-post-comments
description: Scrape all comments from a LinkedIn post, populate a Google Sheet, and enrich commenters with email addresses.
tags: linkedin, google-sheets, enrichment, scraping, leads
---

# LinkedIn Post Comments to Google Sheets

Scrape all comments from a LinkedIn post, populate a Google Sheet, and enrich commenters with email addresses using a waterfall strategy.

## Requirements

- `orth` CLI installed and authenticated (`npm install -g @orth/cli`)
- Google Sheets connected at https://orthogonal.com/dashboard/integrations

## APIs Used

| API | Endpoint | Cost | Purpose |
|-----|----------|------|---------|
| Fiber | `/v1/linkedin-live-fetch/post-comments` | 2 credits/page (10 comments) | Fetch comments |
| Tomba | `/v1/linkedin` | 1 credit/lookup | Email finder (cheap, try first) |
| Sixtyfour | `/find-email` | 5 cents/lookup | Email finder (fallback) |
| Google Sheets | `/create-spreadsheet`, `/update-values` | free | Sheet creation and population |

## Step 1: Extract the Content ID

From a LinkedIn post URL like:
```
https://www.linkedin.com/feed/update/urn:li:activity:7434655206426042368/
```

The content ID is: `urn:li:activity:7434655206426042368`

## Step 2: Create the Google Sheet

```bash
orth run google-sheets /create-spreadsheet -b '{"title": "LinkedIn Post Comments - <description>"}'
```

Save the `spreadsheet_id` from the response.

## Step 3: Add Headers

```bash
orth run google-sheets /update-values -b '{
  "spreadsheet_id": "<SPREADSHEET_ID>",
  "sheet_name": "Sheet1",
  "first_cell_location": "A1",
  "values": [["Name", "Comment", "LinkedIn URL", "LinkedIn Slug", "Reactions", "Date", "Email"]]
}'
```

## Step 4: Fetch All Comments and Populate Sheet

Use this Python script to auto-paginate through all comments and write them to the sheet:

```bash
python3 << 'PYEOF'
import subprocess, json, re

CONTENT_ID = "<CONTENT_ID>"          # e.g. urn:li:activity:7434655206426042368
SHEET_ID = "<SPREADSHEET_ID>"        # from Step 2

cursor = ""
row = 2  # start after header

while True:
    print(f"Fetching from row {row}...")
    if cursor:
        body = json.dumps({"contentId": CONTENT_ID, "cursor": cursor})
    else:
        body = json.dumps({"contentId": CONTENT_ID})

    result = subprocess.run(
        ["orth", "run", "fiber", "/v1/linkedin-live-fetch/post-comments", "-b", body],
        capture_output=True, text=True
    )

    output = result.stdout
    json_start = output.find('{')
    if json_start == -1:
        print("No JSON found in output")
        break

    raw_json = re.sub(r'[\x00-\x1f]', ' ', output[json_start:])

    try:
        data = json.loads(raw_json)
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")
        break

    comments = data.get("output", {}).get("data", [])
    if not comments:
        print("No more comments.")
        break

    print(f"  Got {len(comments)} comments")

    values = []
    for c in comments:
        values.append([
            c["commenter"].get("name", ""),
            c.get("commentary", "").replace('\n', ' ').strip(),
            c["commenter"].get("linkedinUrl", ""),
            c["commenter"].get("linkedinSlug", ""),
            str(c.get("numReactions", 0)),
            c.get("createdAt", "")
        ])

    sheet_body = json.dumps({
        "spreadsheet_id": SHEET_ID,
        "sheet_name": "Sheet1",
        "first_cell_location": f"A{row}",
        "values": values
    })

    subprocess.run(
        ["orth", "run", "google-sheets", "/update-values", "-b", sheet_body],
        capture_output=True, text=True
    )
    print(f"  Written to sheet rows {row}-{row + len(values) - 1}")

    row += len(values)
    cursor = data.get("output", {}).get("cursor", "")
    if not cursor:
        print("No more pages.")
        break

print(f"\nDone! Total comments in sheet: {row - 2}")
PYEOF
```

## Step 5: Enrich Emails (Waterfall)

Use a two-provider waterfall: Tomba first (cheaper), then Sixtyfour as fallback.

To enrich all rows, or just a subset (e.g. first N), use this script:

```bash
python3 << 'PYEOF'
import subprocess, json, re

SHEET_ID = "<SPREADSHEET_ID>"
ENRICH_COUNT = 10  # number of rows to enrich, or "all"

# 1. Read LinkedIn slugs from the sheet
result = subprocess.run(
    ["orth", "run", "google-sheets", "/get-values", "-b",
     json.dumps({"spreadsheet_id": SHEET_ID, "ranges": [f"Sheet1!C2:D{ENRICH_COUNT + 1}"]})],
    capture_output=True, text=True
)
raw = re.sub(r'[\x00-\x1f]', ' ', result.stdout[result.stdout.find('{'):])
data = json.loads(raw)
rows = data.get("response_data", {}).get("valueRanges", [{}])[0].get("values", [])

emails = []
for i, row in enumerate(rows):
    linkedin_url = row[0] if row else ""
    slug = row[1] if len(row) > 1 else ""
    if not linkedin_url:
        emails.append(["Not found"])
        continue

    print(f"[{i+1}/{len(rows)}] Looking up {slug}...")

    # Try Tomba first (1 credit)
    r = subprocess.run(
        ["orth", "run", "tomba", "/v1/linkedin", "-q", f"url={linkedin_url}"],
        capture_output=True, text=True
    )
    try:
        tomba_json = re.sub(r'[\x00-\x1f]', ' ', r.stdout[r.stdout.find('{'):])
        tomba_data = json.loads(tomba_json)
        email = tomba_data.get("data", {}).get("email")
    except:
        email = None

    if email:
        print(f"  Tomba: {email}")
        emails.append([email])
        continue

    # Fallback to Sixtyfour (5 cents)
    r = subprocess.run(
        ["orth", "run", "sixtyfour", "/find-email", "-b",
         json.dumps({"lead": {"linkedin_url": linkedin_url}})],
        capture_output=True, text=True
    )
    try:
        sf_json = re.sub(r'[\x00-\x1f]', ' ', r.stdout[r.stdout.find('{'):])
        sf_data = json.loads(sf_json)
        email_list = sf_data.get("email", [])
        if email_list:
            email_str = email_list[0][0]
            confidence = email_list[0][1]  # OK, RISKY, UNKNOWN
            label = f" ({confidence.lower()})" if confidence != "OK" else ""
            print(f"  Sixtyfour: {email_str}{label}")
            emails.append([f"{email_str}{label}"])
            continue
    except:
        pass

    print(f"  Not found")
    emails.append(["Not found"])

# 2. Write emails to column G
sheet_body = json.dumps({
    "spreadsheet_id": SHEET_ID,
    "sheet_name": "Sheet1",
    "first_cell_location": "G2",
    "values": emails
})
subprocess.run(
    ["orth", "run", "google-sheets", "/update-values", "-b", sheet_body],
    capture_output=True, text=True
)
print(f"\nDone! Enriched {len(emails)} rows.")
PYEOF
```

## Tips

- Most viral LinkedIn posts have hundreds of low-effort "keyword" comments (e.g. "Code", "interested"). Filter these in the sheet if you only want substantive commenters.
- Sixtyfour returns a confidence level: `OK`, `RISKY`, or `UNKNOWN`. Prioritize `OK` emails for outreach.
- To enrich only commenters with substantive comments, filter column B in the sheet first before running the enrichment script.
- The Google Sheets integration requires OAuth — connect at https://orthogonal.com/dashboard/integrations
