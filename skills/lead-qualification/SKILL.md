---
name: lead-qualification
description: Score a prospect or company against your ICP to determine if they're worth pursuing. Use when asked to qualify a prospect, score a company for fit, or decide whether to pursue an outbound target.
---

# Lead Qualification

Score a prospect against your ICP and determine their fit tier. Supports three modes: build a new qualification prompt via intake, reuse a saved prompt, or refine criteria after seeing results.

## When to Use
- "Is [company] worth pursuing?"
- "Qualify these prospects: [list]"
- "Score [name/company] against our ICP"
- "Which of these leads should we prioritize?"
- "Qualify leads from [CSV/list]"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`

## Three Modes

### Mode 1: Full Intake + Qualify
No saved qualification prompt exists. Run intake to build one, save it, then qualify.

### Mode 2: Reuse Saved Prompt
User references an existing saved prompt — skip intake, go straight to qualification.

### Mode 3: Refine / Calibrate
User has seen results and wants to adjust criteria. Update the saved prompt and re-run.

## Workflow

### Setup — pepper-state helpers

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
state_append() { curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$1" "$2")"; }
```

### Phase 1: Intake (Mode 1 only)

**Step 1: Load saved ICP and strategy context**
```bash
ICP=$(state_read "strategy/icp.md")
STRATEGY=$(state_read "strategy/strategy.md")
```

If ICP is empty, ask the user these questions in bulk (tell them to answer what's relevant and skip the rest):

**Product & Campaign Context:**
1. What's your product/service in one sentence?
2. What problem does it solve and for whom?
3. What's the specific campaign or outreach angle?

**Company-Level Criteria:**
4. What company sizes are you targeting? (employee ranges)
5. What industries are a good fit?
6. Any industries to explicitly EXCLUDE?
7. Geographic targets?
8. Does company stage matter? (seed, Series A, Series B+, public)

**Person-Level Criteria:**
9. What job titles are your ideal buyers?
10. What titles are disqualified?
11. Does seniority level matter? (must be Director+, VP+, C-level?)
12. What departments should they be in?

**Dealbreakers & Instant Qualifiers:**
13. Hard disqualifiers — instant "no" regardless of other factors?
14. Strongest qualifiers — near-certain "yes"?

After intake, synthesize criteria into a qualification prompt and save it:
```bash
state_write "strategy/icp.md" "<synthesized ICP criteria>"
```

### Phase 2: Lead Qualification

**Step 1: Parse input**

Accept any format:
- Single company or person name
- List of names/companies
- Email addresses

**Step 2: Enrich each lead**
```bash
orth run company-intel /intelligence \
  --body '{"company": "<company>"}'
```

```bash
orth run fiber /v1/natural-language-search/profiles \
  --body '{"query": "<contact_name> at <company>", "pageSize": 3}'
```

For contacts where you need email:
```bash
orth run hunter /v2/email-finder \
  --query "domain=<company_domain>&first_name=<first>&last_name=<last>"
```

**Step 3: Calibration batch**

Before processing the full list, show the first 5 leads with qualification results. Ask:
"Do these look right? Should I adjust any criteria before processing the full list?"

If user flags issues, update the ICP in state and re-run the calibration batch before proceeding.

**Step 4: LLM qualification score**

For each prospect, pass enriched data + ICP to Claude:
> "Given our ICP and strategy, score this prospect 0-100 for fit. ICP: {ICP}. Strategy: {STRATEGY}. Prospect: {enriched_data}.
>
> Return JSON: {score, tier (A/B/C/D where A=75+, B=50-74, C=30-49, D=under 30), fit_summary: '2-3 sentences', top_3_reasons: [], disqualifiers: [], suggested_approach: (pursue|nurture|skip), confidence: (high|medium|low)}"

Hard overrides:
- Any hard disqualifier present → Tier D regardless of score
- Any hard qualifier present → Tier A lean regardless of score

**Step 5: Output results**

For each prospect:
```
[Name / Company] — Score: X/100 — Tier [A/B/C/D]
Fit: [2-3 sentence summary]
Top reasons: [list]
Disqualifiers: [list, if any]
Suggested approach: Pursue / Nurture / Skip
Confidence: High / Medium / Low
```

Summary for batches:
```
Total: X prospects
Tier A (pursue): X
Tier B (nurture): X
Tier C (near miss): X
Tier D (skip): X
```

**Step 6: Save qualified leads (with user approval)**
```bash
state_append "contacts/qualified-leads.md" "<timestamp> | <name> | <company> | <score> | <tier> | <suggested_approach>"
```

### Mode 3: Refinement

When user provides feedback on qualification results:
1. Discuss what needs to change
2. Update saved ICP: `state_write "strategy/icp.md" "<updated criteria>"`
3. Re-qualify the flagged leads with updated criteria
4. Confirm changes look right before re-processing the full list

## Output

Qualification scorecard per prospect with score (0-100), tier (A/B/C/D), fit summary, and suggested approach (pursue/nurture/skip). Saved to `state_append("contacts/qualified-leads.md", ...)`.

