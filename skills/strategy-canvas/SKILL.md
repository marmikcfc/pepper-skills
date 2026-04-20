---
name: strategy-canvas
description: Generate or refresh the 90-day GTM strategy canvas. Reads company context, positioning, and ICP from state then produces a versioned strategy/strategy.md.
---
# Strategy Canvas

Generate or refresh the 90-day GTM strategy document for your workspace. Reads company, positioning, and ICP context from state and produces a structured strategy document with a single north-star metric, three strategic bets, weekly cadence, and success criteria.

## When to Use

- Starting a new GTM quarter and need a clean 90-day strategy
- Repositioning or pivoting and need to rebuild the strategy from updated inputs
- Running a strategy review and want to formally refresh `strategy/strategy.md`
- Onboarding a new go-to-market team member who needs the full strategic context

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance
- `ANTHROPIC_API_KEY` — used to synthesize the strategy document

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

**Step 1: Load context from state**

```bash
COMPANY=$(state_read "company/company.md")
POSITIONING=$(state_read "strategy/positioning.md")
ICP=$(state_read "strategy/icp.md")
EXISTING_STRATEGY=$(state_read "strategy/strategy.md")
```

For each empty field, ask the user to provide it inline:
- If `COMPANY` is empty: "No company context found. Briefly describe your product, stage, team size, and 2-3 current customers."
- If `POSITIONING` is empty: "No positioning canvas found. Run `positioning-canvas` first, or paste your current positioning statement."
- If `ICP` is empty: "No ICP definition found. Describe your ideal customer: role, company size, industry, and key buying signals."

If `EXISTING_STRATEGY` is non-empty, show the version date and ask: "An existing strategy was found (see below). Refresh it or start fresh? (refresh/fresh)"

**Step 2: Gather 90-day goal**

Ask the user:
1. "What is the single most important metric for the next 90 days? (e.g., 10 signed pilots, $50K MRR, 3 enterprise LOIs)"
2. "What is the current baseline value of that metric?"
3. "What is the hard deadline? (default: 90 days from today)"

**Step 3: Synthesize the strategy document**

Pass all context to Claude:

> "Using the company context, positioning canvas, ICP definition, and 90-day goal below, produce a complete 90-day GTM strategy document.
>
> Structure:
>
> ## Situation Analysis
> - Current state: [product maturity, traction, team, runway]
> - Market context: [category, competition, timing]
> - Key constraints: [top 2-3 things that limit speed]
>
> ## 90-Day Goal
> - North-star metric: [metric + target + baseline]
> - Why this metric: [1-2 sentences on why this is the right lever]
>
> ## 3 Strategic Bets
> For each bet: Title | Hypothesis | Expected impact | Effort | Owner
>
> ## Weekly Cadence
> - Week 1-4: [focus]
> - Week 5-8: [focus]
> - Week 9-12: [focus]
>
> ## Success Criteria
> - Green: [what winning looks like]
> - Yellow: [what needs a strategy review]
> - Red: [what triggers a full pivot]
>
> ## Risks & Mitigations
> Top 3 risks with mitigations.
>
> Be specific, direct, and opinionated. No filler. Return as clean markdown."
>
> Company: {company}
> Positioning: {positioning}
> ICP: {icp}
> 90-day goal: {goal}

**Step 4: Approval gate**

Show the full draft to the user and ask:

"Save this as your 90-day GTM strategy at `strategy/strategy.md`? (yes/edit/no)"

- If `edit`: ask what to change, revise the relevant section, show the updated draft, repeat gate
- If `no`: discard, no state write
- If `yes`: proceed to Step 5

**Step 5: Save to state**

```bash
# Include version timestamp in the document header
VERSIONED_STRATEGY="<!-- version: $(date -u +%Y-%m-%dT%H:%M:%SZ) -->

$STRATEGY_DRAFT"

state_write "strategy/strategy.md" "$VERSIONED_STRATEGY"
```

Confirm: "Strategy canvas saved to `strategy/strategy.md`."

## Output

`strategy/strategy.md` containing situation analysis, 90-day north-star goal, 3 strategic bets, weekly cadence, success criteria, and top risks — versioned with a timestamp.
