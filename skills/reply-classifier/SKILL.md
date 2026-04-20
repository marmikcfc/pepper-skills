---
name: reply-classifier
description: Read recent Gmail replies to outreach sequences, classify each as interested/ooo/unsubscribe/objection/referral/other, and route to the appropriate follow-up action.
---
# Reply Classifier

Fetch unread Gmail replies from outreach sequences, classify each one using an LLM, and surface the right next action per category. Prevents interested leads from going cold, keeps do-not-contact lists accurate, and automates the triage work that usually falls through the cracks.

## When to Use

- After sending an outreach batch and want to triage all replies at once
- Daily morning triage of inbound replies
- Before a pipeline review to ensure all interested replies have been actioned
- Cleaning up unsubscribes before the next send

## Prerequisites

- `ORTHOGONAL_API_KEY` — used to read Gmail
- `ANTHROPIC_API_KEY` — used to classify each reply
- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance
- Gmail connected via `orth` (`orth login gmail`)

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

**Step 1: Read recent replies**

```bash
orth run gmail /inbox \
  --body '{"query": "in:inbox is:unread", "limit": 20}'
```

If no unread emails are returned, inform the user: "No unread replies found. Your inbox is clear."

**Step 2: Classify each reply**

For each email, pass the subject, sender, and body to Claude:

> "Classify this email reply into exactly one category:
> - `interested` — the person wants to talk, learn more, or take a next step
> - `ooo` — out-of-office or auto-reply, no human action yet
> - `unsubscribe` — person explicitly asks to be removed or stop receiving emails
> - `objection` — not interested, pushback, wrong fit, or no budget
> - `referral` — redirecting to someone else in their org
> - `other` — anything else
>
> Return JSON only: {\"category\": \"<category>\", \"confidence\": <0.0-1.0>, \"reason\": \"<one sentence>\", \"suggested_action\": \"<one sentence>\"}"

**Step 3: Show summary table**

Group results and display:

```
Category     | Count | Actions needed
-------------|-------|------------------------------------------
interested   | N     | Draft meeting booking reply for each
objection    | N     | Review — handle or mark disqualified
ooo          | N     | Re-queue to send again in 2 weeks
unsubscribe  | N     | Mark do-not-contact, remove from sequences
referral     | N     | Add referred contact to pipeline
other        | N     | Review manually
```

Also list each email under its category with sender name, subject line, and suggested action.

**Step 4: Handle interested replies**

For each `interested` reply, ask: "Want me to draft a meeting-booking reply for [sender name]? (yes/no)"

If yes, draft a reply:
> "Write a concise, friendly reply to this email that proposes a 20-minute call. Include a Calendly placeholder [CALENDLY_LINK]. Match the tone of the original reply. Keep it under 80 words."

Show the draft and ask: "Send this reply? (yes/no) — Only proceed if user confirms."

**Step 5: Log unsubscribes to state**

If any `unsubscribe` replies were found, ask:

"Log [N] unsubscribe(s) to `revops/do-not-contact.md`? (yes/no) — Only proceed if user confirms."

If yes:
```bash
state_append "revops/do-not-contact.md" "<email_address> | unsubscribed | $(date +%Y-%m-%d)"
```
Repeat for each unsubscribe. Confirm: "[N] unsubscribes logged to `revops/do-not-contact.md`."

## Output

Classified reply table with counts per category, suggested actions per reply, optional meeting-booking drafts for interested replies, and unsubscribes logged to state.
