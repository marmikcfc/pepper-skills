---
name: company-contact-finder
description: Find key contacts at a specific company — executives, decision-makers, or role-specific people. Returns names, titles, emails, and LinkedIn URLs. Use when asked "who should I talk to at [company]?" or "find contacts at [company name]".
---

# Company Contact Finder

Find the right people at a specific company — decision-makers, executives, or role-specific contacts. Uses a layered search strategy to maximize results and returns enriched profiles with emails.

## When to Use
- "Who should I reach out to at [company]?"
- "Find the VP of Engineering at [company]"
- "Get me contacts at [company] for [use case]"
- "Who are the decision-makers at [company]?"
- "Find Partners and Controllers at [firm]"

## Prerequisites
- `ORTHOGONAL_API_KEY`

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| company_name | Yes | — | The company to search (e.g., "Acme Corp") |
| target_titles | Yes | — | List of titles to find (e.g., ["VP Finance", "CFO", "Controller"]) |
| num_results | No | 10 | How many contacts to return |

If the user does not provide target titles, ask. Suggest common senior titles based on context:
- Accounting/CPA firms: Partner, Managing Director, Controller, CFO, VP Finance
- Tech companies: VP Engineering, CTO, Head of Product, Director of Engineering
- General B2B: VP, Director, C-Level, Head of [Department]

## Workflow

**Step 1: Get company overview**
```bash
orth run company-intel /intelligence \
  --body '{"company": "<company_name_or_domain>"}'
```

Use the response to get the verified company domain for email lookup in later steps.

**Step 2: Natural language profile search (primary)**

Build query: join target titles with " OR " and append company name:
```
"<title1> OR <title2> OR <title3> at <company_name>"
```

```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "<title1> OR <title2> OR <title3> at <company_name>", "pageSize": 15}'
```

**Step 3: Evaluate results**

Check how many results match the target titles at the target company (fuzzy company name match is fine — "Acme Corp" matches "Acme Corporation").

- If 3+ quality matches: skip to Step 5
- If fewer than 3: proceed to Step 4

**Step 4: Structured people search (fallback)**

Run one search per target title using people-search:
```bash
orth run people-search /search \
  --body '{"company": "<company_name>", "title": "<target_title>"}'
```

Repeat for each target title. Merge and deduplicate results by LinkedIn URL.

**Step 5: Enrich with emails**

Look up emails for the company domain:
```bash
orth run hunter /v2/domain-search \
  --query "domain=<company_domain>&limit=10"
```

For specific contacts where you have first/last name:
```bash
orth run hunter /v2/email-finder \
  --query "domain=<company_domain>&first_name=<first>&last_name=<last>"
```

**Step 6: Present final contact list**

Table format:
| # | Name | Title | Company | Email | LinkedIn | Location |
|---|------|-------|---------|-------|----------|----------|

If fewer than 3 contacts were found after all steps, tell the user:
> "Only found X contacts. The company may be small, the titles may be uncommon, or database coverage may be limited for this company. Consider broadening the target titles or trying alternate company name spellings."

## Output

Markdown table of company contacts with emails and LinkedIn URLs. Summary line: "Found X contacts matching [titles] at [company]."
