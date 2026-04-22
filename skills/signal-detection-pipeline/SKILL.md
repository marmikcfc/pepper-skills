---
name: signal-detection-pipeline
description: Full outbound spine — detect buying signals across TAM, enrich and qualify matched leads, draft personalized cold emails, get batch approval, send, and log everything to state. Designed to run hourly for signal detection with daily email batches.
---

# Signal Detection Pipeline

The spine of the outbound motion. Runs the full cycle: detect buying signals across your TAM, enrich each matched lead, score against ICP, draft personalized cold emails using the Haines framework, get batch approval before sending, then log every outcome to state.

Designed to run hourly for signal detection. Email sends are batched and held for daily review.

## When to Use
- "Run the signal pipeline"
- "Check for new buying signals and reach out"
- "Run outbound pipeline"
- "Detect signals and queue emails"
- "Run the full GTM pipeline"
- Triggered automatically on a recurring schedule

## Prerequisites

**Environment variables:**
- `ORTHOGONAL_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`
- Gmail connected via Composio (connect at Settings → Integrations in Pepper Cloud dashboard)

**Sub-skills required (must be installed):**
- `signal-scanner`
- `comprehensive-enrichment`
- `lead-qualification`
- `cold-email-outreach`

**State prerequisites:**
- `strategy/icp.md` — ICP definition. If missing, stop and tell the user to define their ICP first.
- `revops/tam.md` — TAM company list. If missing, tell the user to run `tam-builder` first.

---

## Workflow

### Step 1: Load State and Check Prerequisites

Define state helpers (used throughout all steps):

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

Read prerequisite state:

```bash
ICP=$(state_read "strategy/icp.md")
LAST_RUN=$(state_read "signals/last_run.md")
PIPELINE=$(state_read "revops/pipeline.md")
```

- If `ICP` is empty: stop and tell the user — "strategy/icp.md is missing. Please define your ICP before running the signal pipeline."
- If `LAST_RUN` is empty: treat it as 24 hours ago (first run). Set `LAST_RUN` to yesterday's ISO timestamp.
- `PIPELINE` may be empty on first run — that is fine.

Record the current run timestamp now (used at the end for `signals/last_run.md`):

```bash
RUN_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TODAY=$(date -u +"%Y-%m-%d")
```

---

### Step 2: Detect Buying Signals

Use the `signal-scanner` skill to detect buying signals across your TAM since the `LAST_RUN` timestamp.

Instruct `signal-scanner` to:
- Scope scans to signals newer than `LAST_RUN`
- Cover all five signal types: funding rounds, hiring surges, new product launches, competitor post engagers, and pain-language engagers
- Return a structured list of signals with: `company`, `signal_type`, `signal_detail`, `contact_name`, `contact_email`, `contact_linkedin`, `detected_at`

If `signal-scanner` returns zero signals: log the run timestamp (Step 7) and stop — "No new signals detected since `LAST_RUN`. Pipeline run complete."

---

### Step 3: Dedup Against Existing Pipeline

For each signal returned by `signal-scanner`, check if the contact's email already exists in `PIPELINE` (the content of `revops/pipeline.md`).

Discard any signal where the contact email appears anywhere in `PIPELINE`. These contacts are already in the outbound motion — do not re-process.

Also discard any signal whose `detected_at` timestamp is older than or equal to `LAST_RUN`. This handles edge cases where `signal-scanner` returns stale results.

If all signals are deduped out: log the run timestamp (Step 7) and stop — "All detected signals are already in the pipeline. Nothing new to process."

Keep only the net-new signals. Call this set `NEW_SIGNALS`.

Log each signal in `NEW_SIGNALS` to state immediately (post-action logging — no approval gate needed):

For each signal in `NEW_SIGNALS`:
```bash
SIGNAL_ENTRY="$(date -u +"%Y-%m-%dT%H:%M:%SZ") | ${contact_name} | ${contact_email} | ${company} | ${signal_type} | ${signal_detail}"
state_append "signals/${TODAY}.md" "$SIGNAL_ENTRY"
```

---

### Step 4: Enrich Each Lead

For each lead in `NEW_SIGNALS`, use the `comprehensive-enrichment` skill to gather full professional and company context.

Pass to `comprehensive-enrichment`:
- `contact_email`
- `contact_name`
- `company`
- `contact_linkedin` (if available)

Collect the enriched profile for each lead. Store as `ENRICHED_LEADS` — a list of objects combining the original signal data with the enrichment output.

If enrichment fails for a lead (no data returned), keep the lead in the pipeline with a note `enrichment: partial` — do not drop them. Use whatever data is available.

---

### Step 5: Qualify Each Lead Against ICP

For each enriched lead, use the `lead-qualification` skill to score them against the ICP defined in `strategy/icp.md`.

Pass to `lead-qualification`:
- The full enriched profile
- The ICP from `strategy/icp.md`

`lead-qualification` will return an `icp_score` (0–100) and a `fit_tier` (Strong / Moderate / Weak).

**Routing by score:**
- `icp_score >= 65` (Strong or Moderate fit): collect as `QUALIFIED_LEADS` — proceed to email drafting
- `icp_score < 65` (Weak fit): collect as `DISQUALIFIED_LEADS` — requires approval before logging

**Disqualified leads approval gate:**

If any leads scored below 65, present them before writing to state:

```
DISQUALIFIED LEADS — [N] scored below ICP threshold (< 65)

#  | Company      | Contact       | Score | Signal
---|--------------|---------------|-------|------------------
1  | Acme Corp    | Jane Smith    | 58    | Series B funding
...

These leads will be marked as disqualified and excluded from future pipeline runs.
Reply YES to confirm, NO to skip logging, or list numbers (e.g., "2,4") to keep specific leads in QUALIFIED_LEADS instead.
```

