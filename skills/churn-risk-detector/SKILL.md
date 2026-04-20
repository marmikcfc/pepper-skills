---
name: churn-risk-detector
description: Identify customers at risk of churning based on usage patterns and engagement signals. Use when asked to find at-risk customers, predict churn, or prioritize customer success outreach.
---

# Churn Risk Detector

Identify customers showing churn signals before they cancel — score risk and generate a prioritized intervention list.

## When to Use
- "Find customers at risk of churning"
- "Identify at-risk accounts for CS outreach"
- "Predict churn for our customer base"
- "Who should we prioritize for proactive outreach?"

## Prerequisites
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`

## Churn Signals

| Signal | Risk Weight |
|--------|-------------|
| No login in 14+ days | High |
| Support ticket about core features | High |
| Billing contact or downgrade request | Critical |
| Champion changed jobs | High |
| Negative review posted | Medium |
| Feature usage dropped >50% | High |
| NPS score < 6 | Medium |

## Workflow

**Step 1: Load customer data**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }

CUSTOMERS=$(state_read "revops/customers.md")
CHAMPION_MOVES=$(state_read "signals/champion-moves.md")
```
If customer data isn't in state, ask the user to paste or describe the customer list.

**Step 2: Score each customer**
For each customer, score churn risk (0-10) using the signals table above. Use available data from state; ask user to fill in gaps for high-value accounts.

**Step 3: LLM risk assessment**
Pass customer data + signals to Claude:
> "Score each customer's churn risk 0-10 based on these signals. For each customer with score ≥ 7, suggest a specific intervention: (retention call, feature walkthrough offer, executive outreach, or special offer). Format as a prioritized intervention list."

**Step 4: Present high-risk customers**
Show: customers with risk score ≥ 7, their top risk signals, and suggested intervention.

**Step 5: Save risk list**
> "Should I save the churn risk report to state? (yes/no)"

Only proceed if user confirms:
```bash
state_write "revops/churn-risk.md" "<high_risk_list>"
```

## Output
Prioritized churn risk report with intervention recommendations per at-risk account.
