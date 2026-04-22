---
name: content-brief-factory
description: Create a detailed SEO content brief for a target keyword or topic — structure, outline, keyword targets, angle, and writing guidelines. Use when asked to create a content brief, plan a blog post, or build a content outline.
---

# Content Brief Factory

Research a topic and produce a production-ready SEO content brief with outline, keyword targets, angle, and writing guidelines.

## When to Use
- "Create a content brief for [topic/keyword]"
- "Plan a blog post about [topic]"
- "Build a content outline for [keyword]"
- "What should I write about [topic] to rank?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Research current top results**
```bash
orth run search /search \
  --body '{"query": "<target_keyword>", "limit": 10}'
```

**Step 2: Deep competitive content research**
```bash
exa-search "<topic> comprehensive guide" --limit 5
```

**Step 3: Analyze top-ranking content**
For each top result URL:
```bash
orth run scrape "<top_result_url>" \
  --body '{"format": "markdown", "extract": ["title", "h1", "h2", "h3", "meta_description"]}'
```

**Step 4: SEO keyword data**
```bash
orth run seo-analyzer /keywords \
  --body '{"query": "<target_keyword>", "type": "related"}'
```

**Step 5: LLM brief generation**
Pass all research to Claude:
> "Create a detailed SEO content brief for the keyword '<keyword>'. Include:
> 1. Target keyword and 5-8 secondary keywords to include naturally
> 2. Search intent (informational/commercial/transactional) and what the reader wants
> 3. Recommended angle/hook — what makes our take unique vs. current top results?
> 4. Recommended title (H1) and meta description
> 5. Full outline with H2/H3 structure
> 6. Key points to cover in each section
> 7. Content type and format (how-to guide, listicle, comparison, etc.)
> 8. Recommended word count
> 9. Internal link opportunities
> 10. CTA recommendation"

## Output
Production-ready content brief with keyword targets, outline, and writing guidelines.
