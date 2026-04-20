---
name: metric-watcher
description: Check current metrics against committed targets and flag drift. Writes daily snapshot to metrics/daily/ and updates metrics/alerts.md if any metric is off-track.
---
# Metric Watcher

Check current metric values against committed targets, flag any drift beyond acceptable thresholds, and write a daily snapshot. Keeps the strategy review grounded in data and ensures metric drift is caught early — not at the end of the quarter.

## When to Use

- Daily morning check-in on GTM health
- Before a weekly strategy review to populate the latest data
- When you suspect a metric has moved and want to confirm
- After launching an experiment to monitor early signals

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance
- `metrics/commitments.md` should exist (or create it in this session)

## Commitments Format

`metrics/commitments.md` — one row per metric:

```
metric_name | target | baseline | threshold_pct | cadence | source
demo_requests_per_week | 5 | 1 | 20 | daily | manual
cold_email_reply_rate | 8% | 2% | 25 | weekly | Apollo
mrr | $10000 | $2000 | 10 | weekly | Stripe
pipeline_value | $100000 | $20000 | 15 | weekly | manual
```

- `threshold_pct` — drift % from target trajectory that triggers an alert
- `source` — where to get the current value (manual / URL / tool)

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_list() { curl -sf "$PEPPER_CLOUD_URL/api/state/list?prefix=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; [print(e['path']) for e in json.load(sys.stdin)]"; }
```

**Step 1: Load commitments**

```bash
COMMITMENTS=$(state_read "metrics/commitments.md")
```

If `COMMITMENTS` is empty:

Ask the user: "No metric commitments found. Let's set them up. List your 3-5 most important GTM metrics with targets. For each: metric name, current baseline, target value, and where you track it."

Compose the commitments file and ask: "Save these as your metric commitments? (yes/no)"

If yes:
```bash
state_write "metrics/commitments.md" "$COMMITMENTS_CONTENT"
```

**Step 2: Collect current metric values**

For each metric in commitments, ask the user to provide the current value:

"What is the current value of [metric_name]? (target: [target], source: [source])"

If `source` is a URL, offer to fetch it:
```bash
curl -sf "$ANALYTICS_URL" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('<metric_field>', 'not found'))"
```

Collect all current values before proceeding.

**Step 3: Calculate trajectory and drift**

For each metric, compute:

```python
python3 -c "
metric = '$METRIC_NAME'
baseline = float('$BASELINE')
target = float('$TARGET')
current = float('$CURRENT_VALUE')
threshold_pct = float('$THRESHOLD_PCT')

# Days elapsed since strategy start (approximate if unknown)
# Assumes linear trajectory from baseline to target over 90 days
import datetime
today = datetime.date.today()
# For simplicity use current vs target directly
progress_needed = target  # simplified: compare current to target
progress_actual = current
pct_of_target = (current / target * 100) if target > 0 else 0

# Drift: how far off target trajectory are we?
# Simple version: is current below (target * (1 - threshold_pct/100))?
alert_threshold = target * (1 - threshold_pct / 100)
status = 'green' if current >= alert_threshold else ('yellow' if current >= baseline else 'red')

print(f'{metric}: {current} / {target} ({pct_of_target:.0f}% of target) — {status}')
"
```

**Step 4: Build daily snapshot**

```bash
TODAY=$(date -u +%Y-%m-%d)
SNAPSHOT="# Metrics Snapshot — $TODAY

| Metric | Baseline | Current | Target | % of Target | Status |
|--------|----------|---------|--------|-------------|--------|
$(echo "$METRICS_TABLE_ROWS")

## Alert Summary
$(echo "$ALERTS_SUMMARY")

## Notes
$(echo "$USER_NOTES_IF_ANY")
"
```

**Step 5: Write daily snapshot**

```bash
state_write "metrics/daily/$TODAY.md" "$SNAPSHOT"
```

**Step 6: Update alerts if any drift detected**

If any metric is `yellow` or `red`:

```bash
ALERTS="# Metric Alerts — updated $TODAY

$(echo "$ALERT_ROWS")
"
state_write "metrics/alerts.md" "$ALERTS"
```

Show the user which metrics triggered alerts and suggested actions:
- `yellow`: "Off target trajectory — investigate this week"
- `red`: "Below baseline — escalate to strategy review immediately"

**Step 7: Confirm**

Show the full snapshot table and confirm:
"Snapshot saved to `metrics/daily/$TODAY.md`."
If alerts: "Alerts updated in `metrics/alerts.md`. [N] metric(s) need attention."

## Output

`metrics/daily/YYYY-MM-DD.md` — daily snapshot table with status per metric.
`metrics/alerts.md` — updated if any metric is off-track.
