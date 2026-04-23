---
name: idea-validation-playbook
description: Full idea validation pipeline — from raw idea to kill/pivot/proceed decision. Autonomously executes validation methods (smoke test, fake door, concierge, interviews) adapted per market type (B2B / B2C / DTC / Prosumer). Produces actual validation artifacts and spends credits to capture real signal.
inputs:
  - name: EXA_API_KEY
    description: Exa API key for structured research across Reddit, G2, Product Hunt, and forums
    required: false
---

## When to use

- When validating a new business idea before committing resources to build
- When you want the agent to autonomously run validation experiments and return a kill/pivot/proceed decision
- When you need actual validation artifacts: landing page copy, interview scripts, outreach emails, pricing page copy

## When NOT to use

- When the idea is already validated and you're building (use `experiment-design` or `signal-detection-pipeline`)
- When you only need a market analysis report (use `market-analysis` skill)
- When you only need competitor research (use `competitive-landscape-map` skill)

## Important: Autonomous Execution

This playbook will autonomously spend credits and take real-world actions to validate the idea:
- Build and publish landing pages via browser skill
- Send cold outreach emails to recruit interview candidates
- Run paid traffic for smoke tests (if budget provided)

**Confirm budget, timeline, and market type at intake before proceeding.**

## Graph

This playbook defines a directed workflow graph. At each vertex, execute that step fully, then choose the next vertex from its declared allowed transitions based on output and context.

### Vertices

| Vertex | Calls | Description |
|--------|-------|-------------|
| `intake` | — | Collect: idea description, market type (B2B / B2C / DTC / Prosumer), budget for validation, timeline, founder context. |
| `signal-researcher` | web-search, x-search | Mine pain signals: Reddit threads, G2 reviews, Twitter complaints, forum posts, Product Hunt discussions. Score signal strength. |
| `competitor-mapper` | web-search | Map existing solutions: who is solving this, at what price, what gaps exist, what customers complain about. |
| `icp-definer` | — | Define the ideal early adopter. Adapts per market type: job title and buying trigger for B2B; demographics and emotional trigger for B2C/DTC; power-user workflow pain for Prosumer. |
| `method-selector` | — | Select 1–3 validation methods from the menu. Adapted to market type, budget, and timeline. Prefer combinations that triangulate quantitative + qualitative signal. |
| `artifact-generator` | `copywriting` skill | Produce all validation artifacts before any executor runs: landing page copy, interview script, outreach email, pricing page copy. |
| `smoke-test-executor` | browser skill, Composio | Build landing page + pricing page. Drive traffic (organic or paid). Measure conversion rate and plan selection split. |
| `fake-door-executor` | browser skill | Add a fake CTA for the non-existent feature or product. Measure click-through rate. |
| `concierge-executor` | Composio Gmail | Manually deliver the service for the first 5–10 users via email. Measure satisfaction and willingness to pay. |
| `interview-executor` | `find-leads` + `cold-email` skills | Recruit interview candidates via outreach. Run discovery interviews. Extract and theme responses. |
| `signal-aggregator` | — | Synthesize all signals from all executors: conversion rates, interview themes, engagement metrics, WTP evidence. Compute overall confidence score 0–10. |
| `decision-maker` | — | **Approval gate — present all evidence and confidence score. Stop and wait for kill / pivot / proceed decision from user.** |
| `report-generator` | `pdf` skill | Produce full validation report: signals found, methods run, results per method, decision, and next steps. |

### Edges

```
intake               → signal-researcher
signal-researcher    → competitor-mapper
competitor-mapper    → icp-definer
icp-definer          → method-selector
method-selector      → artifact-generator
artifact-generator   → smoke-test-executor        (if smoke test selected)
artifact-generator   → fake-door-executor         (if fake door selected)
artifact-generator   → concierge-executor         (if concierge selected)
artifact-generator   → interview-executor         (if interviews selected)
                       [multiple executors run in parallel when 2+ methods selected]
smoke-test-executor  → signal-aggregator
fake-door-executor   → signal-aggregator
concierge-executor   → signal-aggregator
interview-executor   → signal-aggregator
signal-aggregator    → decision-maker
decision-maker       → report-generator           (proceed or pivot with learnings)
decision-maker       → intake                     (kill — restart with new hypothesis)
report-generator     → END
```

