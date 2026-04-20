---
name: kol-content-monitor
description: Monitor what key opinion leaders in your space are posting and sharing. Use when asked to track influencer content, monitor thought leaders, or find trending topics among KOLs.
---

# KOL Content Monitor

Monitor what key opinion leaders and thought leaders are posting — surface trending topics, content opportunities, and engagement moments.

## When to Use
- "What are [KOL names] posting about?"
- "Monitor our KOL list for new content"
- "What's trending among thought leaders in [space]?"
- "Find engagement opportunities with KOLs"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`

## Workflow

**Step 1: Load KOL list**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }

KOLS=$(state_read "contacts/kols.md")
```
If empty, ask user for KOL names, LinkedIn URLs, or Twitter handles, then ask:

> "Should I save this KOL list to state for future use? (yes/no)"

Only proceed to save if user confirms:
```bash
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_write "contacts/kols.md" "<kol list>"
```

**Step 2: Get recent LinkedIn posts**
For each KOL:
```bash
orth run linkedin-activity /activity \
  --body '{"person": "<linkedin_url>", "limit": 5}'
```

**Step 3: Get recent Twitter/X posts**
```bash
orth run twitter-profile-lookup /profile \
  --body '{"handle": "<twitter_handle>"}'
```

**Step 4: Identify engagement opportunities**
For each post with >100 likes or >20 comments, evaluate:
- Is the topic relevant to our product/space?
- Sentiment: positive (amplify) or negative (solve)?
- Are ICP buyer personas engaging with it?

Flag posts as: Amplify / Engage / Comment-worthy / Monitor

**Step 5: Present content digest**
For each KOL: recent posts (last 7 days), top performing content, engagement trends, and flagged opportunities.

## Output
KOL content digest with engagement opportunities flagged by type (Amplify/Engage/Comment-worthy).
