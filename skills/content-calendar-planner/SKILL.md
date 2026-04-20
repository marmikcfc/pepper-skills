---
name: content-calendar-planner
description: Build a monthly content calendar aligned to business goals, ICP pain points, and distribution channels. Use when planning content for the next month or quarter, or when content production feels ad hoc.
---

# Content Calendar Planner

Build a focused monthly content calendar — topics mapped to business goals, content types matched to channels, and a realistic production schedule.

## When to Use
- "Build our content calendar for [month]"
- "We need a content plan for next quarter"
- "Help us be more systematic about content"

## Prerequisites
- `ANTHROPIC_API_KEY`
- Business goals and ICP context

## Workflow

**Step 1: Anchor to goals**

Define content goals for the period:
- What funnel stage needs the most content?
- Any campaigns, launches, or events to build around?
- What content has performed best recently?

**Step 2: Generate topic pillars**

```
Given our ICP [describe], our product [describe], and our goal to [goal] in [month]:
Generate 4-5 content pillars — themes we can own that map to ICP pain points and our differentiation.
For each pillar: name, rationale, 3 topic ideas, best format (blog/video/newsletter/social).
```

**Step 3: Map to calendar**

| Week | Topic | Format | Channel | CTA | Owner |
|------|-------|--------|---------|-----|-------|
| W1 | | | | | |
| W2 | | | | | |
| W3 | | | | | |
| W4 | | | | | |

**Step 4: Set publish cadence by channel**

| Channel | Frequency | Best day |
|---------|-----------|----------|
| Blog | 2x/month | Tuesday |
| Newsletter | Weekly | Thursday |
| LinkedIn | 3x/week | Tue/Thu/Fri |
| Twitter/X | Daily | Morning |

**Step 5: Add distribution to every piece**

For each content asset:
- Primary publish channel
- Repurpose into (blog → newsletter snippet → 3 social posts)
- Internal distribution (Slack, team email)

**Step 6: Write brief for top priority piece**

- Target reader (specific ICP role)
- Problem it addresses
- Key argument or insight
- Supporting points (3-5)
- CTA

## Output
Monthly content calendar with weekly topics, formats, channels, and briefs for priority pieces.
