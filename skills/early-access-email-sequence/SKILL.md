---
name: early-access-email-sequence
description: Design and send a multi-email early access or waitlist nurture sequence. Use when launching a new product, running a beta program, or nurturing a waitlist toward conversion.
---

# Early Access Email Sequence

Design and send a multi-touch email sequence for early access programs, beta launches, or waitlist nurturing.

## When to Use
- "Set up an early access email sequence"
- "Nurture our waitlist with emails"
- "Build a beta launch email series"
- "Send a drip sequence to our early access list"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`
- Gmail connected via orth

## Workflow

**Step 1: Gather sequence context**
Ask the user:
- What's the product and its core value?
- How long is the early access period?
- What's the goal — get feedback, create FOMO, drive activation?

**Step 2: Design sequence structure**
Using the Haines email-sequence framework, design a 5-email sequence:
- Email 1 (Day 0): Welcome + what's coming — build anticipation
- Email 2 (Day 3): Social proof + momentum — who's already in, early results
- Email 3 (Day 7): Feature highlight + why it matters — one focused benefit
- Email 4 (Day 10): Access opening or urgency — CTA to activate/upgrade
- Email 5 (Day 14): Last chance + breakup — close the loop

**Step 3: Draft all 5 emails with LLM**
For each email, pass to Claude:
> "Write email [N] of an early access sequence. Product: {product_description}. Goal for this email: {email_goal}. Rules: under 150 words, each email stands alone (recipient may not have read prior ones), one clear CTA per email, conversational not salesy."

**Step 4: Get user approval for the full sequence**
Present all 5 emails. Ask:
> "Here's the full 5-email sequence. Approve to send Email 1 now and log the sequence start? (yes/edit/cancel)"

Only proceed if user approves.

**Step 5: Send Email 1 and log sequence start**
```bash
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

orth run gmail /send \
  --body '{"to": "<recipient>", "subject": "<email_1_subject>", "body": "<email_1_body>"}'

state_append "revops/sequences.md" "<recipient> | early-access | $(date +%Y-%m-%d) | email_1_sent"
```

Note: Emails 2-5 require manual follow-up or a scheduled cron job. Log each send in state as you go.

## Output
Full 5-email sequence draft + Email 1 sent with sequence start logged to state.
