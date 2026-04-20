---
name: linkedin-waterfall
description: Find LinkedIn profiles from name, email, or GitHub using a 3-step waterfall (Fiber → Sixtyfour → PDL). Use when asked to find someone's LinkedIn, enrich a person, or resolve identity from email/GitHub.
---

# LinkedIn Waterfall Enrichment

Find LinkedIn profiles using a 3-step provider waterfall optimized for cost and hit rate.

**Latency**: ~2-5s (Fiber) → ~30-60s (Sixtyfour) → ~2-5s (PDL)

## Input

At least one of:
- **email** — email address (personal or business)
- **name** — full name or display name
- **github** — GitHub profile URL (e.g., `https://github.com/username`)

Optional:
- **company** — current employer (improves Fiber match rate)
- **batch** — if `true`, process multiple rows from a JSON file or inline list

## Waterfall Strategy

### Step 1: Fiber Kitchen-Sink — runs on all rows with email

The primary lookup. Fiber's kitchen-sink endpoint accepts name + email + fuzzy search and returns LinkedIn profiles with full work history and education.

**For rows WITH email + name:**

```bash
orth run fiber /v1/kitchen-sink/person --body '{
  "emailAddress": "{email}",
  "personName": {"fullName": "{name}"},
  "fuzzySearch": true
}'
```

**For rows WITH email only (no usable name):**

```bash
orth run fiber /v1/email-to-person/single --body '{
  "email": "{email}"
}'
```

**For rows WITHOUT email:** Skip to Step 2.

**Extract LinkedIn:** `output.data[0].primary_slug` → prepend `linkedin.com/in/`

---

### Step 2: Sixtyfour Enrich-Lead — runs on Step 1 misses + no-email rows

AI research agent that browses the web, cross-references sources, and reasons about identity. Slower but finds people that database lookups miss.

```bash
orth run sixtyfour /enrich-lead --body '{
  "lead_info": {
    "name": "{name}",
    "email": "{email}",
    "github": "{github}"
  },
  "struct": {
    "linkedin_url": "LinkedIn profile URL",
    "full_name": "Full real name",
    "location": "City/Country",
    "current_company": "Current employer"
  },
  "research_plan": "Find the LinkedIn profile for this person. Use their GitHub profile ({github}) and email ({email}) to cross-reference and find their LinkedIn. Check GitHub bio, repos, and commit history for real name clues. Search LinkedIn by name + company if found."
}'
```

**Extract LinkedIn:** `structured_data.linkedin_url`

**Validation:** Reject results where `linkedin_url` is empty, "N/A", "NA", "Not found", or "not found".

---

### Step 3: PDL Person/Identify — last resort on Step 2 misses

Probabilistic matching across People Data Labs' database. Expensive but accepts GitHub profile URLs as input, good for no-email cases.

```bash
orth run peopledatalabs /v5/person/identify \
  -q email={email} \
  -q name={name} \
  -q profile={github}
```

Only include params that have values. At minimum pass `profile` (GitHub URL).

**Extract LinkedIn:** `matches[0].data.linkedin_url`

---

## Batch Mode

When processing multiple rows:

1. **Step 1 (Fiber):** Run all rows with email in parallel batches of 10. Write results to `/tmp/fiber_row_{N}.json`.
2. **Collect misses:** Identify rows where Fiber returned no `primary_slug` or errored (404).
3. **Step 2 (Sixtyfour):** Run all misses in parallel batches of 4. Write results to `/tmp/s64_row_{N}.json`.
4. **Collect remaining misses.**
5. **Step 3 (PDL):** Run remaining in parallel batches of 8. Write results to `/tmp/pdl_row_{N}.json`.
6. **Compile results** into a summary table.

### Batch Shell Script Template

For each step, use this pattern:

```bash
#!/bin/bash
# Process rows START to END through provider
for i in $(seq $START $END); do
  # Extract row data from input JSON
  # Call API
  # Parse result, extract LinkedIn
  # Write to /tmp/{provider}_row_{N}.json
  # Log: "Row N: FOUND linkedin.com/in/slug" or "Row N: miss"
done
```

Run batches in parallel using background tasks for throughput.

## Output Format

### Single Lookup

```json
{
  "linkedin_url": "https://linkedin.com/in/slug",
  "full_name": "Real Name",
  "found_by": "fiber | sixtyfour | pdl",
  "location": "City, Country",
  "current_company": "Company Name",
  "steps_run": ["fiber"],
  "confidence": "high | medium | low"
}
```

Confidence rules:
- **high**: Fiber found with matching name, or Sixtyfour confidence >= 8
- **medium**: Fiber found but name mismatch, Sixtyfour confidence 5-7, or PDL top match
- **low**: Sixtyfour confidence < 5

### Batch Results

Present as a markdown table:

```
| Row | Name | Email | LinkedIn Found | Found By |
|-----|------|-------|----------------|----------|
```

Followed by a summary:

```
| Step | Provider | Found | Cumulative |
|------|----------|-------|------------|
| 1 | Fiber | X/N | X/N (%) |
| 2 | Sixtyfour | X/N | X/N (%) |
| 3 | PDL | X/N | X/N (%) |
```

If Google Sheets output is requested, use the `google-sheets` skill to create a spreadsheet with the results.

## Tips

- Fiber's `fuzzySearch: true` is critical — it catches name variations and transliterations
- Sixtyfour's `research_plan` field dramatically improves results — always include context about the person
- When processing large batches, run Fiber batches of 10 in parallel for ~5x throughput
- PDL accepts GitHub URLs via the `profile` param — this is its main advantage over Fiber for no-email rows
