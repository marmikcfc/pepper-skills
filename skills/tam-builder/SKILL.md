---
name: tam-builder
description: Build and maintain a scored Total Addressable Market (TAM). Discovers companies matching ICP criteria, scores fit (0-100), assigns tiers (1/2/3), and builds a persona watchlist. Use when asked to build a TAM, find target companies, or create a prospect universe.
---

# TAM Builder

Build and maintain a scored Total Addressable Market. Finds companies matching your ICP, scores them, tiers them, and surfaces contact personas for Tier 1-2 companies.

## When to Use
- "Build a TAM for [ICP description]"
- "Find target companies in [industry/location]"
- "Refresh my prospect universe"
- "Which companies should we be targeting?"

## Prerequisites
- `ORTHOGONAL_API_KEY` — for `orth run` commands
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL` — for state storage

## Modes
- **build** — First-time TAM construction
- **refresh** — Update existing TAM: re-score, detect tier changes
- **status** — Read-only report of current TAM state

## Workflow

### Setup — pepper-state helpers

Define these once at the top of every session:

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
state_append() { curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
```

### Build Mode

**Step 1: Load ICP context**
```bash
ICP=$(state_read "strategy/icp.md")
```
If empty, ask the user for ICP criteria: target industries, employee ranges, geographies, and funding stages. Save what they provide:
```bash
state_write "strategy/icp.md" "<ICP criteria from user>"
```

**Step 2: Find target companies — structured search**
```bash
orth run targeted-prospecting /prospect \
  --body '{"industries": ["<industry1>", "<industry2>"], "employee_range": "<e.g. 51-500>", "location": "<geo>", "limit": 100}'
```

**Step 3: Find target companies — natural language search for broader coverage**
```bash
orth run fiber /v1/natural-language-search/companies \
  --body '{"query": "<ICP description — e.g. B2B SaaS companies in the US with 50-500 employees>", "pageSize": 50}'
```

**Step 4: Score and tier each company (0-100)**

For each company returned, compute an ICP fit score using these weighted dimensions:
- Employee count fit: 30 points (does headcount match target range?)
- Industry fit: 25 points (does industry match targets?)
- Funding stage fit: 20 points (is funding stage in target list?)
- Geography fit: 15 points (is HQ in target geo?)
- Keyword match: 10 points (do company keywords overlap ICP keywords?)

Assign tiers:
- Tier 1: score ≥ 75
- Tier 2: score 50-74
- Tier 3: score < 50

**Step 5: Present sample and get user approval**

Show the user:
- Total companies found
- Tier distribution (e.g., Tier 1: 12, Tier 2: 31, Tier 3: 57)
- 5 example Tier 1 companies with scores and reasoning
- Scoring sanity check

Ask: "Does this look right? Should I adjust any scoring weights or filters before I build the full watchlist?"

**NEVER proceed to Step 6 without explicit user approval.**

**Step 6: Build persona watchlist for Tier 1-2 companies**

For each Tier 1-2 company, find the top 3 buyer personas:
```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "<target_title> at <company_name>", "pageSize": 3}'
```

Run for each company and each of your top 2-3 ICP persona titles.

**Step 7: Save TAM to state**
```bash
state_write "revops/tam.md" "<TAM markdown table>"
```

Format the TAM as a markdown table with: company name, score, tier, domain, industry, employee count, HQ location, and top personas (name, title).

### Refresh Mode

1. Load existing TAM: `state_read "revops/tam.md"`
2. Re-run Steps 2-3 with the same ICP filters
3. For companies already in TAM: re-score and detect tier changes (promotions/demotions)
4. For companies missing from new results for 2+ consecutive refreshes: mark as deprecated (skip companies with status `converted`)
5. For newly promoted Tier 3→2 companies: run persona search
6. Save updated TAM back to state

### Status Mode

1. Load TAM: `state_read "revops/tam.md"`
2. Present: total companies, tier counts, last refresh date, newly promoted/demoted companies

## Output

Markdown table of companies with ICP scores, tiers, and persona contacts. Written to `state_write("revops/tam.md")`. Also displayed inline for user review.
