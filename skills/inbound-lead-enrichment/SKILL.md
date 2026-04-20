---
name: inbound-lead-enrichment
description: Enrich an inbound lead with full company and person data — email, phone, LinkedIn, company size, funding, tech stack. Use when a new lead signs up, fills a form, or requests a demo and you need their full profile.
---

# Inbound Lead Enrichment

Take an inbound lead (email or name + company) and enrich with full person and company context. Produces a structured lead profile with ICP fit score.

## When to Use
- "Enrich this inbound lead: [email]"
- "Someone just signed up — what do we know about them?"
- "Fill in the details for this lead: [name] at [company]"
- "Research this inbound: [email or name+company]"
- Upstream triage has flagged leads as `insufficient_data`

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL` (for ICP context)
- `ANTHROPIC_API_KEY` (for ICP scoring)

## Workflow

### Setup — pepper-state helpers

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
state_append() { curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
```

**Step 1: Assess data gaps**

Inventory what's known vs. unknown for each lead:
- **Required:** email, name, company name, title
- **Valuable:** company size, industry, funding stage, HQ location, LinkedIn URL
- **Bonus:** tech stack, recent news, LinkedIn activity

If only an email is available, extract the domain and skip personal email providers (gmail, yahoo, hotmail, outlook).

**Step 2: Full waterfall enrichment**
```bash
orth run comprehensive-enrichment /enrich \
  --body '{"email": "<email>", "name": "<name>", "company": "<company>"}'
```

**Step 3: Company intelligence**
```bash
orth run company-intel /intelligence \
  --body '{"company": "<company_domain_or_name>"}'
```

This returns: company description, industry, employee count, funding stage, HQ location, tech stack, and recent news.

**Step 4: LinkedIn activity scan (recent signals)**
```bash
orth run linkedin-activity /activity \
  --body '{"person": "<linkedin_url_or_name_plus_company>", "limit": 3}'
```

**Step 5: Stakeholder discovery (for Tier 1-2 leads or deep enrichment)**

Find other buying committee members at the same company:
```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "<economic_buyer_title> at <company_name>", "pageSize": 5}'
```

Run for each key buying persona (economic buyer, champion, technical evaluator).

**Step 6: ICP fit scoring**

Load ICP context:
```bash
ICP=$(state_read "strategy/icp.md")
```

Pass enriched profile + ICP to Claude for scoring:
> "Score this lead against our ICP on a 0-100 scale. ICP: {ICP}. Lead profile: {enriched_data}. Return JSON: {score, tier (hot/warm/cold), fit_reasons: [], red_flags: [], recommended_action: (fast-track|nurture|disqualify)}"

**Step 7: Present enriched profile**

Output structured lead profile:
- **Person:** Name, title, seniority level, LinkedIn URL, email, phone
- **Company:** Industry, employee count, funding stage, tech stack, HQ location, description
- **Signals:** Recent LinkedIn posts, job changes, company news
- **Stakeholders:** Other buying committee members found
- **ICP fit:** Score and tier, fit reasons, red flags, recommended next action

**Step 8: Save to cache (after presenting, ask for confirmation)**
```bash
state_append "contacts/cache.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ) | <email> | <name> | <company> | <title> | <linkedin_url>"
```

## Handling Edge Cases

**Personal email (gmail, yahoo, etc.):**
- Check if name + other data can identify the company (e.g., from form field)
- If company is mentioned elsewhere, use it
- If truly unknown, flag as `company_unidentified` and still enrich the person

**Multiple leads from same company:**
- Research the company once, apply profile to all leads
- Note: "X people from [Company] came inbound — buying committee forming?"

**Lead title doesn't match enriched data:**
- Trust enriched data over self-reported form data
- Note the discrepancy in the output

**Enrichment fails for a lead:**
- Fall back to web search for company info
- Mark as `enrichment_partial` and move on — never block the full batch

## Output

Structured lead profile with ICP fit score and recommended next action. Optionally saved to contact cache.
