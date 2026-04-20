---
name: content-repurposer
description: Repurpose existing content into multiple formats — turn a blog post into a Twitter thread, LinkedIn post, email newsletter, and short video script. Use when asked to repurpose content, adapt content for a different channel, or get more mileage from existing content.
---

# Content Repurposer

Transform a single piece of content into multiple channel-optimized formats. No external API calls needed — pure LLM transformation.

## When to Use
- "Repurpose this blog post for LinkedIn"
- "Turn this into a Twitter thread"
- "Make a newsletter version of this content"
- "Create a short video script from this article"
- "Get more mileage from [content piece]"

## Prerequisites
- `ANTHROPIC_API_KEY`

## Workflow

**Step 1: Get the source content**
Ask the user to paste or describe the source content. Clarify:
- What type is the source? (blog post, video transcript, podcast notes, whitepaper section)
- What formats do they want? (Twitter thread, LinkedIn post, email, video script, or all)
- Any specific angle or section to emphasize?

**Step 2: Repurpose for each requested format**

**Twitter/X thread:**
> "Repurpose this content as a Twitter thread. Rules: hook tweet grabs attention with a bold claim or surprising stat, 8-12 tweets total, each tweet one clear idea, end with CTA, thread should work without the original context."

**LinkedIn post:**
> "Repurpose this as a LinkedIn post. Rules: hook in the first line (no 'I' opener), story or insight format, conversational but professional, 150-300 words, one strong CTA at the end."

**Email newsletter section:**
> "Repurpose this as a newsletter section. Rules: short subject line, conversational opener, clear value in first sentence, 150-250 words, one link CTA."

**Short video script (60-90 seconds):**
> "Write a 60-90 second video script from this content. Structure: hook (5 sec) → problem setup (10 sec) → 3 key points (45 sec) → CTA (10 sec). Include [B-ROLL] notes."

**Step 3: Present all versions**
Show all repurposed versions. Ask if any need adjustments.

## Output
Multiple format-optimized versions of the source content, ready to publish.
