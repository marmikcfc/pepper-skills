---
name: battlecard-generator
description: Generate a competitive battlecard for a specific competitor — their positioning, strengths, weaknesses, objection handlers, and how to win against them. Use when asked to create a battlecard, build competitive talking points, or prepare for competitive deals.
---

# Battlecard Generator

Research a competitor and produce a ready-to-use sales battlecard with positioning, win/loss patterns, and objection handlers.

## When to Use
- "Create a battlecard for [competitor]"
- "Build competitive talking points vs [competitor]"
- "How do we beat [competitor] in deals?"
- "What are [competitor]'s weaknesses?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Research competitor overview**
```bash
orth run competitor-research /research \
  --body '{"competitor": "<competitor_name_or_domain>"}'
```

**Step 2: Scrape competitor website**
```bash
orth run scrape "<competitor_homepage>" --body '{"format": "markdown"}'
orth run scrape "<competitor_homepage>/pricing" --body '{"format": "markdown"}'
orth run scrape "<competitor_homepage>/features" --body '{"format": "markdown"}'
```

**Step 3: Company intel**
```bash
orth run company-intel /intelligence \
  --body '{"company": "<competitor_name>"}'
```

**Step 4: Collect customer reviews**
```bash
orth run scrape "https://www.g2.com/products/<competitor_slug>/reviews" \
  --body '{"format": "text"}'
orth run scrape "https://www.capterra.com/p/<id>/<competitor>/reviews/" \
  --body '{"format": "text"}'
```

**Step 5: Social listening**
```bash
orth run social-listening /monitor \
  --body '{"keywords": ["<competitor_name>"], "timeframe": "30d"}'
```

**Step 6: Generate battlecard with LLM**
Pass all research to Claude:
> "Create a sales battlecard for [competitor]. Include:
> 1. Their positioning (how they describe themselves, target ICP)
> 2. Top 3 strengths (what they genuinely do well)
> 3. Top 3 weaknesses (based on reviews and gaps)
> 4. How we win against them (differentiation angles)
> 5. 5 common objections they use against us + our responses
> 6. Discovery questions to expose their weaknesses
> 7. Red flags that signal a deal is at risk of going to them
> Format as a structured battlecard."

**Step 7: Present and review**
Present the battlecard. Ask if any sections need adjustment.

## Output
Structured competitive battlecard with positioning, strengths, weaknesses, and objection handlers.
