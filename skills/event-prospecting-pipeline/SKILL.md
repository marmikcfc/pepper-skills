---
name: event-prospecting-pipeline
description: End-to-end event-triggered prospecting pipeline. Takes a Luma event URL, scrapes and ICP-filters attendees, qualifies them, drafts warm outreach referencing the shared event, gets batch approval, sends, and logs qualified leads to the pipeline.
---

# Event Prospecting Pipeline

Phase 3 GTM orchestrator. Turns any Luma event into a warm outbound motion — scrape attendees, enrich ICP-matching ones, qualify, draft personalized emails that reference the shared event context, get approval, send, and log.

## When to Use
- "Run the event prospecting pipeline for [Luma URL]"
- "Prospect attendees from [conference name]"
- "Find leads from this event and reach out: [URL]"
- "Run outreach for everyone attending [event]"

## Prerequisites

**Environment variables:**
- `ORTHOGONAL_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL`
- `ANTHROPIC_API_KEY`
- Gmail connected via orth (`orth run gmail /send` must work)

**Sub-skills required (must be installed):**
- `luma-event-attendees`
- `lead-qualification`
- `cold-email-outreach`

**State prerequisites:**
- `strategy/icp.md` — ICP definition for filtering and qualification. If missing, stop and tell the user to define their ICP first.
- `revops/pipeline.md` — existing pipeline for dedup check. May be empty on first run — that is fine.

**Inputs required from user:**
- Event URL (Luma event page) — required
- Event name — required (used in email copy to reference shared context)

---

## Workflow

### Step 1: Load State and Validate Prerequisites

