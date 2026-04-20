---
name: industry-scanner
description: Scan an industry or topic for trends, news, and emerging themes. Use when asked to monitor industry news, find trending topics, or get a pulse on what's happening in a market.
---

# Industry Scanner

Monitor an industry or topic for trends, news, emerging companies, and conversation themes.

## When to Use
- "What's happening in [industry] this week?"
- "Scan [topic] for trends"
- "What are people talking about in [space]?"
- "Industry news digest for [market]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Web search for recent news**
```bash
orth run search /search \
  --body '{"query": "<industry> news trends 2025", "limit": 20}'
```

**Step 2: Deep research with Perplexity**
```bash
orth run perplexity /chat \
  --body '{"query": "What are the biggest trends and developments in <industry> in the last 30 days? Include notable companies, funding events, product launches, and strategic shifts."}'
```

**Step 3: Exa semantic search**
```bash
orth run exa /search \
  --body '{"query": "<industry> emerging trends 2025", "numResults": 10, "useAutoprompt": true}'
```

**Step 4: Social signal scan**
```bash
orth run social-listening /monitor \
  --body '{"keywords": ["<industry>", "<key_topic>"], "timeframe": "7d"}'
```

**Step 5: LLM synthesis**
Combine all signals and pass to Claude:
> "Synthesize these industry signals into a weekly digest. Structure as:
> 1. Key trends (3-5 bullet points)
> 2. Notable companies to watch
> 3. Emerging themes not yet mainstream
> 4. Risks/headwinds
> 5. Opportunities for GTM teams
> Keep it actionable — what should a sales or marketing team do with this information?"

## Output
Weekly industry brief with trends, notable companies, and GTM-actionable opportunities.
