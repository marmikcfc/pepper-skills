---
name: strategy-self-critique
description: Use on monthly cron to red-team the current strategy against failure modes and market data — produces a critique the founder must read before the next quarterly planning cycle. Use when asked to challenge or stress-test current strategy.
trigger: cron:monthly 1st 09:00
requires_state:
  - strategy/strategy.md
  - strategy/learnings.md
  - reviews/weekly/*
  - metrics/retention/*
  - experiments/archive/*
writes_state:
  - strategy/critique.md
---

# Strategy Self-Critique

Monthly red-team of your current strategy. Challenges assumptions, surfaces blind spots, and names things that are probably wrong. Designed to be uncomfortable.

## When to Use
- Monthly cron (1st of month)
- "Play devil's advocate on our current strategy"
- Pre-quarterly planning (run before `quarterly-planning`)
- "What are we most wrong about right now?"

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- At least 4 weeks of weekly reviews in `reviews/weekly/`

## Approach

This skill plays the role of a sharp outside advisor who has read everything but owes you no comfort. The critique is meant to surface what's hidden, not to validate the current plan.

## Workflow

### 1. Load state helpers

### 2. Hydrate full context
```bash
STRATEGY=$(state_read "strategy/strategy.md")
LEARNINGS=$(state_read "strategy/learnings.md")
CRITIQUE_LAST=$(state_read "strategy/critique.md")  # Prior month's critique

# Recent weekly reviews
REVIEWS=""
for w in 4 3 2 1; do
  WEEK=$(date -d "${w} weeks ago" +%Y-%W 2>/dev/null || date -v-${w}d +%Y-%W)
  REV=$(state_read "reviews/weekly/${WEEK}.md")
  [ -n "$REV" ] && REVIEWS="${REVIEWS}\n\n---\n${REV}"
done

# Archived experiments
EXP_ARCHIVE=$(state_list "experiments/archive/" | head -10)
```

### 3. Run critique across 5 failure modes

**Failure Mode 1: ICP Drift**
- Is the ICP we're targeting still who we're actually winning?
- Are we chasing logos or chasing revenue?

**Failure Mode 2: Channel Exhaustion**
- Is our primary acquisition channel showing diminishing returns?
- What would happen if that channel went away?

**Failure Mode 3: Positioning Blurring**
- Has our messaging become broader to appeal to more people?
- Are we becoming a solution looking for problems?

**Failure Mode 4: Experiment Theater**
- Are we running experiments to feel rigorous, or to learn?
- What % of experiments in archive were "winner"? (Should be ~20-40%)
- Are experiments actually changing strategy?

**Failure Mode 5: Strategy-Reality Gap**
- What did strategy commit to that didn't happen?
- Have we rationalized delays or pivoted without documenting it?

### 4. Write critique
```bash
CRITIQUE="# Strategy Critique — $(date +%Y-%m-%d)

> This is a red-team. It is designed to make you uncomfortable.
> If everything looks fine, the critique failed.

## Most Likely Wrong Things (Top 3)

1. **[Assumption or claim]**
   Evidence against it: [specific data]
   Risk if wrong: [consequence]

2. **[Assumption or claim]**
   ...

3. ...

## Failure Mode Analysis

### ICP Drift
[Assessment — is it happening or not? Evidence.]

### Channel Exhaustion
[Assessment]

### Positioning Blurring
[Assessment]

### Experiment Theater
[Assessment — what % of experiments produced winning results? Are they being acted on?]

### Strategy-Reality Gap
[What was committed to that didn't happen? Was it documented?]

## What Last Month's Critique Got Right
[Honest look at prior critique — did we act on it?]

## Non-Obvious Risks
[2-3 things that aren't in the risk register but should be]

## Recommended Actions (in priority order)
1. [Action] — do before quarterly planning
2. [Action]
3. [Action]

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

state_write "strategy/critique.md" "$CRITIQUE"
```

## Output
- `strategy/critique.md` — monthly red-team

## Next Step
Critique feeds into `quarterly-planning`. Founder must read and respond before quarterly planning runs.
