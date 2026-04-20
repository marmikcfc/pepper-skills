---
name: aeo-visibility
description: Measure your Answer Engine Optimization visibility — how prominently your product/brand appears in AI-generated answers from Claude, ChatGPT, and Perplexity. Use when asked to check AEO visibility, measure AI search presence, or benchmark against competitors.
---

# AEO Visibility

Measure how visible your product/brand is in AI-generated answers across Claude, ChatGPT, and Perplexity.

## When to Use
- "How visible are we in AI search?"
- "Check our AEO score"
- "Does Claude/ChatGPT mention us?"
- "How do we compare to [competitor] in AI search?"
- "Measure our answer engine presence"

## Prerequisites
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY` (optional but recommended for ChatGPT)
- `ORTHOGONAL_API_KEY` (for Perplexity)

## Workflow

**Step 1: Define test queries**
Ask user for: product category, 3-5 key use cases, main competitors.

Generate 10 test queries covering:
- "best [category] tools"
- "how to [use case]"
- "[problem] solutions"
- "[category] alternatives to [top competitor]"
- "what [category] tool should I use for [scenario]?"

**Step 2: Query Claude**
```python
import anthropic
client = anthropic.Anthropic()
for query in test_queries:
    response = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=500,
        messages=[{"role": "user", "content": query}]
    ).content[0].text
    print(f"Query: {query}\nResponse: {response}\n")
```

**Step 3: Query ChatGPT (if OPENAI_API_KEY available)**
```python
import openai
client = openai.OpenAI()
for query in test_queries:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": query}]
    ).choices[0].message.content
    print(f"Query: {query}\nResponse: {response}\n")
```

**Step 4: Query Perplexity**
```bash
orth run perplexity /chat \
  --body '{"query": "<test_query>"}'
```
Run for each of the 10 test queries.

**Step 5: Score each response**
For each query + engine combination:
- Mentioned: yes/no
- Position: first, second, or later mention
- Framing: positive / neutral / negative
- Competitor mentions: which competitors appeared

**Step 6: Calculate AEO score**
Score per engine = (mention_count / total_queries × 100) × position_weight × sentiment_weight
Position weight: first=1.0, second=0.7, later=0.4
Sentiment weight: positive=1.0, neutral=0.8, negative=0.5

**Step 7: Competitive comparison**
Run the same 10 queries substituting each competitor's name to benchmark your score against theirs.

**Step 8: Present results**
Table: Engine | Your AEO Score | Mention Rate | Avg Position | Sentiment
Competitive matrix: you vs. each competitor across all engines.

## Output
AEO visibility report with per-engine scores and competitive benchmarking matrix.
