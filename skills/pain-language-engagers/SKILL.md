---
name: pain-language-engagers
description: Find people publicly expressing pain points your product solves — on LinkedIn and Reddit. Use when asked to find warm leads, find people complaining about [problem], or find prospects expressing intent.
---

# Pain Language Engagers

Find people actively expressing the pain points your product solves. These are the warmest possible leads — they're already aware of the problem.

## When to Use
- "Find people complaining about [problem]"
- "Who's posting about [pain point]?"
- "Find warm leads expressing frustration with [competitor/problem]"
- "Find people who need what we do"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL` (for ICP context)

## Workflow

**Step 1: Load ICP and pain points**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }

ICP=$(state_read "strategy/icp.md")
```
Ask user for specific pain keywords if not in ICP (e.g., "What pain points are you targeting?").

**Step 2: LinkedIn comment search**
Search for posts about the pain topic, then scrape commenters:
```bash
orth run linkedin-post-comments /scrape \
  --body '{"post_url": "<relevant_post_url>", "keywords": ["<pain_keyword>"]}'
```

**Step 3: Reddit pain mining**
```bash
orth run reddit-wizard /search \
  --body '{"query": "<pain keyword> <industry>", "subreddits": ["<relevant_subreddit>"], "limit": 50}'
```

**Step 4: LLM pain classifier**
Pass each comment/post to Claude:
> "Does this person express the following pain: [pain description]? Return JSON: {matches: true/false, pain_signal: string, urgency: 1-5, direct_quote: string}"

Only keep matches where `matches: true` and `urgency >= 3`.

**Step 5: Enrich matched leads**
For each person with urgency >= 3:
```bash
orth run comprehensive-enrichment /enrich \
  --body '{"linkedin_url": "<url>", "name": "<name>"}'
```

**Step 6: Present results**
Table: Person | Platform | Pain signal | Urgency | Email | LinkedIn

## Output
List of leads actively expressing your ICP's pain, with enriched contact info and urgency scores.
