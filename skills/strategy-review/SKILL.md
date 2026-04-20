---
name: strategy-review
description: Run the weekly GTM strategy review. Reads strategy, metrics, bets, and experiments from state then produces a structured review for the current week.
---
# Strategy Review

Run the weekly GTM strategy review. Pulls all live context from state — strategy, latest metrics, active bets, running experiments — and produces a structured weekly review with what's working, what's not, decisions made, and flags for strategy amendments. Keeps the CMO loop tight and documented.

## When to Use

- End of each week as part of the regular GTM cadence
- After a significant metric movement (good or bad)
- Before a board or investor update
- When experiments have been running long enough to read early signals

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance
- `ANTHROPIC_API_KEY` — used to synthesize the review narrative
- `strategy/strategy.md` should exist (run `strategy-canvas` first)

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_list() { curl -sf "$PEPPER_CLOUD_URL/api/state/list?prefix=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; [print(e['path']) for e in json.load(sys.stdin)]"; }
```

**Step 1: Load all context**

```bash
STRATEGY=$(state_read "strategy/strategy.md")
BETS=$(state_read "bets/bets.md")
ALERTS=$(state_read "metrics/alerts.md")
RANKING=$(state_read "bets/ranking.md")

# Load latest daily metrics (last 7 days)
TODAY=$(date -u +%Y-%m-%d)
WEEK_ISO=$(date -u +%Y-%W)
METRICS_TODAY=$(state_read "metrics/daily/$TODAY.md")
METRICS_PREV=$(state_read "metrics/daily/$(date -u -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-7d +%Y-%m-%d).md")

# Load all active experiment paths
ACTIVE_EXP_PATHS=$(state_list "experiments/active/")
```

For each active experiment path, read its content:
```bash
# For each path in ACTIVE_EXP_PATHS:
EXP_CONTENT=$(state_read "$EXP_PATH")
```

**Step 2: Ask user for the week's context**

Ask a few brief questions to capture what can't be inferred from state:

1. "What was the single most important thing that happened this week? (1-2 sentences)"
2. "Any decisions made this week that aren't in the decision journal yet?"
3. "Any strategy concerns or questions you want to work through in this review?"

**Step 3: Synthesize the weekly review**

Pass all context to Claude:

> "Using the GTM state below, produce a structured weekly strategy review for the week of <week>.
>
> Format:
>
> ## Weekly Review — Week <YYYY-WW>
> Date: <today>
>
> ### North-Star Metric
> [current value vs target, 1-week trend: up/flat/down]
>
> ### What's Working
> [2-4 bullets: specific things generating traction this week]
>
> ### What's Not Working
> [2-4 bullets: specific things underperforming or stalled]
>
> ### Experiment Updates
> For each active experiment: status, early signal, days remaining, confidence change
>
> ### Bet Status
> For each active/pending bet: brief status update — any new signal to change priority?
>
> ### Key Decisions This Week
> [List decisions made, with rationale — 1 sentence each]
>
> ### Flags for Strategy Amendment
> [Anything that might warrant updating strategy/strategy.md — be specific]
>
> ### Next Week's Focus
> [Top 3 priorities for next week, ordered]
>
> Be direct and specific. Avoid filler. Flag problems honestly."
>
> Strategy: {strategy}
> Bets: {bets}
> Metrics today: {metrics_today}
> Metrics last week: {metrics_prev}
> Alerts: {alerts}
> Active experiments: {experiments}
> User notes: {user_notes}

**Step 4: Show review and get approval**

Display the full review to the user.

Ask: "Save this review to `reviews/weekly/$WEEK_ISO.md`? (yes/edit/no)"

- If `edit`: ask what to change, revise, show again, repeat
- If `no`: discard
- If `yes`: proceed to Step 5

**Step 5: Save review**

```bash
WEEK_ISO=$(date -u +%Y-%W)
state_write "reviews/weekly/$WEEK_ISO.md" "$REVIEW_CONTENT"
```

**Step 6: Log decisions to decision journal**

If any decisions were noted in the review:

Ask: "Log the [N] decisions from this review to the decision journal? (yes/no)"

If yes, for each decision:
```bash
state_append "decisions/decisions.log.md" "
---
Date: $(date -u +%Y-%m-%d)
Week: $WEEK_ISO
Decision: <decision text>
Rationale: <rationale>
Source: weekly-review
"
```

**Step 7: Flag strategy amendments**

If the "Flags for Strategy Amendment" section contains any items, ask:

"The review flagged potential strategy amendments. Run `strategy-canvas` to refresh `strategy/strategy.md`? (yes/later/no)"

Do not auto-run — just surface the recommendation.

Confirm: "Weekly review saved to `reviews/weekly/$WEEK_ISO.md`."

## Output

`reviews/weekly/YYYY-WW.md` — structured weekly GTM review with metric trend, what's working/not, experiment updates, bet status, decisions, and next week's focus.
