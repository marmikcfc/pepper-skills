---
name: linkedin-manual-queue
description: Build a personalized LinkedIn outreach queue for manual or Heyreach sending. Finds ICP-matching profiles, generates custom connection messages, and outputs a ready-to-send table.
---
# LinkedIn Manual Queue

Build a structured LinkedIn outreach queue with personalized connection request messages for each prospect. Uses `orth run sales-prospecting` to find ICP-matching profiles, loads ICP context from state to personalize messages, and outputs a ready-to-use table for manual sending or import into Heyreach.

## When to Use

- Launching a new LinkedIn outbound campaign
- Adding new prospects to the pipeline after an ICP refinement
- Building a targeted outreach list for a specific segment (role, company size, signal)
- Generating connection messages for a list of profiles you already have

## Prerequisites

- `ORTHOGONAL_API_KEY` — used by `sales-prospecting` to find profiles
- `ANTHROPIC_API_KEY` — used to write personalized connection messages
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL` — for loading ICP context from state

## Connection Message Rules

LinkedIn connection requests are limited to 300 characters. Each message must:
- Reference something specific about the person (title, company, recent post, or signal)
- Mention a relevant problem or outcome — not your product
- End with a soft, low-friction ask (never "can I get 15 minutes?")
- Sound like a human wrote it, not a template

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

**Step 1: Load ICP context**

```bash
ICP=$(state_read "strategy/icp.md")
POSITIONING=$(state_read "strategy/positioning.md")
COMPANY=$(state_read "company/company.md")
```

If `ICP` is empty: "No ICP definition found. Describe your ideal customer profile: role, seniority, company size, industry, and 2-3 buying signals."

**Step 2: Define targeting criteria**

Ask the user to specify:
1. **Target role(s)** — e.g., "VP of Marketing, Head of Growth, CMO at Series A-B SaaS companies"
2. **Company size** — e.g., "10-200 employees"
3. **Industry** — e.g., "B2B SaaS, dev tools, AI infrastructure"
4. **Signal (optional)** — e.g., "recently posted about AI adoption", "company raised Series A in last 6 months", "hiring growth roles"
5. **Batch size** — "How many prospects? (recommend 20-50 for a manual queue)"

**Step 3: Find matching profiles**

```bash
orth run sales-prospecting /prospect \
  --body "{
    \"role\": \"$TARGET_ROLE\",
    \"company_size\": \"$COMPANY_SIZE\",
    \"industry\": \"$INDUSTRY\",
    \"signal\": \"$SIGNAL\",
    \"limit\": $BATCH_SIZE,
    \"output\": \"linkedin\"
  }"
```

If `orth run sales-prospecting` returns no results, fall back to:
```bash
orth run find-leads /find \
  --body "{\"criteria\": \"$TARGET_ROLE at $INDUSTRY companies, $COMPANY_SIZE employees\", \"limit\": $BATCH_SIZE}"
```

**Step 4: Generate personalized connection messages**

For each profile found, pass profile details + ICP context to Claude:

> "Write a LinkedIn connection request message for this prospect. Max 300 characters.
>
> Rules:
> - Reference something specific about them (their role, company, a recent post if mentioned in profile)
> - Mention a relevant outcome or problem — NOT our product
> - End with a low-friction statement or question (not 'can we chat?')
> - Sound like one human reaching out to another
> - No templates, no 'I came across your profile'
>
> Prospect: {name}, {title} at {company}
> Context: {any_signal_or_linkedin_activity}
> ICP pain we solve: {extract relevant pain from ICP}
> Our positioning: {positioning}
>
> Return only the message text. No labels, no quotes."

**Step 5: Build the queue table**

Assemble the results into a structured table:

```
| # | Name | Title | Company | LinkedIn URL | Connection Message (≤300 chars) |
|---|------|-------|---------|--------------|----------------------------------|
| 1 | ... | ... | ... | https://linkedin.com/in/... | Hi [name], saw you're scaling... |
| 2 | ... | ... | ... | ... | ... |
```

Show the full table to the user. Highlight any messages that exceed 300 characters in red (ask to revise).

**Step 6: Approval gate**

Ask: "Does this queue look good? (yes/edit/no)"

- If `edit`: specify which rows to change (by number) or ask to regenerate specific messages
- If `no`: discard
- If `yes`: proceed to Step 7

**Step 7: Log to state and export**

```bash
state_append "revops/linkedin-queue.md" "
## LinkedIn Queue — $(date -u +%Y-%m-%d)
Target: $TARGET_ROLE | $INDUSTRY | $COMPANY_SIZE
Batch: $BATCH_SIZE prospects

$QUEUE_TABLE
"
```

Present the final table as a clean markdown block the user can copy into Heyreach, a Google Sheet, or their LinkedIn workflow.

Confirm: "Queue logged to `revops/linkedin-queue.md`. Ready to send."

## Output

Structured LinkedIn outreach queue: markdown table with prospect name, title, company, LinkedIn URL, and personalized connection message (≤300 chars) — ready for manual sending or Heyreach import.
