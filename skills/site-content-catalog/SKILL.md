---
name: site-content-catalog
description: Catalog all the pages and content on a website — URLs, titles, topics, and content type. Use when asked to inventory a website, catalog content, or build a content map of a site.
---

# Site Content Catalog

Crawl and catalog a website's content — all pages, titles, topics, word counts, and content types. Foundation for content audits, gap analysis, and topical authority mapping.

## When to Use
- "Inventory all the content on [website]"
- "Catalog [site]'s pages"
- "Build a content map of [website]"
- "What pages does [site] have?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`

## Workflow

**Step 1: Get sitemap**
```bash
orth run scrape "<website_url>/sitemap.xml" \
  --body '{"format": "text"}'
```
If no sitemap.xml, try `/sitemap_index.xml`, `/sitemap/`, or scrape the homepage for navigation links.

**Step 2: Extract and classify URLs**
Pass the sitemap content to Claude:
> "Extract all URLs from this sitemap XML. Categorize each URL by content type: blog post, landing page, product page, case study, documentation, comparison page, pricing page, legal, or other."

**Step 3: Sample and analyze pages**
For each content category, scrape a representative sample (up to 20 pages total):
```bash
orth run scrape "<page_url>" \
  --body '{"format": "markdown", "extract": ["title", "h1", "h2", "meta_description"]}'
```

**Step 4: Build catalog with LLM**
Pass all scraped page metadata to Claude:
> "Build a content catalog from these pages. For each page produce: URL, title, primary topic, content type, estimated word count, target keyword (inferred), and content quality (thin/medium/substantial). Format as a markdown table."

**Step 5: Save catalog to state**
> "Should I save this content catalog to state? (yes/no)"

Only proceed if user confirms:
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_write "seo/content-catalog.md" "<catalog markdown table>"
```

## Output
Full content catalog with URLs, content types, topics, and quality classifications. Saved to `seo/content-catalog.md` for use by brand-voice-extractor and seo-content-audit.
