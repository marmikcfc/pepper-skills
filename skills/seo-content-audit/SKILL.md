---
name: seo-content-audit
description: Audit a website's content for SEO health — thin content, keyword cannibalization, content gaps, and optimization opportunities. Use when asked to audit SEO content, find content issues, or improve existing content for search.
---

# SEO Content Audit

Audit a website's content for SEO health: thin pages, keyword cannibalization, gaps vs. competitors, and highest-leverage optimization opportunities.

## When to Use
- "Audit our content for SEO"
- "Find content issues on [website]"
- "What content should we fix or update?"
- "SEO content health check for [site]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Technical SEO overview**
```bash
orth run seo-analyzer /analyze \
  --body '{"url": "<website_url>"}'
```

**Step 2: Get content inventory from sitemap**
```bash
orth run scrape "<website_url>/sitemap.xml" \
  --body '{"format": "text"}'
```

**Step 3: Analyze top pages**
For the top 10-15 pages by estimated traffic (from SEO analyzer output or user-specified):
```bash
orth run scrape "<page_url>" \
  --body '{"format": "markdown", "extract": ["title", "h1", "h2", "meta_description", "word_count"]}'
```

**Step 4: LLM content audit**
Pass sitemap + page data to Claude:
> "Audit this website's content and identify:
> 1. Thin content pages (under 500 words or low information value)
> 2. Keyword cannibalization risks (multiple pages targeting the same keyword)
> 3. Content gaps (important topics in the space with no coverage)
> 4. Pages with mismatched search intent (content doesn't match what searchers want)
> 5. High-priority pages to update vs. pages to consolidate or delete
> 6. Quick wins — pages close to ranking that need minor improvements
> Format as a prioritized action list."

## Output
Prioritized SEO content audit with thin content, cannibalization risks, gaps, and quick-win recommendations.
