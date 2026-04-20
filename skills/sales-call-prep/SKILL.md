---
name: sales-call-prep
description: Prepare for a sales call with full account research, contact background, company news, and a suggested agenda. Use when asked to prep for a demo, discovery call, or sales meeting.
---

# Sales Call Prep

Comprehensive pre-call brief: company overview, contact background, recent signals, likely objections, and suggested agenda.

## When to Use
- "Prep me for a call with [name] at [company]"
- "I have a demo with [company] tomorrow"
- "Research [person] before my call"
- "Prep for my meeting with [company]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Account research**
```bash
orth run account-research-brief /brief \
  --body '{"company": "<company_name>", "domain": "<domain>"}'

orth run company-intel /intelligence \
  --body '{"company": "<company_name>"}'
```

**Step 2: Contact research**
```bash
orth run linkedin-activity /activity \
  --body '{"person": "<contact_linkedin_url>", "limit": 5}'

orth run comprehensive-enrichment /enrich \
  --body '{"name": "<contact_name>", "company": "<company_name>"}'
```

**Step 3: Recent news and signals**
```bash
orth run search /search \
  --body '{"query": "<company_name> news announcement", "limit": 5}'

orth run hiring-signals /jobs \
  --body '{"company": "<company_name>", "keywords": ["marketing", "sales", "growth"], "limit": 5}'
```

**Step 4: LLM call prep synthesis**
Pass all research to Claude:
> "Create a pre-call brief for a call with [contact_name] at [company]. Include:
> 1. Company snapshot: what they do, size, funding, ICP, recent news
> 2. Contact snapshot: role, tenure, recent LinkedIn posts, likely priorities
> 3. Signal highlights: anything from hiring or news that's relevant
> 4. Tailored opening question to start strong
> 5. Top 3 likely objections + responses
> 6. Suggested agenda: discovery (5 min) → pain exploration (10 min) → demo/solution (15 min) → next steps (5 min)
> Format as a concise 1-page brief."

## Output
Full pre-call brief with company context, contact background, signals, and suggested agenda.
