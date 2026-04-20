---
name: agent-runtime-comparison-pages
description: Use when creating "Pepper vs [Competitor]" comparison pages for SEO and sales enablement — generates structured comparison content using live competitor data. Use when asked to build comparison pages or differentiation content against LangGraph, Dify, CrewAI, or other agent runtimes.
---

# Agent Runtime Comparison Pages

Auto-generate "Pepper vs [Competitor]" comparison pages using live competitive data. Designed for programmatic SEO and sales battlecard generation.

## When to Use
- "Create a Pepper vs LangGraph comparison page"
- "Build comparison pages for all our main competitors"
- Quarterly refresh of existing comparison pages
- Sales asks for a battlecard or one-pager vs a competitor

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY` (for state reads)
- Product marketing context in `company/company.md`

## Supported Competitors
Default coverage (extend as needed):
- LangGraph / LangChain
- Dify
- CrewAI
- Vercel AI SDK
- Flowise
- Relevance AI

## Workflow

### 1. Load context

```bash
COMPANY=$(state_read "company/company.md")
POSITIONING=$(state_read "strategy/positioning.md")
ICP=$(state_read "strategy/icp.md")
COMPETITOR="$1"  # e.g. "LangGraph"
```

### 2. Gather live competitor intelligence

```bash
# Company intel
orth run company-intel --query "{\"company\": \"${COMPETITOR}\"}" > /tmp/comp_intel.json

# Pricing
orth run competitive-pricing-intel --query "{\"domain\": \"$(echo $COMPETITOR | tr '[:upper:]' '[:lower:]' | tr ' ' '-').com\"}" > /tmp/comp_pricing.json

# Reviews (what users say)
orth run review-scraper --query "{\"company\": \"${COMPETITOR}\", \"sources\": [\"g2\", \"productHunt\", \"hackernews\"]}" > /tmp/comp_reviews.json

# Tech stack (to understand their architecture claims)
orth run tech-stack-teardown --query "{\"domain\": \"${COMPETITOR}.com\"}" > /tmp/comp_tech.json

# Recent content (messaging angle)
orth run competitor-content-tracker --query "{\"company\": \"${COMPETITOR}\"}" > /tmp/comp_content.json
```

### 3. Synthesize comparison matrix

Build a structured comparison across these dimensions:

| Dimension | Pepper | [Competitor] | Notes |
|-----------|--------|-------------|-------|
| Setup time | <2 min | [observed] | |
| DevOps required | None | [observed] | |
| Pricing model | [Pepper's] | [competitor's] | |
| Agent framework | Claude / SDK | [observed] | |
| Channels | WA, TG, Slack, Web | [observed] | |
| Self-hosted option | No (managed) | [yes/no] | |
| Skills/plugins | 100+ catalog | [observed] | |
| State/memory | Supabase (persistent) | [observed] | |
| Multi-agent | Yes | [observed] | |
| Target user | Non-technical founder | [inferred from ICP] | |

### 4. Extract review-based positioning

From G2/ProductHunt reviews of the competitor, find:
- Top 3 complaints (what people hate)
- Top 3 praises (what people love, so we don't dismiss)
- Switching triggers (why people leave)

These become the core of the "Why Pepper" section.

### 5. Generate comparison page content

```bash
PAGE_CONTENT="# Pepper vs ${COMPETITOR}: Which AI Agent Platform is Right for You?

**TL;DR:** If you want to deploy AI agents without writing code or managing infrastructure, Pepper gets you running in under 2 minutes. If you need full control over your agent architecture and have engineering resources to invest, ${COMPETITOR} offers more flexibility.

## The Core Difference

[1-2 paragraph honest framing of what each product is optimized for]

## Feature Comparison

[comparison matrix]

## Where Pepper Wins

### No Setup, No DevOps
[Expand on biggest Pepper differentiator vs this specific competitor]

### [Second differentiator]
[Evidence — with specifics]

### [Third differentiator]

## Where ${COMPETITOR} Wins

### [Honest strength of competitor]
[We don't win every dimension — be honest]

## What ${COMPETITOR} Users Say (From Reviews)

> \"[verbatim complaint from review that Pepper solves]\"
> — [Role], [Company size]

> \"[Another relevant quote]\"

## Switching from ${COMPETITOR} to Pepper

[Brief, specific migration story or process — lower the switching cost perception]

## Pricing Comparison

[Honest comparison — if competitor is cheaper on some dimension, say so]

## Who Should Use Pepper vs ${COMPETITOR}

**Choose Pepper if:**
- [ICP-matched scenario 1]
- [ICP-matched scenario 2]

**Choose ${COMPETITOR} if:**
- [Scenario where competitor wins]

## Start With Pepper in 2 Minutes

[CTA]

---
*Data gathered: $(date +%Y-%m-%d). Competitor features and pricing change frequently — see [competitor] website for current information.*"

echo "$PAGE_CONTENT" > "/tmp/pepper-vs-$(echo $COMPETITOR | tr '[:upper:]' '[:lower:]' | tr ' ' '-').md"
```

### 6. SEO optimization

Add to the page:
- H1: "Pepper vs [Competitor]: [Year] Comparison"
- Meta description: "Compare Pepper and [Competitor] side-by-side — setup time, pricing, features, and who each is best for."
- FAQ schema targeting "Pepper vs [Competitor]" related queries
- Internal links to relevant blog posts and docs

### 7. Output options

The generated markdown can be:
- Pasted into your CMS (Webflow, Framer, Next.js MDX)
- Converted to a PDF one-pager for sales
- Adapted into a LinkedIn post with `social-content` skill

## Output
- Markdown comparison page ready for CMS
- Structured battlecard summary for sales

## Refresh Cadence
Run quarterly or when a competitor makes a significant pricing/feature change (flagged by `competitor-positioning-diff`).
