---
name: gtm-state-diff
description: Compare the current GTM state to the prior snapshot and produce a plain-English diff. Shows what changed across strategy, ICP, bets, experiments, and metrics over the past week.
---
# GTM State Diff

Read-only analysis skill. Compares the current state of your GTM workspace to the prior week's snapshot and produces a plain-English summary of what changed. Useful for weekly standup prep, board updates, or understanding drift between strategy sessions.

## When to Use

- Before a weekly strategy review to understand what shifted
- Preparing a board or investor update ("what changed since last time")
- After returning from time away and wanting to catch up on workspace state
- Auditing whether the strategy is drifting from the original direction

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance
- At least one prior week of state (this skill is read-only, never writes)

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_list() { curl -sf "$PEPPER_CLOUD_URL/api/state/list?prefix=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; [print(e['path']) for e in json.load(sys.stdin)]"; }
```

**Step 1: Establish the comparison window**

```bash
TODAY=$(date -u +%Y-%m-%d)
LAST_WEEK=$(python3 -c "
from datetime import date, timedelta
print((date.today() - timedelta(days=7)).isoformat())
")
CURRENT_WEEK_ISO=$(date -u +%Y-%W)
LAST_WEEK_ISO=$(python3 -c "
from datetime import date, timedelta
d = date.today() - timedelta(days=7)
print(d.strftime('%Y-%W'))
")
```

**Step 2: Read current and prior state for each major section**

```bash
# Strategy
STRATEGY_NOW=$(state_read "strategy/strategy.md")
POSITIONING_NOW=$(state_read "strategy/positioning.md")
ICP_NOW=$(state_read "strategy/icp.md")

# Bets
BETS_NOW=$(state_read "bets/bets.md")
RANKING_NOW=$(state_read "bets/ranking.md")

# Experiments — list both active and archive
ACTIVE_NOW=$(state_list "experiments/active/")
ARCHIVE_NOW=$(state_list "experiments/archive/")

# Metrics — today vs last week
METRICS_NOW=$(state_read "metrics/daily/$TODAY.md")
METRICS_PREV=$(state_read "metrics/daily/$LAST_WEEK.md")
ALERTS_NOW=$(state_read "metrics/alerts.md")

# Reviews — current vs prior week
REVIEW_NOW=$(state_read "reviews/weekly/$CURRENT_WEEK_ISO.md")
REVIEW_PREV=$(state_read "reviews/weekly/$LAST_WEEK_ISO.md")

# Decisions log
DECISIONS=$(state_read "decisions/decisions.log.md")
```

**Step 3: Compute structural diffs**

```python
python3 -c "
import sys

# Count bets by status
def count_status(bets_text, status):
    if not bets_text: return 0
    return sum(1 for line in bets_text.split('\n') if f'| {status}' in line)

# Active experiments delta
active_now = '''$ACTIVE_NOW'''.strip().split('\n') if '$ACTIVE_NOW'.strip() else []
active_now = [p for p in active_now if p.strip()]
archive_now = '''$ARCHIVE_NOW'''.strip().split('\n') if '$ARCHIVE_NOW'.strip() else []
archive_now = [p for p in archive_now if p.strip()]

print(f'Active experiments: {len(active_now)}')
print(f'Archived experiments: {len(archive_now)}')
"
```

**Step 4: Synthesize plain-English diff**

Pass all collected state to Claude:

> "Produce a concise plain-English GTM state diff summary comparing this week to last week.
>
> Structure:
>
> ## GTM State Diff — <today> vs <last_week>
>
> ### Strategy
> [Did strategy.md, positioning.md, or icp.md change? If yes, summarize what shifted in 1-2 sentences each. If no change detected, say 'No changes.']
>
> ### Bets
> [How many bets total? Any new bets added? Any status changes (pending→active→complete/killed)? Summarize in 2-3 bullets.]
>
> ### Experiments
> [How many active experiments? Any launched or concluded this week? Any early signals worth noting?]
>
> ### Metrics
> [Key metric movements: which metrics improved, which declined, any new alerts? Compare today vs last week values.]
>
> ### Decisions
> [Any decisions logged to the decision journal this week? List titles only.]
>
> ### Overall Assessment
> [1-2 sentence summary: 'This week the GTM motion [accelerated/held steady/slowed] because...' Be specific.]
>
> Keep the entire diff under 300 words. Be direct and honest — surface problems as clearly as wins."
>
> Strategy now: {strategy_now}
> Positioning now: {positioning_now}
> ICP now: {icp_now}
> Bets now: {bets_now}
> Active experiments now: {active_now}
> Metrics now: {metrics_now}
> Metrics last week: {metrics_prev}
> Alerts: {alerts_now}
> Decisions log: {decisions}
> Review this week: {review_now}
> Review last week: {review_prev}

**Step 5: Present the diff**

Show the full plain-English diff to the user.

This skill never writes to state. Read-only analysis only.

If the user asks "what changed in [specific section]" after seeing the diff, drill in by showing the raw content of the relevant state paths side by side.

## Output

Plain-English GTM state diff covering strategy, bets, experiments, metrics, and decisions — what changed over the past week and an overall assessment of momentum.
