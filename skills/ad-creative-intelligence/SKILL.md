---
name: ad-creative-intelligence
description: Research what ads competitors are running across Meta and Google — their hooks, claims, creative angles, and targeting signals. Use when asked to research competitor ads, find ad inspiration, or analyze what's working in your market.
---

# Ad Creative Intelligence

Research what competitors are running in paid advertising — hooks, claims, creative angles, and messaging themes from Meta Ads Library and Google Ads Transparency.

## When to Use
- "What ads is [competitor] running?"
- "Research competitor ad creatives"
- "Find ad inspiration in [industry]"
- "What messaging is working in paid for [market]?"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Meta Ads Library**
```bash
orth run scrape "https://www.facebook.com/ads/library/?active_status=active&ad_type=all&q=<competitor_name>" \
  --body '{"format": "text"}'
```

**Step 2: Google Ads Transparency Center**
```bash
orth run scrape "https://adstransparency.google.com/?region=anywhere&q=<competitor_name>" \
  --body '{"format": "text"}'
```

**Step 3: Extract ad patterns with LLM**
Pass all scraped ad text to Claude:
> "Analyze these ads and extract:
> 1. Top 5 headline hooks (how they grab attention)
> 2. Core claims and promises (what outcomes do they promise?)
> 3. Creative angles (emotional vs. rational, fear vs. aspiration, problem vs. solution)
> 4. Target audience signals (who are these ads designed for?)
> 5. Unique differentiators they're emphasizing
> 6. Offers they're promoting (free trial, demo, discount, etc.)
> 7. What appears to be their highest-volume/most-tested creative
> Format as a structured ad intelligence report."

**Step 4: Present results**
Display ad intelligence report with patterns and examples.

## Output
Structured report of competitor ad hooks, claims, creative angles, and offer patterns.
