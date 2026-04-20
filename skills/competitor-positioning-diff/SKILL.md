---
name: competitor-positioning-diff
description: Use on weekly cron to detect changes in competitor messaging, pricing, and ad creative — surfaces shifts in positioning before they affect pipeline. Use when asked to monitor competitors or track what changed this week.
trigger: cron:weekly Wednesday 10:00
requires_state:
  - competitors/snapshots/*
  - strategy/strategy.md
writes_state:
  - competitors/diffs/YYYY-WW.md
  - metrics/alerts.md
---

# Competitor Positioning Diff

Weekly competitive intelligence delta — what changed in competitor messaging, pricing, and ads since last week. Surfaces positioning shifts early so you can respond.

## When to Use
- Weekly cron (Wednesday 10:00)
- "What changed with [competitor] this week?"
- Before a board meeting or investor update
- When a competitor makes a big announcement

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- Competitors list in `strategy/strategy.md` or `company/company.md`

## Workflow

### 1. Load state helpers

### 2. Get competitor list
```bash
STRATEGY=$(state_read "strategy/strategy.md")
# Extract competitors (or ask user if not set)
COMPETITORS=("competitor-a.com" "competitor-b.com" "competitor-c.com")
```

### 3. For each competitor: snapshot current state

```bash
WEEK=$(date +%Y-%W)

for COMP in "${COMPETITORS[@]}"; do
  COMP_SLUG=$(echo "$COMP" | tr '.' '-')

  # Current intel
  orth run competitor-research --query "{\"company\": \"${COMP}\"}" > /tmp/intel_${COMP_SLUG}.json

  # Pricing page
  orth run seo-analyzer --query "{\"url\": \"https://${COMP}/pricing\"}" > /tmp/pricing_${COMP_SLUG}.json

  # Ad creative
  orth run ad-creative-intelligence --query "{\"domain\": \"${COMP}\"}" > /tmp/ads_${COMP_SLUG}.json
done
```

### 4. Load prior week snapshot
```bash
PREV_WEEK=$(date -d "7 days ago" +%Y-%W 2>/dev/null || date -v-7d +%Y-%W 2>/dev/null)
PRIOR_SNAPSHOT=$(state_read "competitors/snapshots/${PREV_WEEK}.md")
```

### 5. Diff and synthesize

Compare current vs prior week for each competitor:
- Homepage headline / hero copy changes
- Pricing page changes (new tiers, price changes, feature moves)
- New ad hooks / messaging angles
- New blog posts / content topics
- LinkedIn activity shifts
- Job postings (signals hiring in new areas)

### 6. Write weekly diff
```bash
DIFF_CONTENT="# Competitor Positioning Diff — Week ${WEEK}

## TL;DR
[2-3 sentence summary of most important changes]

## Changes by Competitor

### [Competitor A]
- **Messaging:** [what changed]
- **Pricing:** [what changed or no change]
- **Ads:** [new hooks observed]
- **Content:** [new topics]
- **Signal:** [what this suggests about their strategy]

### [Competitor B]
...

## Implications for Our Strategy
- [How we should respond, if at all]
- [Any urgent battlecard updates needed]

## No Change
- [Competitors with no significant changes]

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

state_write "competitors/diffs/${WEEK}.md" "$DIFF_CONTENT"

# Save current snapshot for next week
SNAPSHOT="$(cat /tmp/intel_*.json | python3 -c 'import json,sys; data={}; [data.update(json.load(open(f))) for f in sys.argv[1:]]; print(json.dumps(data))' /tmp/intel_*.json)"
state_write "competitors/snapshots/${WEEK}.md" "$SNAPSHOT"
```

### 7. Alert if significant change detected
```bash
# If major shift detected (new pricing tier, major message change):
state_write "metrics/alerts.md" "$(state_read 'metrics/alerts.md')

⚠️ [$(date +%Y-%m-%d)] Competitor shift: [description]. See competitors/diffs/${WEEK}.md"
```

## Output
- `competitors/diffs/YYYY-WW.md` — weekly diff
- `competitors/snapshots/YYYY-WW.md` — current snapshot (used next week)
- `metrics/alerts.md` updated if significant change
