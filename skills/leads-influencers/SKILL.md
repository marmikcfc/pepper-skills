---
name: leads-influencers
description: Find influencer and creator leads on Instagram, TikTok, YouTube, Twitter/X, Threads, or Bluesky with bio email, phone, brand site, recent posts, engagement metrics, and audience signals. Use when asked to prospect influencers, creators, KOLs, or UGC partners by niche or hashtag.
---

# Influencer Lead Search

End-to-end recipe for sourcing outreach-ready influencer leads. Built for brand partnerships, UGC, gifting, ambassador programs, and PR pitches.

## Input

Niche + platform query:
- "fitness influencers on Instagram, 10K–100K followers, US"
- "skincare TikTok creators with high engagement"
- "AI YouTubers with 50K+ subs"
- "indie tech newsletter writers on Twitter"

Optional:
- **n** — target creators (default 25, cap 100)
- **followers_min / followers_max** — tier filter (nano <10K, micro 10–100K, mid 100K–1M, macro 1M+)
- **engagement_min** — % engagement floor

## Workflow

### Step 1 — Discover creators

**Pick the platform first.** The discovery query depends on it.

**Instagram — hashtag + keyword:**

```bash
orth run scrapecreators /v1/instagram/song/reels --query song_id=...   # for trending audio
# Better: SERP for hashtag bio matches
orth run searchapi /api/v1/search --query \
  engine=google q='site:instagram.com "skincare" "DM for collabs"'
```

**TikTok — keyword + trending:**

```bash
orth run scrapecreators /v1/tiktok/search/keyword --query keyword="clean skincare" count=50
orth run scrapecreators /v1/tiktok/search/users --query keyword="skincare creator" count=30
orth run scrapecreators /v1/tiktok/creators/popular --query category="beauty"
orth run scrapecreators /v1/tiktok/hashtags/popular --query category="beauty"
```

**YouTube — niche search:**

```bash
orth run searchapi /api/v1/search --query \
  engine=youtube q="ai tools review" type=channel num=30
orth run scrapecreators /v1/youtube/search --query q="ai tools review" type=channel
```

**Twitter / X:**

```bash
orth run searchapi /api/v1/search --query \
  engine=google q='site:x.com OR site:twitter.com "newsletter" "AI"'
```

**Threads / Bluesky:**

```bash
orth run scrapecreators /v1/threads/search/users --query q="skincare"
orth run scrapecreators /v1/bluesky/profile --query handle={handle}
```

### Step 2 — Profile + audience signals

Pull profile (followers, engagement, bio link) and last ~10 posts. Critical for tier filtering and hook generation.

```bash
# Instagram
orth run scrapecreators /v1/instagram/profile --query handle={handle}
orth run scrapecreators /v2/instagram/user/posts --query handle={handle} count=12

# TikTok
orth run scrapecreators /v1/tiktok/profile --query handle={handle}
orth run scrapecreators /v3/tiktok/profile/videos --query handle={handle} count=12
orth run scrapecreators /v1/tiktok/user/audience --query handle={handle}   # demographics

# YouTube
orth run scrapecreators /v1/youtube/channel --query handle={handle}
orth run scrapecreators /v1/youtube/channel-videos --query handle={handle} count=12

# Twitter
orth run scrapecreators /v1/twitter/profile --query handle={handle}
orth run scrapecreators /v1/twitter/user-tweets --query handle={handle} count=20

# Threads / Bluesky
orth run scrapecreators /v1/threads/profile --query handle={handle}
orth run scrapecreators /v1/threads/user/posts --query handle={handle}
```

Compute **engagement rate** = avg(likes + comments) / followers × 100 from the recent posts.

### Step 3 — Filter before enriching contact

Drop creators outside the requested tier or below engagement floor. **Contact enrichment is the expensive step — only run it on rows that survive filtering.**

### Step 4 — Resolve email + phone

Most creators publish a contact email in bio or a Linktree-style link. Cascade:

**4a. Bio link expansion** — almost every creator has one:

```bash
orth run scrapecreators /v1/linktree --query url={bio_link}
orth run scrapecreators /v1/linkbio --query url={bio_link}
orth run scrapecreators /v1/komi --query url={bio_link}
orth run scrapecreators /v1/pillar --query url={bio_link}
```

These often expose the contact email directly.

