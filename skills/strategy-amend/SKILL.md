---
name: strategy-amend
description: Use when metric-watcher or strategy-review detects significant drift from committed strategy — proposes a strategy update for founder review. Never auto-applies changes. Use when triggered by drift threshold breach.
trigger: event:drift-detected
requires_state:
  - strategy/strategy.md
  - metrics/daily/*
  - metrics/alerts.md
  - strategy/learnings.md
writes_state:
  - strategy/proposed-amendment.md
  - decisions/decisions.log.md
---

# Strategy Amend

Propose a targeted strategy update when data shows the current strategy is off-track. Always produces a proposed diff — **never applies changes without founder approval**.

## When to Use
- Drift alert in `metrics/alerts.md`
- `strategy-review` flags strategy misalignment
- "Our CAC has been rising for 6 weeks — we should adjust"
- Triggered automatically by `metric-watcher`

**NEVER auto-apply:** Amendments require explicit founder review and approval before being written to `strategy/strategy.md`.

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- `PEPPER_EVENT_SECRET` (for notifications)

## Workflow

### 1. Load state helpers

### 2. Hydrate context
```bash
STRATEGY=$(state_read "strategy/strategy.md")
ALERTS=$(state_read "metrics/alerts.md")
LEARNINGS=$(state_read "strategy/learnings.md")

# Load recent metrics (last 30 days)
RECENT_METRICS=""
for d in $(seq 0 30 | xargs -I{} date -d "{} days ago" +%Y-%m-%d 2>/dev/null || \
           seq 0 30 | xargs -I{} date -v-{}d +%Y-%m-%d 2>/dev/null); do
  DAY=$(state_read "metrics/daily/${d}.md")
  [ -n "$DAY" ] && RECENT_METRICS="${RECENT_METRICS}\n${DAY}"
done
```

### 3. Diagnose the drift

Analyze the gap between strategy commitments and actual metrics:
- What metric(s) are off-track?
- How long has the drift been happening?
- Is the drift accelerating?
- What experiments or bets are relevant?

### 4. Propose specific amendments

Focus on targeted, surgical changes — not a full strategy rewrite.

```
# Proposed Strategy Amendment — [date]

## Drift Summary
- [Metric]: [committed] vs [actual] for [N] weeks

## Root Cause Hypothesis
[1-2 sentences on why]

## Proposed Changes
### Keep
- [What's working and should continue]

### Amend
- **Before:** [current strategy text]
- **After:** [proposed new text]
- **Why:** [evidence from metrics/learnings]

### Pause
- [Bet or tactic to pause, with rationale]

## Risks
- [What could go wrong with this amendment]

## Decision Required
APPROVE: Write to strategy/strategy.md
REJECT: Keep current strategy, document why in decisions log
ITERATE: Request modifications (describe what to change)
```

### 5. Write proposed amendment
```bash
state_write "strategy/proposed-amendment.md" "$AMENDMENT"
```

### 6. Log the proposal
```bash
state_append "decisions/decisions.log.md" "---
Date: $(date +%Y-%m-%d)
Action: Strategy amendment proposed
Trigger: [drift type]
Requires: Founder approval"
```

### 7. Notify founder
Tell the user: amendment is in `strategy/proposed-amendment.md`. Review and reply APPROVE / REJECT / ITERATE.

## Output
- `strategy/proposed-amendment.md` — awaits approval
- `decisions/decisions.log.md` updated

## After Founder Approves
If approved: copy proposed amendment into `strategy/strategy.md` (use `state_write`), append decision log entry.
