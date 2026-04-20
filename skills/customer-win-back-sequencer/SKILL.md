---
name: customer-win-back-sequencer
description: Run a 3-email win-back sequence for churned customers in the 90-180 day re-engagement window. Use when asked to win back churned customers or run a re-engagement campaign.
---

# Customer Win-Back Sequencer

Run a 3-email win-back sequence targeting churned customers in the optimal re-engagement window (90-180 days post-churn).

## When to Use
- "Run a win-back campaign for churned customers"
- "Reach out to customers who cancelled"
- "Start a win-back sequence for [customer]"
- "Re-engage lapsed customers"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`
- Gmail connected via orth

## Workflow

**Step 1: Load churned customer list**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

CHURNED=$(state_read "revops/churned.md")
```
Expected format per line: `email | company | churn_date (YYYY-MM-DD) | plan`. Pass the list to Claude:
> "Today is $(date +%Y-%m-%d). From this churned customer list, extract only customers whose churn_date is between 90 and 180 days ago. Return each as: email | company | churn_date | days_since_churn. Skip anyone outside that window."

Earlier than 90 days = too soon. Later than 180 days = likely stale.

**Step 2: Design 3-email win-back sequence**
Draft all 3 emails for each customer using Claude:

- **Email 1 (Day 0):** "We've improved" — acknowledge time passed, highlight 1-2 meaningful improvements made since they left
  > "Write Email 1 of a win-back sequence. Acknowledge that [customer] left a while ago. Share 1-2 genuine improvements we've made that address common reasons people leave. Under 100 words. No discount, no hard sell."

- **Email 2 (Day 7):** Case study relevant to their use case
  > "Write Email 2 of a win-back sequence. Share a brief customer story relevant to [customer]'s use case. Show a concrete result. End with a low-friction CTA. Under 80 words."

- **Email 3 (Day 14):** Special offer with clear expiry
  > "Write Email 3 of a win-back sequence. Make a specific offer (discount or trial extension). Give a clear deadline. This is the last touch — be direct. Under 60 words."

**Step 3: Get approval for full sequence**
Present all 3 emails. Ask:
> "Here's the full win-back sequence for <customer>. Approve to send Email 1 now? (yes/no)"

Only proceed if user confirms.

**Step 4: Send Email 1 and log**
```bash
orth run gmail /send \
  --body '{"to": "<email>", "subject": "<email_1_subject>", "body": "<email_1_body>"}'

state_append "revops/win-back.md" "<customer_email> | <company> | $(date +%Y-%m-%d) | email_1_sent"
```

Note: Emails 2 and 3 require manual follow-up or scheduled cron. Log each send as `email_2_sent` and `email_3_sent` in state.

## Output
3-email win-back sequence drafted + Email 1 sent + sequence logged to `revops/win-back.md`.
