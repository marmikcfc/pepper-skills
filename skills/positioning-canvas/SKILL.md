---
name: positioning-canvas
description: Build April Dunford's 7-component positioning canvas. Use when defining product positioning, messaging strategy, or entering a new market segment.
---
# Positioning Canvas

Walk through April Dunford's 7-component positioning framework to produce a clear, defensible positioning statement. The result is saved as the workspace's canonical positioning document and referenced by other GTM skills.

## When to Use

- Starting a new GTM motion and need a positioning foundation
- Repositioning after product or market changes
- Onboarding a new go-to-market hire who needs to understand the positioning
- Reviewing whether current positioning still holds against the competitive landscape

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance
- `ANTHROPIC_API_KEY` — used to synthesize the positioning statement draft

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

**Step 1: Load existing positioning**

```bash
EXISTING=$(state_read "strategy/positioning.md")
```

If content exists, show it and ask: "You already have a positioning canvas saved. Start fresh or update the existing one? (fresh/update)"

If empty, proceed to Step 2.

**Step 2: Walk through each of the 7 components**

Ask for user input on each component one at a time. Do not move to the next until the user has answered (or explicitly skipped).

1. **Competitive alternatives** — "What would your best-fit customers do if your product didn't exist? (e.g., spreadsheets, hire someone, use [alternative])"
2. **Unique attributes** — "What capabilities or features do you have that those alternatives lack?"
3. **Provable value** — "For each unique attribute, what does it actually enable the customer to do or achieve?"
4. **Best-fit customers** — "Which customers care most about that value? Describe the firmographic and behavioral profile."
5. **Market category** — "What market frame makes your attributes feel obvious and expected rather than surprising? (e.g., 'AI agent platform', 'workflow automation')"
6. **Relevant trends** — "What macro or industry trends make this the right time for your solution?"
7. **Positioning statement** — "Any existing statement or tagline you want to preserve or evolve?"

**Step 3: Synthesize a draft canvas**

Pass all inputs to Claude:

> "Using these 7 inputs from the April Dunford positioning framework, synthesize a complete positioning canvas document. Include: a section for each of the 7 components with the user's input plus any clarifying insight, and a final positioning statement in this format: 'For [best-fit customers] who [situation/trigger], [product name] is the [market category] that [unique value]. Unlike [competitive alternatives], [product name] [key differentiator].' Make the statement punchy and specific. Return as clean markdown."

**Step 4: Approval gate**

Show the full draft canvas to the user and ask:

"Save this as your canonical positioning document at `strategy/positioning.md`? (yes/edit/no) — Only proceed if user confirms."

- If `edit`: ask what to change, revise, show again, repeat gate
- If `no`: discard, no state write
- If `yes`: proceed to Step 5

**Step 5: Save to state**

```bash
state_write "strategy/positioning.md" "<full_canvas_markdown>"
```

Confirm: "Positioning canvas saved to `strategy/positioning.md`."

## Output

`strategy/positioning.md` containing all 7 components and a synthesized positioning statement in April Dunford's framework.
