---
name: brand-voice-guidelines
description: Define and document brand voice, tone principles, and writing style for consistent content across channels. Use when creating a brand voice guide, onboarding writers, or standardizing how the company communicates.
---

# Brand Voice Guidelines

Define the voice and tone that makes your brand recognizable — then document it so every piece of content sounds like the same company.

## When to Use
- "We need a brand voice guide"
- "Our content sounds inconsistent — help us define our voice"
- "Onboard a new writer to our style"
- "What tone should we use for [channel]?"

## Prerequisites
- `ANTHROPIC_API_KEY`
- Sample content (blog posts, emails, website copy, social posts)

## Workflow

**Step 1: Audit existing content**

Collect 10-20 representative pieces across channels. Look for:
- Words and phrases that recur
- Sentence length and complexity patterns
- Formality level
- Use of humor, jargon, analogies
- What the writing avoids

**Step 2: Extract voice patterns with LLM**

```
Analyze these content samples and identify:
1. The brand's personality (3-5 adjectives)
2. Recurring vocabulary choices
3. Sentence and paragraph structure patterns
4. What this brand would and would NOT say
5. How the tone shifts between channels (email vs. social vs. docs)
[paste samples]
```

**Step 3: Define the voice pillars**

For each pillar:
| Element | Definition |
|---------|-----------|
| **Personality trait** | e.g., "Direct" |
| **What it means** | Plain language, no fluff |
| **In practice** | Short sentences, active voice |
| **Not** | Jargon, passive voice, hedging |

**Step 4: Build the do/don't table**

| We say | We don't say |
|--------|--------------|
| "simple" | "easy to use" |
| "here's how" | "please be advised" |
| "you" | "the user" |

**Step 5: Write the channel tone guide**

| Channel | Tone | Formality | Length |
|---------|------|-----------|--------|
| Website homepage | Confident, inviting | Semi-formal | Punchy |
| Email newsletter | Warm, informative | Casual | Medium |
| Social (LinkedIn) | Thought-leadership | Professional | Varied |
| Social (Twitter/X) | Sharp, direct | Casual | Short |
| Docs / Help | Clear, patient | Neutral | Thorough |
| Sales outreach | Human, specific | Casual-pro | Brief |

**Step 6: Create the litmus test**

3 questions to ask before publishing:
1. Does this sound like a person, not a corporation?
2. Would our best customer find this useful or interesting?
3. Is every word earning its place?

## Output
Brand voice guide with personality pillars, do/don't vocabulary table, channel tone matrix, and writing litmus test.
