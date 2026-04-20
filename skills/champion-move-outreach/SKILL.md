---
name: champion-move-outreach
description: Send personalized re-engagement outreach to a champion who just moved to a new company. Use when a tracked champion changes jobs and their new company fits your ICP.
---

# Champion Move Outreach

Re-engage a past champion (customer, power user, advocate) who just moved to a new ICP-fit company.

## When to Use
- "Reach out to a champion who moved to a new company"
- "Activate champion move alerts for outreach"
- "[Person] just started at [new company] — reach out"
- "Follow up on champion job change alerts"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`
- Gmail connected via orth

## Workflow

**Step 1: Load champion move alerts**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

MOVES=$(state_read "signals/champion-moves.md")
```

**Step 2: Filter for ICP-fit new companies**
Only proceed with outreach if the champion's new company ICP score is ≥ 60.
Low-fit companies (score < 60): log but do not send.

**Step 3: Write warm re-engagement email**
Pass to Claude:
> "Write a short email to a past champion who just started at a new company. Reference their positive past experience working with us (without being specific about what we did — keep it professional). Express genuine congratulations on the new role. Offer to help them succeed there with what we do. Under 60 words. Warm, personal, not salesy. No hard CTA — just open the door."

**Step 4: Show draft and get approval**
> "Draft ready for <name> at <new_company>. Should I send this? (yes/no)"

Only proceed if user confirms.

**Step 5: Send and log**
```bash
orth run gmail /send \
  --body '{"to": "<email>", "subject": "Congrats on <new_company>!", "body": "<approved_email>"}'

state_append "revops/outreach.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ) | SENT | <email> | <new_company> | champion-move"
```

## Output
Warm re-engagement email sent + log entry. Champion move logged as actioned.
