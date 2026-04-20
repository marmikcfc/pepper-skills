---
name: pain-point-content-map
description: Map content assets to customer pain points across funnel stages to identify gaps and prioritize new content. Use when auditing content coverage or building a content strategy rooted in buyer needs.
---

# Pain Point Content Map

Build a matrix of customer pain points × funnel stages × existing content — then find the gaps.

## When to Use
- "Map our content to customer pain points"
- "Where do we have content gaps?"
- "Build a content strategy from buyer needs"

## Prerequisites
- `ANTHROPIC_API_KEY`
- ICP definition, list of existing content (optional)

## Workflow

**Step 1: Extract ICP pain points**

```
For our ICP [describe: role, company type], list the top 10-15 pain points related to [problem space].

For each pain point:
- State it in their words
- Categorize: strategic / operational / technical
- Stage most relevant to: awareness / consideration / decision
```

**Step 2: Build the pain point matrix**

| Pain Point | Stage | Category | Existing content? | Gap? |
|-----------|-------|----------|-------------------|------|

**Step 3: Audit existing content**

For each asset, tag:
- Pain point(s) addressed
- Funnel stage
- Format
- Performance (traffic, leads)

**Step 4: Identify gaps**

Look for:
- Pain points with no content at all
- Pain points covered only at one stage
- Decision-stage pains with only awareness content
- High-performing content with no follow-up assets

**Step 5: Prioritize gap fills**

| Factor | Score (1-5) |
|--------|------------|
| Pain point intensity | |
| Buyer stage (decision > awareness) | |
| Search volume | |
| Competitive coverage (low = opportunity) | |

**Step 6: Brief top 5 gaps**

```
Content brief for: [pain point] at [funnel stage]
Target reader: [ICP role]
Pain in their words: [exact phrasing]
Goal: [educate / help evaluate / convert]
Format: [blog / video / guide / case study]
Key message: [one takeaway]
CTA: [next step]
```

## Output
Pain point map, gap analysis, prioritized content roadmap with briefs for top 5 gaps.
