---
name: inbound-lead-qualification
description: Qualify an inbound lead against ICP — enrich, score fit, and recommend next action (fast-track, nurture, or disqualify). Use when asked to qualify a new lead or determine if a signup is a good fit.
---

# Inbound Lead Qualification

Enrich an inbound lead, score ICP fit across multiple dimensions, and recommend the next action. Produces a scored qualification verdict with reasoning.

## When to Use
- "Qualify this lead: [email/name]"
- "Is [company] a good fit for us?"
- "Should we fast-track this signup?"
- "Score this inbound lead"
- "Qualify these [N] inbound leads: [list]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL` (for ICP context)
- `ANTHROPIC_API_KEY` (for LLM scoring)

## Workflow

### Setup — pepper-state helpers

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
state_append() { curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
```

**Step 1: Load ICP and check for saved qualification prompt**
```bash
ICP=$(state_read "strategy/icp.md")
```

If ICP is empty, ask the user for their qualification criteria:
- Target company sizes (employee ranges)
- Target industries (and exclusions)
- Target geographies
- Target titles and seniority levels
- Hard disqualifiers (instant no)
- Hard qualifiers (instant yes)

Save the criteria: `state_write "strategy/icp.md" "<criteria>"`

**Step 2: Parse and assess leads**

Accept any input format: single email, list of emails, name+company pairs, or a batch.

For each lead, inventory what's known vs. unknown. If more than 50% of leads are missing company name or title, recommend running `inbound-lead-enrichment` first and ask the user.

**Step 3: Enrich each lead**
```bash
orth run comprehensive-enrichment /enrich \
  --body '{"email": "<email>", "company": "<company>"}'
```

```bash
orth run company-intel /intelligence \
  --body '{"company": "<company_domain_or_name>"}'
```

**Step 4: LLM ICP scoring**

For each lead, pass enriched profile + ICP to Claude:
> "Score this lead against our ICP on a 0-100 scale across these dimensions:
> - Company size fit (15%): does headcount match target range?
> - Industry fit (20%): does industry match targets?
> - Company stage fit (10%): is funding stage in targets?
> - Geography fit (10%): is HQ in target region?
> - Use case fit (25%): can they plausibly use the product?
> - Title/role match (15%): does their title match buyer personas?
> - Seniority match (5%): are they at the right level?
>
> ICP: {ICP}. Lead: {enriched_profile}.
>
> Return JSON: {composite_score, verdict (qualified|borderline|near_miss|disqualified), sub_verdict (qualified_hot|qualified_warm|borderline_review|near_miss_nurture|disqualified_polite), dimension_scores: {}, fit_reasons: [], red_flags: [], summary: '1 sentence', recommended_action: (fast-track|nurture|disqualify), personalization_hook: '1 observation for outreach'}"

**Step 5: Apply hard overrides**

- Any hard disqualifier present → `disqualified` regardless of score
- Any hard qualifier present → `qualified` regardless of score (still show full breakdown)
- Borderline (50-74) inbound leads: lean toward qualifying — they came to you, which tips borderline cases

**Step 6: Run calibration check for batches**

If processing more than 5 leads, show the first 5 results and ask:
"Do these qualifications look right? Should I adjust any criteria before processing the full batch?"

Wait for user approval before continuing. Update ICP if user provides corrections.

**Step 7: Present qualification results**

For each lead:
```
Score: X/100 — [Qualified Hot / Qualified Warm / Borderline / Near Miss / Disqualified]
Fit: [why they match]
Red flags: [disqualifying signals, if any]
Recommended action: Fast-track / Nurture / Disqualify
Personalization hook: [one observation for outreach]
```

For batches, present a summary:
```
Total: X leads
Qualified: X (Y%) — X hot, X warm
Borderline (manual review): X (Y%)
Near miss: X (Y%)
Disqualified: X (Y%)
```

**Step 8: Export (ask user before writing)**

Offer to save qualified leads:
```bash
state_append "contacts/qualified-leads.md" "<timestamp> | <email> | <name> | <company> | <score> | <verdict> | <recommended_action>"
```

## Handling Edge Cases

**Email only, no company:**
- Extract domain, skip personal email providers
- If corporate domain: qualify the company, note that person data is limited

**Same company, multiple leads:**
- Qualify the company once, apply to all leads
- Note: "X people from [Company] came inbound — potential committee buy"

**Missing data on 3+ dimensions:**
- Score as `insufficient_data` regardless of composite score
- Recommend enrichment first

## Output

Qualification scorecard with composite score (0-100), verdict, fit reasoning, and recommended next action (fast-track / nurture / disqualify).
