---
name: founder-voice-amplifier
description: Turn one founder post into 10 derivative content assets in the founder's voice — threads, LinkedIn posts, email, Reddit, and hook variants.
---
# Founder Voice Amplifier

Take a single piece of founder content and generate 10 derivative assets across every major distribution channel — all in the founder's authentic voice. Reduces the cost of distribution from "write 10 posts" to "write one post."

## When to Use

- Publishing a new piece of content and want to distribute it across channels without rewriting from scratch
- Have a good LinkedIn post and want the Twitter thread, email version, and Reddit angle
- Want to test multiple hooks on the same underlying idea
- Warming up a new channel with existing content

## Prerequisites

- `ORTHOGONAL_API_KEY` — used to scrape URLs if a link is provided
- `ANTHROPIC_API_KEY` — used to extract voice and generate assets

## Workflow

**Step 1: Get the source content**

Ask: "Paste the source post or provide a URL."

If a URL is provided, scrape it:
```bash
orth run scrape /scrape \
  --body '{"url": "<url>", "format": "text"}'
```

**Step 2: Load brand voice**

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }

BRAND_VOICE=$(state_read "strategy/brand-voice.md")
```

If `BRAND_VOICE` is empty, use the `brand-voice-extractor` skill on the source post to derive voice attributes before generating.

**Step 3: Extract voice if needed**

If no brand voice document exists, pass the source post to Claude:

> "Analyze this post and extract the author's writing voice. Describe: sentence length patterns, vocabulary level (casual/technical/mixed), use of first person, emotional register (analytical/passionate/dry/warm), structural habits (lists vs prose, use of line breaks), any recurring phrases or stylistic tics. Return as a brief voice guide (under 150 words)."

**Step 4: Generate 10 assets**

Pass source content + voice guide to Claude:

> "Using the brand voice guide below, rewrite this source content into 10 derivative assets. Maintain the author's authentic voice throughout — do not sanitize or genericize it.
>
> **Voice guide:** <voice_guide>
>
> **Source content:** <source_content>
>
> Generate:
> 1. **Twitter/X thread** — 5-7 tweets. Hook tweet + body tweets + CTA tweet. Each tweet under 280 chars.
> 2. **LinkedIn long-form post** — 300-500 words. Story arc: hook → insight → proof → takeaway → CTA.
> 3. **LinkedIn short post** — under 150 words. Punchy, high white space, direct.
> 4. **Email newsletter section** — 250 words. Conversational, personal, like writing to one person.
> 5. **Reddit comment** — subreddit-native tone. No self-promotion. Adds genuine value to a thread. Under 200 words.
> 6. **Instagram caption** — visual-first framing, 2-3 sentences, 5-8 relevant hashtags.
> 7. **Hook variant A** — curiosity-gap opening line only (rewrite just the first sentence/tweet).
> 8. **Hook variant B** — bold claim opening line only.
> 9. **Hook variant C** — story opening line only ('I used to think...' / 'Last week...' / 'Three years ago...').
> 10. **TL;DR summary** — 3 bullet points, each under 15 words.
>
> Label each asset clearly. Return as clean markdown."

**Step 5: Present all 10 assets**

Show the full output to the user. No state write needed — these assets are for the user to copy, edit, and publish directly.

## Output

10 labeled derivative content assets in the founder's voice: Twitter thread, two LinkedIn variants, email section, Reddit comment, Instagram caption, three hook variants, and a TL;DR.
