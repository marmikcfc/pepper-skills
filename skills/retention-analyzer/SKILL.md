---
name: retention-analyzer
description: Use on monthly cron to analyze cohort retention and churn drivers — surfaces which customer segments are retaining vs. churning and why. Use when asked to understand retention health, churn patterns, or cohort performance.
trigger: cron:monthly 1st 09:30
requires_state:
  - strategy/icp.md
  - metrics/retention/*
writes_state:
  - metrics/retention/YYYY-MM.md
  - metrics/alerts.md
---

# Retention Analyzer

Monthly cohort retention and churn driver analysis. Answers: who is staying, who is leaving, and why.

## When to Use
- Monthly cron (1st of month)
- "Why are we churning so many customers?"
- "Which cohort has the best retention?"
- "What's driving expansion revenue?"

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- Access to product analytics (PostHog, Mixpanel, or Supabase) OR manual churn data

## Workflow

### 1. Load state helpers

### 2. Load context
```bash
ICP=$(state_read "strategy/icp.md")
LAST_MONTH=$(date -d "1 month ago" +%Y-%m 2>/dev/null || date -v-1m +%Y-%m)
PRIOR_RETENTION=$(state_read "metrics/retention/${LAST_MONTH}.md")
```

### 3. Collect retention data

Ask user to provide or pull from analytics:

```
Cohort retention data (ideally by signup month):
- Cohort [month]: N customers, retained at 30d: %, 60d: %, 90d: %
- MRR retention: [%]
- Expansion revenue this month: [N customers upgraded, $N]
- Churned this month: [N customers, $N MRR]
- Voluntary churn reasons: [source: exit surveys, support, founder calls]
```

### 4. Analyze patterns

For each churn reason, map to:
- ICP fit (was this customer in ICP or not?)
- Onboarding completion (did they activate?)
- Usage pattern (power user, occasional, ghost)
- Time to churn (0-30d, 31-90d, 90d+)

### 5. Identify top drivers

Rank churn drivers by MRR impact:

| Driver | % of Churned MRR | Fixable? |
|--------|-----------------|---------|
| Never activated | 40% | Yes — onboarding |
| Price sensitivity | 25% | Maybe — packaging |
| Competitor switch | 20% | Partial — battlecard |
| Use case mismatch | 15% | Partially — ICP |

### 6. Write monthly retention report
```bash
RETENTION_CONTENT="# Retention Analysis — $(date +%Y-%m)

## Headline Numbers
- MRR Retention: [%] (prior month: [%])
- Net Revenue Retention: [%]
- Churned MRR: $[N] ([N] customers)
- Expansion MRR: $[N]

## Cohort Performance

| Cohort | 30d | 60d | 90d | 6mo |
|--------|-----|-----|-----|-----|
| [month] | [%] | [%] | [%] | [%] |

## Churn Driver Analysis

### #1 — [Driver] ([% of MRR])
- Who: [customer profile]
- Why: [verbatim reason if available]
- Fix: [recommendation]

### #2 — [Driver]
...

## Retention Bright Spots
- [Segment or cohort with unusually high retention — why?]

## Actions
1. [Priority fix with owner]
2. ...

## ICP Alignment Check
- ICP customers retaining at: [%]
- Non-ICP customers retaining at: [%]
- Signal: [are we selling outside ICP?]

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

state_write "metrics/retention/$(date +%Y-%m).md" "$RETENTION_CONTENT"
```

### 7. Alert if MRR retention drops
```bash
# If MRR retention < 85% or significant drop from prior month:
state_write "metrics/alerts.md" "$(state_read 'metrics/alerts.md')

⚠️ [$(date +%Y-%m-%d)] Retention alert: MRR retention at [%]. See metrics/retention/$(date +%Y-%m).md"
```

## Output
- `metrics/retention/YYYY-MM.md` — monthly analysis
- `metrics/alerts.md` updated if threshold breached

## Next Step
Retention insights feed into `strategy-self-critique` (monthly) and `quarterly-planning` (quarterly).
