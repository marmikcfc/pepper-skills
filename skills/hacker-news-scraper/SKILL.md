---
name: hacker-news-scraper
description: Search Hacker News for discussions, posts, and comments about a topic, company, or technology. Use when asked to find HN discussions, check what HN thinks about something, or monitor HN mentions.
---

# Hacker News Scraper

Search Hacker News discussions using the Algolia HN API (free, no API key required).

## When to Use
- "What does HN think about [topic/company]?"
- "Find HN discussions about [technology]"
- "Search HN for [keyword]"
- "Are people on HN talking about [product/problem]?"

## Prerequisites
None — Algolia HN API is free and public.

## Workflow

**Step 1: Search stories**
```bash
curl -s "https://hn.algolia.com/api/v1/search?query=<ENCODED_QUERY>&tags=story&hitsPerPage=20" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for hit in data['hits']:
    print(f\"[{hit.get('points',0)} pts] {hit['title']}\")
    print(f\"  URL: {hit.get('url','https://news.ycombinator.com/item?id='+str(hit['objectID']))}\")
    print(f\"  Comments: {hit.get('num_comments',0)} | Date: {hit.get('created_at','')[:10]}\")
    print()
"
```

**Step 2: Search comments**
```bash
curl -s "https://hn.algolia.com/api/v1/search?query=<ENCODED_QUERY>&tags=comment&hitsPerPage=20" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for hit in data['hits']:
    print(f\"Comment by {hit.get('author','?')}: {hit.get('comment_text','')[:200]}\")
    print(f\"  Story: {hit.get('story_title','')}\")
    print()
"
```

**Step 3: LLM synthesis**
Pass top results to Claude:
> "Summarize what Hacker News thinks about [topic]. Extract: key themes, overall sentiment (positive/negative/mixed), notable discussions, and any concerns or praise that repeat across multiple threads."

## Output
Summary of HN sentiment + top 5 discussion links with comment counts and scores.
