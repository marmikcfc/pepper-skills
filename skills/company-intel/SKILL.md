---
name: company-intel
description: Get a company intelligence brief using PredictLeads. Use when someone asks about a company, wants to research a company, or wants a company overview/profile. Takes a domain or company name.
---

# Company Intel

Pull a company profile and recent news events from PredictLeads. Returns company overview, key details, and latest news.

## Inputs

- `$DOMAIN` — company domain (e.g. `stripe.com`, `openai.com`)

## Steps

### 1. Get company profile

```bash
orth run predictleads /v3/companies/$DOMAIN
```

### 2. Get recent news events

```bash
orth run predictleads /v3/companies/$DOMAIN/news_events -q limit=10
```

### 3. Format output

Combine results into a brief with:
- **Company name, domain, description** from the profile
- **Key facts** (location, industry, employee count, founded date) if available
- **Recent news** — summarize each event with date and category
- Keep it scannable. Use bullet points, not walls of text.
