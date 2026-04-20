---
name: funding-radar
description: Discover recent startup funding and financing events via PredictLeads. Use when someone asks about recent funding rounds, who just raised money, investment activity, or financing events. Optionally filter by location or funding type.
---

# Funding Radar

Surface recent financing events (funding rounds, acquisitions, IPOs) from PredictLeads.

## Inputs (all optional)

- `$LOCATION` — filter by company location (e.g. `United States`, `San Francisco`)
- `$TYPE` — financing type filter. Options: `seed`, `series_a`, `series_b`, `series_c`, `series_d`, `series_e`, `ipo`, `acquired`, `grant`, `debt`, `angel`, `pre_seed`

## Steps

### 1. Fetch recent financing events

```bash
orth run predictleads /v3/discover/financing_events -q limit=15
```

If location provided:
```bash
orth run predictleads /v3/discover/financing_events -q limit=15 -q company_location=$LOCATION
```

If type provided:
```bash
orth run predictleads /v3/discover/financing_events -q limit=15 -q financing_types_normalized=$TYPE
```

Both can be combined.

### 2. Format output

Present as a list of recent deals:
- **Company name and domain** (from `included` array)
- **Financing type** and **amount** (if available)
- **Date** of the event
- Sort by most recent first
- Summarize the overall landscape at the end (e.g. "Mostly seed rounds, heavy in US/Europe")
