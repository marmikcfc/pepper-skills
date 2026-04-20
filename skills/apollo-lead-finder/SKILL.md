---
name: lead-finder
description: Find leads matching a specific role, industry, or company profile. Returns enriched contacts with emails and LinkedIn URLs. Use when asked to find leads, build a prospect list, or find people matching a title/company criteria.
---

# Lead Finder

Find leads matching a job title, company type, location, or industry criteria. Returns enriched contacts with verified emails and LinkedIn profiles.

Two phases: **discovery** (free, broad search) then **enrichment** (targeted, with approval gate before any write).

## When to Use
- "Find VPs of Marketing at B2B SaaS companies in the US"
- "Get me 50 CTOs at fintech startups"
- "Find decision-makers at [company list]"
- "Who should I be reaching out to at [company]?"
- "Build a prospect list for [ICP description]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL` (for saving results)

## Workflow

### Setup — pepper-state helpers

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
state_append() { curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
```

### Phase 0: Intake

Ask the user for:
1. **Job titles** — e.g., "VP of Sales", "Head of Growth"
2. **Company size** — employee range (e.g., 51-200, 201-1000)
3. **Industries** — e.g., "B2B SaaS", "FinTech"
4. **Location** — e.g., "United States", "San Francisco"
5. **How many results** — default 50

### Phase 1: Discovery (free)

**Step 1: Natural language prospect search**
```bash
orth run sales-prospecting /prospect \
  --body '{"query": "<user query — e.g. VP of Sales at B2B SaaS companies in the US with 50-500 employees>", "limit": 50}'
```

**Step 2: Broader profile search via Fiber**
```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "<title> at <industry> companies", "pageSize": 15}'
```

**Step 3: Present search results and get approval**

Show the user a preview table with available data (name, title, company, location). State the total count found.

Ask: "Found X leads matching your criteria. Should I enrich these with emails and LinkedIn URLs?"

**NEVER proceed to Phase 2 without explicit user approval.**

### Phase 2: Enrichment (runs after approval)

For each lead, run the enrichment waterfall:

**Try Hunter first (best email coverage):**
```bash
orth run hunter /v2/email-finder \
  --query "domain=<company_domain>&first_name=<first_name>&last_name=<last_name>"
```

**If Hunter returns no email, try Sixtyfour:**
```bash
orth run sixtyfour /enrich \
  --body '{"name": "<full_name>", "company": "<company_name>"}'
```

**Get LinkedIn profiles:**
```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "<full_name> <title> <company_name>", "pageSize": 1}'
```

**Step 4: Deduplicate**

Check existing contacts cache to avoid re-processing known leads:
```bash
CACHED=$(state_read "contacts/cache.md")
# For each lead, check if their email is already in the cache
# If email found in cache, skip that lead
echo "$CACHED" | grep "<lead_email>" && echo "Already cached, skipping" || echo "New lead, proceed"
```

Only pass leads through to Step 5 if their email does NOT appear in `$CACHED`.

**Step 5: Present enriched results**

Display as markdown table:
| # | Name | Title | Company | Email | LinkedIn | Location |
|---|------|-------|---------|-------|----------|----------|

Ask user: "Want me to save these to the contact cache and export as CSV?"

**Step 6: Save (only after user confirms)**
```bash
state_append "contacts/leads.md" "<timestamp> | <email> | <name> | <company> | <title> | <linkedin_url>"
```

### Phase 3: Review & Adjust

Present summary:
- Total found: X
- Email coverage: X% with verified emails
- LinkedIn coverage: X% with profile URLs
- New leads (not in cache): X

Common adjustments:
- Too broad: add seniority filter, narrow industry
- Too narrow: broaden title list, remove location filter
- Low email coverage: try Hunter domain search for more emails at each company

## Output

Markdown table of enriched leads. Optionally saved to `state_append("contacts/leads.md", ...)` and exported as CSV.
