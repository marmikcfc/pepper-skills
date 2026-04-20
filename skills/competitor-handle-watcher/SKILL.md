---
name: competitor-handle-watcher
description: Use to monitor competitor Twitter/X and LinkedIn handles for frustrated users, feature requests, and complaints — surfaces warm leads who are already considering alternatives. Use when asked to monitor competitor complaints or find dissatisfied competitor customers.
---

# Competitor Handle Watcher

Monitor competitor social handles for frustrated users and switching signals. Surfaces people who are already unhappy with the competitor — the warmest possible leads.

## When to Use
- "Monitor what people say about [competitor]"
- "Find people complaining about [competitor]"
- "Are there customers who want to switch from [competitor]?"
- Daily/weekly monitoring of competitor mentions

## Prerequisites
- `ORTHOGONAL_API_KEY`
- Competitor list (names + Twitter handles)

## Workflow

### 1. Define competitors and frustration signals

```bash
# Define competitors and their handles
declare -A COMPETITORS=(
  ["LangGraph"]="@LangChainAI"
  ["Dify"]="@dify_ai"
  ["CrewAI"]="@crewAIInc"
)

# Frustration keywords to look for
FRUSTRATION_SIGNALS=(
  "bug"
  "broken"
  "doesn't work"
  "slow"
  "expensive"
  "support"
  "alternative"
  "looking for"
  "switched"
  "nightmare"
  "hate"
  "frustrated"
)
```

### 2. Monitor Twitter/X for @mentions and complaints

```bash
for COMP_NAME in "${!COMPETITORS[@]}"; do
  HANDLE="${COMPETITORS[$COMP_NAME]}"

  # Search for mentions with frustration signals
  orth run twitter-profile-lookup --query "{\"handle\": \"${HANDLE#@}\"}" > /tmp/comp_profile_${COMP_NAME}.json

  # Search for people mentioning competitor + frustration terms
  for SIGNAL in "${FRUSTRATION_SIGNALS[@]}"; do
    orth run social-listening --query "{
      \"query\": \"${COMP_NAME} ${SIGNAL}\",
      \"platform\": \"twitter\",
      \"limit\": 20
    }" >> /tmp/mentions_${COMP_NAME}.json
    sleep 0.5
  done
done
```

### 3. Monitor LinkedIn for competitor frustration

```bash
for COMP_NAME in "${!COMPETITORS[@]}"; do
  orth run linkedin-activity --query "{
    \"company\": \"${COMP_NAME}\",
    \"search_comments\": true,
    \"keywords\": [\"looking for alternative\", \"switched from\", \"frustrated with\", \"disappointed\"]
  }" >> /tmp/linkedin_mentions_${COMP_NAME}.json
done
```

### 4. Score and filter signals

```python
#!/usr/bin/env python3
import json, sys

HIGH_INTENT = ["looking for alternative", "switched from", "anyone recommend", "replace", "migrate"]
MEDIUM_INTENT = ["frustrated", "broken", "expensive", "bug", "slow"]

results = []
for line in sys.stdin:
    mention = json.loads(line)
    text = mention.get("text", "").lower()

    score = 0
    intent_level = "low"

    for kw in HIGH_INTENT:
        if kw in text:
            score += 10
            intent_level = "high"

    for kw in MEDIUM_INTENT:
        if kw in text:
            score += 5
            if intent_level == "low":
                intent_level = "medium"

    if score > 0:
        mention["intent_score"] = score
        mention["intent_level"] = intent_level
        results.append(mention)

# Sort by intent score
results.sort(key=lambda x: x["intent_score"], reverse=True)
print(json.dumps(results, indent=2))
```

### 5. Enrich high-intent signals

For `high` intent mentions — enrich the person:
```bash
# Get top 10 high-intent signals and enrich
HIGH_INTENT_USERS=$(cat /tmp/scored_mentions.json | python3 -c "
import json,sys
mentions = json.load(sys.stdin)
high = [m for m in mentions if m['intent_level'] == 'high'][:10]
print('\n'.join([m.get('author_handle', '') for m in high]))
")

for HANDLE in $HIGH_INTENT_USERS; do
  orth run twitter-profile-lookup --query "{\"handle\": \"${HANDLE}\"}" >> /tmp/enriched_leads.json
done
```

### 6. Output report

```
# Competitor Handle Watch — [date]

## High-Intent Signals (act now)

1. @handle — "Has anyone found a good alternative to [Competitor]? We've been having issues..."
   - Company: [if found]
   - Email: [if enriched]
   - Recommended action: Send empathy-first outreach

## Medium-Intent Signals (monitor)
[list]

## Volume by Competitor
| Competitor | Total Mentions | High Intent | Medium Intent |
|-----------|---------------|-------------|--------------|
| LangGraph | 47 | 3 | 12 |

## Suggested Outreach
For high-intent signals, use `cold-email-outreach` skill with this angle:
"Saw your tweet about [issue] — we built Pepper specifically to solve that..."
```

## Output
Ranked list of competitor-frustrated users with intent scores and enrichment data.

## Next Step
Feed high-intent contacts into `cold-email-outreach` or `linkedin-manual-queue`.
