---
name: dev-tool-community-distribution
description: Generate platform-appropriate distribution content for dev/AI communities. Given one piece of content, produces tailored variants for HN, Reddit (LocalLLaMA, LangChain), Twitter dev threads, and Discord.
---
# Dev Tool Community Distribution

Turn a single piece of content — a blog post, product launch, demo, or feature release — into platform-native variants optimized for each dev and AI community. Each variant adapts tone, length, code presence, and calls-to-action for the specific community. No cross-posting generic content.

## When to Use

- Launching a new product, feature, or integration
- Publishing a technical blog post or tutorial
- Sharing a demo, benchmark, or case study
- Making a Show HN or community announcement
- Distributing a major release or milestone

## Prerequisites

- `ANTHROPIC_API_KEY` — used to generate each platform variant
- `ORTHOGONAL_API_KEY` — used to scrape URL content if a link is provided
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL` — for loading brand voice from state

## Workflow

```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
```

**Step 1: Get the source content**

Ask: "Paste the content you want to distribute, or provide a URL."

If a URL is provided:
```bash
orth run scrape /scrape \
  --body '{"url": "<url>", "format": "text"}'
```

**Step 2: Load context from state**

```bash
COMPANY=$(state_read "company/company.md")
POSITIONING=$(state_read "strategy/positioning.md")
```

Ask: "What is the target audience for this distribution? (e.g., 'developers building with LLMs', 'ML engineers', 'founders using AI tools')"

Ask: "Does this content include code, benchmarks, or a demo link? (yes/no) — helps tailor each variant."

**Step 3: Determine relevance per community**

For each platform, assess if the content is a fit:

- **Hacker News** — fits if: technical, novel, or has a "we built this" story. Not a fit if: pure marketing.
- **r/LocalLLaMA** — fits if: local models, inference, open weights, or self-hosting involved. Skip if pure SaaS.
- **r/LangChain** — fits if: agent frameworks, LLM orchestration, tooling, or integration with LangChain/LlamaIndex/etc.
- **r/MachineLearning** — fits if: novel architecture, benchmark, or research angle. Skip if pure product launch.
- **Twitter/X dev thread** — fits almost always for dev tools.
- **Discord** — fits if: you have a specific Discord server or community in mind.

Flag to the user which communities are a natural fit and which to skip.

**Step 4: Generate each platform variant**

Pass source content + context to Claude for each relevant platform:

> "Generate platform-native distribution content for a developer tool. Produce each variant separately, labeled clearly.
>
> **Source content:** {source_content}
> **Company context:** {company}
> **Positioning:** {positioning}
> **Target audience:** {target_audience}
> **Has code/demo/benchmark:** {has_code}
>
> Generate the following variants:
>
> ### 1. Hacker News — Show HN post
> Title (max 80 chars, must start with 'Show HN:' if showing a project, or 'Ask HN:' if asking).
> Body (200-400 words): What you built, why, key technical decisions, what's novel, honest limitations. HN voice: direct, technical, no marketing language, acknowledge tradeoffs.
>
> ### 2. r/LocalLLaMA post
> Title (engaging, specific, no clickbait).
> Body (150-300 words): Focus on local/self-hosted angle, performance, model compatibility, or inference quality. Community voice: enthusiastic about local AI, values benchmarks and specifics.
>
> ### 3. r/LangChain post
> Title (specific to what the integration or tool does).
> Body (150-250 words): Lead with the integration or workflow, include a code snippet if relevant (even pseudocode), focus on what it enables. Voice: practical, workflow-focused, welcomes contributions.
>
> ### 4. r/MachineLearning post (only if research/benchmark angle exists)
> Title (precise, academic-adjacent).
> Body (200-300 words): Lead with the technical contribution, include numbers, reference related work if relevant. Voice: rigorous, skeptical, values reproducibility.
>
> ### 5. Twitter/X developer thread
> 6-8 tweets. Tweet 1: bold hook (the insight or result). Tweets 2-6: expand — key technical details, one per tweet, use code blocks where relevant. Tweet 7: CTA (try it, star it, read the post). Tweet 8 (optional): reply bait question. Each tweet under 280 chars.
>
> ### 6. Discord message
> 3-5 sentences. Casual, community-native, no hard sell. Mention what's new, why it matters to this server's members, and a link. End with an invitation to try it or ask questions.
>
> For each variant: adapt tone, specificity, and CTA for that community. No generic cross-posting."

**Step 5: Show all variants**

Display all generated variants clearly labeled and separated.

Ask: "Want to adjust any variant? Specify the platform and what to change. Or say 'done' to finish."

Allow the user to iterate on specific variants. Once satisfied, the content is ready to post.

No state writes — these assets are for immediate use by the user.

## Output

6 platform-native content variants (HN, r/LocalLLaMA, r/LangChain, r/MachineLearning, Twitter thread, Discord) — each adapted for the community's tone, format, and expectations.
