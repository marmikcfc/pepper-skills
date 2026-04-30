---
name: leads-coaches-creators
description: Find coach and solopreneur leads (executive coaches, fitness coaches, business coaches, consultants, course creators) with email, phone, LinkedIn, social handles, recent posts, and website. Use when asked to prospect coaches, consultants, course creators, or solo practitioners.
---

# Coaches & Solo Creators Lead Search

End-to-end recipe for sourcing outreach-ready coach/consultant/course-creator leads. Built for the niche where the person *is* the brand — they sell their own time or knowledge.

## Input

Niche + qualifier query:
- "executive coaches with 5+ years experience"
- "Notion course creators on YouTube"
- "fitness coaches running paid programs on Instagram"
- "B2B sales consultants in the UK"

Optional:
- **n** — target leads (default 20, cap 50)
- **platforms** — restrict to specific platforms (e.g. `["linkedin", "youtube"]`)
- **followers_min** — for social-first niches

## Workflow

### Step 1 — Source candidates

Coaches live across LinkedIn, YouTube, Instagram, TikTok. Pull from each plausible channel for the niche, then dedupe by name.

**1a. LinkedIn (best for B2B/exec/business coaches):**

```bash
orth run fiber /v1/natural-language-search/profiles --body '{
  "query": "executive coach OR leadership coach OR business coach, 5+ years experience, US",
  "pageSize": 25
}'
```

For deeper LinkedIn pulls (Sales Nav data):

```bash
orth run edges /actions/linkedin-search-people/run/live --body '{
  "input": {
    "keywords": "executive coach",
    "location": "United States",
    "current_title": "coach"
  }
}'
```

**1b. Apollo (when targeting by title across the web):**

```bash
orth run apollo /api/v1/mixed_people/api_search --body '{
  "person_titles": ["Executive Coach", "Leadership Coach", "Business Coach"],
  "person_locations": ["United States"],
  "page": 1, "per_page": 25
}'
```

**1c. Social-first niches (fitness, lifestyle, course creators) — discover via SearchAPI:**

```bash
# YouTube — niche keyword
orth run searchapi /api/v1/search --query \
  engine=youtube q="notion productivity course" type=channel

# Instagram — hashtag + bio search
orth run scrapecreators /v1/google/search --query q='site:instagram.com "fitness coach" "DM to apply"'
```

Dedupe; aim for ~30 candidates to filter down to N.

### Step 2 — Profile + recent content per platform

For each candidate, identify their **primary platform** (where they post most) and pull profile + last 5–8 posts.

```bash
# LinkedIn (Fiber for live data + posts)
orth run fiber /v1/linkedin-live-fetch/profile/single --body '{"identifier": "{linkedin_url}"}'
orth run fiber /v1/linkedin-live-fetch/profile-posts --body '{"identifier": "{linkedin_url}"}'

# YouTube
orth run scrapecreators /v1/youtube/channel --query handle={handle}
orth run scrapecreators /v1/youtube/channel-videos --query handle={handle} count=8

# Instagram
orth run scrapecreators /v1/instagram/profile --query handle={handle}
orth run scrapecreators /v2/instagram/user/posts --query handle={handle} count=8

# TikTok
orth run scrapecreators /v1/tiktok/profile --query handle={handle}
orth run scrapecreators /v3/tiktok/profile/videos --query handle={handle} count=8

# Twitter/X
orth run scrapecreators /v1/twitter/profile --query handle={handle}
orth run scrapecreators /v1/twitter/user-tweets --query handle={handle} count=10
```

### Step 3 — Resolve website + bio link

Coaches almost always have a website or Linktree-style bio link. Capture it from the social profile, then scrape:

```bash
# Linktree / Linkbio / Komi expansion
orth run scrapecreators /v1/linktree --query url={bio_link}
orth run scrapecreators /v1/linkbio --query url={bio_link}

# Their main site — extract email, services, calendar link, lead magnet
orth run scrapegraph /v1/smartscraper --body '{
  "website_url": "{website_url}",
  "user_prompt": "Extract: contact email, booking/calendar link (Calendly etc), services or offers and price tiers, lead magnet (free PDF/quiz/webinar), testimonials count, primary CTA on home page, podcast/newsletter if any."
}'
```

