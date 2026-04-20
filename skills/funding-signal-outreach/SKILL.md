---
name: funding-signal-outreach
description: Send personalized outreach to companies that just raised funding — timing-aware, congratulatory emails that connect their raise to a relevant growth challenge. Use when asked to reach out to recently funded companies or activate funding signals for outbound.
---

# Funding Signal Outreach

Reach out to companies that just raised funding with timing-aware, congratulatory outreach that connects their raise to the growth challenges that come with fresh capital.

## When to Use
- "Reach out to companies that just raised"
- "Activate our funding signals for outbound"
- "Send outreach to [company] — they just raised a Series A"
- "Follow up on funding signal alerts"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`
- Gmail connected via orth

## Workflow

**Step 1: Load funding signals**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

SIGNALS=$(state_read "signals/$(date +%Y-%m-%d).md")
```
If signals file is empty, load from the most recent signals file or ask user to specify the company directly.

**Step 2: Find decision-maker at funded company**
```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "VP Marketing CEO COO CMO at <company_name>", "pageSize": 3}'
```

**Step 3: Get company intel**
```bash
orth run company-intel /intelligence \
  --body '{"company": "<company_name>"}'
```

**Step 4: Write trigger-based cold email**
Pass to Claude:
> "Write a cold email congratulating [company] on their [round size] raise. Connect the raise to a specific growth challenge our product solves. Frame it as: 'Companies that just raised at your stage typically face [relevant challenge]. We help with that.'
> Rules: under 80 words, congratulatory opener (not sycophantic), one specific pain point, low-friction CTA like 'Worth a quick chat?'"

**Step 5: Show draft and get approval**
> "Draft ready for <name> at <company>. Should I send this? (yes/no)"

Only proceed if user confirms.

**Step 6: Send and log**
```bash
orth run gmail /send \
  --body '{"to": "<email>", "subject": "Congrats on the raise", "body": "<approved_email>"}'

state_append "revops/outreach.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ) | SENT | <email> | <company> | funding-trigger"
```

## Output
Sent outreach email + log entry in `revops/outreach.md`.
