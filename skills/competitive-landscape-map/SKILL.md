---
name: competitive-landscape-map
description: Map competitors by positioning, pricing, and feature differentiation to identify whitespace and sharpen your own positioning. Use when entering a new market, refreshing positioning, or preparing for a competitive review.
---

# Competitive Landscape Map

Build a structured map of your competitive landscape — who the players are, how they position, and where the whitespace is for your product.

## When to Use
- "Map our competitive landscape"
- "Who are our main competitors and how do they differ?"
- "Find positioning whitespace in [market]"
- "Prepare for a competitive review"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Identify competitors**
```bash
orth run perplexity /chat \
  --body '{"query": "Who are the main competitors in [market/category]? Include direct, adjacent, and DIY alternatives. What are their positioning claims and pricing?"}'
```

**Step 2: Pull positioning data per competitor**
```bash
orth run exa /search \
  --body '{"query": "[competitor] positioning value proposition pricing target customer", "numResults": 5}'
```

**Step 3: Categorize competitor types**

| Type | Description |
|------|-------------|
| **Direct** | Same buyer, same problem |
| **Adjacent** | Same buyer, different problem |
| **DIY/Status quo** | Spreadsheets, manual process |
| **Emerging** | New entrants, different approach |

**Step 4: Build the positioning matrix**

Ask Claude to synthesize:
> "Here are [N] competitors in [market] with their positioning, pricing, and target segments: [data].
> Create a 2x2 positioning map with the two most differentiating axes.
> For each competitor: primary message, ICP, key differentiator, pricing model, main weakness."

**Step 5: Identify whitespace**

Look for:
- Buyer segments competitors ignore
- Pricing tiers with no coverage
- Use cases underserved by current solutions
- Messages no one is claiming

**Step 6: Summarize competitive implications**

For each key finding:
- The observation
- What it means for our positioning
- One action to take

## Output
Competitive landscape map with positioning matrix, per-player profiles, whitespace analysis, and positioning recommendations.
