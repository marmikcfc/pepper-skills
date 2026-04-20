---
name: experiment-preregister
description: Use when locking in an experiment spec before running it — prevents HARKing (hypothesizing after results are known). Use when a bet has been approved and needs a tamper-proof record before traffic or spend is committed.
trigger: event:bet-approved
requires_state:
  - experiments/active/exp-NNN.md
  - bets/bets.md
writes_state:
  - experiments/active/exp-NNN.locked.md
---

# Experiment Preregister

Lock an experiment spec with a cryptographic hash before data collection starts. Prevents post-hoc rationalization and keeps the strategy loop honest.

## When to Use
- "Lock this experiment before we start"
- A bet has been approved in `bets/bets.md`
- Before committing budget or engineering time to an experiment

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- Experiment ID (e.g. `exp-007`)

## Workflow

### 1. Load state helpers (see pepper-state skill)

### 2. Read the experiment draft
```bash
EXP_ID="exp-007"  # replace with actual ID
DRAFT=$(state_read "experiments/active/${EXP_ID}.md")
echo "$DRAFT"
```

Confirm these fields are present before locking:
- Hypothesis (falsifiable claim)
- Primary metric + minimum detectable effect
- Control and treatment definition
- Traffic split and sample size calculation
- Guardrail metrics (what would cause early stop)
- Duration (days)
- Decision rule (what constitutes success)

### 3. Generate SHA256 hash
```bash
HASH=$(echo "$DRAFT" | sha256sum | awk '{print $1}')
LOCKED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

### 4. Write locked spec
```bash
LOCKED_CONTENT="# PREREGISTERED EXPERIMENT — DO NOT EDIT

Locked: ${LOCKED_AT}
SHA256: ${HASH}

## Original Spec

${DRAFT}

## Lock Certification
This experiment spec was locked before data collection. Any changes to hypothesis,
metrics, or decision rules after this lock must be documented as protocol amendments
with justification in \`experiments/active/${EXP_ID}.amendments.md\`."

state_write "experiments/active/${EXP_ID}.locked.md" "$LOCKED_CONTENT"
```

### 5. Update bet status
```bash
# Mark bet as "in experiment" in bets.md
BETS=$(state_read "bets/bets.md")
# Append status update
state_append "bets/bets.md" "**[$(date +%Y-%m-%d)] ${EXP_ID} preregistered — spec locked at ${HASH:0:8}**"
```

### 6. Confirm to user
Report: experiment ID, hash prefix, locked timestamp, duration, decision date.

## Output
- `experiments/active/exp-NNN.locked.md` — tamper-proof spec
- Append to `bets/bets.md` with lock timestamp

## Next Step
Run `experiment-monitor` on cron to check significance daily.
