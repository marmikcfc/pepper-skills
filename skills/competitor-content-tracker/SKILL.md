---
name: competitor-content-tracker
description: Track what content a competitor is publishing — new blog posts, LinkedIn updates, Twitter posts, and content strategy shifts. Use when asked to monitor competitor content, find new posts from a competitor, or track their content strategy.
---

# Competitor Content Tracker

Monitor competitor content across blog, LinkedIn, and Twitter. Detect new posts, identify content themes, and surface engagement opportunities.

## When to Use
- "What has [competitor] published recently?"
- "Monitor [competitor]'s content"
- "Track [competitor]'s blog and social posts"
- "What content is [competitor] pushing right now?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`

## Workflow

**Step 1: Load previous content snapshot**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

PREV=$(state_read "competitive/content/<competitor>.md")
```

**Step 2: Scrape blog for new posts**
```bash
orth run scrape "<competitor_homepage>/blog" \
  --body '{"format": "links"}'
```

**Step 3: LinkedIn activity**
```bash
orth run linkedin-activity /activity \
  --body '{"company": "<competitor_name>", "limit": 10}'
```

**Step 4: Twitter activity**
```bash
orth run twitter-profile-lookup /profile \
  --body '{"handle": "<competitor_twitter_handle>"}'
```

**Step 5: Detect new content**
Compare current blog links and post titles against `$PREV` to identify what's new since last check.

**Step 6: Analyze content themes**
Pass new content to Claude:
> "What topics and themes is [competitor] focusing on in their latest content? What keywords are they targeting? Is there a strategic shift in their messaging?"

**Step 7: Present and save**
Show: new content list + theme analysis.

> "Should I update the content snapshot in state? (yes/no)"

Only proceed if user confirms:
```bash
state_write "competitive/content/<competitor>.md" "<current_content_list>"
```

## Output
New content detected since last check, theme analysis, and updated content snapshot.
