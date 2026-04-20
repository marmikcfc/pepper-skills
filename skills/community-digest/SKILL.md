---
name: community-digest
description: Pull daily intelligence from HN, Reddit, and social listening into one digest — use for a morning brief, market pulse, or competitive signals summary.
---
# Community Digest

Aggregate daily intelligence from developer and founder communities — Hacker News, Reddit, and social listening — then synthesize it into a concise, actionable brief scoped to your ICP.

## When to Use

- Starting the day and want a market pulse before outreach or content
- Preparing for a customer call and need current pain signal context
- Looking for competitive moves or emerging category narratives
- Running a weekly GTM review and need the signal feed

## Prerequisites

- `ORTHOGONAL_API_KEY` — used by the `hacker-news-scraper`, `reddit-wizard`, and `social-listening` skills
- `ANTHROPIC_API_KEY` — used to synthesize the final digest
- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

**Step 1: Load ICP context**

```bash
ICP=$(state_read "strategy/icp.md")
```

If `ICP` is not empty, extract the top 3-5 keywords or themes to focus the intelligence searches. If empty, proceed with general searches.

**Step 2: Run intelligence gathering in parallel**

Run all three gathering steps simultaneously:

```bash
# HN signals
orth run hacker-news-scraper /search \
  --body "{\"keywords\": [\"<icp_keyword_1>\", \"<icp_keyword_2>\", \"<icp_keyword_3>\"], \"limit\": 20}"

# Reddit pain signals
orth run reddit-wizard /mine \
  --body "{\"subreddits\": [\"startups\", \"SaaS\", \"entrepreneur\", \"LocalLLaMA\", \"LangChain\"], \"keywords\": [\"<icp_keyword_1>\", \"<icp_keyword_2>\"], \"limit\": 30}"

# Social listening
orth run social-listening /mentions \
  --body "{\"queries\": [\"<product_name>\", \"<competitor_1>\", \"<competitor_2>\"], \"limit\": 20}"
```

Collect all outputs before proceeding.

**Step 3: Synthesize the digest**

Pass all gathered intelligence to Claude:

> "Synthesize this intelligence into a daily digest. Format:
>
> **Top 3 signals worth acting on today** — for each: source, what it means for us, and the suggested action.
>
> **Competitor activity** — any notable moves, launches, or positioning shifts detected.
>
> **ICP pain themes** — recurring pain patterns surfacing across sources today.
>
> Keep the entire digest under 400 words. Be specific and direct — no filler."

**Step 4: Show digest**

Present the synthesized digest in full to the user.

**Step 5: Optional save**

Ask: "Save this digest to state? (yes/no)"

Only if yes:
```bash
state_append "intel/$(date +%Y-%m-%d).md" "<digest>"
```

Confirm: "Digest saved to `intel/$(date +%Y-%m-%d).md`."

## Output

Formatted daily digest covering top signals, competitor activity, and ICP pain themes — optionally saved to `intel/YYYY-MM-DD.md`.
