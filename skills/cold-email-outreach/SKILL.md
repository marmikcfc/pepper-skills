---
name: cold-email-outreach
description: Write and send personalized cold email outreach to a prospect or list. Combines the Haines cold email framework with orth Gmail sending. Use when asked to send cold emails, reach out to prospects, or run an outbound sequence.
---

# Cold Email Outreach

Write and send personalized cold emails using the proven Haines cold email framework, then send via Gmail through orth.

## When to Use
- "Send cold email to [prospect]"
- "Reach out to [person] at [company]"
- "Run outbound to [prospect list]"
- "Write and send cold outreach for [campaign]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`
- Gmail connected via orth (`orth run gmail /send` must work)

## Workflow

**Step 1: Load context**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

ICP=$(state_read "strategy/icp.md")
POSITIONING=$(state_read "strategy/positioning.md")
```

**Step 2: Enrich prospect**
```bash
orth run comprehensive-enrichment /enrich \
  --body '{"email": "<prospect_email>", "name": "<name>", "company": "<company>"}'
```

**Step 3: Research personalization signals**
```bash
orth run linkedin-activity /activity \
  --body '{"person": "<linkedin_url>", "limit": 3}'
orth run company-intel /intelligence \
  --body '{"company": "<company>"}'
```

**Step 4: Write email using Haines cold-email framework**
Pass to Claude:
> "Write a cold email using the Observation → Problem → Proof → Ask framework.
> Rules: under 100 words, no jargon, one interest-based CTA (e.g., 'Worth exploring?'), personalization must connect to the problem.
> Subject line: 2-4 words, lowercase, no tricks.
> Prospect: {enriched_profile}
> Recent activity: {linkedin_recent_posts}
> Our positioning: {positioning}
> Their pain we solve: {pain_point}"

**Step 5: Show draft and get explicit approval**
Present the draft email (subject + body).

> "Here's the draft email. Should I send this to <prospect_email>? (yes/no)"

Only proceed if user confirms.

**Step 6: Send via Gmail**
```bash
orth run gmail /send \
  --body '{"to": "<email>", "subject": "<subject>", "body": "<approved_body>"}'
```

**Step 7: Log to state**
```bash
state_append "revops/outreach.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ) | SENT | <prospect_email> | <company>"
```

## Output
Sent email confirmation + outreach log entry in `revops/outreach.md`.
