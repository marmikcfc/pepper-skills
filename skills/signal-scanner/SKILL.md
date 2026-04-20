---
name: signal-scanner
description: Detect buying signals across target companies — funding rounds, hiring surges, competitor post engagement, and product launches. Use when asked to scan for signals, find companies showing buying intent, or run a signal sweep.
---

# Signal Scanner

Detect buying signals across your TAM: funding rounds, new hires, competitor engagement, and product launches. Writes detected signals to state for downstream outreach activation.

## When to Use
- "Scan for signals across our TAM"
- "Which companies just raised funding?"
- "Find companies showing buying intent"
- "Run a signal sweep"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`

## Signal Types

| Signal | Tool | Priority |
|--------|------|----------|
| Funding round | funding-radar | P0 |
| Hiring surge (relevant roles) | hiring-signals | P0 |
| New product launches | startup-launches | P1 |
| GitHub activity | github | P1 |
| Competitor post engagement | linkedin-post-comments | P2 |

## Workflow

**Step 1: Load TAM**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

TAM=$(state_read "revops/tam.md")
LAST_RUN=$(state_read "signals/last_run.md")
```
If TAM is empty, tell the user to run `tam-builder` first.

**Step 2: Funding signals**
For each Tier 1-2 company in TAM:
```bash
orth run funding-radar /funding-events \
  --body '{"company": "<company_name>", "since": "<last_run_date>"}'
```

**Step 3: Hiring signals**
```bash
orth run hiring-signals /jobs \
  --body '{"company": "<company_name>", "keywords": ["VP", "director", "head of"], "limit": 5}'
```

**Step 4: New launches**
```bash
orth run startup-launches /launches \
  --body '{"query": "<industry> new product launch", "limit": 20}'
```

**Step 5: Dedup against already-seen signals**
```bash
SEEN=$(state_read "signals/seen.md")
# For each signal, check: echo "$SEEN" | grep "<company_id>" && echo "already seen" || echo "new signal"
# Only keep signals whose company_id does NOT appear in $SEEN
```

**Step 6: Score signals**
Score each signal 1-10: funding=10, hiring surge=8, launch=6, GitHub activity=4, competitor engagement=3. Multiply by company tier weight (Tier 1=1.0, Tier 2=0.8, Tier 3=0.5).

**Step 7: Present and get approval**
Show: total signals found by type, top 10 ranked by score.

> "Found N signals. Top 10 shown above. Should I save these to state? (yes/no)"

Only proceed if user confirms.

**Step 8: Write signals to state**
```bash
state_write "signals/last_run.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
state_append "signals/seen.md" "<newline-separated company_ids of processed signals>"
state_append "signals/$(date +%Y-%m-%d).md" "<signals markdown table>"
```

## Output
Ranked list of signals with company, signal type, date, and suggested outreach trigger. Written to `signals/YYYY-MM-DD.md`.
