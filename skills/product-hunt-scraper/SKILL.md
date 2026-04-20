---
name: product-hunt-scraper
description: Find recent product launches on Product Hunt. Use when asked to monitor new product launches, find recently launched products in a category, or track competitor launches.
---

# Product Hunt Scraper

Find and analyze recent product launches on Product Hunt.

## When to Use
- "What launched on Product Hunt this week?"
- "Find new products in [category] on Product Hunt"
- "Monitor Product Hunt for competitor launches"
- "What AI tools launched recently?"

## Prerequisites
- `ORTHOGONAL_API_KEY`

## Workflow

**Step 1: Search recent launches**
```bash
orth run startup-launches /launches \
  --body '{"query": "<category or keyword>", "limit": 20, "source": "product_hunt"}'
```

**Step 2: Enrich top launches**
For launches with >100 upvotes:
```bash
orth run company-intel /intelligence \
  --body '{"company": "<product_name>", "domain": "<product_domain>"}'
```

**Step 3: Classify signals**
For each enriched launch, answer:
- Is this a direct competitor?
- Does their messaging signal market validation for our category?
- Are they targeting our ICP?
- Is the launch getting unusual traction (>500 upvotes, top 5 of the day)?

**Step 4: Present results**
Table: Product | Upvotes | Tagline | Category | Maker | Domain | Signal Type (Competitor / Market Validation / ICP Overlap / Watch)

## Output
List of recent launches with competitive signal classification and enriched company context.