## Traversal Rules

1. Always start at `intake`. Confirm market type, budget, and timeline before proceeding. Do not begin any executor without these confirmed.
2. At `method-selector`, choose methods the agent can execute autonomously. Prefer: one quantitative method (smoke test or fake door) + one qualitative method (interviews or concierge).
3. At `artifact-generator`, produce ALL artifacts before launching any executor. Never begin execution with incomplete artifacts.
4. When 2+ methods are selected, all corresponding executors run in parallel. Collect all results before advancing to `signal-aggregator`.
5. At `decision-maker`, **stop and present all evidence. Do not proceed to `report-generator` without the user's explicit kill/pivot/proceed decision.**
6. If user chooses "kill + new hypothesis" at `decision-maker`, return to `intake` with the new hypothesis. If the idea space is similar, skip `signal-researcher` and `competitor-mapper` and resume at `method-selector`.
7. Terminal vertex: `END`. Stop when reached.

## Market Type Adaptation

At `icp-definer` and `method-selector`, adapt to the market type from `intake`:

| Market Type | ICP Focus | Recommended Methods | Key Signal |
|-------------|-----------|---------------------|------------|
| B2B | Job title, company size, buying trigger, budget authority | Interviews + fake door | Booked discovery calls, stated WTP, org-level pain |
| B2C | Demographics, emotional trigger, watering holes, impulse vs considered | Smoke test + concierge | Conversion rate, repeat session, spontaneous referral |
| DTC | Buyer persona, purchase trigger, price sensitivity, AOV target | Smoke test + interviews | Add-to-cart rate, email capture rate, AOV |
| Prosumer | Power user profile, workflow pain, tool stack, build vs buy threshold | All three methods | Paid signup rate, feature requests, NPS from manual users |

## Validation Methods Reference

| Method | What the agent does | Signal measured | Typical cost |
|--------|---------------------|-----------------|--------------|
| Smoke test | Build landing page + pricing page. Drive organic or paid traffic. | Conversion rate, plan selected | Low–Medium |
| Fake door | Add CTA for non-existent feature or product. | Click-through rate | Very low |
| Concierge | Manually deliver the service for first 5–10 users via email | Satisfaction, WTP, churn at offer | Medium (agent time) |
| Interviews | Cold outreach to recruit candidates. Run 5–10 discovery sessions. | Themes, pain depth, WTP, objections | Low–Medium |

**Decision thresholds (adjust per context at signal-aggregator):**
- Smoke test: >10% conversion from cold traffic = strong demand signal
- Fake door: >15% CTR = feature/product is worth building
- Concierge: 3+ of 5 users pay or explicitly want to continue = real demand
- Interviews: 3+ of 5 unprompted mention the same pain = validated problem

## Artifacts Produced

At `artifact-generator`, always produce:

1. **Landing page copy** — headline, subheadline, 3 benefit bullets, social proof placeholder, CTA button copy, pricing section with 2–3 tiers
2. **Interview script** — 10 open-ended discovery questions, 5 willingness-to-pay probes, 3 common objection handlers
3. **Outreach email** — 3-line cold email for interview recruitment, 3 subject line variants
4. **Pricing page copy** — 2–3 pricing tiers with feature differentiation and recommended plan callout

## Output

`report-generator` produces a PDF validation report containing:
- Idea summary and market type
- Methods run and results per method (with raw numbers)
- Overall confidence score (0–10) with rationale
- Kill / pivot / proceed recommendation
- If proceed: suggested first experiment to run next
- If pivot: new hypothesis and what signal triggered the pivot

Upload report:
```
mcp__pepper__upload_artifact({
  file_path: "/workspace/group/validation/[idea-slug]-validation-report.pdf",
  title: "Validation Report: [Idea Name]"
})
```

Store decision to workspace memory:
```
mcp__pepper__workspace_memory({ action: "remember", text: "Idea validation: [idea] ([market type]) — [decision]. Confidence: [score]/10. Key signal: [evidence]. Next: [action]." })
```
