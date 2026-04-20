---
name: funding-signal-monitor
description: Monitor your TAM for new funding rounds and surface companies that just raised as outreach targets. Use when asked to find recently funded companies, monitor funding activity, or find companies with fresh budget.
---

# Funding Signal Monitor

Monitor your target market for new funding rounds. Companies that just raised have fresh budget, new growth mandates, and are often actively hiring and buying.

## When to Use
- "Find companies that just raised funding"
- "Monitor [industry] for new funding rounds"
- "Which companies in our TAM just got funded?"
- "Find companies with fresh budget to spend"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`

## Workflow

**Step 1: Load TAM and last scan timestamp**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

TAM=$(state_read "revops/tam.md")
LAST_SCAN=$(state_read "signals/funding_last_scan.md")
```
Default `LAST_SCAN` to 30 days ago if empty.

**Step 2: Scan for new funding events**
```bash
orth run funding-radar /funding-events \
  --body '{"industries": ["<target_industries_from_TAM>"], "since": "<LAST_SCAN>", "limit": 50}'
```

**Step 3: Dedup against already-seen signals**
```bash
SEEN=$(state_read "signals/seen_funding.md")
# For each funding event: echo "$SEEN" | grep "<company_domain>" && echo "skip" || echo "new"
# Only keep events where company_domain does NOT appear in $SEEN
```

**Step 4: Score and prioritize**
For each new funding event:
- ICP fit: cross-ref company against TAM (Tier 1 = 30 pts, Tier 2 = 20 pts, not in TAM = 5 pts)
- Round size: Series B+ = 20 pts, Series A = 15 pts, Seed = 10 pts
- Recency: <=7 days = 20 pts, <=14 days = 15 pts, <=30 days = 10 pts

**Step 5: Present results and get approval**
Table: Company | Round | Amount | Date | ICP Fit | Priority Score | Suggested Trigger

> "Found N newly funded companies. Should I save these signals to state? (yes/no)"

Only proceed if user confirms.

**Step 6: Update state after confirmation**
```bash
state_write "signals/funding_last_scan.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
state_append "signals/seen_funding.md" "<newline-separated company domains>"
state_append "signals/$(date +%Y-%m-%d).md" "<funding signals markdown>"
```

## Output
List of newly funded companies with ICP fit scores and outreach timing recommendations.
