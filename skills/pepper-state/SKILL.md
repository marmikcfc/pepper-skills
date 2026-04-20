---
name: pepper-state
description: Read, write, and append to persistent workspace state backed by Pepper Cloud. Use when any skill needs to load prior context (strategy, ICP, metrics, bets) or persist results across sessions.
---
# Pepper State

Foundational state utility for the Pepper Cloud workspace. Every Phase 4 CMO loop skill sources these helpers and uses the state tree documented below to persist and retrieve data across sessions.

## When to Use

- Any skill needs to load prior context before acting (strategy, ICP, metrics, bets)
- You want to persist results, logs, or decisions across agent sessions
- You need to hydrate context at the start of a GTM workflow
- You want to inspect, update, or browse the workspace state tree

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API (Bearer token, NOT `PEPPER_API_KEY`)
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance

## State Helpers

Define all four at the top of every Bash block before use:

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_list() { curl -sf "$PEPPER_CLOUD_URL/api/state/list?prefix=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; [print(e['path']) for e in json.load(sys.stdin)]"; }
```

## State Tree Reference

The canonical GTM state tree. All skills read from and write to these paths.

| Path | Description | Write mode |
|------|-------------|------------|
| `strategy/strategy.md` | 90-day GTM strategy document | mutable |
| `strategy/positioning.md` | April Dunford positioning canvas | mutable |
| `strategy/icp.md` | ICP definition with fit signals | mutable |
| `company/company.md` | Company overview: product, stage, team, customers | mutable |
| `competitors/watchlist.md` | Competitor watchlist (name\|domain\|last_deep_refresh) | mutable |
| `competitors/changes.md` | Daily competitor change log | append-only |
| `bets/bets.md` | Strategic bet ledger | append-only |
| `bets/ranking.md` | ICE-scored bet ranking table | mutable |
| `decisions/decisions.log.md` | Decision journal | append-only |
| `experiments/active/exp-NNN.md` | Active experiment specs | mutable per file |
| `experiments/archive/exp-NNN.md` | Archived experiments | mutable per file |
| `metrics/commitments.md` | Committed metric targets | mutable |
| `metrics/daily/YYYY-MM-DD.md` | Daily metric snapshots | mutable per day |
| `metrics/alerts.md` | Active metric alerts | mutable |
| `revops/pipeline.md` | Outbound pipeline | append-only |
| `revops/outreach.md` | Outreach log | append-only |
| `revops/linkedin-queue.md` | LinkedIn outreach queue | append-only |
| `revops/do-not-contact.md` | Unsubscribe / do-not-contact list | append-only |
| `intel/YYYY-MM-DD.md` | Daily intelligence digest | mutable per day |
| `reviews/weekly/YYYY-WW.md` | Weekly GTM review | mutable per week |

## Context Hydration Pattern

At the top of any skill that needs company/strategy context, source the helpers and load the common state:

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_list() { curl -sf "$PEPPER_CLOUD_URL/api/state/list?prefix=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; [print(e['path']) for e in json.load(sys.stdin)]"; }

# Load core context
COMPANY=$(state_read "company/company.md")
STRATEGY=$(state_read "strategy/strategy.md")
ICP=$(state_read "strategy/icp.md")
POSITIONING=$(state_read "strategy/positioning.md")
```

If a required context field is empty, stop and ask the user to provide it rather than proceeding blind.

## Browsing the State Tree

To list all paths under a prefix:

```bash
state_list "strategy/"
state_list "bets/"
state_list "experiments/"
state_list "metrics/"
state_list "intel/"
```

To list all active experiments:

```bash
state_list "experiments/active/"
```

To find the latest daily metric snapshot:

```bash
state_list "metrics/daily/" | sort | tail -1
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `$PEPPER_API_KEY` as the Bearer token | Always use `$PEPPER_EVENT_SECRET` |
| Proceeding without checking if context exists | Check if `COMPANY` / `STRATEGY` / `ICP` are non-empty before using them |
| Writing to append-only paths with `state_write` | Use `state_append` for logs, ledgers, and journals |
| Overwriting state without showing a diff | Always read the existing value, show what will change, get confirmation |
