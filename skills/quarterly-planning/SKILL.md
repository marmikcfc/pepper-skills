---
name: quarterly-planning
description: Use at the start of each quarter to generate OKRs and a prioritized bet backlog for the next 90 days — reads all strategy state and produces a founder-reviewable quarterly plan. Human approval required before committing to state.
trigger: cron:quarterly Q-start 09:00
requires_state:
  - strategy/strategy.md
  - strategy/icp.md
  - strategy/critique.md
  - strategy/learnings.md
  - bets/bets.md
  - metrics/retention/*
  - retros/*
  - experiments/archive/*
writes_state:
  - strategy/okrs.md
  - strategy/q-plan.md
  - decisions/decisions.log.md
---

# Quarterly Planning

Generate the next quarter's OKRs and prioritized bet backlog from the full strategy state. Always requires founder review — never commits without explicit approval.

## When to Use
- Start of each quarter (Jan 1, Apr 1, Jul 1, Oct 1)
- "Let's plan Q[N]"
- "What should we focus on next quarter?"

**Requires founder review and approval before OKRs are committed to state.**

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- At least one quarter of state data (learnings, retros, metrics)

## Workflow

### 1. Load state helpers

### 2. Hydrate full planning context
```bash
STRATEGY=$(state_read "strategy/strategy.md")
ICP=$(state_read "strategy/icp.md")
CRITIQUE=$(state_read "strategy/critique.md")
LEARNINGS=$(state_read "strategy/learnings.md")
BETS=$(state_read "bets/bets.md")

# Last 3 months of retros
RETROS=""
for m in 1 2 3; do
  MONTH=$(date -d "${m} months ago" +%Y-%m 2>/dev/null || date -v-${m}m +%Y-%m)
  RET=$(state_read "retros/${MONTH}.md")
  [ -n "$RET" ] && RETROS="${RETROS}\n${RET}"
done
```

### 3. Synthesize prior quarter learnings

From retros + experiment archive:
- What 3 things worked that we should double down on?
- What 2 things failed that we should stop?
- What's the #1 unresolved learning from last quarter?

### 4. Review strategy critique recommendations

From `strategy/critique.md`:
- What did the monthly critique recommend before this quarter?
- Which recommendations have we not yet acted on?

### 5. Generate proposed OKRs

OKR format:
- 1 overarching Objective (qualitative, inspiring)
- 3–4 Key Results (quantitative, measurable, time-bound)
- Suggested bets to hit each KR

**OKR quality checklist:**
- [ ] Objective is challenging but achievable in 90 days
- [ ] KRs are measurable with data we actually have
- [ ] KRs are outcomes, not outputs
- [ ] KRs are specific enough to debate progress

### 6. Generate prioritized bet backlog

For each proposed bet:
- Which KR does it support?
- ICE score: Impact (1-10), Confidence (1-10), Ease (1-10)
- ICE Total = (I + C + E) / 3
- Estimated time to run
- Who owns it

### 7. Write proposed quarterly plan
```bash
Q_PLAN="# Quarterly Plan — Q[N] $(date +%Y)
DRAFT — Awaiting founder approval

## Objective
[Single inspiring objective for the quarter]

## Key Results

| KR | Target | Current | How We'll Measure |
|----|--------|---------|------------------|
| 1. [KR] | [target] | [current] | [measurement] |
| 2. [KR] | [target] | [current] | [measurement] |
| 3. [KR] | [target] | [current] | [measurement] |

## Top Bets (prioritized by ICE)

| Rank | Bet | KR | ICE | Owner | Timeline |
|------|-----|-----|-----|-------|---------|
| 1 | [bet] | KR1 | 8.2 | [owner] | 2 weeks |
| 2 | [bet] | KR2 | 7.6 | [owner] | 3 weeks |
| ...  |

## What We're NOT Doing This Quarter
[List of ideas explicitly deprioritized — and why]

## Dependencies and Risks
- [Risk 1] — mitigation: [plan]

## Learnings We're Applying From Last Quarter
- [Learning] → [How it changes our approach this quarter]

## Critique Recommendations We're Acting On
- [Recommendation from strategy-self-critique]

---
DRAFT — Reply APPROVE to commit OKRs to strategy/okrs.md"

state_write "strategy/q-plan-draft.md" "$Q_PLAN"
```

### 8. Present to founder for approval

**Do NOT write to `strategy/okrs.md` until founder replies APPROVE.**

Show the plan and ask:
- Any OKR changes?
- Any bets to add or remove?
- Any dependencies we've missed?

### 9. On approval: commit
```bash
# Only after explicit APPROVE
state_write "strategy/okrs.md" "$COMMITTED_OKRS"
state_write "strategy/q-plan.md" "$Q_PLAN"

state_append "decisions/decisions.log.md" "---
Date: $(date +%Y-%m-%d)
Action: Q[N] plan approved
Objective: [objective]
OKRs: [N KRs committed]"
```

## Output (on approval)
- `strategy/okrs.md` — committed OKRs for the quarter
- `strategy/q-plan.md` — full quarterly plan
- `decisions/decisions.log.md` entry

## Next Step
OKRs are now live. `okr-checkin` will track progress biweekly.
