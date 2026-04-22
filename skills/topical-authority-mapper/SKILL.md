---
name: topical-authority-mapper
description: Build a topical authority map for a topic or keyword cluster — pillar pages, cluster pages, and content hierarchy to dominate a topic in search. Use when asked to build a content strategy, create a topical map, or plan content pillars.
---

# Topical Authority Mapper

Build a comprehensive topical authority map: pillar pages, cluster pages, and internal link structure to dominate a topic in search.

## When to Use
- "Build a topical authority map for [topic]"
- "What content do we need to own [topic area]?"
- "Create a content pillar strategy for [keyword]"
- "Plan our content hierarchy for [subject]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Broad topic research**
```bash
orth run search /search \
  --body '{"query": "<topic> subtopics related questions comprehensive", "limit": 20}'
```

**Step 2: Semantic coverage research**
```bash
exa-search "<topic> everything you need to know complete guide" --limit 10
```

**Step 3: Question and long-tail discovery**
```bash
perplexity "What are all the subtopics, related questions, and aspects someone learning about <topic> would want to understand? Be comprehensive — include beginner, intermediate, and advanced angles."
```

**Step 4: LLM topical map generation**
Pass all research to Claude:
> "Build a topical authority content map for [topic]. Structure it as:
> 1. Pillar page (main hub — what's the single most comprehensive piece on this topic?)
> 2. Cluster pages — group into 5-8 thematic clusters, each with 3-6 supporting pages
> 3. For each page: title, target keyword, search intent, word count estimate, key angle
> 4. Internal link recommendations (which pages should link to which)
> 5. Prioritization: which pages to build first to establish initial topical authority
> Format as a content hierarchy map with clear visual nesting."

## Output
Topical authority content map with pillar and cluster structure, prioritized build order, and internal link recommendations.
