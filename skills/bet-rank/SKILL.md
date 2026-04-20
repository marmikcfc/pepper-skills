---
name: bet-rank
description: Score and rank all pending bets using the ICE framework. Reads bets.md from state, scores by Impact × Confidence × Ease, and writes a ranked priority table to bets/ranking.md.
---
# Bet Rank

Score every pending bet in the ledger using the ICE framework (Impact × Confidence × Ease) and produce a ranked priority table. Helps you decide which bet to run first and makes prioritization transparent and auditable.

## When to Use

- Deciding which bet to execute next
- Before a strategy review to prepare the prioritization discussion
- After adding several new bets to the ledger and needing to re-rank
- When the team disagrees on what to work on next

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance
- `ANTHROPIC_API_KEY` — used to score each bet
- `bets/bets.md` must exist (run `bet-ledger` first if empty)

## ICE Framework

Each bet is scored on three dimensions, each 1–10:

- **Impact** — How much will this move the north-star metric if it works?
  - 10 = transformational (2× the metric), 1 = negligible
- **Confidence** — How confident are we the bet will produce the expected outcome?
  - 10 = strong evidence (customer pulled, proven pattern), 1 = pure hypothesis
- **Ease** — How easy is this to execute given current resources?
  - 10 = can ship in 1 day, 1 = requires months or major dependencies

**ICE Score = Impact × Confidence × Ease** (max 1000)

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

**Step 1: Load bets and context**

```bash
BETS=$(state_read "bets/bets.md")
STRATEGY=$(state_read "strategy/strategy.md")
METRICS=$(state_read "metrics/daily/$(date +%Y-%m-%d).md")
```

If `BETS` is empty, stop: "No bets found in `bets/bets.md`. Run `bet-ledger` to log bets first."

Parse the bets file — skip the header row, extract only rows with status `pending`.

**Step 2: Score each pending bet**

For each pending bet, pass its details to Claude with the strategy context:

> "Score this GTM bet on the ICE framework given the strategy context.
>
> Bet: {bet_title} — {hypothesis}
> Signal: {signal}
> Effort estimate: {effort_days} days
> Expected impact: {expected_impact}
>
> Strategy context: {strategy}
> Current metrics: {metrics}
>
> Return JSON only:
> {\"impact\": <1-10>, \"confidence\": <1-10>, \"ease\": <1-10>, \"impact_reason\": \"<one sentence>\", \"confidence_reason\": \"<one sentence>\", \"ease_reason\": \"<one sentence>\"}"

Calculate: `ice_score = impact * confidence * ease`

**Step 3: Produce ranked table**

Sort all scored bets by ICE score descending. Build the ranking output:

```
# Bet Rankings — <date>
Generated: <timestamp>
Strategy goal: <extract north-star metric from strategy.md>

| Rank | Bet Title | I | C | E | ICE Score | Status | Owner |
|------|-----------|---|---|---|-----------|--------|-------|
| 1    | ...       | 9 | 8 | 7 | 504       | pending | ... |
| 2    | ...       | ...                                        |
...

## Scoring Notes

### <Bet 1 Title>
- Impact (9): <reason>
- Confidence (8): <reason>
- Ease (7): <reason>

### <Bet 2 Title>
...

## Recommendation
Top bet to run next: <bet_title>
Rationale: <2-3 sentences on why this is the best first move given current context>
```

**Step 4: Show ranking and save**

Display the full ranking table to the user.

Ask: "Save this ranking to `bets/ranking.md`? (yes/no)"

Only if yes:

```bash
state_write "bets/ranking.md" "$RANKED_OUTPUT"
```

Confirm: "Ranking saved to `bets/ranking.md`. Highest-priority bet: <bet_title> (ICE: <score>)."

## Output

Ranked ICE table of all pending bets with per-dimension scores and reasoning, plus a top recommendation — saved to `bets/ranking.md`.
