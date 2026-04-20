---
name: experiment-design
description: Design a rigorous experiment spec for a strategic bet. Produces a complete experiment card with hypothesis, variants, success metric, sample size, duration, and guardrails.
---
# Experiment Design

Turn a strategic bet into a rigorous, runnable experiment. Produces a complete experiment spec card with hypothesis, control, variant, primary metric, sample size calculation, duration, guardrails, and kill criteria. Saves the spec to the experiments/active/ directory for tracking.

## When to Use

- Ready to run a bet and want a structured spec before starting
- Need to define success criteria before investing time in execution
- Want to ensure the experiment is falsifiable (not just a vague "try it")
- Setting up experiments for the weekly strategy review to track

## Prerequisites

- `PEPPER_EVENT_SECRET` — auth token for the state API
- `PEPPER_CLOUD_URL` — base URL of your Pepper Cloud instance
- `ANTHROPIC_API_KEY` — used to draft the experiment spec
- A bet should exist in `bets/bets.md` (or provide one inline)

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
state_write() { local path="$1"; local content="$2"; curl -sf -X PUT "$PEPPER_CLOUD_URL/api/state" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" -H "Content-Type: application/json" -d "$(python3 -c "import json,sys; print(json.dumps({'path':sys.argv[1],'content':sys.argv[2]}))" "$path" "$content")"; }
state_list() { curl -sf "$PEPPER_CLOUD_URL/api/state/list?prefix=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; [print(e['path']) for e in json.load(sys.stdin)]"; }
```

**Step 1: Identify the bet**

Ask: "Which bet are you designing an experiment for? Provide the bet title, or paste the full bet row from `bets/bets.md`."

```bash
BETS=$(state_read "bets/bets.md")
```

Show matching bets from the ledger if `BETS` is non-empty. Let the user pick by number or title. If no match found, accept a free-form hypothesis from the user.

**Step 2: Auto-increment experiment number**

```bash
# List existing active and archived experiments to determine next number
ACTIVE_EXPS=$(state_list "experiments/active/")
ARCHIVE_EXPS=$(state_list "experiments/archive/")

# Extract max NNN from filenames like exp-001.md, exp-002.md
NEXT_NUM=$(python3 -c "
import sys
lines = '''$ACTIVE_EXPS
$ARCHIVE_EXPS'''.strip().split('\n')
nums = []
for line in lines:
    line = line.strip()
    if 'exp-' in line:
        try:
            n = int(line.split('exp-')[1].replace('.md','').split('/')[-1])
            nums.append(n)
        except: pass
print(str(max(nums) + 1).zfill(3) if nums else '001')
")
EXP_ID="exp-$NEXT_NUM"
```

**Step 3: Gather experiment parameters**

Ask the user for any missing details:

1. **Primary metric** — "What is the one metric that will tell you if this experiment worked? Be specific: e.g., 'reply rate on cold email sequence', 'demo requests from HN post', 'conversion from free trial to paid'"
2. **Baseline** — "What is the current baseline value of that metric?"
3. **Minimum detectable effect (MDE)** — "What improvement would make this experiment worth the effort? (e.g., 2× reply rate, +5 demos/week)"
4. **Control** — "What is the control condition? (what you're doing today)"
5. **Variant** — "What is the variant? (the specific change you're testing)"
6. **Sample pool** — "How large is the population you can expose to this experiment? (e.g., 200 prospects, 1000 site visitors)"

**Step 4: Calculate duration**

```python
python3 -c "
import math

baseline = float('$BASELINE_VALUE')
mde = float('$MDE_PERCENT') / 100  # convert % to decimal
sample_pool = int('$SAMPLE_POOL')
weekly_throughput = int('$WEEKLY_THROUGHPUT')  # ask user if not obvious

# Simple power calculation for proportions (80% power, 95% confidence)
# n per variant = 16 * p * (1-p) / (mde * p)^2  (approximate)
p = baseline
effect = mde * p
n_per_variant = max(30, int(16 * p * (1-p) / (effect**2))) if effect > 0 else 100

total_needed = n_per_variant * 2
weeks_needed = math.ceil(total_needed / weekly_throughput) if weekly_throughput > 0 else 4

print(f'Sample needed per variant: {n_per_variant}')
print(f'Total sample needed: {total_needed}')
print(f'Estimated duration: {weeks_needed} weeks')
print(f'Feasible: {\"yes\" if total_needed <= sample_pool else \"no — pool too small, consider a simpler qualitative experiment\"}')
"
```

If the sample pool is too small for statistical significance, note this and suggest a qualitative experiment instead (e.g., 5 customer interviews, 10 manual tests).

**Step 5: Draft the experiment spec**

Pass all parameters to Claude:

> "Write a clean, complete experiment spec card in markdown for this GTM experiment.
>
> Include:
> - **Experiment ID**: $EXP_ID
> - **Bet**: <bet title and hypothesis>
> - **Status**: active
> - **Start date**: <today>
> - **Target end date**: <today + duration>
> - **Owner**: <owner>
> - **Hypothesis**: 'We believe [variant] will cause [metric] to improve from [baseline] to [target] because [reason]'
> - **Control**: <control description>
> - **Variant**: <variant description>
> - **Primary metric**: <metric name + baseline + target>
> - **Secondary metrics** (guardrails — must not regress): <list 1-3>
> - **Sample size**: <n per variant, total>
> - **Duration**: <weeks>
> - **Execution plan**: numbered steps to run the experiment
> - **Kill criteria**: stop the experiment early if [condition] (e.g., primary metric drops >20% in first week)
> - **Decision rule**: 'Call it a win if primary metric reaches target AND no guardrail regresses. Call it a loss if...'
>
> Be specific and direct. No filler."

**Step 6: Approval gate and save**

Show the full spec to the user and ask:

"Save this experiment spec to `experiments/active/$EXP_ID.md`? (yes/edit/no)"

- If `edit`: ask what to change, revise, show again, repeat gate
- If `no`: discard
- If `yes`:

```bash
state_write "experiments/active/$EXP_ID.md" "$EXPERIMENT_SPEC"
```

Confirm: "Experiment spec saved to `experiments/active/$EXP_ID.md`. Track progress in the weekly `strategy-review`."

## Output

`experiments/active/exp-NNN.md` — a complete, runnable experiment spec with hypothesis, variants, metric targets, sample size, duration, guardrails, and kill criteria.
