---
name: audience-segment-builder
description: Build targeted audience segments from CRM data, behavioral signals, and firmographics. Use when asked to segment customers, define target lists, or identify distinct buyer groups for campaigns or outreach.
---

# Audience Segment Builder

Build distinct, actionable audience segments from CRM data and behavioral signals — each with its own messaging angle and activation channel.

## When to Use
- "Segment our customer base"
- "Who should we target for this campaign?"
- "Build a list of [segment] for outreach"
- "How should we divide our audience?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Pull customer data signals**
```bash
orth run perplexity /chat \
  --body '{"query": "What are the most valuable ways to segment B2B SaaS customers for marketing? Include firmographic, behavioral, and intent-based dimensions."}'
```

**Step 2: Identify segment dimensions**

Analyze your customer base across these axes:
- **Firmographic**: company size, industry, funding stage, headcount
- **Behavioral**: product usage patterns, feature adoption, login frequency
- **Intent**: job postings, tech stack changes, funding events
- **Lifecycle**: new, active, at-risk, churned

**Step 3: Synthesize segments with LLM**

Pass your customer data to Claude:
> "Here is our customer list with attributes: [data]. Identify 4-6 distinct, actionable segments. For each segment, define:
> 1. Segment name and size estimate
> 2. Defining characteristics (firmographic + behavioral)
> 3. Primary pain point we solve for them
> 4. Best messaging angle
> 5. Recommended activation channel
> 6. Example companies or profiles"

**Step 4: Prioritize segments**

Score each segment on:
| Dimension | Score (1-5) |
|-----------|------------|
| Size (addressable accounts) | |
| Fit (ICP alignment) | |
| Reachability (data quality) | |
| Revenue potential | |

**Step 5: Create activation lists**
```bash
orth run apollo-lead-finder /search \
  --body '{"filters": {"industry": "<segment_industry>", "employee_count": "<range>", "keywords": ["<segment_keyword>"]}, "limit": 100}'
```

## Output
Segment cards with definitions, sizing, messaging, and activation-ready lead lists.
