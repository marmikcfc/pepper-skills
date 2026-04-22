---
name: social-listening
description: Monitor brand mentions, competitor activity, and industry conversations across social media and the web
---

# Social Listening

Track brand mentions, competitor activity, and industry conversations across social media and the web.

## When to Use

- User wants to monitor what people say about a brand or product
- User asks "what are people saying about [company]?"
- Tracking competitor launches or announcements
- Monitoring industry trends and sentiment
- Social media due diligence before partnerships

## Workflow

### Step 1: Search Web Mentions with Exa

Find recent mentions, reviews, and discussions across the web:

```bash
exa-search "Notion reviews opinions user feedback" --limit 30
```

### Step 2: Monitor Social Media with Scrape Creators

Check what's being posted on X/Twitter:

```bash
orth run scrapecreators /v1/twitter/user-tweets -q 'handle=NotionHQ'
```

Check LinkedIn company activity:

```bash
orth run scrapecreators /v1/linkedin/company -q 'url=https://linkedin.com/company/notion'
```

> **Note:** Scrape Creators does not have a dedicated "company posts" endpoint. Use `/v1/linkedin/company` to get company page data, or `/v1/linkedin/post` with a specific post URL.

### Step 3: Deep Scrape Key Pages with Scrapegraph

Extract structured data from specific pages found in Steps 1-2:

```bash
orth run scrapegraph /v1/smartscraper -d '{
  "website_url": "https://example.com/review-page",
  "user_prompt": "Extract sentiment, key complaints, and praise about the product"
}'
```

## Examples

**User:** "What are people saying about Slack?"
```bash
# Step 1: Web mentions
exa-search "Slack reviews complaints praise 2025 2026" --limit 20

# Step 2: Their social presence
orth run scrapecreators /v1/twitter/user-tweets -q 'handle=SlackHQ'
```

**User:** "Monitor competitor launches in the AI space"
```bash
exa-search "AI startup launch announcement new product 2026" --limit 30
```

## Tips

- Use Exa for broad web monitoring (blogs, forums, news)
- Use Scrape Creators for social media (X/Twitter, LinkedIn, Instagram, TikTok)
- Use Scrapegraph for extracting structured data from specific URLs
- Include date ranges in Exa queries for recent results
- Track both your brand and competitors for comparative insights