Define state helpers (used throughout all steps):

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_append() { local path="$1"; local content="$2"; curl -sf -X POST "$PEPPER_CLOUD_URL/api/state/append" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
```

Read prerequisite state:

```bash
ICP=$(state_read "strategy/icp.md")
PIPELINE=$(state_read "revops/pipeline.md")
TODAY=$(date -u +"%Y-%m-%d")
```

- If `ICP` is empty: stop — "strategy/icp.md is missing. Please define your ICP before running the event prospecting pipeline."
- If event URL or event name was not provided: ask for them before continuing.

---

### Step 2: Scrape, Filter, and Enrich Attendees

Use the `luma-event-attendees` skill with the provided event URL to scrape and enrich attendees.

Instruct `luma-event-attendees` to:
- Scrape the public attendee list from the event URL
- Filter attendees against the ICP in `strategy/icp.md` — keep only ICP-matching attendees
- Enrich each ICP-matching attendee with full contact info (email, LinkedIn, title, company)

Collect the enriched, ICP-filtered attendee list as `ENRICHED_ATTENDEES`.

If `luma-event-attendees` returns zero attendees (event attendees not public, or zero ICP matches): stop — "No ICP-matching attendees found for [event name]. The event attendee list may not be public, or no attendees match your ICP."

---

### Step 3: Dedup Against Existing Pipeline

For each attendee in `ENRICHED_ATTENDEES`, check if their email already appears anywhere in `PIPELINE` (the content of `revops/pipeline.md`).

Discard any attendee whose email is found in the pipeline — they are already in the outbound motion.

If all attendees are deduped out: stop — "All [event name] attendees are already in the pipeline. Nothing new to process."

Keep only net-new attendees. Call this set `NET_NEW_ATTENDEES`.

---

### Step 4: Qualify Each Attendee Against ICP

Use the `lead-qualification` skill to score each attendee in `NET_NEW_ATTENDEES` against the ICP defined in `strategy/icp.md`.

Pass to `lead-qualification` for each attendee:
- The full enriched profile
- The ICP from `strategy/icp.md`

`lead-qualification` will return an `icp_score` (0–100) and a `fit_tier` (Strong / Moderate / Weak).

Routing by score:
- `icp_score >= 65`: collect as `QUALIFIED_ATTENDEES` — proceed to email drafting
- `icp_score < 65`: discard silently (do not log, no gate needed — event attendees are a curated set)

**Approval gate — qualified list:**

After scoring, present the qualified attendees before drafting any emails:

```
EVENT PROSPECTING — [event name]
[N] attendees qualify for outreach (ICP score ≥ 65)

#  | Company      | Contact       | Title              | Score
---|--------------|---------------|--------------------|-------
1  | Acme Corp    | Jane Smith    | VP of Marketing    | 82
2  | Beta Inc     | John Doe      | Head of Growth     | 74
...

These [N] attendees qualify for outreach. Proceed to draft emails? (yes/no)
```

Wait for explicit user response. If "no": stop — do not draft or send anything.

If `QUALIFIED_ATTENDEES` is empty after qualification: stop — "No attendees from [event name] met the ICP threshold (score ≥ 65). No emails to send."

---

### Step 5: Draft Emails, Get Batch Approval, Send

#### 5a: Draft all emails first

For each attendee in `QUALIFIED_ATTENDEES`, use the `cold-email-outreach` skill to draft a warm outreach email — **draft-only mode, do not send yet**.

Each draft must:
- Reference the shared event context in the opening line (e.g., "Saw you're attending [event name]" or "I noticed we're both going to [event name]")
- Use the Haines cold email framework: Observation → Problem → Proof → Ask
- Stay under 100 words in the body
- Include a single interest-based CTA (e.g., "Worth grabbing coffee at the event?" or "Worth a quick chat?")
- Subject line: 2–4 words, lowercase, no tricks
- Personalization must tie to the attendee's role/company and the event context

Pass to `cold-email-outreach` for each attendee:
- The enriched attendee profile
- The event name and URL as warm context
- The ICP context from `strategy/icp.md`

Collect all drafts. Each draft should include: `contact_name`, `contact_email`, `company`, `subject`, `body_preview` (first line + word count).

#### 5b: Present batch for approval

Show the full batch in a structured table. Do NOT send any email before getting explicit approval.

```
OUTREACH BATCH — [event name] — [TODAY] — [N] emails pending approval

#  | Company         | Contact          | Subject                      | Opening line
---|-----------------|------------------|------------------------------|-------------------------------------
1  | Acme Corp       | Jane Smith       | see you at [event]           | Noticed we're both attending [event]...
2  | Beta Inc        | John Doe         | quick one before [event]     | Saw you're going to [event] too...
...

Reply YES to send all, NO to cancel, or list numbers to send selectively (e.g., "send 1, 3").
```

Wait for explicit user response before proceeding.

#### 5c: Handle approval response

- **"YES" / "yes" / "send all"**: send all emails in the batch.
- **"NO" / "no" / "cancel"**: cancel the batch. Do not log anything. Stop.
- **Selective approval** (e.g., "send 1, 3"): send only the listed emails. Skip the rest — do not log skipped leads.

#### 5d: Send approved emails and log

For each approved email, use the `cold-email-outreach` skill to send via Gmail.

After each successful send, append to pipeline:

```bash
PIPELINE_ENTRY="$(date -u +"%Y-%m-%dT%H:%M:%SZ") | ${contact_name} | ${contact_email} | ${company} | ${icp_score} | event:${EVENT_NAME} | email-sent"
state_append "revops/pipeline.md" "$PIPELINE_ENTRY"
```

For any send that fails (Gmail error): log with `status: send-failed` and report the failure to the user after the batch completes. Do not append a pipeline entry for failed sends.

---

## Output

After the pipeline completes, report a summary:

```
Event Prospecting Pipeline — [event name] — [TODAY]

Attendees scraped (ICP-filtered): [N]
After dedup against pipeline:     [N]
Qualified (ICP ≥ 65):             [N]
Emails sent:                      [N]
Send failures:                    [N]

State written:
  revops/pipeline.md  — [N] new lead records appended
```

If any step produced an error or partial result, surface it in the summary with enough detail for the user to act on it.
