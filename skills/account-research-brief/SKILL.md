---
name: account-research-brief
description: Generate a sales research brief on any target account - company intel, GTM contacts with emails, and personalization hooks from recent news
---

# Account Research Brief

Generate a comprehensive account research brief on any company. Combines Openmart (local business data), Aviato (company intel, founders, funding, headcount, job listings), and Linkup (recent news & signals) into a single actionable dossier.

## Input

The user provides a natural language query like:
- "Research Sweetgreen in Los Angeles"
- "Give me an account brief on Blank Street Coffee in NYC"
- "Tell me everything about Cava in Washington DC"

Extract from the query:
- **Company name** (required)
- **City, State** (optional — improves Openmart results)

## Workflow

### Step 1 — Resolve the website domain

If you don't know the company's website, do a quick Linkup search first:

```bash
orth run linkup /search --body '{"q": "{company_name} official website", "depth": "standard", "outputType": "searchResults", "maxResults": 3}'
```

Extract the root domain (e.g. `blankstreet.com`) from the results. This is needed for Aviato.

If the domain is obvious (e.g. "Sweetgreen" → `sweetgreen.com`), skip this step.

### Step 2 — Fire all API calls in parallel

Run ALL of these as **parallel Bash tool calls in a single response**:

**Openmart — Local business data:**
```bash
orth run openmart /api/v1/search --body '{"query": "{company_name} {city} {state}", "page_size": 3}'
```

**Aviato — Company enrich (includes job listings):**
```bash
orth run aviato /company/enrich -q website={domain} -q full=true
```

**Aviato — Founders:**
```bash
orth run aviato /company/founders -q website={domain} -q page=1 -q perPage=10
```

**Linkup — Recent news & signals:**
```bash
orth run linkup /search --body '{"q": "{company_name} latest news funding expansion hiring 2025 2026", "depth": "deep", "outputType": "searchResults", "maxResults": 5}'
```

That's **4 parallel calls**.

### Step 3 — Filter & merge results

**Openmart:** Filter results by state match. Pick the best name/city match. Extract: address, phone, email, Google rating, Yelp rating, services, staff, social media links.

**Aviato enrich:** Extract: legal name, founded date, headcount, headcount trends, web traffic, traffic sources, traffic by country, social followers, funding total, funding rounds, latest deal, financing status, ownership status, job listings, investor count, description.

**Aviato founders:** Extract: founder names, locations, LinkedIn/Twitter/Crunchbase URLs.

**Linkup:** Extract: news headlines, dates, summaries, source URLs.

## Output Format

Present a clean account research brief:

```
# Account Research Brief: {Company Name}

## Company Snapshot
| | |
|---|---|
| **Legal Name** | {legalName} |
| **Founded** | {year} |
| **HQ** | {locality}, {region} |
| **Industry** | {industryList} |
| **Status** | {financingStatus}, {ownershipStatus} |
| **Headcount** | {headcount} (computed: {computed_headcount}) |
| **Headcount Growth** | {yearlyHeadcountPercent}% YoY |
| **Locations** | {num_stores from Openmart} stores |
| **Total Funding** | ${totalFunding} across {fundingRoundCount} rounds |
| **Latest Round** | ${latestDealAmount} {latestDealType} ({latestDealDate}) |
| **Investors** | {investorCount} total |

## Web Traffic
| Metric | Value |
|--------|-------|
| **Monthly Visits** | {currentWebTraffic} |
| **YoY Growth** | {yearlyWebTrafficPercent}% |
| **Top Sources** | {webTrafficSources breakdown} |
| **Top Countries** | {webViewerCountries} |

## Social Media
| Platform | Followers | YoY Growth |
|----------|-----------|------------|
| LinkedIn | {linkedinFollowers} | - |
| Twitter | {twitterFollowers} | {yearlyTwitterPercent}% |
| Facebook | {facebookLikes} | {yearlyFacebookPercent}% |
| Instagram | {from Openmart social_media_links} |
| TikTok | {from Openmart social_media_links} |

## Founders
For each founder:
- **{fullName}** — {location} | [LinkedIn]({url}) | [Twitter]({url}) | [Crunchbase]({url})

## Local Business Data
| | |
|---|---|
| **Address** | {street_address}, {city}, {state} {zipcode} |
| **Google Rating** | {google_rating}/5 ({google_reviews_count} reviews) |
| **Yelp Rating** | {yelp_rating}/5 ({yelp_reviews_count} reviews) |
| **Phone** | {store_phones or business_phones} |
| **Email** | {business_emails} |
| **Website** | {website_url} |
| **Services** | {product_services_offered} |
| **Type** | {ownership_type} — {business_type} |

## Active Job Listings
| Title | Location | Link |
|-------|----------|------|
| {title} | {inferred from title} | [Apply]({full greenhouse/lever URL}) |

Include ALL job listings from the Aviato response. These are live links to Greenhouse, Lever, etc.

## Recent News & Signals
For each Linkup result:
1. **[{headline}]({url})** — {1-2 sentence summary}

## Outreach Angles
Based on all the data above, suggest 3-4 specific outreach angles:
- What they're actively doing (expanding, hiring, launching)
- Pain points implied by the signals
- Relevant contact emails from Openmart (e.g. partnerships@, realestate@)
```

## Important Rules

- **Only use `orth run` commands** — no curl, no shell scripting, no temp files. This ensures auto-approval.
- **Openmart needs city + state in the query** — always include location for best results. If no location given, still include the company name alone.
- **Aviato uses the website domain** — not the full URL, just `blankstreet.com` not `https://www.blankstreet.com/`.
- **Aviato `full=true`** — this returns funding rounds, investments, acquisitions, founders, AND job listings in one call.
- **Job listings are in `jobListingList`** from Aviato enrich — always include the full URL (e.g. `https://job-boards.greenhouse.io/blankstreet/jobs/4740474003`).
- **Filter Openmart by state** — Openmart search is name-based, not geo-fenced. Always check the `state` field matches.
- **Don't fabricate data** — omit any section where no data was returned.
- **Parallel is key** — all 4 calls in Step 2 have no dependencies on each other. Fire them all at once.

## API Reference

### Openmart `/api/v1/search`
Returns: business_name, street_address, city, state, zipcode, google_rating, google_reviews_count, yelp_rating, yelp_reviews_count, store_phones, business_phones, business_emails, website_url, tags, product_services_offered, staffs (name + role), num_stores, ownership_type, social_media_links (Instagram, TikTok, Facebook, etc.), order_platforms.

### Aviato `/company/enrich`
Returns: legalName, founded, headcount, computed_headcount, headcount trends (monthly/tri-monthly/yearly), headcountHistorical, currentWebTraffic, web traffic trends, webTrafficSources, webViewerCountries, linkedinFollowers, twitterFollowers, facebookLikes, social trends, totalFunding, fundingRoundCount, latestDealType, latestDealDate, latestDealAmount, investorCount, financingStatus, ownershipStatus, industryList, description, URLs (website, linkedin, twitter, facebook, crunchbase, pitchbook), **jobListingList** (title, url, isRemote, locations), fundingRoundList, investmentList, founderList, acquisitionList.

### Aviato `/company/founders`
Returns: founders[] with id, fullName, firstName, lastName, location, URLs (linkedin, twitter, crunchbase, angelList, signalNFX, website).

### Linkup `/search`
Returns: results[] with name (headline), url, content (article text), favicon.
