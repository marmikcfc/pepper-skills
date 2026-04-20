---
name: aviato-people-search
description: Search and enrich people profiles using Aviato. Use when asked to find people by name, look up someone's professional background, or search for professionals matching criteria.
---

# Aviato People Search

Find and enrich people using Aviato's person APIs.

## Simple Search by Name

```bash
orth run aviato /person/simple/search -q 'fullName=Sam Altman' -q 'page=1' -q 'perPage=5'
```

Add `enrich=true` to auto-enrich results (1 credit per result):

```bash
orth run aviato /person/simple/search -q 'fullName=Jensen Huang' -q 'enrich=true' -q 'page=1' -q 'perPage=3'
```

## Person Enrichment

Enrich by LinkedIn URL, email, or other identifier:

```bash
orth run aviato /person/enrich -q 'linkedinURL=https://www.linkedin.com/in/satyanadella'
```

```bash
orth run aviato /person/enrich -q 'email=someone@company.com'
```

Use `full=true` for all relational data:

```bash
orth run aviato /person/enrich -q 'linkedinURL=https://www.linkedin.com/in/reidhoffman' -q 'full=true'
```

## Get Email

```bash
orth run aviato /person/email -q 'linkedinURL=https://www.linkedin.com/in/reidhoffman'
```

## Person Investments & Founded Companies

```bash
orth run aviato /person/investments/companies -q 'linkedinURL=https://www.linkedin.com/in/naval'
orth run aviato /person/founded-companies -q 'linkedinURL=https://www.linkedin.com/in/naval'
```

## Identifiers

Person endpoints accept:
- `linkedinURL` — LinkedIn profile URL
- `linkedinID` — LinkedIn username
- `email` — email address
- `id` — Aviato person ID
- `twitterID`, `crunchbaseID`, `angelListID`
