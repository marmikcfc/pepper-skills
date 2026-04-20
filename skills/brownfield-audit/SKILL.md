---
name: brownfield-audit
description: Use when onboarding an existing SaaS product onto Pepper — audit current GTM motion before running strategy-canvas. Use when the product already has customers, revenue, or marketing history and needs a baseline before strategy work.
---

# Brownfield Audit

Baseline your existing GTM motion before building strategy. Prevents strategy-canvas from starting from scratch when you already have customers, revenue, and market history.

## When to Use
- New Pepper workspace for an existing SaaS product
- "Before we plan strategy, let's understand where we are"
- Pre-step for `strategy-canvas`

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_CLOUD_URL` + `PEPPER_API_KEY` (for state writes)
- Company name + website URL

## Workflow

### 1. Load pepper-state helpers
```bash
source <(curl -sf "$PEPPER_CLOUD_URL/api/skills/pepper-state/SKILL.md" | grep -A 30 "^state_read()")
# Or define manually:
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_API_KEY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_API_KEY" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
```

### 2. Gather current state

Ask the user (or read from company.md):
- Company name + website
- Current ARR or MRR range (rough)
- Top 3 channels driving leads today
- Current ICP (best guess)
- 2–3 biggest customers and why they bought

### 3. SEO and content audit
```bash
orth run seo-analyzer --query '{"url": "COMPANY_WEBSITE"}' | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d, indent=2))" > /tmp/seo_audit.json
```

### 4. Competitive positioning baseline
```bash
orth run competitor-research --query '{"company": "COMPANY_NAME"}' > /tmp/comp_baseline.json
```

### 5. Tech stack + signals
```bash
orth run company-intel --query '{"company": "COMPANY_NAME"}' > /tmp/company_intel.json
```

### 6. Synthesize findings

Produce a structured audit with these sections:

```
# Brownfield Audit — [Company Name]
Date: [today]

## What's Working
- [channel/tactic, evidence]

## What's Broken or Missing
- [gap, evidence]

## Current ICP (observed)
- [who is actually buying, not who we think is buying]

## SEO Baseline
- Domain authority, top keywords, content gaps

## Competitive Position
- Where we win, where we lose, why

## Top 3 Priorities Before Strategy
1. [priority]
2. [priority]
3. [priority]
```

### 7. Write to state
```bash
state_write "company/brownfield-audit.md" "$AUDIT_CONTENT"
state_write "company/company.md" "$COMPANY_BASELINE"
```

## Output
- `company/brownfield-audit.md` — full audit
- `company/company.md` — company context for all downstream skills

## Next Step
Run `strategy-canvas` — it reads `company/brownfield-audit.md` automatically.