**4b. Brand site scrape** if bio link points to a personal site:

```bash
orth run scrapegraph /v1/smartscraper --body '{
  "website_url": "{site}",
  "user_prompt": "Extract: contact email, management/PR/booking email, agent or talent rep contact, press email, phone, all social handles, list of brand collaborations or sponsorships visible."
}'
```

**4c. Email-finder fallback** if site has a real domain but no email shown:

```bash
orth run hunter /v2/email-finder --query domain={domain} first_name={first} last_name={last}

# For management/agency lookups
orth run hunter /v2/domain-search --query domain={domain}
```

**4d. Verify:**

```bash
orth run hunter /v2/email-verifier --query email={email}
```

Phone is rarely available for creators and usually undesirable for cold outreach — skip unless explicitly requested.

### Step 5 — Assemble lead record

```json
{
  "creator_name": "Lila Park",
  "handle": "@lilaparkbeauty",
  "primary_platform": "instagram",
  "tier": "micro",
  "niche": "Clean skincare, K-beauty",
  "followers": {"instagram": 47200, "tiktok": 18900, "youtube": 0, "twitter": 0},
  "engagement_rate_pct": 5.8,
  "audience_signals": {
    "top_country": "US",
    "top_age_band": "18-34",
    "gender_skew_pct_female": 87
  },
  "bio_link": "https://linktr.ee/lilaparkbeauty",
  "website": "https://lilapark.beauty",
  "email": "lila@lilapark.beauty",
  "email_status": "valid",
  "management_email": "talent@xyzmgmt.com",
  "past_brand_collabs": ["Glossier", "Ilia Beauty"],
  "recent_posts": [
    {"platform": "instagram", "date": "2026-04-25", "type": "reel", "caption": "K-beauty haul under $50", "likes": 4120, "comments": 87, "views": 89000},
    {"platform": "tiktok", "date": "2026-04-23", "caption": "5-step routine for sensitive skin", "likes": 12400, "shares": 890}
  ],
  "personalization_hooks": [
    "Recent K-beauty haul reel pulled 4K likes (Apr 25) — primed audience for similar brands",
    "Past collabs with Glossier + Ilia — proven brand-partnership track record at premium tier",
    "5.8% engagement rate — top quartile for micro-tier; high-conversion potential"
  ]
}
```

## Output

**Tier 1 — summary table:**

| Creator | Platform | Followers | Eng % | Email | Past Brands | Hook |
|---------|----------|-----------|-------|-------|-------------|------|

**Tier 2 — full JSON array** ready for handoff to `cold-email-outreach` or `kol-discovery`-style follow-on skills.

End with: `Found {N} {tier}-tier {niche} creators. {M} have direct email, {K} have management/agency contact, avg engagement {X}%. Cost: ~${total}.`

## Cost Estimate

- Discovery (search + initial profile): $0.05–$0.10 / candidate
- Profile + posts pull (one platform): $0.08
- Audience demographics (TikTok only): $0.02
- Bio link expansion: $0.02
- Site scrape: $0.02 (when needed)
- Hunter find + verify: $0.02
- Multi-platform creators (cross-platform pull): +$0.10/extra platform

**~$0.20–$0.40 per filtered, enriched creator.** A 25-creator batch runs $5–$10.

## Tips

- **Filter BEFORE enriching contact** — discovery returns lots of fluff. Apply follower/engagement/niche filters first; only enrich the survivors. This is the single biggest cost lever.
- **Engagement rate > follower count** — a 20K micro-influencer with 6% engagement beats a 200K mid-tier at 1% almost every time. Sort by engagement.
- **Bio link is the unlock** — Linktree/Komi/Pillar/Linkbio expansion finds the email faster than any email-finder API. Try it first.
- **Past brand collabs** is a critical hook — surface them in the lead record. Brands love hearing "you already work with [comparable brand]."
- **Audience demographics for TikTok** are uniquely good — use the `/tiktok/user/audience` endpoint when targeting region/age/gender-specific campaigns.
- **Skip phone numbers** — creators don't take cold calls; the email + DM path converts.
- **For nano-creators (<10K)** the email finder fallback often won't work (no business domain). Bio link is the only path.
- **For coaches/course creators who happen to have a following** use `leads-coaches-creators` — different qualification model (offer + calendar link matter more than engagement rate).
