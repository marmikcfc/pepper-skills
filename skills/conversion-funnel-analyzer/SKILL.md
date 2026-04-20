---
name: conversion-funnel-analyzer
description: Identify drop-off points in the conversion funnel and propose targeted experiments to recover lost conversions. Use when diagnosing funnel performance issues or preparing a CRO roadmap.
---

# Conversion Funnel Analyzer

Diagnose where and why users drop off, then build an experiment backlog to recover those conversions.

## When to Use
- "Why is our funnel leaking?"
- "Where are we losing people?"
- "Help me build a CRO roadmap"
- "Our [stage] conversion rate is low"

## Prerequisites
- `ANTHROPIC_API_KEY`
- Funnel metrics by stage

## Workflow

**Step 1: Map the funnel stages**

| Stage | Entry volume | Exit volume | Conversion % |
|-------|-------------|-------------|--------------|
| Landing → Signup | | | |
| Signup → Activation | | | |
| Activation → First value | | | |
| First value → Retained | | | |
| Retained → Paid | | | |

**Step 2: Calculate absolute drop-off**

Rank stages by absolute loss, not just %. A 20% drop from 10k is more valuable to fix than a 30% drop from 100.

**Step 3: Diagnose root causes per stage**

```
For a [product type] targeting [ICP], the conversion rate from [stage A] to [stage B] is [X%].
Benchmark is [Y%].
Data: [data]
Identify the 3 most likely causes of drop-off and suggest one experiment for each.
```

**Step 4: Map friction types**

| Friction type | Signs | Fix |
|--------------|-------|-----|
| Motivational | High bounce, low time-on-page | Improve value messaging |
| Ability | Drop at form/signup | Reduce steps, clarify UX |
| Prompt | Users don't know what to do next | Add explicit CTAs |
| Trust | Cart abandonment, no signup | Social proof, reduce risk |

**Step 5: Build experiment backlog**

For each experiment:
- Stage targeted
- Hypothesis (because X → change Y → expect Z)
- Type (copy, UX, flow, incentive)
- Effort (S/M/L)
- ICE score

**Step 6: Prioritize by ICE and plan sprints**

Run highest ICE experiments first. Aim for 2-3 per sprint.

## Output
Funnel diagnostic with drop-off map, root cause analysis per stage, and prioritized experiment backlog.