Only proceed if user replies YES or provides a number list. On YES, append disqualified entries:
```bash
for each lead in confirmed DISQUALIFIED_LEADS:
  PIPELINE_ENTRY="$(date -u +"%Y-%m-%dT%H:%M:%SZ") | ${contact_name} | ${contact_email} | ${company} | ${icp_score} | ${signal_type} | disqualified"
  state_append "revops/pipeline.md" "$PIPELINE_ENTRY"
```

Collect all qualified leads (score >= 65, plus any user-rescued leads) as `QUALIFIED_LEADS`.

If `QUALIFIED_LEADS` is empty: log the run timestamp (Step 7) and stop — "All leads scored below ICP threshold. No emails to send."

---

### Step 6: Draft Emails, Get Batch Approval, Send

#### 6a: Draft all emails first

For each lead in `QUALIFIED_LEADS`, use the `cold-email-outreach` skill in **draft-only mode** — generate the email but do not send yet.

Each draft must use the Haines cold email framework:
- Structure: Observation → Problem → Proof → Ask
- Under 100 words in the body
- No jargon
- One interest-based CTA (e.g., "Worth a quick chat?")
- Subject line: 2–4 words, lowercase, no tricks
- Personalization must tie directly to the detected signal (e.g., "Saw you just raised your Series A" or "Noticed you're hiring a VP of Sales")

Each draft should incorporate:
- The enriched profile
- The specific signal that triggered this outreach (`signal_type` + `signal_detail`)
- The ICP context from `strategy/icp.md`

Collect all drafts. Each draft should include: `contact_name`, `contact_email`, `company`, `signal_type`, `subject`, `body_preview` (first line + word count).

#### 6b: Present batch for approval

Show the full batch of drafted emails in a structured table. Do NOT send any email before getting explicit approval.

Present as:

```
OUTREACH BATCH — [TODAY] — [N] emails pending approval

#  | Company         | Contact          | Signal            | Subject                  | Opening line
---|-----------------|------------------|-------------------|--------------------------|-----------------------------
1  | Acme Corp       | Jane Smith       | Series B funding  | congrats on the raise    | Saw Acme just closed $12M...
2  | Beta Inc        | John Doe         | VP Sales hire     | scaling your sales team  | Noticed you're building out...
...

Reply YES to send all, NO to cancel, or list numbers to send selectively (e.g., "send 1, 3").
```

Wait for explicit user response before proceeding.

#### 6c: Handle approval response

- **"YES" or "yes" or "send all"**: send all emails in the batch.
- **"NO" or "no" or "cancel"**: cancel the batch. Log all leads with `status: email-draft-rejected`. Skip to Step 7.
- **Selective approval** (e.g., "send 1, 3"): send only the listed emails. Log the rest with `status: email-draft-skipped`.

#### 6d: Send approved emails

```bash
# Verify Gmail is connected before proceeding
composio-tool apps | grep -i gmail || echo "Gmail not connected — user must connect at Settings → Integrations"

# Search for the send email action slug
composio-tool search "send email" --toolkit gmail --limit 3
```

For each approved email, use composio-tool to send via Gmail:

```bash
composio-tool execute GMAIL_SEND_EMAIL '{"recipient_email": "<contact_email>", "subject": "<subject>", "body": "<body>"}'
```

After each successful send:
```bash
PIPELINE_ENTRY="$(date -u +"%Y-%m-%dT%H:%M:%SZ") | ${contact_name} | ${contact_email} | ${company} | ${icp_score} | ${signal_type} | email-sent"
state_append "revops/pipeline.md" "$PIPELINE_ENTRY"
```

For any send that fails (Gmail error), log with `status: send-failed` and report the failure to the user after the batch completes.

For approved emails that were not sent due to cancellation or skip:
```bash
PIPELINE_ENTRY="$(date -u +"%Y-%m-%dT%H:%M:%SZ") | ${contact_name} | ${contact_email} | ${company} | ${icp_score} | ${signal_type} | email-draft-skipped"
state_append "revops/pipeline.md" "$PIPELINE_ENTRY"
```

---

### Step 7: Update Dedup Timestamp

After all processing is complete (regardless of how many emails were sent), update the last-run timestamp so the next pipeline run only processes new signals:

```bash
state_write "signals/last_run.md" "$RUN_TIMESTAMP"
```

This is the final step. Always run this even if zero emails were sent.

---

## Output

After each run, report a summary:

```
Signal Detection Pipeline — [TODAY]

Signals detected:     [N]
After dedup:          [N]
Enriched:             [N]
Qualified (ICP ≥ 65): [N]
Disqualified:         [N]
Emails sent:          [N]
Emails skipped:       [N]
Send failures:        [N]

State written:
  signals/[TODAY].md       — [N] signal entries
  revops/pipeline.md       — [N] new lead records appended
  signals/last_run.md      — updated to [RUN_TIMESTAMP]
```

If any step produced an error or partial result, surface it in the summary with enough detail for the user to act on it.

---

## Cadence Notes

- **Signal detection** (Steps 1–3): safe to run hourly. Writes only to `signals/YYYY-MM-DD.md` — no emails triggered.
- **Email sends** (Step 6): always require batch approval. Never send automatically without a human in the loop.
- **Dedup logic** ensures re-running hourly does not generate duplicate drafts or re-process leads already in `revops/pipeline.md`.
