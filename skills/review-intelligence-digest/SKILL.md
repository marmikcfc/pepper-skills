---
name: review-intelligence-digest
description: Synthesize customer reviews into actionable intelligence — top praised features, top complaints, switching reasons, and competitive positioning insights. Use when asked to analyze reviews, understand customer sentiment, or find product positioning gaps.
---

# Review Intelligence Digest

Turn raw customer reviews into structured competitive and product intelligence.

## When to Use
- "Analyze reviews for [company/product]"
- "What do customers complain about most?"
- "What features do customers love about [competitor]?"
- "Find switching triggers from [competitor] reviews"
- "What's the VOC for [company]?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL` (to read cached reviews)

## Workflow

**Step 1: Load reviews**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

REVIEWS=$(state_read "intelligence/reviews/<company>.md")
```
If `REVIEWS` is empty, run `review-scraper` first to collect reviews.

**Step 2: LLM synthesis**
Pass all reviews to Claude with this prompt:
> "Analyze these customer reviews and extract:
> 1. Top 5 praised features (what customers love most)
> 2. Top 5 pain points / complaints
> 3. Top 3 switching reasons (why customers left or would leave)
> 4. ICP patterns (what roles and company sizes leave reviews?)
> 5. Competitive positioning gaps (what buyers want that isn't delivered)
> 6. One representative quote for each category
> Return as structured JSON with these 6 keys."

**Step 3: Format and present**
Format output as a structured intelligence report with sections for each of the 6 categories.

**Step 4: Save digest to state**
> "Should I save this review intelligence digest to state? (yes/no)"

Only proceed if user confirms:
```bash
state_write "intelligence/review-digest/<company>.md" "<formatted digest>"
```

## Output
Structured review intelligence report with actionable competitive insights. Optionally saved to `intelligence/review-digest/<company>.md`.
