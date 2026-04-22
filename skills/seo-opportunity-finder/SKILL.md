---
name: seo-opportunity-finder
description: Find SEO keyword opportunities — low-competition, high-intent keywords where a website can realistically rank. Use when asked to find keyword opportunities, identify SEO gaps, or discover what to write about next.
---

# SEO Opportunity Finder

Find keyword opportunities where you can realistically rank: low competition, high intent, and aligned with your product and ICP.

## When to Use
- "Find keyword opportunities for [topic/domain]"
- "What should we write to rank?"
- "Find low-competition keywords in [space]"
- "SEO gap analysis vs. [competitor]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: SEO keyword opportunity scan**
```bash
orth run seo-analyzer /keywords \
  --body '{"url": "<website_url>", "type": "opportunities"}'
```

**Step 2: Competitor content gap analysis**
```bash
exa-search "<topic> site:<competitor_domain>" --limit 10
```

**Step 3: Perplexity research on keyword landscape**
```bash
perplexity "What keywords should a [company_type] targeting [ICP] create content for to rank in <current_year>? What high-intent, lower-competition opportunities exist in [topic_area]?"
```

**Step 4: LLM opportunity prioritization**
Pass all keyword data to Claude:
> "Prioritize these keyword opportunities. For each, score:
> 1. Search intent match (high / medium / low for our ICP)
> 2. Competition level (estimated difficulty to rank)
> 3. Business relevance (does ranking for this drive pipeline?)
> 4. Quick win potential (could we rank in 90 days?)
> Output as a prioritized keyword opportunity list with: keyword, monthly search volume estimate, intent, competition, business relevance score, recommended content type."

## Output
Prioritized keyword opportunity list with intent, competition, and business relevance scores.
