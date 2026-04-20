---
name: product-positioning-doc
description: Write a complete product positioning document from competitive and customer research. Use when launching a new product, repositioning an existing one, or aligning the team on how to talk about what you build.
---

# Product Positioning Doc

Write a formal product positioning document — the source of truth for how your product is framed, differentiated, and sold.

## When to Use
- "Write a positioning doc for [product]"
- "We're repositioning — document the new positioning"
- "Align sales and marketing on how to talk about the product"

## Prerequisites
- `ANTHROPIC_API_KEY`
- Product description, ICP, competitive context

## Workflow

**Step 1: Gather positioning inputs**

Collect:
- Top 3 reasons customers buy (from interviews or wins)
- Top 3 reasons you win / lose (win-loss data)
- Top 3 competitive alternatives
- Gap between internal perception and customer reality

**Step 2: Define the market frame**

| Element | Answer |
|---------|--------|
| What category are you in? | |
| Who specifically are you for? | |
| What problem do you solve? | |
| World without you? | |
| World with you? | |

**Step 3: Write the positioning statement**

> **For** [target customer], **who** [has this need], **[product]** is a [category] **that** [key benefit]. **Unlike** [primary alternative], **our product** [key differentiator].

Write 3 candidates. Test: Is this true? Is this different? Does our best customer recognize themselves?

**Step 4: Define competitive differentiation**

| Competitor | Their claim | Our counter-claim | Proof |
|-----------|------------|-------------------|-------|

**Step 5: Write the positioning document**

```
Write a product positioning doc for [product]:

1. Overview (what we do, for whom, why it matters)
2. Target customer (ICP with firmographics and psychographics)
3. Problem we solve (before state)
4. Our solution (after state)
5. Key differentiators (3-4 with proof)
6. Competitive alternatives (top 3 and why we win)
7. Proof points (quotes, data, case study refs)
8. What we are NOT (explicit anti-positioning)

Tone: clear, direct, internal use. Length: 2-3 pages.
```

**Step 6: Validate**

Test with 3 customers, 3 sales reps, 1 new employee. Key question: "Does this help you understand what we do and why it matters?"

## Output
Product positioning document with market frame, positioning statement, competitive differentiation, and proof points.
