---
name: email-newsletter-drip
description: Create a multi-email nurture sequence for a specific segment or trigger event. Use when building onboarding emails, post-signup sequences, lead nurture campaigns, or re-engagement flows.
---

# Email Newsletter Drip

Write a complete multi-email nurture sequence — from trigger to conversion — with subject lines, body copy, and send timing.

## When to Use
- "Write a welcome email sequence"
- "Build a nurture sequence for [segment]"
- "Create a post-trial drip campaign"
- "We need onboarding emails"

## Prerequisites
- `ANTHROPIC_API_KEY`
- Trigger event, desired outcome, audience segment

## Workflow

**Step 1: Define sequence parameters**

| Parameter | Value |
|-----------|-------|
| Trigger event | |
| Goal of sequence | |
| Audience segment | |
| Number of emails | |
| Total sequence length | |

**Step 2: Map the emotional journey**

| Email # | Entering state | Job of this email | Leaving state |
|---------|---------------|-------------------|---------------|
| 1 | Curious / skeptical | Welcome + set expectations | Interested |
| 2 | Interested | Deliver first value | Engaged |
| 3 | Engaged | Address main objection | Considering |
| 4 | Considering | Social proof + urgency | Ready to act |
| 5 | Stalled | Re-engage / offer help | Reactivated |

**Step 3: Write each email**

```
Write email [#] of a [N]-email [sequence type] sequence for [ICP description].
Trigger: [trigger event]
Goal: [specific job]
Tone: [casual/professional]
Length: [short/medium]
CTA: [one clear action]
Write 3 subject line variants.
```

**Step 4: Set send timing**

| Email | Send timing | Reasoning |
|-------|-------------|-----------|
| 1 | Immediately | Strike while engaged |
| 2 | Day 2 | Time to absorb #1 |
| 3 | Day 4 | Build on previous |
| 4 | Day 7 | Weekly check-in |
| 5 | Day 14 | Re-engagement window |

**Step 5: Add exit conditions**

Stop sending when the user: completes the desired action, unsubscribes, books a meeting, or upgrades.

## Output
Complete email sequence with subject variants, body copy, send timing, and exit conditions.
