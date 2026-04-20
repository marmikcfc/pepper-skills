---
name: experiment-monitor
description: Use on daily cron to check running experiments for statistical significance, guardrail breaches, or stale experiments past their end date. Alerts founder and triggers experiment-archive on completion.
trigger: cron:daily 09:00
requires_state:
  - experiments/active/*
  - metrics/daily/*
writes_state:
  - metrics/alerts.md
---

# Experiment Monitor

Daily check on all active experiments. Surfaces significance, guardrail breaches, and experiments past end date.

## When to Use
- Daily cron at 09:00
- "Check if any experiments are done"
- "Are we seeing significance yet on exp-007?"

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- Active experiments in `experiments/active/`
- Daily metrics in `metrics/daily/`

## Workflow

### 1. Load state helpers

### 2. List active experiments
```bash
ACTIVE_EXPS=$(state_list "experiments/active/")
# Filter to locked specs only (exclude .amendments.md)
LOCKED=$(echo "$ACTIVE_EXPS" | grep '\.locked\.md$')
echo "Active experiments: $(echo "$LOCKED" | wc -l)"
```

### 3. For each experiment

```bash
for EXP_PATH in $LOCKED; do
  EXP_ID=$(basename "$EXP_PATH" .locked.md)
  SPEC=$(state_read "$EXP_PATH")

  # Extract key fields from spec
  PRIMARY_METRIC=$(echo "$SPEC" | grep "Primary metric:" | head -1 | cut -d: -f2-)
  END_DATE=$(echo "$SPEC" | grep "Duration:" | head -1)
  MDE=$(echo "$SPEC" | grep "minimum detectable effect:" | head -1)

  # Pull today's metrics
  TODAY_METRICS=$(state_read "metrics/daily/$(date +%Y-%m-%d).md")

  # Check 1: Is experiment past end date?
  # Check 2: Is primary metric at stat-sig (p<0.05)?
  # Check 3: Is any guardrail metric breached?
  echo "Checking $EXP_ID..."
done
```

### 4. Synthesize status for each experiment

| Experiment | Days Running | Primary Metric | Status |
|-----------|-------------|---------------|--------|
| exp-007 | 12 / 14 | CTR: +8% | Trending sig |
| exp-008 | 3 / 21 | Activation: -2% | Guardrail watch |

### 5. Write alerts
```bash
ALERT_CONTENT="# Experiment Alerts — $(date +%Y-%m-%d)

## Completed (archive these)
- [exp-007]: 14 days, primary metric significant (p=0.02). WINNER: treatment.

## Guardrail Breach
- [exp-008]: Activation rate dropped 12% (guardrail: -5%). STOP.

## On Track
- [exp-009]: Day 3/21. No action needed.

Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

state_write "metrics/alerts.md" "$ALERT_CONTENT"
```

### 6. Trigger completions
For any completed experiments: tell the user to run `experiment-archive` with the experiment ID.

For guardrail breaches: notify immediately. Recommend stopping and archiving as failed.

## Output
- Updated `metrics/alerts.md`
- Summary message to founder

## Next Step
- Completed experiments: run `experiment-archive`
- Guardrail breach: stop experiment, run `experiment-archive` with result=failed
