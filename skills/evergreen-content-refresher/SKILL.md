---
name: evergreen-content-refresher
description: Audit existing evergreen content for staleness, update it with current data and SEO signals, and republish for continued organic traffic. Use when top-performing content has declined in rankings or traffic.
---

# Evergreen Content Refresher

Audit your best evergreen content, update it with current data, and republish to recover and improve rankings.

## When to Use
- "Our top blog post is losing traffic"
- "Refresh our evergreen content"
- "Update [post] with new data"
- "Improve rankings on existing content"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- List of top content assets with traffic data

## Workflow

**Step 1: Identify refresh candidates**

Prioritize posts that:
- Rank positions 5-20 (easiest to push up)
- Had strong historical traffic that's declined
- Target high-value keywords
- Are over 12 months old

**Step 2: Audit each piece**
```bash
orth run seo-analyzer /audit \
  --body '{"url": "<post_url>", "checks": ["rankings", "freshness", "broken_links"]}'
```

Check for: dated statistics, outdated tool references, broken links, missing sections competitors now cover, missing schema markup.

**Step 3: Research the current SERP**
```bash
orth run exa /search \
  --body '{"query": "<target keyword>", "numResults": 10}'
```

Identify: what new content is outranking you, what angles they cover you don't, what questions they answer.

**Step 4: Pull fresh data**
```bash
orth run perplexity /chat \
  --body '{"query": "Latest statistics on <topic> in <current_year>. Include sources."}'
```

**Step 5: Refresh the content**

```
Here is the existing post: [paste]
Competing content now outranking it: [paste excerpts]
Fresh data: [paste research]

Refresh to:
1. Replace dated statistics with current data (cite sources)
2. Add section covering [missing angle]
3. Update intro to reference current year
4. Add FAQ section for [SERP questions]
5. Keep existing H1 and URL slug (preserve ranking signals)
```

**Step 6: Republish**

- Update published date to today
- Add "Updated [Month Year]" to the intro
- Submit updated URL to Google Search Console

## Output
Refreshed post with current data, new sections, updated metadata, and republish checklist.
