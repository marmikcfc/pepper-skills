---
name: kol-discovery
description: Find key opinion leaders (KOLs), influencers, and thought leaders relevant to your ICP and industry. Use when asked to find influencers to partner with, thought leaders in a space, or people who influence your buyers.
---

# KOL Discovery

Find key opinion leaders and thought leaders who influence your target buyers.

## When to Use
- "Find influencers in [industry/topic]"
- "Who are the thought leaders our ICP follows?"
- "Find people with large audiences in [space]"
- "Who should we partner with for distribution?"

## Prerequisites
- `ORTHOGONAL_API_KEY`

## Workflow

**Step 1: Twitter/X influencer search**
```bash
orth run find-twitter-influencers /search \
  --body '{"topic": "<industry/topic>", "min_followers": 5000, "limit": 20}'
```

**Step 2: LinkedIn thought leaders**
```bash
orth run linkedin-activity /search \
  --body '{"keywords": ["<topic>", "author", "thought leader"], "limit": 20}'
```

**Step 3: Exa semantic search**
```bash
orth run exa /search \
  --body '{"query": "top <industry> influencers bloggers thought leaders", "numResults": 10}'
```

**Step 4: Score and rank**
For each KOL:
- Audience size: >100k = 30 pts, >10k = 20 pts, >1k = 10 pts
- Relevance to ICP pain points (LLM score 1-10): multiply by 3
- Platform overlap with ICP (LinkedIn for B2B, Twitter for tech): +10 if primary platform matches

**Step 5: Enrich top KOLs**
For each KOL scoring >40:
```bash
orth run comprehensive-enrichment /enrich \
  --body '{"name": "<name>", "twitter_handle": "<handle>"}'
```

**Step 6: Present ranked list**
Table: Name | Platform | Followers | Relevance Score | Audience Fit | Contact

## Output
Ranked list of KOLs with audience fit scores and contact info.
