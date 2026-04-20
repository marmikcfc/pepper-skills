---
name: champion-tracker
description: Track job changes for your champions and past customers — detect when a contact moves to a new company and alert you to re-engage. Use when asked to track job changes, find where champions moved, or set up champion tracking.
---

# Champion Tracker

Track when your champions (past customers, power users, advocates) change jobs — and alert you when they land somewhere you can re-engage.

## When to Use
- "Track job changes for our champions list"
- "Did any of our past champions move to new companies?"
- "Set up champion tracking for these contacts"
- "Find where [person] works now"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`

## Workflow

**Step 1: Load champions list**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

CHAMPIONS=$(state_read "contacts/champions.md")
```
If empty, ask user to provide a list of champion emails or LinkedIn URLs, then ask for confirmation:

> "I'll save this champion list to state. Should I proceed? (yes/no)"

Only proceed if the user confirms:
```bash
state_write "contacts/champions.md" "<champion list>"
```

**Step 2: Check current employment for each champion**
```bash
orth run people-search /search \
  --body '{"name": "<champion_name>", "email": "<email>"}'
```

**Step 3: Detect job changes**
For each champion: compare `current_company` from the people-search response vs. the `last_known_company` stored in `contacts/champions.md`. Flag if they differ.

**Step 4: Enrich new companies**
For each champion who moved:
```bash
orth run company-intel /intelligence \
  --body '{"company": "<new_company>"}'
```
Score new company against ICP criteria. Suggest re-engagement if ICP fit >= 60.

**Step 5: Present job change alerts**
Table: Champion | Old Company | New Company | New Title | ICP Fit Score | Suggested Action

> "Found N job changes. Should I update the champions state and log these moves? (yes/no)"

Only proceed if user confirms.

**Step 6: Update state after confirmation**
```bash
state_write "contacts/champions.md" "<updated champions with new companies>"
state_append "signals/champion-moves.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ) | <name> | <old_company> | <new_company> | <new_title> | <icp_fit_score>"
```

## Output
Job change alerts for tracked champions, with ICP fit scores for their new companies. Updated champion list written to state.
