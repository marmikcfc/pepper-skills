---
name: find-leads
description: Find leads by job title, seniority, location, industry, or company. Returns a table of people with name, company, title, location, and LinkedIn URL. Use when asked to find executives, leads, prospects, decision-makers, or people matching a role.
---

# Find Leads

Search for people by role, seniority, location, industry, or company using Fiber's natural language people search. Returns a clean table of leads.

## Input

The user provides a natural language query describing who they're looking for. Examples:
- "Find CXOs in the US"
- "CTOs at SaaS startups in San Francisco"
- "VP of Marketing at e-commerce companies in New York"
- "Founders of AI companies in Austin TX"
- "Software engineers at Google"

## Workflow

Run this single command that fetches AND formats results in one step:

```bash
orth run fiber /v1/natural-language-search/profiles --body '{"query": "REPLACE_WITH_QUERY", "pageSize": 15}' | python3 -c "
import json, sys
text = sys.stdin.read()
start = text.index('{')
data = json.loads(text[start:])
profiles = data['output']['data']
for p in profiles:
    name = p.get('name', 'N/A')
    slug = p.get('primary_slug', '').strip()
    linkedin = f'https://linkedin.com/in/{slug}' if slug else ''
    locality = p.get('locality') or ''
    if not locality:
        loc = p.get('inferred_location') or {}
        locality = loc.get('formatted_address') or loc.get('full_address') or ''
    cj = p.get('current_job') or {}
    company = cj.get('company_name') or ''
    title = cj.get('title') or ''
    if not company or not title:
        headline = p.get('headline', '')
        if not title: title = headline
        if not company and ' at ' in headline:
            company = headline.split(' at ', 1)[1]
    print(f'{name}\t{company}\t{title}\t{locality}\t{linkedin}')
"
```

Replace REPLACE_WITH_QUERY with the user's actual query. The output is tab-separated rows where the last column is the full LinkedIn URL (or empty if unavailable).

### Adjustments
- Default pageSize is 15. Increase to 25 for more results.
- If the user asks for a specific number (e.g. "find 5 CTOs"), set pageSize accordingly.

## Output Format

CRITICAL: After running the command, render results as a markdown table immediately. Do NOT run additional Bash commands.

Use the tab-separated output directly. The 5th column is the full LinkedIn URL. If it is empty, omit the LinkedIn cell entirely (leave the cell blank — do NOT write `[Profile]()` or `[Profile](null)`).

| Name | Company | Title | Location | LinkedIn |
|------|---------|-------|----------|----------|
| Alice Chen | Stripe | CTO | San Francisco, CA | [Profile](https://linkedin.com/in/alicechen) |
| Bob Kim | Acme | VP Sales | New York, NY | |

After the table, include:
```
Found {N} leads matching "{query}". Data from Fiber via Orthogonal.
```

If more results are available: "More results available — ask me to load the next page."

## API Details

Fiber natural language people search returns output.data[] with:
- name, first_name, last_name
- headline (e.g. "CTO at Stripe")
- locality (e.g. "San Francisco Bay Area")
- inferred_location — structured with city, state, country, coordinates
- primary_slug — LinkedIn slug (may be null/empty for some profiles)
- current_job — object with company_name, title, seniority, start_date

## Cost Estimate

~$0.02-0.05 per search (single API call)

## Tips

- One command, one step — the command includes the Python parser. Do NOT run a second Bash command.
- Natural language is powerful — Fiber handles complex queries like "senior engineers at Series B startups in healthcare".
- Table is mandatory — always present results as a markdown table, not prose.
- LinkedIn links — only include if the URL is non-empty. Never emit a link with an empty or null href.
- Pagination — use the cursor field from last_sort_key to fetch the next page.
