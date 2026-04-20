---
name: competitor-monitoring-system
description: Use when the user wants ongoing competitive intelligence across a watchlist of competitors, including daily content and pricing diffs, weekly deep profile refreshes, battlecard updates, and digest notifications.
---

# Competitor Monitoring System

## Overview

Phase 3 GTM orchestrator. Chains competitive intelligence sub-skills into a daily light scan and weekly deep refresh loop across every competitor in a watchlist. Produces persistent state per competitor and sends email digests when changes are found.

## State Helpers

Define all three at the top of every Bash block before use:

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

## Watchlist Format

`competitors/watchlist.md` — one row per competitor:

```
name | domain | last_deep_refresh
Acme Corp | acme.com | 2026-04-10
Rival Inc | rivalinc.io | 2026-04-01
```

**If `competitors/watchlist.md` does not exist:** Stop. Ask the user to list competitor names and domains before proceeding. Do not guess or fabricate a watchlist.

## Execution Flow

### Step 1 — Read Watchlist

```bash
WATCHLIST=$(state_read "competitors/watchlist.md")
```

Parse each line (skip header). For each competitor, extract `name`, `domain`, and `last_deep_refresh`.

### Step 2 — Daily Light Scan (every competitor)

Run for every competitor on every invocation.

For each competitor:

1. **Content check** — Use the `competitor-content-tracker` skill to check for new blog posts, LinkedIn activity, and Twitter posts from `<competitor name>` at `<domain>`.

2. **Pricing check** — Use the `competitive-pricing-intel` skill to detect any pricing page changes for `<competitor name>` at `<domain>`.

3. **Log changes (no gate needed):**

```bash
# Only run if changes were detected
state_append "competitors/changes.md" "$(python3 -c "
import datetime
entry = '''
## $(date -u +%Y-%m-%d) — <competitor name>
- Content changes: <summary or 'none'>
- Pricing changes: <summary or 'none'>
'''
print(entry)
")"
```

Changes log is append-only — no approval gate required.

### Step 3 — Weekly Deep Refresh (conditional per competitor)

Check whether `last_deep_refresh` is more than 7 days ago. If yes, run the full deep refresh for that competitor.

```bash
TODAY=$(date -u +%Y-%m-%d)
LAST_REFRESH="<last_deep_refresh value from watchlist>"
DAYS_SINCE=$(python3 -c "
from datetime import date
d1 = date.fromisoformat('$LAST_REFRESH')
d2 = date.fromisoformat('$TODAY')
print((d2 - d1).days)
")
```

If `DAYS_SINCE >= 7`, proceed with steps 3a–3d below. Otherwise skip to the next competitor.

#### 3a — Full Profile

Use the `competitor-research` skill to generate a full updated profile for `<competitor name>` (`<domain>`).

Read the existing profile for diff:

```bash
EXISTING_PROFILE=$(state_read "competitors/<name>/profile.md")
```

**Approval gate — profile overwrite:**

Present the diff between the existing profile and the new profile to the user:

```
The following changes would overwrite competitors/<name>/profile.md:

[show key additions, removals, and edits]

Approve? (yes/no)
```

Only call `state_write` after explicit yes:

```bash
state_write "competitors/<name>/profile.md" "<new profile content>"
```

#### 3b — Ad Creative Intelligence

Use the `ad-creative-intelligence` skill to analyze the current ad strategy for `<competitor name>`. Save the output as `AD_INTEL_<name>` and write to state:

```bash
state_write "competitors/<name>/ad-intel.md" "<ad intelligence output>"
```

No approval gate — this is a full overwrite of intelligence data, but it is non-destructive (always freshly sourced). Skip the gate here to keep the deep refresh fast.

#### 3c — Hiring Signals

Use the `hiring-signals` skill to surface team growth signals for `<competitor name>`. Save the output as `HIRING_INTEL_<name>` and write to state:

```bash
state_write "competitors/<name>/hiring.md" "<hiring signals output>"
```

#### 3d — Battlecard Refresh

Use the `battlecard-generator` skill to create an updated battlecard for `<competitor name>`. Pass it the full context:
- The updated profile from 3a (or read from `competitors/<name>/profile.md`)
- The ad intelligence from 3b (`AD_INTEL_<name>`)
- The hiring signals from 3c (`HIRING_INTEL_<name>`)

This context ensures the battlecard reflects the full current picture — not just the public website.

Read the existing battlecard for diff:

```bash
EXISTING_BATTLECARD=$(state_read "competitors/<name>/battlecard.md")
```

**Approval gate — battlecard overwrite:**

Show the user what is changing versus the prior version:

```
The following changes would overwrite competitors/<name>/battlecard.md:

[show key additions, removals, and edits]

Approve? (yes/no)
```

Only call `state_write` after explicit yes:

```bash
state_write "competitors/<name>/battlecard.md" "<new battlecard content>"
```

#### 3e — Update Watchlist Timestamp

After a successful deep refresh, update `last_deep_refresh` in `competitors/watchlist.md` to today's date. Read the full file, replace the matching line, and write it back.

> "Deep refresh complete for <competitor name>. Update `last_deep_refresh` to today in the watchlist? (yes/no)"

Only proceed if user confirms:

```bash
# Read current watchlist, update last_deep_refresh for this competitor, write back
state_write "competitors/watchlist.md" "<updated watchlist content with new last_deep_refresh>"
```

### Step 4 — Daily Digest Email

After processing all competitors, if any changes were detected in Step 2:

1. Draft the digest email:

```
Subject: Competitive Intel Digest — <date>

Changes detected today:

<for each competitor with changes>
**<competitor name>**
- Content: <summary>
- Pricing: <summary>

<end for each>

Full change log: competitors/changes.md
```

2. **Approval gate — email send:**

Show the draft to the user:

```
Ready to send the following digest via Gmail:

[draft content]

Send? (yes/no)
```

Only send after explicit yes. Use the Gmail integration to send the approved draft.

If no changes were detected across all competitors, skip the email entirely — do not send an empty digest.

## State Files Summary

| Path | Operation | Gate Required |
|------|-----------|---------------|
| `competitors/watchlist.md` | read + write (timestamp update) | Yes — confirm timestamp update |
| `competitors/changes.md` | append | No |
| `competitors/<name>/profile.md` | read + write | Yes — show diff |
| `competitors/<name>/battlecard.md` | read + write | Yes — show diff |
| Gmail digest | send | Yes — show draft |

## Cadence Reference

| Cadence | Triggers | Sub-skills | API calls per competitor |
|---------|----------|------------|--------------------------|
| Daily light | Every run | competitor-content-tracker, competitive-pricing-intel | ~2 |
| Weekly deep | `last_deep_refresh` > 7 days | competitor-research, ad-creative-intelligence, hiring-signals, battlecard-generator | ~8 |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing to profile or battlecard without showing diff | Always read existing file first and present changes before overwriting |
| Sending empty digest | Only send email if at least one change was detected |
| Running deep refresh every day | Always check `last_deep_refresh` against today — skip if < 7 days |
| Proceeding without a watchlist | If `competitors/watchlist.md` is missing, stop and ask the user |
| Using `orth run` to invoke sub-skills | Use natural language: "Use the `<skill-name>` skill to..." |
