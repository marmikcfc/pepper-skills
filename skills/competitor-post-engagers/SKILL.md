---
name: competitor-post-engagers
description: Find people engaging with competitor content on LinkedIn — commenters, likers, and sharers who are active in your competitor's community. Use when asked to find people who follow competitors or engage with competitor posts.
---

# Competitor Post Engagers

Find people engaging with your competitor's content — these prospects are already aware of the problem space and evaluating solutions.

## When to Use
- "Find people engaging with [competitor]'s LinkedIn posts"
- "Who's active in [competitor]'s community?"
- "Find people commenting on [competitor] content"

## Prerequisites
- `ORTHOGONAL_API_KEY`

## Workflow

**Step 1: Find competitor's recent posts**
```bash
orth run linkedin-activity /activity \
  --body '{"company": "<competitor_name>", "limit": 10}'
```

**Step 2: Scrape commenters from top posts**
For the top 3-5 posts by engagement:
```bash
orth run linkedin-post-comments /scrape \
  --body '{"post_url": "<post_url>", "limit": 100}'
```

**Step 3: Filter by ICP match**
Cross-reference commenters against ICP criteria (title keywords, company size range, industry). Keep only commenters whose title/company match your ICP.

**Step 4: Enrich ICP-matching commenters**
```bash
orth run comprehensive-enrichment /enrich \
  --body '{"linkedin_url": "<url>"}'
```

**Step 5: Present results**
Table: Name | Title | Company | Post they engaged with | Email

## Output
List of competitor-engaged prospects with enriched contact info.
