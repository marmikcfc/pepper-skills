---
name: llm-answer-engine-direct
description: Use when querying ChatGPT, Claude, Gemini, and Perplexity directly to measure brand visibility in AI search — returns structured results showing which engines mention the brand, at what rank, and with what framing. Used by aeo-visibility-monitor.
---

# LLM Answer Engine Direct

Query the major AI answer engines directly and return structured brand visibility data. The primitive behind AEO (Answer Engine Optimization) measurement.

## When to Use
- "Are we mentioned in ChatGPT / Claude / Gemini / Perplexity answers?"
- "What does ChatGPT say when someone asks about [our category]?"
- Running AEO visibility benchmarks
- Called by `aeo-visibility` and `aeo-visibility-monitor`

## Prerequisites
Required API keys (at least one):
- `OPENAI_API_KEY` — for ChatGPT (GPT-4o)
- `ANTHROPIC_API_KEY` — for Claude
- `GEMINI_API_KEY` — for Gemini
- `PERPLEXITY_API_KEY` — for Perplexity

## Workflow

### 1. Define queries

Ask user for (or receive from calling skill):
- The brand/product name to look for
- 3–5 queries a target buyer would ask

Example queries for "Pepper":
- "What's the best AI agent hosting platform?"
- "How do I host a Claude agent without DevOps?"
- "Best managed AI agent platforms 2024"

### 2. Query each engine

```python
#!/usr/bin/env python3
import os, json, sys
from openai import OpenAI

BRAND = sys.argv[1]
QUERY = sys.argv[2]
ENGINE = sys.argv[3]  # openai | anthropic | gemini | perplexity

results = {"engine": ENGINE, "query": QUERY, "brand": BRAND}

if ENGINE == "openai":
    client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": QUERY}],
        max_tokens=800
    )
    answer = resp.choices[0].message.content

elif ENGINE == "anthropic":
    import anthropic
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    resp = client.messages.create(
        model="claude-opus-4-6",
        max_tokens=800,
        messages=[{"role": "user", "content": QUERY}]
    )
    answer = resp.content[0].text

elif ENGINE == "perplexity":
    client = OpenAI(
        api_key=os.environ["PERPLEXITY_API_KEY"],
        base_url="https://api.perplexity.ai"
    )
    resp = client.chat.completions.create(
        model="sonar-pro",
        messages=[{"role": "user", "content": QUERY}]
    )
    answer = resp.choices[0].message.content

elif ENGINE == "gemini":
    import google.generativeai as genai
    genai.configure(api_key=os.environ["GEMINI_API_KEY"])
    model = genai.GenerativeModel("gemini-1.5-pro")
    resp = model.generate_content(QUERY)
    answer = resp.text

# Score mention
brand_lower = BRAND.lower()
answer_lower = answer.lower()
mentioned = brand_lower in answer_lower

# Find position (which paragraph first mentions brand)
paragraphs = answer.split('\n\n')
position = next((i+1 for i, p in enumerate(paragraphs) if brand_lower in p.lower()), None)

# Extract surrounding context
context = ""
if mentioned:
    idx = answer_lower.index(brand_lower)
    context = answer[max(0, idx-100):idx+200]

results.update({
    "answer": answer,
    "mentioned": mentioned,
    "position": position,
    "context": context,
    "word_count": len(answer.split())
})

print(json.dumps(results))
EOF
```

### 3. Run across all available engines

```bash
BRAND="Pepper"
QUERY="What's the best AI agent hosting platform?"

for ENGINE in openai anthropic perplexity gemini; do
  KEY_VAR="${ENGINE^^}_API_KEY"
  if [ -n "${!KEY_VAR}" ] || [ "$ENGINE" = "anthropic" -a -n "$ANTHROPIC_API_KEY" ]; then
    python3 /tmp/aed_query.py "$BRAND" "$QUERY" "$ENGINE" >> /tmp/aed_results.jsonl
    sleep 1  # rate limit
  fi
done
```

### 4. Structured output

```json
{
  "query": "What's the best AI agent hosting platform?",
  "brand": "Pepper",
  "results": [
    {
      "engine": "openai",
      "mentioned": true,
      "position": 2,
      "context": "...Pepper offers zero-DevOps agent hosting...",
      "framing": "positive"
    },
    {
      "engine": "anthropic",
      "mentioned": false,
      "position": null
    },
    {
      "engine": "perplexity",
      "mentioned": true,
      "position": 1,
      "context": "...Pepper is a managed hosting platform..."
    },
    {
      "engine": "gemini",
      "mentioned": false
    }
  ],
  "visibility_score": "2/4 engines",
  "top_engine": "perplexity"
}
```

## Output
Structured JSON with per-engine mention status, position, and context.

## Called By
- `aeo-visibility` — for on-demand checks
- `aeo-visibility-monitor` — for weekly tracking
