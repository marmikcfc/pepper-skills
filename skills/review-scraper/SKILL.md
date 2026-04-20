---
name: review-scraper
description: Scrape and collect customer reviews for a company or product from G2, Capterra, and Trustpilot. Use when asked to collect reviews, get customer feedback data, or research what customers say about a company.
---

# Review Scraper

Collect customer reviews from G2, Capterra, and Trustpilot for any company.

## When to Use
- "Scrape reviews for [company] from G2"
- "Get Capterra reviews for [product]"
- "Collect customer feedback for [company name]"
- "What are customers saying about [competitor]?"

## Prerequisites
- `ORTHOGONAL_API_KEY`

## Workflow

**Step 1: G2 reviews**
```bash
orth run scrape "https://www.g2.com/products/<company-slug>/reviews" \
  --body '{"format": "text"}'
```

**Step 2: Capterra reviews**
```bash
orth run scrape "https://www.capterra.com/p/<id>/<company>/reviews/" \
  --body '{"format": "text"}'
```

**Step 3: Trustpilot reviews**
```bash
orth run scrape "https://www.trustpilot.com/review/<company-domain>" \
  --body '{"format": "text"}'
```

**Step 4: Extract structured reviews with LLM**
Pass raw scraped text from all three sources to Claude:
> "Extract individual reviews from this text. For each review return JSON: {rating: number, title: string, body: string, pros: string, cons: string, reviewer_role: string, reviewer_company_size: string, date: string}"

**Step 5: Present results**
Display as a table: Rating | Role | Pros | Cons | Date

Ask user if they want to save to state for downstream analysis:
> "Should I save these reviews to state for analysis by review-intelligence-digest? (yes/no)"

Only proceed if user confirms:
```bash
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_write "intelligence/reviews/<company>.md" "<structured reviews>"
```

## Output
Structured review dataset with ratings, roles, pros/cons. Optionally saved to `intelligence/reviews/<company>.md`.