### Step 4 — Email + phone

Coaches commonly publish their email on the site. If not:

```bash
# Hunter + Tomba waterfall by domain + name
orth run hunter /v2/email-finder --query domain={domain} first_name={first} last_name={last}
orth run tomba /v1/email-finder --query domain={domain} first_name={first} last_name={last}

# If they only have a personal LinkedIn (no business domain):
orth run sixtyfour /find-email --body '{
  "lead": {"first_name": "{first}", "last_name": "{last}", "linkedin_url": "{linkedin_url}"}
}'

# Phone (LinkedIn-based for solo practitioners is usually personal cell — handle accordingly)
orth run sixtyfour /find-phone --body '{
  "lead": {"first_name": "{first}", "last_name": "{last}", "linkedin_url": "{linkedin_url}"}
}'

# Verify
orth run hunter /v2/email-verifier --query email={email}
```

### Step 5 — Assemble lead record

```json
{
  "name": "Marcus Hill",
  "tagline": "Executive coach for first-time founders",
  "primary_platform": "linkedin",
  "linkedin": "https://linkedin.com/in/marcushill",
  "twitter": "https://x.com/marcushill",
  "instagram": null,
  "youtube": null,
  "website": "https://marcushill.coach",
  "email": "marcus@marcushill.coach",
  "email_status": "valid",
  "phone": "+1 646-555-0118",
  "location": "New York, NY",
  "offers": [
    {"name": "1:1 Founder Coaching", "price": "$2,500/mo"},
    {"name": "First 90 Days Cohort", "price": "$1,200"}
  ],
  "lead_magnet": "Free 10-question founder readiness quiz",
  "calendar_link": "https://calendly.com/marcushill/intro",
  "recent_posts": [
    {"platform": "linkedin", "date": "2026-04-26", "text": "The 3 questions I ask every first-time founder before we start...", "reactions": 412, "comments": 38},
    {"platform": "linkedin", "date": "2026-04-22", "text": "Just opened 3 spots for May cohort", "reactions": 156, "comments": 22}
  ],
  "personalization_hooks": [
    "Just opened 3 May cohort spots (Apr 22) — actively filling pipeline",
    "Lead magnet is a quiz — already invested in funnel automation",
    "412-reaction post on first-time founders (Apr 26) — recent viral moment to reference"
  ]
}
```

## Output

**Tier 1 — summary table:**

| Name | Niche | Platform | Followers | Email | Offer | Hook |
|------|-------|----------|-----------|-------|-------|------|

**Tier 2 — full JSON array** for handoff to outreach skills.

End with: `Found {N} coaches in {niche}. {M} have verified email, {K} have phone, {J} have public calendar links. Cost: ~${total}.`

## Cost Estimate

- Source pull (Fiber NL search OR Apollo OR Edges): $0.05–$0.20 / candidate
- ScrapeCreators profile + posts (one platform): $0.08
- Scrapegraph site scrape: $0.02
- Hunter/Tomba email + verify: $0.03
- Sixtyfour fallback (only if needed): $0.10–$0.20

**~$0.20–$0.45 per fully-enriched lead.** A 20-lead batch runs $4–$9.

## Tips

- **Identify primary platform first** — don't fetch all five. A LinkedIn-native business coach won't be on TikTok; a fitness coach won't post on LinkedIn. Pick one, maybe two.
- **The lead magnet field is gold** — knowing they offer a quiz/webinar/PDF tells you their funnel maturity and gives a direct hook.
- **Calendar link presence** is a qualification signal — coaches with public Calendly are pipeline-ready and will respond faster than ones who hide booking.
- **Skip coaches with no public site** — they aren't running a real funnel; conversion will be poor.
- **For pure influencers (not selling time/courses)** use `leads-influencers` instead — the qualification model is different.
- **For coaches at a firm/agency** treat them like B2B and use `comprehensive-enrichment` against their employer.
