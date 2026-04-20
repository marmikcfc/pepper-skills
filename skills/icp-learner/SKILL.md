---
name: icp-learner
description: Use on weekly cron to update ICP definition based on closed-won and closed-lost patterns — keeps targeting sharp as the market responds. Use when asked to update ICP or analyze who is actually buying vs. who we thought would buy.
trigger: cron:weekly Friday 16:00
requires_state:
  - strategy/icp.md
  - bets/bets.md
writes_state:
  - strategy/icp.md
  - decisions/decisions.log.md
---

# ICP Learner

Update your Ideal Customer Profile weekly based on evidence from actual buyers. Prevents ICP drift and keeps prospecting targeted on who actually converts.

## When to Use
- Weekly cron (Friday 16:00)
- "Update ICP based on who closed this quarter"
- "We're getting a lot of inbound from [segment] — should we update ICP?"
- After a significant won/lost pattern emerges

## Prerequisites
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY`
- Source of closed-won/lost data (CRM, deal notes, or paste in manually)

## Data Sources (in priority order)
1. CRM export (Hubspot, Salesforce, Pipedrive) — ideal
2. Deal notes pasted directly by founder
3. Gmail search for "happy customers" or "churned" signals
4. `revops` skill (if configured)

## Workflow

### 1. Load state helpers

### 2. Load current ICP
```bash
CURRENT_ICP=$(state_read "strategy/icp.md")
echo "Current ICP:"
echo "$CURRENT_ICP"
```

### 3. Collect closed-won/lost data

Ask the user for recent deal data or use CRM export:
```
For each closed-won deal in last 30/90 days:
- Company: name, size, industry, tech stack
- Champion: role, seniority
- Why they bought (verbatim if possible)
- Time to close
- ACV

For each closed-lost deal:
- Company profile
- Why lost (verbatim if possible)
- Where they went instead
```

### 4. Enrich for pattern matching

For each deal, cross-reference with enrichment data:
```bash
for EMAIL in $CHAMPION_EMAILS; do
  orth run person-enrichment --query "{\"email\": \"${EMAIL}\"}" >> /tmp/champion_profiles.json
done
```

### 5. Identify ICP shifts

Analyze patterns across won/lost:
- What company attributes correlate with fast closes?
- What champion roles correlate with highest ACV?
- What objections appear in lost deals? Is the ICP "aspirational" vs. "actual"?
- Are there unexpected winning segments?

### 6. Update ICP

```bash
UPDATED_ICP="# ICP — $(date +%Y-%m-%d) (v[N+1])

> Previous version: [date]
> Changed by: icp-learner cron

## Primary ICP (80% of revenue)
- **Company size:** [N-M employees]
- **Industry:** [industry]
- **Tech stack signals:** [signals]
- **Champion role:** [role]
- **Trigger event:** [what makes them buy now]
- **Why they buy:** [verbatim patterns]

## Secondary ICP (20%)
[if applicable]

## Anti-ICP (exclude from prospecting)
- [pattern 1 — evidence]
- [pattern 2 — evidence]

## Changes This Update
- [What changed from prior version]
- [Evidence driving the change]

## Data Sources
- Closed-won: N deals
- Closed-lost: N deals
- Date range: [range]"

state_write "strategy/icp.md" "$UPDATED_ICP"
```

### 7. Log the update
```bash
state_append "decisions/decisions.log.md" "---
Date: $(date +%Y-%m-%d)
Action: ICP updated
Changes: [summary of what changed]
Evidence: [N won, N lost deals analyzed]"
```

## Output
- Updated `strategy/icp.md` with version history
- `decisions/decisions.log.md` entry

## Next Step
Updated ICP flows into `targeted-prospecting`, `signal-scanner`, and `strategy-review`.
