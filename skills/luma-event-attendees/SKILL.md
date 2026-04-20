---
name: luma-event-attendees
description: Find and enrich attendees of a Luma event for networking or prospecting. Use when asked to get attendees from a Luma event or find people attending a specific event.
---

# Luma Event Attendees

Scrape attendees from a Luma event page and enrich ICP-matching attendees with contact info and LinkedIn profiles.

## When to Use
- "Get attendees from this Luma event: [URL]"
- "Find people attending [event name]"
- "Who's going to [conference]? Find them on Luma"
- "Get contacts from this event: [luma_url]"

## Prerequisites
- `ORTHOGONAL_API_KEY`

## Workflow

**Step 1: Scrape Luma attendee list**
```bash
orth run scrape "<luma_event_url>" \
  --body '{"format": "text"}'
```
Extract names, companies, and titles from the public attendee list. Note: Luma shows attendees publicly only when the event organizer enables it.

**Step 2: Filter by ICP match**
For each attendee, check if their role/company matches your ICP criteria (title keywords, company type, industry). Keep only ICP-matching attendees.

**Step 3: Enrich ICP-matching attendees**
```bash
orth run comprehensive-enrichment /enrich \
  --body '{"name": "<name>", "company": "<company>"}'
```

**Step 4: Get LinkedIn profiles**
For attendees where LinkedIn URL wasn't returned by enrichment:
```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "<name> <title> <company>", "pageSize": 1}'
```

**Step 5: Present results**
Table: Name | Company | Title | Email | LinkedIn | ICP Fit Score

## Output
Enriched attendee list filtered by ICP fit, with contact info and LinkedIn profiles.
