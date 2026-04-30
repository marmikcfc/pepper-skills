---
name: leads-online-d2c
description: Find online D2C and e-commerce brand leads (Shopify/WooCommerce/BigCommerce stores, indie consumer brands) with founder email, phone, LinkedIn, brand social handles, and recent posts. Use when asked to prospect D2C brands, e-commerce stores, indie consumer brands, or Shopify merchants.
---

# Online D2C Brand Lead Search

End-to-end recipe for sourcing outreach-ready D2C brand leads where the buyer is the founder or marketing lead. Built for online-only consumer brands with a storefront and a brand social presence.

## Input

Natural-language query describing the segment:
- "Shopify skincare brands under 50 employees"
- "DTC pet food brands in the US"
- "Indie coffee brands with strong Instagram"
- "Sustainable fashion D2C launched in last 2 years"

Optional:
- **n** — target number of brands (default 20, cap 50)
- **employee_min / employee_max**
- **funding_stage** — `bootstrapped`, `seed`, `series_a`, etc.

## Workflow

### Step 1 — Source brands

Two parallel paths; merge & dedupe.

**1a. Apollo company search** — strong for brands with any LinkedIn presence:

```bash
orth run apollo /api/v1/mixed_companies/search --body '{
  "q_organization_keyword_tags": ["skincare", "beauty", "DTC"],
  "organization_num_employees_ranges": ["1,50"],
  "page": 1,
  "per_page": 25
}'
```

**1b. Crustdata company search** — better firmographics + web traffic + decision makers:

```bash
orth run crustdata /screener/companydb/search --body '{
  "filters": [
    {"column": "industry", "type": "in", "value": ["Cosmetics", "Personal Care"]},
    {"column": "headcount", "type": "between", "value": [2, 50]},
    {"column": "tech_stack", "type": "in", "value": ["Shopify"]}
  ],
  "page": 1
}'
```

**1c. (Optional) Surface stores via SERP** if firmographic search is thin:

```bash
orth run searchapi /api/v1/search --query \
  engine=google q='site:myshopify.com "skincare" -inurl:admin' num=50
```

Dedupe by domain.

### Step 2 — Enrich each brand

Run in parallel per brand.

**2a. Storefront scrape — extract brand story, founder name, contact:**

```bash
orth run scrapegraph /v1/smartscraper --body '{
  "website_url": "https://{domain}",
  "user_prompt": "Extract: founder/CEO name, founding year, brand story one-liner, product categories, price tier (budget/mid/premium), contact email or PR email, all social media handles (Instagram, TikTok, YouTube, Twitter, Pinterest, LinkedIn), retail availability."
}'
```

**2b. Company firmographics + decision makers:**

```bash
# Crustdata company enrich (web traffic, headcount trend, news)
orth run crustdata /screener/company --query company_domain={domain}

# Apollo decision-maker search at this company
orth run apollo /api/v1/mixed_people/api_search --body '{
  "q_organization_domains": "{domain}",
  "person_titles": ["Founder", "CEO", "Co-Founder", "Head of Marketing", "VP Marketing", "Head of Growth"],
  "page": 1, "per_page": 5
}'
```

**2c. Email + phone for the founder/marketing lead:**

```bash
# Apollo often returns emails directly. If not:
orth run hunter /v2/email-finder --query domain={domain} first_name={first} last_name={last}
orth run contactout /v1/people/linkedin --query profile={linkedin_url} include=phone

# Verify
orth run hunter /v2/email-verifier --query email={email}
```

### Step 3 — Brand social activity

D2C brands live on social. Pull recent posts from their **two most-active platforms** (typically Instagram + TikTok).

```bash
orth run scrapecreators /v1/instagram/profile --query handle={ig_handle}
orth run scrapecreators /v2/instagram/user/posts --query handle={ig_handle} count=8

orth run scrapecreators /v1/tiktok/profile --query handle={tt_handle}
orth run scrapecreators /v3/tiktok/profile/videos --query handle={tt_handle} count=8

# Founder's own LinkedIn posts (for personalization)
orth run scrapecreators /v1/linkedin/profile --query url={founder_linkedin}
orth run fiber /v1/linkedin-live-fetch/profile-posts --body '{"identifier": "{founder_linkedin}"}'
```

### Step 4 — Assemble lead record

```json
{
  "brand": "Glow Botanicals",
  "domain": "glowbotanicals.com",
  "category": "Clean skincare",
  "founded": 2023,
  "employees": 8,
  "tech_stack": ["Shopify", "Klaviyo", "Yotpo"],
  "monthly_traffic": 42000,
  "decision_maker": {
    "name": "Aria Chen",
    "title": "Founder & CEO",
    "email": "aria@glowbotanicals.com",
    "email_status": "valid",
    "phone": "+1 415-555-0193",
    "linkedin": "https://linkedin.com/in/ariachen"
  },
  "brand_social": {
    "instagram": {"handle": "@glowbotanicals", "followers": 18400},
    "tiktok": {"handle": "@glowbotanicals", "followers": 6200},
    "youtube": null
  },
  "recent_posts": [
    {"platform": "instagram", "date": "2026-04-25", "caption": "New retinol serum drops Friday", "engagement": 412},
    {"platform": "linkedin_founder", "date": "2026-04-20", "text": "We just hit 50K customers...", "reactions": 234}
  ],
  "personalization_hooks": [
    "Founder posted about hitting 50K customers (Apr 20) — growth-stage signal",
    "Launching new SKU Friday — retention moment",
    "Stack includes Klaviyo + Yotpo — already invested in lifecycle/UGC"
  ]
}
```

## Output

**Tier 1 — summary table:**

| Brand | Founder | Email | Stack | Traffic | IG | Hook |
|-------|---------|-------|-------|---------|-----|------|

**Tier 2 — full JSON array** suitable for handoff to `cold-email-outreach` or `outbound-prospecting-engine`.

End with: `Found {N} brands. {M} have verified founder email, {K} have phone, {J} have active social. Cost: ~${total}.`

## Cost Estimate

- Apollo / Crustdata company search: $0.05–$0.10 / brand
- Scrapegraph storefront: $0.02
- Apollo people search: $0.04
- ContactOut LinkedIn lookup: $0.20
- Email verify: $0.01
- ScrapeCreators (2 platforms × profile + posts): $0.15

**~$0.40–$0.55 per fully-enriched brand.** A 20-brand batch runs $8–$11.

## Tips

- **Stack signals matter** — `tech_stack` from Crustdata (Klaviyo, Recharge, Gorgias, Attentive) is gold for personalization. Always include in hooks.
- **Founder LinkedIn posts > brand IG** for personalization in cold outreach. Fetch both, but lead with the founder's own voice.
- **Apollo is usually fastest** for decision-maker email — try it before falling back to Hunter/Tomba waterfall.
- **Skip brands with no founder identifiable** — D2C cold outreach needs a person, not info@. If we can't resolve a name in step 2a/2b, drop the row.
- **Don't fetch tweets** — most indie D2C brands are dormant on Twitter. Save the call.
- **For local D2C with a storefront**, use `leads-local-smb` instead — the addressability model is different.
