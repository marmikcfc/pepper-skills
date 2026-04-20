---
name: competitor-intel
description: Gather comprehensive competitive intelligence on a competitor — their current positioning, recent moves, product changes, hiring signals, and social activity. Use when asked to research a competitor, monitor competitor activity, or get a competitive update.
---

# Competitor Intel

Comprehensive competitive intelligence: current positioning, recent product moves, hiring signals, content strategy, and social activity.

## When to Use
- "Research [competitor] for me"
- "What's [competitor] up to lately?"
- "Get competitive intel on [company]"
- "Competitive update on [competitor]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Research overview**
```bash
orth run competitor-research /research \
  --body '{"competitor": "<competitor_name_or_domain>"}'
```

**Step 2: Social listening (last 30 days)**
```bash
orth run social-listening /monitor \
  --body '{"keywords": ["<competitor_name>", "<competitor_product_name>"], "timeframe": "30d"}'
```

**Step 3: Recent LinkedIn activity**
```bash
orth run linkedin-activity /activity \
  --body '{"company": "<competitor_name>", "limit": 10}'
```

**Step 4: Blog and changelog**
```bash
orth run scrape "<competitor_homepage>/blog" --body '{"format": "links"}'
orth run scrape "<competitor_homepage>/changelog" --body '{"format": "markdown"}'
```

**Step 5: Hiring signals**
```bash
orth run hiring-signals /jobs \
  --body '{"company": "<competitor_name>", "keywords": ["marketing", "sales", "product", "engineering"], "limit": 20}'
```

**Step 6: Customer sentiment (reviews)**
```bash
orth run scrape "https://www.g2.com/products/<competitor_slug>/reviews" \
  --body '{"format": "text"}'
```

**Step 7: LLM synthesis**
> "Synthesize this competitive intelligence into a brief. Cover:
> 1. Current positioning and messaging (how they're pitching now)
> 2. Recent product moves (last 30 days)
> 3. GTM signals from hiring (what are they investing in?)
> 4. Content strategy (what topics are they dominating?)
> 5. Customer sentiment (what are customers loving/hating?)
> 6. Strategic implications for us (what should we watch or respond to?)"

## Output
Competitive intelligence brief with current positioning, recent moves, and strategic implications.
