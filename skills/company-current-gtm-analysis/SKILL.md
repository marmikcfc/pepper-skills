---
name: company-current-gtm-analysis
description: Analyze a company's current go-to-market motion — how they're selling, who they're targeting, what channels they use, and where they're investing. Use when asked to analyze a company's GTM strategy, understand how they go to market, or research a prospect's or competitor's sales motion.
---

# Company Current GTM Analysis

Analyze a company's go-to-market motion from public signals — website messaging, job postings, LinkedIn activity, and content strategy.

## When to Use
- "How does [company] go to market?"
- "Analyze [company]'s sales motion"
- "What's [company]'s GTM strategy?"
- "How are they selling and who are they targeting?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Company intelligence**
```bash
orth run company-intel /intelligence \
  --body '{"company": "<company_name>"}'
```

**Step 2: Website messaging analysis**
```bash
orth run scrape "<company_homepage>" --body '{"format": "markdown"}'
orth run scrape "<company_homepage>/pricing" --body '{"format": "markdown"}'
orth run scrape "<company_homepage>/customers" --body '{"format": "markdown"}'
```

**Step 3: LinkedIn GTM signals**
```bash
orth run linkedin-activity /activity \
  --body '{"company": "<company_name>", "limit": 10}'
```

**Step 4: GTM hiring signals**
```bash
orth run hiring-signals /jobs \
  --body '{"company": "<company_name>", "keywords": ["sales", "marketing", "growth", "partnerships", "SDR", "AE", "demand gen"], "limit": 20}'
```

**Step 5: LLM GTM synthesis**
Pass all research to Claude:
> "Based on their website, LinkedIn posts, job openings, and company intel, analyze their current GTM motion:
> 1. Primary sales motion (PLG / sales-led / channel / community)
> 2. Target ICP (industry, company size, buyer role)
> 3. Primary acquisition channels (paid, SEO, events, outbound, partnerships)
> 4. Pricing model (freemium, trial, sales-assisted, enterprise)
> 5. Current GTM investments (based on hiring — where are they doubling down?)
> 6. GTM weaknesses or gaps (where are they under-investing?)
> 7. Implications for competing with or selling to them"

## Output
GTM analysis report with sales motion, ICP, channels, and strategic implications.
