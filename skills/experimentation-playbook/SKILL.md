---
name: experimentation-playbook
description: End-to-end experiment orchestrator — from bet or raw hypothesis through design, preregistration, execution, monitoring, archival, and strategy update. LLM drives the graph; valid transitions are declared explicitly per vertex.
inputs: []
---

## When to use

- When running any experiment: GTM, product, pricing, content, or onboarding
- When a bet needs to be turned into a rigorous experiment with full lifecycle tracking
- When you want to close the full loop: hypothesis → design → run → learn → archive

## When NOT to use

- For quick one-off tests with no need to track learnings (use `experiment-design` directly)
- For experiments already in-flight that need monitoring only (use `experiment-monitor` directly)

## Graph

This playbook defines a directed workflow graph. At each vertex, execute that step fully, then choose the next vertex from its declared allowed transitions. Do not jump to vertices not listed as valid next steps from your current position.

### Vertices

| Vertex | Calls | Description |
|--------|-------|-------------|
| `intake` | — | Collect bet reference OR raw hypothesis. Identify experiment domain: GTM / product / pricing / content / onboarding. |
| `bet-logger` | `bet-ledger` skill | Log raw hypothesis as a strategic bet. Required only if no existing bet ID provided at intake. |
| `experiment-designer` | `experiment-design` skill | Design the experiment card: hypothesis, variants, primary metric, sample size, duration, guardrails. |
| `preregistration` | `experiment-preregister` skill | Lock spec with SHA256 hash. **Approval gate — stop and wait for explicit user confirmation before proceeding.** |
| `experiment-runner` | domain-adaptive (see below) | Execute the experiment. Adapt method to domain identified at intake. |
| `monitor-loop` | `experiment-monitor` skill | Check for statistical significance or guardrail breach. Loop on cadence until terminal condition. |
| `early-stop` | — | Document guardrail breach. Halt experiment. Proceed to archival. |
| `results-collector` | — | Gather final metrics: primary metric observed, p-value, sample sizes, anomalies. |
| `archiver` | `experiment-archive` skill | Archive completed experiment. Update bet ledger and learnings log. |
| `strategy-updater` | `strategy-review` or `retro` skill | Feed learnings into weekly strategy review or monthly retro. |

### Edges

```
intake              → bet-logger             (if raw hypothesis, no existing bet ID)
intake              → experiment-designer    (if bet already exists in bets/bets.md)
bet-logger          → experiment-designer
experiment-designer → experiment-designer    (if spec needs revision — loop until user approves)
experiment-designer → preregistration        (spec approved by user)
preregistration     → experiment-runner
experiment-runner   → monitor-loop
monitor-loop        → monitor-loop           (not yet significant, within planned duration)
monitor-loop        → early-stop             (guardrail breached)
monitor-loop        → results-collector      (significance reached OR deadline hit)
early-stop          → archiver
results-collector   → archiver
archiver            → strategy-updater       (if strategy session is due or learnings are high-value)
archiver            → END                    (if no strategy session needed)
strategy-updater    → END
```

## Traversal Rules

1. Always start at `intake`. Identify domain before proceeding.
2. At `experiment-designer`, loop until the user explicitly approves the spec before advancing to `preregistration`.
3. At `preregistration`, **stop and wait for explicit user approval** before locking the spec. This is irreversible.
4. At `monitor-loop`, check once per scheduled cadence and evaluate: loop / stop / kill. Do not auto-loop without user awareness.
5. Terminal vertex: `END`. Stop when reached.

## Domain Adaptation at `experiment-runner`

Adapt execution method to the domain identified at `intake`:

| Domain | Execution method |
|--------|-----------------|
| GTM / outbound | Launch outreach sequence via Composio Gmail. Track reply rate vs control baseline. |
| Content | Publish variant A/B posts. Track engagement (likes, shares, click-through) via x-search + Composio analytics. |
| Pricing | Smoke test landing page with two price point variants. Track conversion rate and plan selection split. |
| Product | Toggle feature flag for target segment. Monitor primary metric dashboard. Use `experiment-monitor` for significance check. |
| Onboarding | A/B two onboarding flows. Track activation rate and time-to-first-value. |

## State Files

Reads from:
- `bets/bets.md` — active bets
- `experiments/active/exp-NNN.md` — existing experiment specs
- `strategy/icp.md` — ICP context for GTM experiments

Writes to:
- `bets/bets.md` — new bets, outcome updates
- `experiments/active/exp-NNN.md` — new experiment spec
- `experiments/active/exp-NNN.locked.md` — preregistered spec
- `experiments/archive/exp-NNN.md` — archived result
- `strategy/learnings.md` — distilled learnings

## Output

When `archiver` completes, produce a summary card:
- Experiment ID + bet reference
- Original hypothesis
- Result: WIN / LOSS / INCONCLUSIVE
- Primary metric: baseline vs observed, p-value
- Key learning (stated as a generalizable principle)
- Decision: scale / kill / iterate

Store to workspace memory:
```
mcp__pepper__workspace_memory({ action: "remember", text: "Experiment exp-NNN: [hypothesis] → [result]. Learning: [principle]." })
```
