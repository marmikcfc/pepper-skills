---
name: experiment-archive
description: Use when an experiment is complete, stopped, or abandoned — archives the spec with results, updates the bet ledger, and distills learnings. Use after experiment-monitor flags completion or guardrail breach.
trigger: event:experiment-complete
requires_state:
  - experiments/active/exp-NNN.locked.md
  - bets/bets.md
writes_state:
  - experiments/archive/exp-NNN.md
  - bets/bets.md
  - strategy/learnings.md
---

# Experiment Archive

Archive a completed experiment with full results and distilled learnings. Updates the bet ledger so future strategy work can learn from what worked.

## When to Use
- experiment-monitor signals completion or guardrail breach
- "Archive exp-007, it was a winner"
- "We stopped exp-008 early — guardrail breach"

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- Experiment ID and result (winner/failed/inconclusive/stopped)

## Workflow

### 1. Load state helpers

### 2. Read the locked spec
```bash
EXP_ID="exp-007"
RESULT="winner"  # winner | failed | inconclusive | stopped

SPEC=$(state_read "experiments/active/${EXP_ID}.locked.md")
```

### 3. Collect results from user
Ask for:
- Primary metric: actual vs control (e.g., "CTR: 4.2% vs 3.8%, +10.5%")
- Secondary metrics
- p-value / confidence interval
- Sample size reached
- Any anomalies observed

### 4. Build archive record
```bash
ARCHIVE_CONTENT="# ${EXP_ID} — Archive

**Result:** ${RESULT} ($(date +%Y-%m-%d))

## Original Spec
${SPEC}

## Results
- Primary metric: [actual vs control]
- p-value: [value]
- Sample size: [N treatment] / [N control]
- Duration: [actual days] / [planned days]

## Learnings
1. [What we learned — stated as a generalizable principle, not just an observation]
2. [What we'd do differently]
3. [What this suggests for future bets]

## Decision
[SHIP / ROLLBACK / ITERATE — with rationale]"

state_write "experiments/archive/${EXP_ID}.md" "$ARCHIVE_CONTENT"
```

### 5. Remove from active
```bash
# Note: no delete API — just flag as archived in alerts
state_write "metrics/alerts.md" "$(state_read 'metrics/alerts.md')

[$(date +%Y-%m-%d)] ${EXP_ID} archived. Result: ${RESULT}."
```

### 6. Update bet ledger
```bash
state_append "bets/bets.md" "**[$(date +%Y-%m-%d)] ${EXP_ID} archived — Result: ${RESULT}. Decision: [SHIP/ROLLBACK/ITERATE]**"
```

### 7. Append learning to master learnings log
```bash
LEARNING="---
Date: $(date +%Y-%m-%d)
Experiment: ${EXP_ID}
Result: ${RESULT}
Learning: [distilled principle]"

state_append "strategy/learnings.md" "$LEARNING"
```

## Output
- `experiments/archive/exp-NNN.md` — full archive
- `bets/bets.md` updated with outcome
- `strategy/learnings.md` updated with learning

## Next Step
Learnings feed into `strategy-review` (weekly) and `strategy-self-critique` (monthly).
