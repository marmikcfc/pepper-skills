---
name: content-generation-playbook
description: Full content production waterfall — from raw idea to published, distributed, repurposed content across all channels. Three modes: long-form first, social first, or full waterfall (one idea → every format). LLM drives the graph; valid transitions are declared explicitly.
inputs: []
---

## When to use

- When turning an idea into published content across multiple formats and channels
- When you want to produce all content formats from a single idea (waterfall mode)
- When you need a systematic content pipeline from ideation through distribution and performance tracking

## When NOT to use

- For a quick one-off social post (use `social-content` skill directly)
- For editing or improving existing content (use `copy-editing` skill directly)
- For content strategy and planning only without production (use `content-strategy` skill directly)

## Graph

This playbook defines a directed workflow graph. At each vertex, execute that step fully, then choose the next vertex from its declared allowed transitions based on output and context.

### Vertices

| Vertex | Calls | Description |
|--------|-------|-------------|
| `intake` | — | Collect: raw idea, target audience, brand voice, mode (long-form / social / waterfall), channels to publish to. |
| `ideation-expander` | web-search, x-search | Expand idea into 3–5 angles. Validate with audience signals: what's resonating, what's trending, what's been overdone. |
| `competitor-audit` | web-search | Find what's already been published on this topic. Identify gaps and differentiation opportunities. |
| `brief-builder` | — | Synthesize research into a content brief: winning angle, audience, CTA, key points, intended format and length. |
| `hook-writer` | `copywriting` skill | Generate 5+ hook variants. Select the strongest based on audience and angle. Confirm with user before proceeding. |
| `long-form-creator` | `copywriting` skill | Write full long-form draft: blog post or newsletter (800–2,500 words). |
| `social-first-creator` | `social-content` skill | Write hook → thread → short-form posts. Optimise for engagement before expanding to long-form. |
| `waterfall-creator` | long-form-creator + social-first-creator | Run long-form creation then social creation in sequence, feeding long-form as source material. |
| `repurposing-engine` | `social-content` skill | Break long-form into: LinkedIn carousel, Twitter/X thread, Instagram caption, quote cards, TikTok script. |
| `email-drafter` | `email-sequence` skill | Write newsletter version or email announcement with subject line variants. |
| `distribution-scheduler` | Composio (Buffer / Beehiiv / LinkedIn / Twitter scheduling) | Schedule posts and newsletter across all channels. List all scheduled items and confirm timing before publishing. |
| `performance-tracker` | x-search, Composio analytics | Track engagement 24–72h post-publish: likes, shares, replies, CTR, open rate. |
| `learnings-logger` | `workspace-memory` skill | Distill what worked (hook, angle, format, channel) into workspace memory for future content runs. |

### Edges

```
intake                 → ideation-expander
ideation-expander      → competitor-audit                (default — always audit competitors)
ideation-expander      → brief-builder                   (skip audit only if idea is highly original with no prior art)
competitor-audit       → brief-builder
brief-builder          → hook-writer
hook-writer            → long-form-creator               (long-form mode)
hook-writer            → social-first-creator            (social mode)
hook-writer            → waterfall-creator               (waterfall mode)
long-form-creator      → repurposing-engine              (produce social formats from long-form)
long-form-creator      → email-drafter                   (also send as newsletter)
long-form-creator      → distribution-scheduler          (publish long-form only, skip repurpose)
social-first-creator   → distribution-scheduler          (quick publish, social only)
social-first-creator   → long-form-creator               (expand winning hook to long-form)
waterfall-creator      → repurposing-engine              (all social formats in parallel)
repurposing-engine     → email-drafter                   (add email to the mix)
repurposing-engine     → distribution-scheduler          (schedule all social pieces)
email-drafter          → distribution-scheduler
distribution-scheduler → performance-tracker
performance-tracker    → learnings-logger
learnings-logger       → END
learnings-logger       → ideation-expander               (next piece in a content series)
```

## Traversal Rules

1. Always start at `intake`. Confirm mode (long-form / social / waterfall) before proceeding.
2. **Waterfall mode**: run `long-form-creator` first, feed output into `social-first-creator`, then `repurposing-engine`.
3. **Social mode**: publish social first, then optionally expand via `long-form-creator` if the hook performs well.
4. **Long-form mode**: create long-form, repurpose into social formats, draft email, then distribute.
5. At `hook-writer`: present hook variants to user, confirm selection before writing long-form. Do not write long-form with an unconfirmed hook.
6. At `distribution-scheduler`: list all scheduled items with proposed times and channels. Confirm before publishing.
7. Terminal vertex: `END`. Stop when reached.

## Mode Reference

| Mode | Flow | Best for |
|------|------|----------|
| Long-form first | hook → long-form → repurpose → email → distribute | Newsletter, blog, thought leadership |
| Social first | hook → thread → posts → distribute → (optionally) expand | Building audience, testing angles fast |
| Waterfall | hook → long-form + social in sequence → repurpose all formats → email → distribute | Maximum reach from one idea |

## Content Formats by Channel

At `repurposing-engine`, produce for all relevant channels selected at intake:

| Channel | Format | Target length |
|---------|--------|---------------|
| LinkedIn | Carousel (5–10 slides) or long post | 1,200–1,800 chars |
| Twitter/X | Thread (6–12 tweets) | 280 chars/tweet |
| Instagram | Caption + quote card copy | 150–300 chars |
| TikTok / Reels | Script (hook + 3 points + CTA) | 60–90 second read |
| Newsletter | Full email with subject line variants | 400–800 words |
| YouTube | Video outline (hook + sections + CTA) | Outline only |

## State Files

Writes to:
- `content/briefs/YYYY-MM-DD-[topic].md` — content brief
- `content/drafts/YYYY-MM-DD-[topic]-[format].md` — each content draft
- `content/published/YYYY-MM-DD-[topic].md` — published record with links
- `strategy/learnings.md` — content learnings

## Output

After `learnings-logger`, store to workspace memory:
```
mcp__pepper__workspace_memory({ action: "remember", text: "Content: [topic] — [hook] performed [result] on [channel]. Winning angle: [angle]." })
```

Upload content bundle as artifact:
```
mcp__pepper__upload_artifact({
  file_path: "/workspace/group/content/drafts/[topic]-bundle.md",
  title: "Content Bundle: [Topic]"
})
```
