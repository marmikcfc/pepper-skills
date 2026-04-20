---
name: bet-ledger
description: Log a new strategic bet to the append-only bet ledger. Use when committing to a new GTM experiment, channel, or positioning move.
---
# Bet Ledger

Log a strategic GTM bet to the append-only bet ledger. Every deliberate commitment — a new channel, a positioning move, a pricing experiment, an ICP expansion — should be recorded here before execution. The ledger feeds the `bet-rank` and `experiment-design` skills.

## When to Use

- Committing to a new GTM bet, channel, or experiment
- Formalizing an idea from a strategy review session
- Recording a decision that came out of a weekly review
- Building the backlog of bets to rank with `bet-rank`

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance

## Bet Format

Each bet is one row in `bets/bets.md`:

```
date | bet_title | hypothesis | signal | effort_days | expected_impact | owner | status
```

- `date` — ISO date logged (YYYY-MM-DD)
- `bet_title` — short name, 3-6 words
- `hypothesis` — "We believe [action] will cause [outcome] because [reason]"
- `signal` — what evidence or insight triggered this bet
- `effort_days` — estimated person-days to run the experiment
- `expected_impact` — qualitative impact on the north-star metric
- `owner` — person or agent responsible
- `status` — `pending` / `active` / `complete` / `killed`

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

**Step 1: Show existing bets**

```bash
EXISTING_BETS=$(state_read "bets/bets.md")
```

If `EXISTING_BETS` is non-empty, display the current ledger so the user can see what bets are already logged before adding a new one.

If empty, note: "No bets logged yet. Starting a new ledger."

**Step 2: Collect new bet details**

Ask the user for each field in sequence. Provide examples to reduce friction:

1. **Bet title** — "Short name for this bet? (e.g., 'HN Show Launch', 'DevRel Channel', 'Pricing Anchor Test')"
2. **Hypothesis** — "Complete this: 'We believe [action] will cause [outcome] because [reason]'"
3. **Signal** — "What triggered this bet? (e.g., '3 prospects asked about X', 'competitor launched Y', 'community thread had 200 comments')"
4. **Effort estimate** — "Estimated person-days to run this experiment? (e.g., 3, 10, 20)"
5. **Expected impact** — "What impact do you expect on the north-star metric? (e.g., '+5 pilots', '+$10K MRR', 'validate pricing hypothesis')"
6. **Owner** — "Who owns this bet? (name or 'agent')"

**Step 3: Compose the entry**

```bash
TODAY=$(date -u +%Y-%m-%d)
BET_ENTRY="$TODAY | $BET_TITLE | $HYPOTHESIS | $SIGNAL | $EFFORT_DAYS | $EXPECTED_IMPACT | $OWNER | pending"
```

Show the composed entry to the user:

```
New bet entry:
  $BET_ENTRY

Append to bets/bets.md? (yes/no)
```

**Step 4: Append to ledger**

Only proceed if user confirms:

```bash
state_append "bets/bets.md" "
$BET_ENTRY"
```

Confirm: "Bet logged to `bets/bets.md`. Run `bet-rank` to score it against existing bets, or `experiment-design` to build a full experiment spec."

## Output

One new row appended to `bets/bets.md` with status `pending`. The bet is now available for ranking with `bet-rank` and experiment design with `experiment-design`.
