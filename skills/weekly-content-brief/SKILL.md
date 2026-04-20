---
name: weekly-content-brief
description: Generate a weekly content brief with topics, angles, distribution plan, and writer guidance. Use when running a content team and want a structured weekly planning artifact.
---

# Weekly Content Brief

Generate a structured weekly content brief — topics from data and strategy, angles sharpened for the audience, distribution plan per piece.

## When to Use
- "Write our content brief for this week"
- "What should we create this week?"
- "Build the content plan for [week]"

## Prerequisites
- `ANTHROPIC_API_KEY`
- Current business priorities, available channels

## Workflow

**Step 1: Pull this week's signals**

Inputs for brief:
- Any launches, campaigns, or events this week
- Top-performing content from last week
- Trending topics in your industry
- Sales requests (content for specific objections/use cases)
- SEO opportunities (positions 4-10 ready to push)

**Step 2: Generate topic candidates**

```
Generate 5 content topic ideas for this week for [company] targeting [ICP].

Context:
- Business priority: [priority]
- Trending topic: [trend]
- Top post last week: [topic]
- Sales request: [request]
- Funnel stage focus: [awareness/consideration/decision]

For each topic: headline, angle (why now), format, estimated time, distribution channel.
```

**Step 3: Write the brief per approved piece**

| Element | Detail |
|---------|--------|
| **Headline** | Working headline |
| **Target reader** | Specific ICP role + context |
| **Their pain** | Problem this addresses |
| **Core argument** | One takeaway |
| **Key points** | 3-5 supporting ideas |
| **Evidence needed** | Data, quotes, examples |
| **CTA** | What they do after |
| **SEO target** | Primary keyword (if applicable) |
| **Word count** | Target length |
| **Due / Publish** | Dates |

**Step 4: Distribution plan per piece**

Distribution is part of the brief — not an afterthought.

| Channel | Action | Timing |
|---------|--------|--------|
| Email newsletter | Feature as main story | Same day |
| LinkedIn | Post + share 3 key quotes | Day of + Day 3 |
| Twitter/X | Thread from key points | Same day |
| Slack community | Share in relevant channel | Day after |
| Sales team | Add to battlecard / enablement | Within week |

**Step 5: Retro from last week**

| Piece | Metric | vs. Avg | Learning |
|-------|--------|---------|----------|

One-line implication for this week.

## Output
Weekly brief with 5 topic candidates, full brief for approved pieces, and distribution plan per asset.
