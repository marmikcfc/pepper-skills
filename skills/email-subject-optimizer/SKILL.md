---
name: email-subject-optimizer
description: Generate and rank subject line variants optimized for open rate by segment and context. Use when writing cold outreach, newsletter campaigns, or drip emails and want to maximize opens.
---

# Email Subject Optimizer

Generate high-converting subject line variants, score them, and select the best for your audience.

## When to Use
- "Write subject lines for this email"
- "Our open rates are low — improve the subject line"
- "Generate variants for A/B testing"
- "Write cold outreach subject lines for [segment]"

## Prerequisites
- `ANTHROPIC_API_KEY`
- Email body or core message, audience segment

## Workflow

**Step 1: Extract the core hook**

From the email, identify:
- Primary value offered
- Recipient's most relevant pain point
- Any time sensitivity or urgency
- Social proof or credibility signals

**Step 2: Generate 10 variants across 5 archetypes**

| Archetype | Principle | Example |
|-----------|-----------|---------|
| **Direct** | States the benefit | "Cut [task] time in half" |
| **Curiosity** | Opens a loop | "Why [company] stopped doing [X]" |
| **Specificity** | Numbers and data | "3 companies added [X] in 90 days" |
| **Personal** | Feels 1:1 | "Quick question about [their company]" |
| **Question** | Reader self-interest | "Still doing [painful thing] manually?" |

Generate 2 variants per archetype.

**Step 3: Score each variant**

| Subject line | Length | Personalization | Clarity | Intrigue | Spam risk | Score |
|-------------|--------|-----------------|---------|----------|-----------|-------|

Scoring (1-5): Length 30-50 chars = best. Personalization = mentions their context. Spam risk = penalize ALL CAPS, excessive punctuation, spam words.

**Step 4: Filter by segment**

| Segment | Preferred style | Avoid |
|---------|----------------|-------|
| C-suite | Direct, ROI-focused | Clickbait |
| Technical | Specific, credible | Vague promises |
| Marketing | Creative, trend-aware | Generic |
| Sales | Peer-to-peer | Corporate |

**Step 5: Final selection**

Top 2-3 for A/B testing. For cold outreach: 1 direct + 1 curiosity.

## Output
10 scored subject line variants with top 2-3 recommended for testing.
