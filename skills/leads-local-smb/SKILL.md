---
name: leads-local-smb
description: Find local-business leads (dentists, gyms, salons, restaurants, clinics, med-spas, law firms, contractors, local D2C with storefronts) with owner email, phone, website, social handles, and recent posts ready for outreach. Use when asked to prospect local SMBs, local-service businesses, or any "businesses near {location}" segment.
---

# Local SMB Lead Search

End-to-end recipe for sourcing outreach-ready local-business leads. Optimized for: dentists, gyms, salons, restaurants, clinics, med-spas, law firms, contractors, auto shops, plumbers, local D2C stores.

## Input

Free-text query — must include a vertical and a location:
- "dentists in Austin TX"
- "med-spas in Miami FL"
- "yoga studios in Toronto"
- "Shopify-powered home goods stores in Brooklyn"

Optional knobs:
- **n** — target number of leads (default 25, cap 100)
- **min_reviews** — Google review-count floor (default none)
- **revenue_min / revenue_max** — Openmart revenue band

## Workflow

### Step 1 — Source businesses

**Primary (US/CA/AU): Openmart search.** Purpose-built for local SMBs, returns owner email + phone when known.

```bash
orth run openmart /api/v1/search --body '{
  "query": "dentists",
  "location": "Austin, TX",
  "limit": 25,
  "min_review_count": 10
}'
```

Map vertical to Openmart `tags` where helpful (e.g. `["dental_clinic"]`, `["gym"]`, `["beauty_salon"]`). For local D2C with a storefront, leave tags empty and rely on `query`.

**Fallback (non-US/CA/AU, or thin Openmart results): SearchAPI Google Maps.**

```bash
orth run searchapi /api/v1/search --query \
  engine=google_maps q="dentists" location="Austin, Texas" type=search
```

Take `local_results[]` — each has `title`, `phone`, `website`, `place_id`, `address`, `rating`, `reviews`.

### Step 2 — Enrich each business

Run these in parallel for the top N businesses.

**2a. Pull website signals** — extract owner name, contact page, about copy, services:

```bash
orth run scrapegraph /v1/smartscraper --body '{
  "website_url": "{website}",
  "user_prompt": "Extract: owner or principal name, contact email if listed, phone, social links (Instagram, Facebook, LinkedIn, TikTok), recent blog/news, list of services or treatments offered, years in business."
}'
```

**2b. Find owner email if not on site** (only if website didn't return one):

```bash
# Hunter domain search — returns role-targeted emails (owner, founder, manager)
orth run hunter /v2/domain-search --query domain={domain} department=executive

# Tomba email-finder by name (run after we have owner name from 2a)
orth run tomba /v1/email-finder --query domain={domain} first_name={first} last_name={last}
```

**2c. Verify every email found:**

```bash
orth run hunter /v2/email-verifier --query email={email}
```

**2d. Phone fallback** (if Openmart/Maps didn't return one):

```bash
orth run tomba /v1/phone-finder --query domain={domain} first_name={first} last_name={last}
```

### Step 3 — Pull social handles + recent posts

For each social link found in 2a, fetch the profile and the most recent posts. **Pick the single most active platform per business** (don't fetch all four — costs add up).

Heuristic: dentists/clinics/lawyers → Instagram or LinkedIn. Gyms/salons/restaurants → Instagram or TikTok. Local D2C → Instagram + TikTok.

```bash
# Instagram profile + last posts
orth run scrapecreators /v1/instagram/profile --query handle={handle}
orth run scrapecreators /v2/instagram/user/posts --query handle={handle} count=5

# TikTok
orth run scrapecreators /v1/tiktok/profile --query handle={handle}
orth run scrapecreators /v3/tiktok/profile/videos --query handle={handle} count=5

# Facebook
orth run scrapecreators /v1/facebook/profile --query url={url}
orth run scrapecreators /v1/facebook/profile/posts --query url={url}

# LinkedIn (company)
orth run scrapecreators /v1/linkedin/company --query url={url}
```

### Step 4 — Assemble lead record

Emit one normalized JSON object per business:

```json
{
  "business_name": "Bright Smile Dental",
  "vertical": "Dentist",
  "owner_name": "Dr. Sarah Patel",
  "address": "123 Main St, Austin, TX 78701",
  "website": "https://brightsmile.com",
  "email": "sarah@brightsmile.com",
  "email_status": "valid",
  "phone": "+1 512-555-0142",
  "rating": 4.8,
  "review_count": 187,
  "social": {
    "instagram": "https://instagram.com/brightsmiledental",
    "facebook": "https://facebook.com/brightsmiledental",
    "linkedin": null,
    "tiktok": null
  },
  "recent_posts": [
    {"platform": "instagram", "date": "2026-04-22", "caption": "Free whitening with new patient exam this month!", "engagement": 142},
    {"platform": "instagram", "date": "2026-04-18", "caption": "Meet our new hygienist Maria!", "engagement": 87}
  ],
  "personalization_hooks": [
    "Just promoted a new hygienist (Apr 18) — staff growth signal",
    "Running new-patient whitening promo — actively investing in acquisition",
    "187 Google reviews at 4.8★ — strong reputation, candidate for review-management upsell"
  ],
  "source": "openmart"
}
```

## Output

Two-tier output:

**Tier 1 — summary table** (Markdown, every row scannable):

| Business | Owner | Email | Phone | IG | Rating | Hook |
|----------|-------|-------|-------|-----|--------|------|
| Bright Smile Dental | Dr. Sarah Patel | sarah@... ✓ | 512-555-0142 | @brightsmile | 4.8 (187) | New-patient promo running |

**Tier 2 — full JSON array** of all lead records, ready to pipe into the `cold-email-outreach`, `cold-call`, or `outbound-prospecting-engine` skills.

End with one-line summary: `Found {N} leads in {location}. {M} have verified email, {K} have phone, {J} have active Instagram. Cost: ~${total}.`

## Cost Estimate

Per lead (typical):
- Openmart search: $0.01 amortized
- Scrapegraph site scrape: ~$0.02
- Hunter domain-search: $0.01
- Tomba email-finder + verify: $0.02
- ScrapeCreators profile + posts (one platform): ~$0.08

**~$0.10–$0.15 per fully-enriched lead.** A 25-lead batch runs $2.50–$4.

## Tips

- **Respect Openmart's geo limits** — US/CA/AU only. Always fall back to SearchAPI Google Maps for other countries.
- **Don't over-enrich** — if Openmart already returned email + phone (it often does for owner-operated SMBs), skip Hunter/Tomba. Save the call.
- **One social platform, not four** — pick the single most active. For most local SMBs that's Instagram.
- **Personalization hooks > generic openers** — every lead must have at least one hook tied to a real signal (recent post, promo, hire, milestone). Without a hook, the row is half-finished.
- **Filter weak rows before output** — drop businesses with no email AND no phone AND no usable website. They aren't outreach-ready.
- **For Shopify D2C with a storefront** (e.g. local skincare, local apparel) use this skill, not `leads-online-d2c` — the storefront makes them addressable like a local SMB.
