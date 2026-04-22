---
name: disqualification-handling
description: Handle a disqualified lead gracefully — send a breakup email, save for future re-engagement, or route to a nurture sequence. Use when a prospect says no, goes dark, or is clearly not a fit now.
---

# Disqualification Handling

Handle disqualified leads with a graceful breakup email that leaves the door open for future re-engagement.

## When to Use
- "This prospect said no — handle it"
- "Lead went dark — close it out"
- "Send a breakup email to [prospect]"
- "Disqualify [lead] and log them"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`
- Gmail connected via Composio (connect at Settings → Integrations in Pepper Cloud dashboard)

## Workflow

**Step 1: Understand the disqualification reason**
Ask the user: Why are they disqualified?
- Wrong timing (come back in N months)
- No budget (cost objection)
- Wrong ICP (not a fit at all)
- Went dark (ghosted after initial contact)
- Chose competitor (lost deal)

**Step 2: Write breakup email**
Pass to Claude:
> "Write a short breakup email (under 5 sentences) for a prospect being disqualified due to [reason].
> Rules: acknowledge their situation gracefully, leave the door open for future conversation, no guilt or pressure, end with a clear closure line.
> Do NOT ask for a referral or try to re-open the deal."

**Step 3: Show draft and get approval**
> "Here's the breakup email draft. Should I send this and log the lead as disqualified? (yes/no)"

Only proceed if user confirms.

**Step 4: Send breakup email**
```bash
# Verify Gmail is connected before proceeding
composio-tool apps | grep -i gmail || echo "Gmail not connected — user must connect at Settings → Integrations"

# Search for the send email action slug
composio-tool search "send email" --toolkit gmail --limit 3

# Send the breakup email
composio-tool execute GMAIL_SEND_EMAIL '{"recipient_email": "<email>", "subject": "Re: [our thread subject]", "body": "<breakup_email>"}'
```

**Step 5: Log disposition**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

state_append "revops/disqualified.md" "$(date +%Y-%m-%d) | <email> | <company> | <reason>"
```

## Output
Breakup email sent + lead logged as disqualified in `revops/disqualified.md`.
