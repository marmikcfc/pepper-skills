---
name: competitor-ad-teardown
description: Deep-dive analysis of a single competitor's ad strategy — creative themes, messaging evolution, best-performing angles, and what their ad spend reveals about their GTM priorities. Use when asked to do a deep competitor ad analysis or understand one competitor's paid strategy in detail.
---

# Competitor Ad Teardown

Deep analysis of a single competitor's paid advertising strategy — what they're testing, what's working, and what their ad creative reveals about their GTM priorities.

## When to Use
- "Do a deep dive on [competitor]'s ad strategy"
- "Tear down [competitor]'s paid marketing"
- "What's [competitor]'s best-performing ad creative?"
- "Analyze [competitor]'s advertising approach"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Meta Ads Library — full ad set**
```bash
orth run scrape "https://www.facebook.com/ads/library/?active_status=all&ad_type=all&q=<competitor_name>" \
  --body '{"format": "text"}'
```
Pull both active and inactive ads to see what they've tested.

**Step 2: Google Ads Transparency**
```bash
orth run scrape "https://adstransparency.google.com/?region=anywhere&q=<competitor_name>" \
  --body '{"format": "text"}'
```

**Step 3: Validate scrape results**
Meta Ads Library and Google Ads Transparency are JavaScript-rendered pages. Check that each scrape returned at least 500 characters of actual ad content. If a scrape returned minimal content:

> "The [Meta / Google] ad library scrape returned minimal content — the page may require JavaScript or a logged-in session. I'll proceed with whatever was captured, but the teardown may be incomplete."

**Step 4: Enrich with company context**
```bash
orth run competitor-research /research \
  --body '{"competitor": "<competitor_name>"}'
```

**Step 5: LLM deep analysis**
Pass all ad data + competitor research to Claude:
> "Perform a deep teardown of [competitor]'s paid advertising strategy:
> 1. Creative themes and clusters (group their ads into 3-5 distinct creative themes)
> 2. Messaging evolution (how has their pitch changed over time?)
> 3. Top hooks and openings (what grabs attention in their best ads?)
> 4. Claims and proof points (what evidence do they use?)
> 5. Targeting signals (what audiences are they going after?)
> 6. Offer strategy (what conversions are they optimizing for?)
> 7. Budget signals (which creatives have run longest = highest confidence in what works)
> 8. Strategic insights: what does their ad spend reveal about their GTM priorities and where they feel competitive pressure?
> 9. Gaps and opportunities for us: where are they NOT competing that we could win?"

**Step 6: Present teardown**
Display full teardown report.

## Output
Comprehensive ad teardown with creative themes, messaging evolution, top hooks, and strategic implications.
