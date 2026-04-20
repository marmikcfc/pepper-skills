---
name: hiring-signal-outreach
description: Send personalized outreach to companies with hiring signals that indicate they need your product — connect their open roles to the pain your product solves. Use when asked to activate hiring signals for outbound or reach out based on job postings.
---

# Hiring Signal Outreach

Reach out to companies posting jobs that signal they need your product — connect their hiring pain to your solution.

## When to Use
- "Reach out to companies hiring for [role]"
- "Activate hiring signals for outbound"
- "Send outreach to [company] — they're hiring a VP of Marketing"
- "Follow up on hiring signal alerts"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`
- Gmail connected via orth

## Workflow

**Step 1: Load hiring signals**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

SIGNALS=$(state_read "signals/$(date +%Y-%m-%d).md")
```
Filter for hiring-type signals. If empty, ask user to specify a company or job posting directly.

**Step 2: Get the hiring context**
```bash
orth run hiring-signals /jobs \
  --body '{"company": "<company_name>", "keywords": ["<relevant_role>"], "limit": 5}'
```
Read the job description carefully — it reveals exactly what problem they're trying to solve with the hire.

**Step 3: Find the right contact**
```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "<hiring_manager_title> at <company_name>", "pageSize": 3}'
```

**Step 4: Write hiring-triggered email**
Pass to Claude:
> "Write a cold email to [company] referencing their job posting for [role]. The hook: hiring for [role] usually means [specific pain point]. We help companies solve that without the hire — or make the hire more effective. Under 80 words. Reference the specific role title."

**Step 5: Show draft and get approval**
> "Draft ready for <name> at <company>. Should I send this? (yes/no)"

Only proceed if user confirms.

**Step 6: Send and log**
```bash
orth run gmail /send \
  --body '{"to": "<email>", "subject": "Re: your <role> opening", "body": "<approved_email>"}'

state_append "revops/outreach.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ) | SENT | <email> | <company> | hiring-trigger | <role>"
```

## Output
Sent outreach email + log entry in `revops/outreach.md`.
