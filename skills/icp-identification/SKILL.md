---
name: icp-identification
description: Identify and document your Ideal Customer Profile — who buys your product, what companies fit, and which roles make the decisions. Use when asked to define the ICP, identify target customers, or build an ICP document.
---

# ICP Identification

Research and document your Ideal Customer Profile: target industries, company sizes, buyer roles, and qualifying criteria.

## When to Use
- "Define our ICP"
- "Who should we be targeting?"
- "Build an ICP document for [product]"
- "Identify our ideal customers"

## Prerequisites
- `ORTHOGONAL_API_KEY` — for `orth run exa`, `orth run perplexity`, `orth run company-intel`
- `ANTHROPIC_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`

## Workflow

**Step 1: Research who buys in the category**
```bash
orth run exa /search \
  --body '{"query": "<product_category> ideal customer profile buyer persona B2B", "numResults": 10}'
```

**Step 2: Perplexity research**
```bash
orth run perplexity /chat \
  --body '{"query": "Who typically buys <product_type>? What industries, company sizes, and roles are most common buyers? What triggers the purchase decision?"}'
```

**Step 3: Analyze existing customers (if available)**
If user has examples: "Tell me about 3-5 of your best customers — industry, size, role of buyer, what problem they had."

**Step 4: Company intel on example customers**
For each named example customer:
```bash
orth run company-intel /intelligence \
  --body '{"company": "<customer_company>"}'
```

**Step 5: LLM synthesis — produce ICP document**
Pass all research to Claude:
> "Based on this research, create a structured ICP document with:
> 1. Firmographic profile (industry, company size, funding stage, geography, tech stack signals)
> 2. Buyer roles (primary buyer, champion, economic buyer, blocker)
> 3. Trigger events (what events prompt them to buy?)
> 4. Must-have qualifying criteria (deal-breakers if absent)
> 5. Nice-to-have signals (higher conversion probability)
> 6. Disqualification criteria (who is NOT a good fit)
> 7. Key pain points and desired outcomes
> Format as a reference document the team can use daily."

**Step 6: Present and get approval**
Present the ICP draft. Ask for edits.

> "Should I save this ICP to state as the foundational strategy document? (yes/no)"

Only proceed if user confirms:
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_write "strategy/icp.md" "<approved ICP document>"
```

## Output
Structured ICP document saved to `strategy/icp.md`. Used by tam-builder, lead-qualification, signal-scanner, and other skills.
