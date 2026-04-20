---
name: voice-of-customer-synthesizer
description: Synthesize the voice of your customers from reviews, support emails, and interview notes into messaging frameworks and positioning insights. Use when asked to understand customer language, extract VOC, or build messaging from customer feedback.
---

# Voice of Customer Synthesizer

Synthesize customer feedback from multiple sources into messaging frameworks your team can actually use.

## When to Use
- "Synthesize our VOC data"
- "What language do customers use to describe our product?"
- "Build messaging from customer feedback"
- "Extract VOC from [source]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL` (to read cached reviews and interview notes)

## Workflow

**Step 1: Load available feedback sources**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

REVIEWS=$(state_read "intelligence/reviews/<company>.md")
INTERVIEWS=$(state_read "intelligence/interviews.md")
```

**Step 2: Pull support emails**
```bash
orth run gmail /search \
  --body '{"query": "from:customers subject:feedback OR subject:love OR subject:problem OR subject:question", "limit": 50}'
```

**Step 3: LLM synthesis**
Pass all collected feedback (reviews + interview notes + email subjects/bodies) to Claude:
> "Extract the voice of customer from these inputs. Produce:
> 1. Top 10 exact phrases customers use to describe the problem (verbatim, in their words)
> 2. Top 5 desired outcomes (what they're trying to achieve)
> 3. Top 5 fears/anxieties (what they're worried about)
> 4. Top 3 'aha moment' descriptions (when they realized the product worked)
> 5. Positioning statement draft using customer language
> 6. 3 headline variants written in customer voice
> Return as structured JSON."

**Step 4: Present synthesis and get approval**
Display the full VOC synthesis for review.

> "Should I save this VOC synthesis to state for use in messaging and copy? (yes/no)"

Only proceed if user confirms:
```bash
state_write "strategy/voc.md" "<voc synthesis>"
```

## Output
VOC synthesis report with customer phrases, desired outcomes, fears, aha moments, and ready-to-use messaging drafts. Saved to `strategy/voc.md`.
