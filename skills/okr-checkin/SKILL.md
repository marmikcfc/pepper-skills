---
name: okr-checkin
description: Use on biweekly cron to check OKR progress, surface off-track key results, and propose new bets when KRs are lagging. Use when asked to review OKRs or check quarterly goal progress.
trigger: cron:biweekly Thursday 10:00
requires_state:
  - strategy/okrs.md
  - metrics/daily/*
  - bets/bets.md
writes_state:
  - okrs/checkins/YYYY-WW.md
  - bets/bets.md
---

# OKR Checkin

Biweekly progress review on committed OKRs. Flags lagging key results and proposes concrete bets to close the gap before quarter end.

## When to Use
- Biweekly cron (Thursday 10:00)
- "How are we doing against our OKRs?"
- "Which KRs are off track?"
- "We're 6 weeks into the quarter — what needs a plan?"

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- OKRs defined in `strategy/okrs.md`

## Workflow

### 1. Load state helpers

### 2. Load OKRs and current metrics
```bash
OKRS=$(state_read "strategy/okrs.md")
BETS=$(state_read "bets/bets.md")
TODAY_METRICS=$(state_read "metrics/daily/$(date +%Y-%m-%d).md")
WEEK=$(date +%Y-%W)
```

### 3. Assess each key result

For each KR, determine:
- Current value
- Target value
- % of quarter elapsed
- Expected value at this pace (linear extrapolation)
- Status: On Track / At Risk / Off Track / Complete

Status thresholds:
- **On Track:** ≥70% of linear target at current date
- **At Risk:** 50–69%
- **Off Track:** <50%
- **Complete:** ≥100%

### 4. For each Off Track KR: propose a bet
```bash
# For each Off Track KR, generate a specific, time-boxed bet:
# - What's the bet?
# - Expected impact on the KR (in KR units)
# - Time/cost estimate
# - How to measure
```

### 5. Write checkin
```bash
CHECKIN="# OKR Checkin — ${WEEK}
Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Objective: [Objective name]

| Key Result | Target | Current | Pace | Status |
|-----------|--------|---------|------|--------|
| [KR 1] | [target] | [actual] | [on pace for N] | ✅ On Track |
| [KR 2] | [target] | [actual] | [on pace for N] | ⚠️ At Risk |
| [KR 3] | [target] | [actual] | [on pace for N] | 🔴 Off Track |

## Off-Track KRs — Proposed Bets

### 🔴 [KR 3]
- **Gap:** Need [N] more by [quarter end date]
- **Bet:** [specific action]
- **Expected lift:** [N units of KR]
- **Time to run:** [N days/weeks]
- **Measure:** [how we'll know it worked]

**Approve this bet? Reply YES to add to bets/bets.md**

## Quarter Trajectory
At current pace:
- [KR 1]: Will hit [N]% of target
- [KR 2]: Will hit [N]% of target
- [KR 3]: Will hit [N]% of target

## Since Last Checkin
- [What moved and why]"

state_write "okrs/checkins/${WEEK}.md" "$CHECKIN"
```

### 6. Auto-propose approved bets
If the user replies YES to a proposed bet, append to bets.md:
```bash
state_append "bets/bets.md" "---
Date: $(date +%Y-%m-%d)
Bet: [bet name]
KR: [which KR it supports]
Expected lift: [N]
Status: proposed
Source: okr-checkin ${WEEK}"
```

## Output
- `okrs/checkins/YYYY-WW.md` — biweekly checkin
- `bets/bets.md` updated with new proposed bets (on approval)
