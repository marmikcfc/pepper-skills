---
name: cold-call
description: End-to-end cold calling workflow — research contact, generate personalized script, initiate call via VAPI or Bolna, analyse transcript, and produce outcome report
inputs:
  - name: VAPI_API_KEY
    description: VAPI API key for global voice calling (connect via Composio → VAPI integration)
    required: false
  - name: BOLNA_API_KEY
    description: Bolna API key for India voice calling (connect via Composio → Bolna integration)
    required: false
---

# Cold Call

End-to-end cold calling workflow. Given a goal and a contact, this skill researches the person, generates a personalized script, initiates the call via VAPI (global) or Bolna (India), waits for the call-completed webhook, analyses the transcript, and produces a structured outcome report.

## Prerequisites

Connect at least one of:
- **VAPI** (global default): Composio → VAPI integration → enter API key
- **Bolna** (India): Composio → Bolna integration → enter API key

## Workflow

### Step 1: Clarify the Goal

Before proceeding, confirm:
- What outcome defines success? (e.g., "book a 30-min demo", "qualify budget and timeline", "gather churn feedback")
- What tone? (challenger, consultative, warm intro)
- Any constraints? (max duration, required talking points, topics to avoid)

If the user has not provided these, ask before continuing.

### Step 2: Research the Contact

Use available enrichment skills to build a contact profile:

1. Run **Person Enrichment** or **Comprehensive Enrichment** on the contact (name + company or email)
2. Run **Company Intel** on their company
3. Check **LinkedIn Activity** for recent posts and signals if available

Synthesize a research brief:
- Role, tenure, background
- Company size, industry, recent news, funding stage
- Likely pain points relevant to the call goal
- Personalization hooks (recent post, company milestone, shared connection, competitor move)

### Step 3: Generate Call Script

Write a personalized call script based on the goal and research brief:

```
OPENER (15 seconds)
  - Name, company, one-line reason for calling
  - Ask permission: "Do you have 2 minutes?"

HOOK (30 seconds)
  - Lead with a specific, researched insight about their situation
  - Connect it to the outcome you help with

KEY QUESTIONS (60–90 seconds)
  - 2–3 open-ended discovery questions
  - Listen for pain signals

VALUE BRIDGE (30 seconds)
  - Connect their stated pain to your solution, concisely

CLOSE (20 seconds)
  - Direct ask aligned to the call goal

OBJECTION HANDLERS
  - "Not interested" → reframe to the specific pain you researched
  - "Too busy" → offer a specific short time slot
  - "Send me an email" → confirm they'll read it, commit to exact follow-up time
  - "We already have something" → ask what's working, probe for gaps
```

Show the script to the user and get approval before initiating the call.

### Step 4: Initiate the Call

**Provider selection:**
- If only `VAPI_API_KEY` is set → use VAPI
- If only `BOLNA_API_KEY` is set → use Bolna
- If both are set → use VAPI by default; use Bolna if the contact's phone number starts with `+91`

**Using VAPI (via Composio):**

Use the Composio VAPI tool to create a call. Set:
- `webhook_url`: `https://{RAILWAY_PUBLIC_DOMAIN}/webhooks/vapi`
- `assistant.systemPrompt`: the approved script
- `assistant.firstMessage`: the opener line
- `customer.number`: the contact's phone number in E.164 format

**Using Bolna (via Composio):**

Use the Composio Bolna tool to initiate a call. Set:
- `webhook_url`: `https://{RAILWAY_PUBLIC_DOMAIN}/webhooks/bolna`
- Agent prompt: the approved script
- `recipient_phone_number`: the contact's phone number in E.164 format

Confirm call initiated and share the call ID with the user.

### Step 5: Receive Transcript (Post-Call)

The call-completed event is delivered automatically as a message when the call ends via the platform webhook. It includes:
- Call status and end reason
- Full transcript
- Recording URL (if available)

The agent picks this up on the next run and proceeds to Step 6.

### Step 6: Analyse the Transcript

Read the full transcript and determine:

**Goal Assessment:**
- Was the goal achieved? (YES / PARTIAL / NO)
- If PARTIAL or NO: what prevented success?

**Call Dynamics:**
- How was the opener received? (positive / neutral / negative)
- Objections raised (list each)
- Interest signals that appeared
- How the close was handled and the prospect's response

**Sentiment Arc:**
- Start → Middle → End (e.g., skeptical → engaged → positive)

**Key Moments:**
- Best moment (what worked and why)
- Missed opportunity (what could have been done differently)

### Step 7: Produce Outcome Report

Generate a structured report. If output volume is low, deliver as a message. If multiple contacts were called, produce a Google Doc with per-contact sections and a campaign summary.

```
COLD CALL OUTCOME REPORT
========================
Contact:   [Name] | [Title] | [Company]
Goal:      [Stated objective]
Date:      [Call date]
Duration:  [HH:MM:SS]
Provider:  [VAPI | Bolna]

OUTCOME: [GOAL MET ✓ | PARTIAL ◐ | NOT MET ✗]

NEXT ACTION:
  [ ] [Specific follow-up action with timeline and owner]

TRANSCRIPT SUMMARY:
  [3–5 sentence summary of the call flow and key moments]

ANALYSIS:
  Opener reception:  [positive / neutral / negative]
  Objections raised: [bulleted list]
  Interest signals:  [bulleted list]
  Close:             [what was asked, what was agreed or declined]

COACHING NOTES:
  ✓ What worked:  [specific moment or technique]
  △ Improve:      [specific moment or technique with suggested alternative]

RECORDING: [URL or "not available"]
```

**Campaign summary (when multiple contacts):**
- Total calls made
- Goal attainment rate (%)
- Most common objections across calls
- Patterns in successful vs. unsuccessful calls
- Recommended script adjustments
