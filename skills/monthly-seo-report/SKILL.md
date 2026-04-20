---
name: monthly-seo-report
description: Generate a monthly SEO performance report with keyword rankings, organic traffic trends, and prioritized opportunities. Use when reporting on SEO progress or planning next month's content.
---

# Monthly SEO Report

Generate a monthly SEO performance summary — what moved, what's new, what needs attention, what to do next.

## When to Use
- "Generate our monthly SEO report"
- "How is our organic traffic performing?"
- "What SEO wins did we have this month?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- Google Search Console access or rank tracking data

## Workflow

**Step 1: Pull top-level metrics**

Compare MoM and YoY:
- Organic sessions
- Organic clicks (Search Console)
- Average position
- Click-through rate
- Impressions

**Step 2: Rank movement report**
```bash
orth run seo-analyzer /rankings \
  --body '{"domain": "<your_domain>", "period": "last_30_days"}'
```

Categorize:
- **Winners**: Rose 3+ positions
- **Losers**: Dropped 3+ positions
- **Quick wins**: Positions 4-10 (one push to page 1)

**Step 3: Top content performance**

| Page | Clicks | Impressions | CTR | Avg pos | MoM change |
|------|--------|-------------|-----|---------|------------|

Flag: high impressions + low CTR → fix title/meta. Good rank + low impressions → low demand keyword.

**Step 4: Competitor snapshot**
```bash
orth run perplexity /chat \
  --body '{"query": "What new content has [competitor] published in the past 30 days targeting [your keywords]?"}'
```

**Step 5: Technical health check**
```bash
orth run seo-analyzer /technical \
  --body '{"domain": "<your_domain>", "checks": ["core_web_vitals", "crawl_errors", "new_404s"]}'
```

**Step 6: Synthesize the report**

```
SEO data for [month]: [data]

Write monthly SEO report with:
1. Executive summary (3 bullets: wins, losses, priorities)
2. Traffic summary with MoM and YoY trends
3. Ranking wins and losses
4. Quick wins to act on next month
5. Content opportunities (new keywords)
6. Technical issues to fix (prioritized)
```

## Output
Monthly SEO report with traffic summary, rank movement, quick wins, content opportunities, and technical action list.
