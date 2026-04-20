---
name: competitive-pricing-intel
description: Research and track competitor pricing — tiers, limits, price points, and recent changes. Use when asked to analyze competitor pricing, compare pricing strategies, or detect pricing changes.
---

# Competitive Pricing Intel

Research competitor pricing pages, extract structured pricing data, and track changes over time.

## When to Use
- "What does [competitor] charge?"
- "Compare pricing for [competitors]"
- "Did [competitor] change their pricing?"
- "Build a competitive pricing matrix"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Screenshot pricing page (visual reference)**
```bash
orth run screenshot-website /screenshot \
  --body '{"url": "<competitor_homepage>/pricing"}'
```

**Step 2: Scrape pricing page text**
```bash
orth run scrape "<competitor_homepage>/pricing" \
  --body '{"format": "markdown"}'
```

**Step 3: Load previous pricing (for change detection)**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

PREV=$(state_read "competitive/pricing/<competitor>.md")
```

**Step 4: Extract structured pricing with LLM**
> "Extract pricing from this page as JSON: {tiers: [{name, price_monthly, price_annual, limits, features}], free_trial: true/false, enterprise: true/false, notable_changes: string}"

**Step 5: Detect changes (if prior version exists)**
If `PREV` is not empty, pass both versions to Claude:
> "What changed between these two versions of the pricing page? Focus on price changes, new/removed tiers, limit changes, and feature gate changes."

**Step 6: Present results**
Show: current pricing table + detected changes (if any).

> "Should I save the current pricing to state for future change tracking? (yes/no)"

Only proceed if user confirms:
```bash
state_write "competitive/pricing/<competitor>.md" "<current_pricing_markdown>"
```

## Output
Structured pricing comparison table. Change detection if prior version exists. Saved to state for ongoing tracking.
