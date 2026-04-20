---
name: outbound-prospecting-engine
description: Full outbound orchestrator — coordinates TAM maintenance, signal detection, and sequence tracking into one daily playbook
---

# Outbound Prospecting Engine

## When to Use

Run this skill daily (or on demand) to execute the full outbound motion in one pass. It internally decides which sub-steps to run based on timing: TAM refresh monthly, signal detection every run, sequence follow-up review weekly.

Use this as the single entry point for all outbound activity. Do not invoke `tam-builder` or `signal-detection-pipeline` directly unless debugging a specific sub-step in isolation.

## Prerequisites

- `PEPPER_CLOUD_URL` and `PEPPER_API_KEY` env vars must be set
- `tam-builder` skill must be installed
- `signal-detection-pipeline` skill must be installed
- ICP definition must be established (embedded in `tam-builder`)

## Workflow

### Step 1 — Define State Helpers and Load Current State

Define all three state helpers up front, then read existing state:

```bash
state_read() {
  curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" \
    -H "Authorization: Bearer $PEPPER_API_KEY" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"
}

state_write() {
  local path="$1"; local content="$2"
  curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" \
    -H "Authorization: Bearer $PEPPER_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"
}

state_append() {
  local path="$1"; local content="$2"
  curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" \
    -H "Authorization: Bearer $PEPPER_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"
}

TAM=$(state_read "revops/tam.md")
PIPELINE=$(state_read "revops/pipeline.md")
SEQUENCES=$(state_read "revops/sequences.md")
TODAY=$(date +%Y-%m-%d)
```

Inspect each file:
- If `revops/tam.md` is empty or missing, mark `TAM_REFRESH_NEEDED=true`
- If present, extract the `last_updated:` field from the file header. If the date is more than 30 days ago relative to today, mark `TAM_REFRESH_NEEDED=true`; otherwise `TAM_REFRESH_NEEDED=false`
- If `revops/sequences.md` is empty or missing, mark `SEQUENCE_REVIEW_NEEDED=false`
- If present, extract the `last_reviewed:` field. If the date is more than 7 days ago or missing, mark `SEQUENCE_REVIEW_NEEDED=true`; otherwise `SEQUENCE_REVIEW_NEEDED=false`

Report to the user:
```
State loaded.
  TAM: [found / not found] — last updated: [date or N/A]
  Pipeline log: [found / not found]
  Sequences: [found / not found] — last reviewed: [date or N/A]

TAM refresh due: [yes / no]
Sequence review due: [yes / no]
```

---

### Step 2 — TAM Refresh (if due)

Skip this step if `TAM_REFRESH_NEEDED=false`.

Use the `tam-builder` skill to discover and score companies matching your ICP. Collect the full scored TAM list it produces.

Once `tam-builder` returns results, summarize them for the user:

```
TAM Refresh Results
───────────────────
Total companies scored: [N]

Top 10 by ICP score:
  1. [Company] — score [X] — [1-line reason]
  2. ...
 10. ...

Last updated will be set to: [TODAY]

Write this TAM list to revops/tam.md? (yes / no)
```

Wait for explicit user approval before proceeding.

- If the user says **yes**: call `state_write "revops/tam.md"` with the full scored list, prepending a header:
  ```
  last_updated: [TODAY]
  ---
  [full scored TAM content from tam-builder]
  ```
- If the user says **no**: skip the write and note that the TAM was not updated this run.

---

### Step 3 — Signal Detection

Use the `signal-detection-pipeline` skill to detect signals, qualify leads, and send outreach.

This skill handles its own deduplication, enrichment, ICP qualification, and email approval gate internally. Do not bypass or replicate its internal logic here.

Wait for `signal-detection-pipeline` to complete. Capture from its output:
- Number of new signals detected
- Number of leads qualified and added to pipeline
- Number of emails sent this run

---

### Step 4 — Weekly Sequence Review (if due)

Skip this step if `SEQUENCE_REVIEW_NEEDED=false`.

Read `revops/sequences.md` and parse all active sequences. For each sequence entry, check the `started:` date:

- If `started` was 7 ± 1 days ago → Email 2 is due
- If `started` was 14 ± 1 days ago → Email 3 is due

Surface each pending send to the user, grouped by due date:

```
Sequence Follow-ups Due
───────────────────────
Email 2 (Day 7):
  • [Lead name] <email> — [Company] — original context: [1-line]
  • ...

Email 3 (Day 14):
  • [Lead name] <email> — [Company] — original context: [1-line]
  • ...

Approve these follow-up sends? (yes / no, or list specific indices to skip)
```

Wait for user response.

- If the user approves all or a subset: proceed with sending the approved emails (via the mechanism used in `signal-detection-pipeline` — do not re-implement, delegate back to that skill's send step or note the approved sends for the user to action).
- Update the sequence log with sent timestamps for approved emails.

After handling approvals, update `revops/sequences.md` with:

```
Sequences log — last_reviewed: [TODAY]

[existing sequence entries with updated sent timestamps where applicable]
```

Show the user what will be written to `revops/sequences.md`:

```
Ready to update revops/sequences.md with:
  - last_reviewed set to [TODAY]
  - [N] sequence entries updated with sent timestamps

Write? (yes / no)
```

Wait for explicit user approval before calling `state_write "revops/sequences.md"`.

---

### Step 5 — Summary Report

Present a single end-of-run summary:

```
Outbound Engine — Run Summary [TODAY]
══════════════════════════════════════
TAM
  Total companies in TAM:    [N]
  TAM refreshed this run:    [yes / no]

Signals & Pipeline
  New signals detected:      [N]
  Leads qualified (this run):[N]
  Leads in pipeline (total): [N]

Outreach
  Emails sent this run:      [N]
  Sequences in flight:       [N]
  Follow-ups sent (Day 7):   [N]
  Follow-ups sent (Day 14):  [N]

Next runs
  Next TAM refresh due:      [date]
  Next sequence review due:  [date]
```

If any sub-step was skipped, note why (e.g., "TAM refresh skipped — last updated 5 days ago").

## Output

- Updated `revops/tam.md` (only if TAM was refreshed and user approved)
- Updated `revops/sequences.md` (only if sequence review ran and user approved)
- Terminal summary report for every run
- All pipeline entries written by `signal-detection-pipeline` appear in `revops/pipeline.md` (managed by that child skill)
