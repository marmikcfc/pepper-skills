---
name: seo-content-engine
description: Weekly SEO content production engine — chains opportunity finding, topical mapping, brief creation, article writing, and repurposing into one end-to-end content run. Use when asked to run the weekly content engine, produce SEO content, or generate articles from keyword opportunities.
---

# SEO Content Engine

## When to Use

Run this skill weekly to execute the full SEO content production cycle in one pass: keyword opportunities → topical hierarchy → content briefs → written articles → repurposed variants → state log.

Use this as the single entry point for recurring SEO content production. Do not invoke sub-skills directly unless debugging a specific step in isolation.

## Prerequisites

- `PEPPER_CLOUD_URL` and `PEPPER_API_KEY` env vars must be set
- `seo-opportunity-finder` skill must be installed
- `topical-authority-mapper` skill must be installed
- `content-brief-factory` skill must be installed
- `content-repurposer` skill must be installed
- `strategy/icp.md` must exist in state (run `icp-identification` first if missing)
- `ORTHOGONAL_API_KEY` and `ANTHROPIC_API_KEY` must be set

## Workflow

### Step 1 — Define State Helpers and Load Context

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

ICP=$(state_read "strategy/icp.md")
POSITIONING=$(state_read "strategy/positioning.md")
PUBLISHED=$(state_read "content/published.md")
TODAY=$(date +%Y-%m-%d)
```

**ICP check:** If `ICP` is empty, stop immediately and tell the user:

```
strategy/icp.md is missing. Please run the `icp-identification` skill first, then re-run the SEO content engine.
```

Report what was loaded:

```
Context loaded.
  ICP: [found / not found]
  Positioning: [found / not found]
  Published content log: [found — N entries / not found]
```

If `PUBLISHED` has entries, extract the list of titles and target keywords already covered so the opportunity finder can avoid duplicates.

---

### Step 2 — Find Keyword Opportunities

Use the `seo-opportunity-finder` skill to find keyword gaps and opportunities relevant to your ICP and product.

Pass the following context to the skill:
- The ICP summary from `strategy/icp.md`
- Any positioning context from `strategy/positioning.md` (if available)
- The list of already-published topics from `content/published.md` (if any) — instruct the skill to exclude topics already covered

Wait for the skill to return a prioritized keyword opportunity list.

---

### Step 3 — Build Topical Authority Map

Use the `topical-authority-mapper` skill to organize the keyword opportunities into a content hierarchy.

Pass:
- The prioritized keyword list from Step 2
- The ICP context
- The existing published content (for deduplication — mark topics already covered)

Ask the skill to produce a topical map with pillar and cluster structure, and to flag the top 1–3 highest-priority opportunities to produce this week.

---

### Step 4 — Select Topics for This Run

From the topical map, identify the top 1–3 opportunities to produce this week. Present them to the user:

```
Top opportunities for this week's content run:

1. [Title] — keyword: [keyword] — priority: [high/medium] — reason: [1-line]
2. [Title] — keyword: [keyword] — priority: [high/medium] — reason: [1-line]
3. [Title] — keyword: [keyword] — priority: [high/medium] — reason: [1-line]

Proceed with all 3, or enter the numbers you want to produce this run (e.g. "1" or "1,2"):
```

Wait for user response. Proceed only with the selected topics.

---

### Step 5 — Content Brief + Write + Repurpose (per topic)

Repeat this loop for each selected topic. Complete the full cycle for topic 1 before moving to topic 2.

#### 5a. Create Content Brief

Use the `content-brief-factory` skill to create a detailed SEO content brief for the selected topic.

Pass the target keyword, ICP context, and positioning context. The skill will produce a full brief with outline, keyword targets, angle, and writing guidelines.

**Approval gate — brief review:**

Present the brief to the user, then ask:

```
Content brief for: [topic title]
[display brief]

Approve this brief to proceed to writing? (yes / edit / skip)
```

Wait for response.
- **yes** — proceed to writing
- **edit** — accept the user's edits, then proceed
- **skip** — skip this topic entirely and move to the next

#### 5b. Write the Article

Using the approved brief, write the full article via LLM. Use the Haines framework:

> "Write a complete SEO article based on this brief. Use the Haines framework: open with a direct, confident statement of what the article will deliver; establish credibility through specificity, not credentials; move through the outline with clear H2/H3 headers; use short paragraphs (2–3 sentences max); include concrete examples, not vague platitudes; close with a single clear CTA. Match the recommended word count and incorporate all target keywords naturally. Do not pad — every paragraph must earn its place."

Present the full article to the user.

**Approval gate — article review:**

```
Article written: [title]
[display article]

Approve to generate repurposed variants and log as published? (yes / no)
```

Wait for explicit user response.
- **no** — skip repurposing and logging for this topic; note it was not published
- **yes** — proceed to repurposing, then wait for publish confirmation before logging

#### 5c. Repurpose Content

Use the `content-repurposer` skill to create three variants from the approved article:
1. LinkedIn post
2. X (Twitter) thread
3. Email newsletter section

Pass the full article text. Present all three variants to the user.

#### 5d. CMS Publishing Instructions

After repurposing, instruct the user:

```
Next steps for: [title]

1. Copy the article above and publish it to your CMS.
2. Apply schema markup using the `schema-markup` skill before or after publishing.
3. Confirm below once the article is live so it can be logged.

Article published to CMS? (yes / not yet)
```

Wait for the user to confirm the article is published.
- **not yet** — tell the user the log entry will be skipped for now. They can log it manually later by appending to `content/published.md`.
- **yes** — proceed to Step 5e.

#### 5e. Log Published Article

Append the article record to `content/published.md`:

```bash
state_append "content/published.md" "$(python3 -c "
import sys
date, title, keyword, url, repurposed = sys.argv[1:]
print(f'{date} | {title} | {keyword} | {url} | repurposed: {repurposed}')
" "$TODAY" "[title]" "[target_keyword]" "[url or pending]" "yes")"
```

Ask the user for the published URL (or enter "pending" if not yet available).

Confirm to the user: `Logged: [title] → content/published.md`

---

### Step 6 — Run Summary

After all selected topics are processed, present a single end-of-run summary:

```
SEO Content Engine — Run Summary [TODAY]
═════════════════════════════════════════
Topics selected this run:    [N]
Articles written:            [N]
Articles published + logged: [N]
Articles skipped/pending:    [N]

Published this run:
  • [title] — [keyword] — [url]
  • ...

Repurposed variants created: [N × 3 formats]

Next steps:
  - Publish any pending articles and log them by appending to content/published.md
  - Apply schema markup using the `schema-markup` skill
  - Run the SEO content engine again next week
```

## Output

- Written articles (shown inline, ready to copy to CMS)
- Repurposed variants: LinkedIn post, X thread, email newsletter section per article
- `content/published.md` updated with one entry per confirmed-published article (format: `date | title | target_keyword | url | repurposed: yes/no`)
