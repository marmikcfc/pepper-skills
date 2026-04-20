---
name: contact-cache
description: Store and retrieve enriched contact records to avoid re-enriching the same people. Use when you want to save a contact after enrichment or check if a contact has already been enriched before calling external APIs.
---

# Contact Cache

Store and retrieve enriched contact records. Prevents duplicate enrichment API calls and duplicate outreach across campaigns running on a recurring cadence. Deduplicates by email or LinkedIn URL.

## When to Use
- "Cache this contact after enrichment"
- "Check if we've already enriched [email]"
- "Add these contacts to our contact store"
- "Have we seen [person] before?"
- "Don't re-enrich people we've already processed"

## Prerequisites
- `PEPPER_API_KEY` + `PEPPER_CLOUD_URL`

## Setup — pepper-state helpers

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
state_append() { curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
```

## Operations

### Check cache (before enrichment — prevents duplicate API calls)

Check by email:
```bash
CACHED=$(state_read "contacts/cache.md")
echo "$CACHED" | grep "<email>"
```

Check by LinkedIn URL:
```bash
CACHED=$(state_read "contacts/cache.md")
echo "$CACHED" | grep "<linkedin_url>"
```

If the grep returns a result, the contact is already cached — skip enrichment and use cached data.

### Add single contact to cache (after enrichment)
```bash
state_append "contacts/cache.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ) | <email> | <name> | <company> | <title> | <linkedin_url> | <status>"
```

### Bulk add contacts from a list

For each contact in the list:
```bash
state_append "contacts/cache.md" "$(date -u +%Y-%m-%dT%H:%M:%SZ) | <email> | <name> | <company> | <title> | <linkedin_url> | new"
```

### Update a contact's status
```bash
CACHED=$(state_read "contacts/cache.md")
UPDATED=$(echo "$CACHED" | python3 -c "
import sys
lines = sys.stdin.read().strip().split('\n')
updated = []
for line in lines:
    if '<email>' in line:
        parts = line.split(' | ')
        parts[-1] = '<new_status>'
        updated.append(' | '.join(parts))
    else:
        updated.append(line)
print('\n'.join(updated))
")
state_write "contacts/cache.md" "$UPDATED"
```

### List all cached contacts
```bash
state_read "contacts/cache.md"
```

### Get stats
```bash
CACHED=$(state_read "contacts/cache.md")
echo "Total contacts: $(echo "$CACHED" | grep -c '|')"
echo "Contacted: $(echo "$CACHED" | grep -c 'contacted')"
echo "Qualified: $(echo "$CACHED" | grep -c 'qualified')"
```

### Export contacts with a specific status
```bash
state_read "contacts/cache.md" | grep "contacted"
```

## Cache Format

Each entry is a pipe-delimited line:
```
<ISO timestamp> | <email> | <name> | <company> | <title> | <linkedin_url> | <status>
```

Example:
```
2026-04-20T14:30:00Z | jane@acme.com | Jane Smith | Acme Corp | VP Finance | https://linkedin.com/in/janesmith | new
2026-04-20T14:31:00Z | john@techco.io | John Doe | TechCo | CTO | https://linkedin.com/in/johndoe | contacted
```

## Valid Statuses

`new` | `qualified` | `contacted` | `replied` | `meeting_booked` | `converted` | `not_interested`

## Output

Cache hit/miss report for check operations, or confirmation of new entry stored. Stats summary when requested.
