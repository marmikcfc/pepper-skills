---
name: person-enrichment
description: Clay-style person enrichment waterfall using Hunter, Fiber, and Brand.dev. Give an email or name+company to get a full profile.
---

# Person Enrichment Waterfall

Enrich a person from minimal inputs (email OR name+company) using Hunter, Fiber, and Brand.dev. Mimics a Clay enrichment workflow — runs steps in parallel where possible for speed, then merges results.

## Input

Ask the user for **1-2 datapoints**:
- **Email address** (best — unlocks all 3 steps)
- **Full name + Company name/domain** (if no email available)

## Execution Strategy

### If you have an EMAIL:

**Run ALL 3 steps in parallel** — email is sufficient input for every API, so there's no dependency chain. Use parallel Bash tool calls:

```bash
# Step 1 — Hunter (run in parallel)
orth run hunter /v2/combined/find -q email=john.smith@example.com

# Step 2 — Fiber (run in parallel)
orth run fiber /v1/kitchen-sink/person --body '{"emailAddress": "john.smith@example.com", "numProfiles": 1}'

# Step 3 — Brand.dev (run in parallel — extract domain from email)
orth run brand-dev /v1/brand/retrieve -q domain=example.com
```

Fire all 3 as separate Bash tool calls in a single response. They have no dependencies on each other when you already have the email.

### If you have NAME + COMPANY (no email):

**Run Step 1 first, then Steps 2 and 3 in parallel:**

**Step 1 (first):** Find the email via Hunter:
```bash
orth run hunter /v2/email-finder -q domain=example.com -q first_name=John -q last_name=Smith
```

**Steps 2 + 3 (parallel after Step 1):** Once you have the email from Hunter, fire Fiber and Brand.dev at the same time:
```bash
# Step 2 — Fiber (run in parallel, use email from Step 1 + name + company for best match)
orth run fiber /v1/kitchen-sink/person --body '{"emailAddress": "john.smith@example.com", "personName": {"fullName": "John Smith"}, "companyName": {"name": "Example Inc"}, "numProfiles": 1}'

# Step 3 — Brand.dev (run in parallel)
orth run brand-dev /v1/brand/retrieve -q domain=example.com
```

If Hunter didn't find an email, still run Fiber with name + company:
```bash
orth run fiber /v1/kitchen-sink/person --body '{"personName": {"fullName": "John Smith"}, "companyName": {"name": "Example Inc"}, "numProfiles": 1}'
```

## API Details

### Hunter — Person + Company from Email
```bash
# Combined person + company lookup (best when you have email)
orth run hunter /v2/combined/find -q email=john.smith@example.com

# Email finder (when you only have name + domain)
orth run hunter /v2/email-finder -q domain=example.com -q first_name=John -q last_name=Smith
```
Returns: full name, job title, company, social profiles (Twitter, LinkedIn), location, company domain, industry, employee count.

### Fiber — Deep LinkedIn Profile + Work History
```bash
# Best: pass everything you have
orth run fiber /v1/kitchen-sink/person --body '{
  "emailAddress": "john.smith@example.com",
  "personName": {"fullName": "John Smith"},
  "companyName": {"name": "Example Inc"},
  "numProfiles": 1
}'

# With LinkedIn URL (highest accuracy)
orth run fiber /v1/kitchen-sink/person --body '{
  "profileIdentifier": "johnsmith",
  "numProfiles": 1
}'
```
Returns: full LinkedIn profile, work history, education, certifications, skills, headline, location, profile photo.

### Brand.dev — Company Enrichment
```bash
orth run brand-dev /v1/brand/retrieve -q domain=example.com
```
Returns: company description, industry, logos, colors, social links, HQ address, stock ticker.

## Output Format

After all parallel calls complete, merge the results and present a clean enriched profile:

```
## Person Profile

**Name:** John Smith
**Title:** CEO
**Company:** Example Inc
**Email:** john.smith@example.com
**Location:** San Francisco, CA

**LinkedIn:** linkedin.com/in/johnsmith
**Twitter:** @johnsmith

### Work History
- CEO at Example Inc (2022-present)
- VP Engineering at Previous Co (2019-2022)

### Education
- BS Computer Science, Stanford University

### Company Info
**Domain:** example.com
**Industry:** Software / SaaS
**Employees:** 50-200
**Description:** Example Inc builds developer tools...
**Logo:** [url if available]
```

Only include fields that were actually returned. Don't fabricate data. If a field came back empty from all sources, omit it.

## Cost Estimate

Typical enrichment from email costs ~$0.02-0.05 total across all 3 steps:
- Hunter combined: ~$0.01
- Fiber kitchen-sink: ~$0.01-0.02
- Brand.dev retrieve: ~$0.01

## Tips

- **Parallel is the default** — when you have an email, always run all 3 in parallel. No reason to wait.
- **Email is king** — if the user has an email, start there. Hit rates are highest and all steps can run simultaneously.
- **Skip steps that won't help** — if the user only wants person data, skip Brand.dev. If they only want company data, skip Fiber.
- **Deduplicate** — merge data across sources, preferring the most detailed version of each field.
- **Show sources** — tell the user which API provided each piece of data so they know reliability.
