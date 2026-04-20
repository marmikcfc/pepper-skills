---
name: hiring-signals
description: Find job openings and hiring signals for a specific company via PredictLeads. Use when someone asks about a company's open roles, hiring activity, whether a company is growing, or wants to see job openings at a company. Takes a domain.
---

# Hiring Signals

Pull job openings for a specific company from PredictLeads to understand their hiring activity and growth areas.

## Inputs

- `$DOMAIN` — company domain (e.g. `stripe.com`, `databricks.com`)

## Steps

### 1. Get company job openings

```bash
orth run predictleads /v3/companies/$DOMAIN/job_openings -q limit=25 -q active_only=true
```

### 2. Format output

Analyze and present the hiring data:
- **Total open roles** count
- **Breakdown by category** (engineering, sales, marketing, etc.) with counts
- **Seniority distribution** (junior, mid, senior, etc.)
- **Top roles** — list the most recent or notable openings with title, location, and seniority
- **Hiring signal summary** — one sentence interpreting what the hiring pattern suggests (e.g. "Heavy engineering hiring suggests product buildout phase")
