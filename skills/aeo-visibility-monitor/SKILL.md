---
name: aeo-visibility-monitor
description: Track your AEO visibility over time and alert when scores change significantly. Use when asked to monitor AEO trends, set up AEO tracking, or compare current vs. past AI search visibility.
---

# AEO Visibility Monitor

Track AEO visibility over time and surface meaningful changes in AI search presence.

## When to Use
- "Track our AEO score over time"
- "How has our AI search visibility changed?"
- "Monitor our AEO and alert me to changes"
- "Compare our current AEO to last month"

## Prerequisites
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY` (optional)
- `ORTHOGONAL_API_KEY` (for Perplexity)
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`

## Workflow

**Step 1: Load baseline AEO data**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

BASELINE=$(state_read "seo/aeo_baseline.md")
```
If empty, run `aeo-visibility` first to establish baseline, then save:
```bash
state_write "seo/aeo_baseline.md" "<aeo_scores>"
```

**Step 2: Run current AEO check**
Run the `aeo-visibility` skill using the same 10 test queries stored in the baseline.

**Step 3: Compare against baseline with LLM**
Pass baseline scores and current scores to Claude:
> "Compare these two AEO visibility reports and identify:
> 1. Overall score changes per engine (improved / declined / stable)
> 2. Specific queries where position changed
> 3. New competitors appearing where they weren't before
> 4. Queries where we dropped out of responses entirely
> 5. Queries where we newly appeared
> Flag anything that changed by more than 10 points as significant."

**Step 4: Alert on significant changes**
Present changes. Flag if: score dropped >10 points, competitor appeared in a key query, brand disappeared from a key query.

**Step 5: Update state**
> "Should I save the current AEO scores and log this run to history? (yes/no)"

Only proceed if user confirms:
```bash
state_write "seo/aeo_latest.md" "<current_scores>"
state_append "seo/aeo_history.md" "$(date +%Y-%m-%d) | <summary_scores>"
```

## Output
AEO trend report showing changes from baseline, significant movements, and updated history log.
