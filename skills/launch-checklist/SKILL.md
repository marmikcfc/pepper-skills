---
name: launch-checklist
description: Generate a tailored pre-launch checklist for a product, feature, or campaign launch. Use when planning a launch to ensure nothing falls through the cracks across marketing, product, and ops.
---

# Launch Checklist

Generate a complete, tailored launch checklist — from 6 weeks out to launch day and the 48 hours after.

## When to Use
- "We're launching [product/feature] — what do we need to do?"
- "Build a launch checklist for [campaign]"
- "Make sure we don't miss anything for launch"

## Prerequisites
- `ANTHROPIC_API_KEY`
- Launch type, scope, and date

## Workflow

**Step 1: Define launch parameters**

| Parameter | Value |
|-----------|-------|
| What are you launching? | |
| Launch date | |
| Target audience | |
| Primary channel | |
| Launch goal (metric) | |

**Step 2: Generate the master checklist**

```
Generate a pre-launch checklist for: [launch description]
Target audience: [ICP]
Launch date: [date]
Channels: [list]

Organize by:
1. T-6 weeks: Strategy and positioning
2. T-4 weeks: Content and assets
3. T-2 weeks: Technical and ops
4. T-1 week: Review and finalize
5. Launch day: Execution
6. T+48h: Monitor and respond

For each item include: owner role, dependency, checkbox.
```

**Step 3: Channel-specific checklists**

**Email:** Segment built, subject lines tested, send time optimized, preview text written, unsubscribe working.

**Social:** Graphics sized per platform, copy variants per channel, posting schedule set, community posts scheduled.

**Product:** Feature flagged for staged rollout, error monitoring set, rollback plan documented, support docs published.

**Step 4: Set success metrics**

Define "good launch" at:
- 24 hours / 72 hours / 1 week / 1 month

**Step 5: War room plan**

Launch day essentials:
- Dedicated Slack channel
- On-call rotation for 48 hours
- Escalation path if something breaks
- Check-in cadence

## Output
Tailored launch checklist by timeline, channel-specific items, success metrics, and launch day war room plan.
