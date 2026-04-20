---
name: retro
description: Use on monthly cron to run a GTM retrospective — what bets played out, what failed, what we learned, and what goes into the playbook. Use when asked to run a retro, review last month, or distill learnings from experiments.
trigger: cron:monthly 1st 10:00
requires_state:
  - bets/bets.md
  - experiments/archive/*
  - reviews/weekly/*
  - strategy/learnings.md
writes_state:
  - retros/YYYY-MM.md
  - playbooks/YYYY-MM-learnings.md
  - strategy/learnings.md
---

# Retro

Monthly retrospective on GTM bets and experiments. Distills what actually worked into reusable playbooks so the team gets smarter every month.

## When to Use
- Monthly cron (1st of month)
- "What did we learn last month?"
- "Run a retro on last quarter"
- "What should go in our playbook?"

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`

## Workflow

### 1. Load state helpers

### 2. Hydrate retro context
```bash
BETS=$(state_read "bets/bets.md")
LEARNINGS=$(state_read "strategy/learnings.md")

# Weekly reviews from last month
MONTH=$(date -d "1 month ago" +%Y-%m 2>/dev/null || date -v-1m +%Y-%m)
REVIEWS=""
for w in 1 2 3 4; do
  WEEK=$(date -d "${w} weeks ago" +%Y-%W 2>/dev/null || date -v-${w}d +%Y-%W)
  REV=$(state_read "reviews/weekly/${WEEK}.md")
  [ -n "$REV" ] && REVIEWS="${REVIEWS}\n${REV}"
done

# Archived experiments this month
EXP_LIST=$(state_list "experiments/archive/" | grep "$MONTH" || true)
```

### 3. Structure the retro

**Section 1: Bets Review**
For each bet from last month: Won / Lost / Still running / Abandoned?

**Section 2: Experiment Results**
Archive entries from the month — what was the hit rate? What learnings applied?

**Section 3: What We'd Do Differently**
Not what went wrong — what would you change knowing what you know now?

**Section 4: Playbook Entry**
What can we codify so we don't have to rediscover this?

### 4. Write the retro
```bash
RETRO_CONTENT="# GTM Retro — ${MONTH}

## Bets Placed Last Month

| Bet | Status | Result | Learning |
|-----|--------|--------|---------|
| [bet name] | Won/Lost/Open | [outcome] | [what we learned] |

## Experiment Hit Rate
- Experiments completed: [N]
- Winners: [N] ([%])
- Failed/inconclusive: [N]
- Stopped early: [N]

## What Worked
1. [tactic/approach] — evidence: [result]
2. ...

## What Didn't
1. [tactic/approach] — why: [honest assessment]
2. ...

## What We'd Do Differently
1. [specific change]
2. ...

## Surprises
- [Something unexpected that happened — positive or negative]

## Playbook Entry
**Title:** [Reusable principle]
**Pattern:** [When to apply it]
**Evidence:** [Why we trust this]
**Do:** [Specific action]
**Avoid:** [Specific anti-pattern]

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

state_write "retros/${MONTH}.md" "$RETRO_CONTENT"
```

### 5. Write to playbook
```bash
PLAYBOOK_ENTRY="# Learnings — ${MONTH}

[Extract the playbook entry from retro — the generalizable principle]"

state_write "playbooks/${MONTH}-learnings.md" "$PLAYBOOK_ENTRY"
```

### 6. Append to master learnings log
```bash
state_append "strategy/learnings.md" "---
Month: ${MONTH}
Source: retro
Learnings: [distilled from retro]"
```

## Output
- `retros/YYYY-MM.md` — full monthly retro
- `playbooks/YYYY-MM-learnings.md` — reusable principles
- `strategy/learnings.md` updated

## Next Step
Retro feeds into `quarterly-planning` and `strategy-self-critique`.
