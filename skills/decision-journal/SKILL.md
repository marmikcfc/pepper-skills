---
name: decision-journal
description: Log a strategic decision to the append-only decision journal. Records the decision, alternatives considered, rationale, and expected outcome. Append-only — decisions are never overwritten.
---
# Decision Journal

Log a strategic decision to the append-only decision journal. Every significant GTM decision — a pricing change, a channel commitment, an ICP pivot, a hire — should be recorded here with the reasoning at the time. Creates a permanent, auditable record of how the strategy evolved and why.

## When to Use

- Making a significant GTM decision (pricing, channel, ICP, positioning, hire)
- After a strategy review where a decision was reached
- When committing to a bet or killing an experiment
- Before a board update to ensure decisions are documented

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance

## Decision Entry Format

Each entry in `decisions/decisions.log.md`:

```markdown
---
Date: YYYY-MM-DD
Decision: <decision title — what was decided, 1 sentence>
Alternatives considered:
  - <alternative 1>
  - <alternative 2>
  - (none considered if this was the only option)
Rationale: <why this option, 2-4 sentences>
Expected outcome: <what you expect to happen as a result, be specific>
Reversibility: <reversible / hard-to-reverse / irreversible>
Owner: <person or agent>
---
```

Entries are append-only. Decisions are never edited or deleted — even if they turn out to be wrong.

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

**Step 1: Show recent decisions (context)**

```bash
JOURNAL=$(state_read "decisions/decisions.log.md")
```

If `JOURNAL` is non-empty, show the last 3 entries so the user has context before logging a new one.

**Step 2: Collect decision details**

Ask the user for each field:

1. **Decision** — "What was decided? (1 sentence, active voice: 'We will...', 'We are committing to...', 'We are killing...')"
2. **Alternatives considered** — "What other options were on the table? (list them, or say 'none' if this was the only path)"
3. **Rationale** — "Why did you choose this option? What evidence or reasoning led here? (2-4 sentences)"
4. **Expected outcome** — "What do you expect to happen as a result? Be specific: what metric, behavior, or situation changes?"
5. **Reversibility** — "How hard is this to reverse? (reversible / hard-to-reverse / irreversible)"
6. **Owner** — "Who is accountable for this decision?"

**Step 3: Compose and preview the entry**

```bash
TODAY=$(date -u +%Y-%m-%d)
ENTRY="
---
Date: $TODAY
Decision: $DECISION
Alternatives considered:
$(echo "$ALTERNATIVES" | sed 's/^/  - /')
Rationale: $RATIONALE
Expected outcome: $EXPECTED_OUTCOME
Reversibility: $REVERSIBILITY
Owner: $OWNER
---"
```

Show the composed entry to the user:

```
Here is the decision entry to log:

$ENTRY

Append to decisions/decisions.log.md? (yes/edit/no)
```

- If `edit`: ask what to change, revise, show again, repeat
- If `no`: discard
- If `yes`: proceed

**Step 4: Append to journal**

```bash
state_append "decisions/decisions.log.md" "$ENTRY"
```

Confirm: "Decision logged to `decisions/decisions.log.md`. This entry is permanent and append-only."

**Step 5: Check for strategy amendment**

Ask: "Should this decision trigger a strategy amendment to `strategy/strategy.md`? (yes/no)"

If yes: "Run `strategy-canvas` to refresh the 90-day strategy with this new context. (Recommended if this is a significant pivot or ICP/positioning change.)"

Do not auto-run `strategy-canvas`. Just surface the recommendation and let the user decide.

## Output

One new entry appended to `decisions/decisions.log.md` — permanent, append-only, with full decision context. Optional prompt to refresh strategy if the decision warrants it.
