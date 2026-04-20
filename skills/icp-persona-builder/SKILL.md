---
name: icp-persona-builder
description: Build a detailed buyer persona card for a specific role within your ICP — their goals, frustrations, day-in-the-life, and the language they use. Use when asked to build a persona, create a buyer profile, or understand a specific buyer role more deeply.
---

# ICP Persona Builder

Build a detailed Jobs-to-be-Done persona card for a specific buyer role: their world, pain points, goals, and the language they actually use.

## When to Use
- "Build a persona for [job title]"
- "What does a VP of Marketing think about all day?"
- "Create a buyer persona card for [role]"
- "Help me understand the [role] buyer"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Reddit research — their world in their words**
```bash
orth run reddit-wizard /search \
  --body '{"query": "<job_title> challenges frustrations problems day in the life", "subreddits": ["<relevant_subreddit>"], "limit": 30}'
```

**Step 2: Perplexity — structured pain point research**
```bash
orth run perplexity /chat \
  --body '{"query": "What are the biggest challenges and frustrations for <job_title> at <company_type> companies in <current_year>? What keeps them up at night? What are their KPIs and success metrics?"}'
```

**Step 3: Exa — day-in-the-life content**
```bash
orth run exa /search \
  --body '{"query": "<job_title> day in the life pain points goals challenges", "numResults": 10}'
```

**Step 4: LLM persona synthesis — Jobs-to-be-Done format**
Pass all research to Claude:
> "Create a detailed buyer persona card in Jobs-to-be-Done format for a [job_title] at [company_type]:
> 1. Demographics and context (role, seniority, company type, team size)
> 2. Jobs to be done (functional: what tasks do they need to accomplish? emotional: how do they want to feel?)
> 3. Pains (current frustrations, obstacles, risks they fear)
> 4. Gains (desired outcomes, what success looks like)
> 5. Trigger events (what prompts them to look for a solution?)
> 6. Their language (exact phrases and words they use to describe their problems)
> 7. Where they spend time (communities, publications, events, social platforms)
> 8. Buying behavior (how do they evaluate tools? who else is involved?)
> Format as a practical reference card."

## Output
Detailed buyer persona card in Jobs-to-be-Done format with exact language for messaging use.
