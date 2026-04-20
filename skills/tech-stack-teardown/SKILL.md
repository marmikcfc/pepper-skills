---
name: tech-stack-teardown
description: Identify and analyze a company's technology stack — tools, platforms, and infrastructure they use. Use when asked to find what tech a company uses, analyze their stack, or understand their build vs. buy decisions.
---

# Tech Stack Teardown

Identify a company's full technology stack and analyze what it reveals about their architecture, scale, and strategic priorities.

## When to Use
- "What tech stack does [company] use?"
- "Analyze [company]'s technology"
- "Find what tools [competitor] is using"
- "What does [company]'s stack say about them?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Scan tech stack**
```bash
orth run tech-stack-scout /analyze \
  --body '{"domain": "<company_domain>"}'
```

**Step 2: Scrape job listings for stack signals**
```bash
orth run hiring-signals /jobs \
  --body '{"company": "<company_name>", "keywords": ["React", "Python", "Kubernetes", "AWS", "Snowflake", "Salesforce"], "limit": 20}'
```
Job postings are the most reliable signal for their actual stack.

**Step 3: LLM analysis**
Pass the tech stack data to Claude:
> "Analyze this tech stack and produce:
> 1. Core infrastructure (cloud, databases, deployment)
> 2. Product/frontend stack
> 3. Data and analytics tools
> 4. Sales and marketing tooling (CRM, marketing automation, analytics)
> 5. What this stack reveals about their scale and maturity
> 6. Build vs. buy decisions — where are they building vs. using SaaS?
> 7. Gaps or weaknesses the stack implies
> 8. Competitive implications for us (do they use our competitors? are there integration opportunities?)"

## Output
Structured tech stack analysis with architectural insights and competitive implications.
