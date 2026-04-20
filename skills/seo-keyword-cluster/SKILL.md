---
name: seo-keyword-cluster
description: Build a keyword cluster strategy around a topic to capture intent across funnel stages and establish topical authority. Use when building out a content pillar, launching a category page, or planning an SEO content sprint.
---

# SEO Keyword Cluster

Build a keyword cluster that establishes topical authority — from head term to long-tail, mapped to intent and content format.

## When to Use
- "Build a keyword cluster for [topic]"
- "We want to own [topic] in search"
- "Plan content around [keyword]"
- "Find long-tail opportunities for [subject]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- Target topic or head term

## Workflow

**Step 1: Seed keyword research**
```bash
orth run perplexity /chat \
  --body '{"query": "What are people searching for around [topic]? List 20+ keyword variations, questions, and related terms. Include search intent for each."}'
```

**Step 2: Expand with SERP analysis**
```bash
orth run exa /search \
  --body '{"query": "[topic] guide how to best", "numResults": 20}'
```

Extract: questions top-ranking pages answer, phrases in H2s/H3s, related topics they link to.

**Step 3: Classify by intent**

| Intent | Example | Best format |
|--------|---------|-------------|
| Informational | "what is [X]" | Blog, guide |
| Commercial | "best [X] tools" | Comparison, listicle |
| Transactional | "[X] pricing" | Landing page |

**Step 4: Build the cluster**

| Keyword | Volume (est.) | Difficulty | Intent | Content type |
|---------|--------------|------------|--------|--------------|
| [head term] | | | | Pillar page |
| [variation] | | | | Supporting blog |
| [long-tail] | | | | FAQ / blog |

Structure: 1 pillar page (head term) + 5-10 supporting pages (cluster terms) + internal links cluster → pillar.

**Step 5: Prioritize with opportunity score**

Opportunity = (volume × CTR potential) ÷ difficulty

Focus on: low difficulty + medium volume (quick wins), high commercial intent, competitor gaps.

**Step 6: Write briefs for top 3 pieces**

```
SEO content brief for: [keyword]
Intent: [informational/commercial]
Target reader: [ICP description]
Required sections: [from SERP analysis]
Internal links: [pillar + related cluster pages]
Word count: [based on SERP avg]
```

## Output
Keyword cluster map with intent classification, pillar + cluster structure, priority scores, and briefs for top 3 pieces.
