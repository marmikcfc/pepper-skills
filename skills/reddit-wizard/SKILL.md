---
name: reddit-wizard
description: Plan and draft high-performing Reddit posts that drive traffic to your product. Researches subreddits, analyzes top posts, builds a persona, and writes a story-driven post with subtle product placement.
metadata:
  openclaw:
    emoji: "🧙‍♂️"
---
# Reddit Wizard

Step-by-step Reddit growth workflow based on the "1M+ impressions in 30 days" playbook. Researches target subreddits, analyzes what works, builds a persona, and drafts a story post with subtle product placement. Uses Tavily, Olostep, and SearchAPI.

## Input

Ask the user for:
- **Product name and URL** (required)
- **One-line description of the product** (required)
- **Target ICP for THIS post** (required -- one specific persona, not a list)
- **Target subreddits** (optional -- will research and suggest if not provided)
- **Any specific angle or story idea** (optional)

## Step 1: Research Target Subreddits

If the user didn't provide subreddits, find 3-5 candidates. Run these in parallel:

```bash
# Find subreddits where the ICP hangs out
orth run tavily /search --body '{
  "query": "reddit best subreddits for [ICP description] 2025 2026",
  "search_depth": "basic",
  "max_results": 5
}'

# Find subreddits where similar products get discussed
orth run tavily /search --body '{
  "query": "reddit [product category] recommendations discussion subreddit",
  "search_depth": "basic",
  "max_results": 5
}'
```

For each candidate subreddit, scrape its page to assess fit:

```bash
# Check subreddit size, rules, activity
orth run olostep /v1/scrapes --body '{
  "url_to_scrape": "https://old.reddit.com/r/[subreddit]",
  "formats": ["markdown"]
}'
```

### Evaluate Each Subreddit

The best subreddits for this strategy have **low post volume relative to their subscriber count**. A subreddit with lots of readers but few daily posts gives your content much higher odds of being seen.

Score each subreddit on:

| Factor | What to look for | Good sign | Bad sign |
|--------|-----------------|-----------|----------|
| **Size** | Subscriber count | 50K-500K (sweet spot) | Under 5K (no reach) or 5M+ (too competitive) |
| **Post-to-subscriber ratio** | Posts per day vs. subscribers | Low posts relative to subscribers (e.g., university subs) | Flooded with posts (e.g., r/sideproject has a million posts a day) |
| **Mod activity** | Removal rate, rules page | Mods not extremely active, rules against self-promo not strictly enforced | Strict no-promo rules actively enforced |
| **Top post style** | What gets upvoted | Story posts, personal wins, advice | Memes, images, link-only posts |
| **Audience match** | Who comments | Your exact ICP | Wrong demographic |

No matter how good your content is, it doesn't matter if no one sees it. Prioritize subreddits where you can actually cut through the noise.

Present the top 3-5 subreddits as a ranked table and let the user pick 1-3 to target. Having 3-5 options is important because you'll likely need to workshop content across multiple subreddits.

## Step 2: Analyze Top Posts in Target Subreddit

Scrape the top posts to understand what works:

```bash
# Top posts of the month
orth run olostep /v1/scrapes --body '{
  "url_to_scrape": "https://old.reddit.com/r/[subreddit]/top/?t=month",
  "formats": ["markdown"]
}'

# Hot posts right now
orth run olostep /v1/scrapes --body '{
  "url_to_scrape": "https://old.reddit.com/r/[subreddit]/hot",
  "formats": ["markdown"]
}'
```

Also search for posts similar to the angle the user wants:

```bash
orth run tavily /search --body '{
  "query": "site:reddit.com/r/[subreddit] [topic related to product angle]",
  "search_depth": "basic",
  "max_results": 5
}'
```

### Extract Patterns

From the scraped top posts, analyze and report:

**Titles:**
- Average length (words)
- Common patterns (numbers? questions? emotional triggers? all caps?)
- Are they detailed?
- Do they follow a pattern?
- Examples of the top 5 titles

**Hooks (first 2-3 lines):**
- What grabs attention in the first few lines?
- Are they personal, emotional, polarizing, or unexpected?
- Tone (casual, excited, vulnerable, frustrated, controversial)

**Format:**
- Average post length
- Are they broken into sections?
- Use of headers, bold, italics, lists, line breaks
- Story structure (chronological? problem-solution? listicle?)

**Personas:**
- Who is posting the top content (students, founders, employees, hobbyists)
- What tone do they use
- How much personal detail do they share

**Links:**
- Do top posts include links? How many? Where are they placed?
- Do linked posts get more or fewer upvotes than text-only?

Present this as a structured analysis the user can reference while writing.

## Step 3: Build the Persona

Based on the subreddit analysis and the user's ICP, create a detailed persona for the post author. Redditors hate inauthentic posts. The only way to fake being authentic is to come up with a persona and write the post entirely from that person's perspective.

### Persona Research

```bash
# Research what this persona type talks about on Reddit
orth run tavily /search --body '{
  "query": "site:reddit.com [persona type] [subreddit topic] experience story",
  "search_depth": "basic",
  "max_results": 5
}'
```

### Persona Card

Generate a persona card with:

```
## Persona for r/[subreddit]

**Who you are:** [Age, role, situation -- e.g., "26-year-old SDR at a mid-stage B2B startup"]
**Your problem:** [What struggle are you posting about -- must be real to this persona]
**Your tone:** [How this person writes on Reddit -- casual, detailed, excited, frustrated]
**Your credibility:** [Why the subreddit would trust you -- you're one of them]
**Details to include:** [2-3 specific life details that make the persona feel real]
**Details to avoid:** [Anything that would break the illusion]
```

Do not cut corners on this step. If you can't truly imagine yourself living a day as this persona, the post will fail. Think about how a person with the problem/story in the post would naturally encounter and use the product.

## Step 4: Draft the Post

Using the subreddit patterns, persona, and product context, draft a Reddit post. **IMPORTANT: Write the base story first without AI assistance as much as possible.** Redditors can sense AI-written content. Draft the core story from scratch, then use AI only to polish formatting at the end.

### Title
- Emotional, specific, uses patterns from top posts
- Examples: "Finally [achieved thing] after [struggle]!!!", "How I [result] in [timeframe]", "[Number] things I wish I knew about [topic]"

### Opening Paragraph (The Hook)
- Introduce the persona with 2-3 personal details (age, role, situation)
- Give a short summary of what the story is about to give readers a roadmap
- This ensures the only readers are people who want to see you succeed -- anyone not interested leaves, preventing negative comments and downvotes
- Keep it under 4 sentences

### The Story (Body)
- Write the story of how the persona solved their problem
- Do NOT mention the product by name in the story
- Write in first person, conversational tone
- Include specific details (dates, numbers, emotions)
- No AI-sounding language (no em dashes, no "landscape", no "leverage", no "streamline", no "navigate", no "I'd be happy to")

### The Product Mention (Subtle)
- Embed the product as ONE of 3 links in the story
- The product should appear as something the persona discovered naturally, not the hero of the story
- The other 2 links should be to real, relevant tools/resources (not competitors)
- The reason for 3 links: it distracts attention from promoting your product. Redditors who sense a promotion will kill your post. With 2 other links, it looks much more like a realistic post, and your brand only has a 1/3 chance of being harmed if the post is viewed as inauthentic.
- Place links where they feel organic to the story

### Advice Section
- 4-6 numbered tips based on the persona's experience
- Practical, specific, genuinely useful
- Product can be mentioned in ONE tip as a tool that helped

### Closing
- Short, encouraging, community-oriented
- No CTA to your product
- Something like "Hope this helps someone out there"

### Final Polish
After the base draft is written, use AI to:
- Add Reddit markdown formatting (headers with ##, bold with **, lists with -, line breaks between sections)
- Clean up grammar and flow
- Make sure the tone is consistently human (no AI-sounding phrases slipped in)

### Post Rules

1. **No AI language.** No em dashes (--), no "leverage", no "streamline", no "navigate", no "I'd be happy to". Write like a real person.
2. **3 links max.** 1 to your product, 2 to other real tools/resources.
3. **Product mention should be casual.** "Someone recommended [product] and it actually helped" not "I discovered this amazing tool called [product]!!!"
4. **Use Reddit markdown.** Headers with ##, bold with **, lists with -, line breaks between sections.
5. **Length: 300-600 words.** Long enough to be a real story, short enough that people finish it.
6. **No promotional language.** Never say "check it out", "game-changer", "highly recommend". Let the story speak.

## Step 5: Posting & Monitoring

After drafting, present a posting strategy:

### Timing
- Post between 9AM-8PM in target audience's timezone
- Weekdays may have a slight edge, but don't delay a good post just to wait
- Make sure you have at least 4 hours after posting to monitor
- **Use Reddit's Markdown editor, not Fancy Pants** -- Fancy Pants can break formatting on longer posts

### Verify It's Live
After posting:
1. Go to the subreddit and sort by "New"
2. Confirm your post shows up
3. If it's missing, two scenarios:
   - **You got a removal notification** -- read the reason, politely message the mods asking them to reconsider
   - **No notification at all** -- your account is likely shadowbanned. No quick fix; you need to build more organic activity (comments, upvotes) before trying again

### First Hour (Critical)
- Get 3-5 initial upvotes from team/friends to seed the algorithm
- Monitor every 10 minutes
- Reply to every single comment -- comments are a factor in Reddit's algorithm, and engagement makes the persona feel real
- If negative sentiment appears, delete the post immediately
- **If not in the top 5 of Hot after 60 minutes, delete and iterate**

### After First Hour
- Check in every hour, making sure sentiment stays positive
- As soon as sentiment turns negative, delete the post
- This is a volume game -- don't feel bad about deleting

### Account Rules
- **Only 1 live post per Reddit account at a time.** If you want to run multiple posts, use separate accounts or get friends to post.
- Account must be 30+ days old with ~20+ karma to post in most subreddits
- Account history should NOT be all about your product -- Redditors will check your history and kill your post if it looks like a shill account
- If you need more accounts, buy aged accounts ($10-20 extra). Aging new accounts yourself is too much effort.

### Pre-Post Checklist

```
### Account Ready?
- [ ] Account is 30+ days old
- [ ] Account has 20+ karma
- [ ] Account has post/comment history in target subreddit (or similar ones)
- [ ] Account history is NOT all about your product

### Post Ready?
- [ ] Title matches patterns that work in this subreddit
- [ ] Opening hook is personal and specific
- [ ] Story feels authentic (could a real person have written this?)
- [ ] Product mention is subtle (1 of 3 links)
- [ ] No AI-sounding language
- [ ] Formatted in Reddit markdown (using Markdown editor, not Fancy Pants)
- [ ] Read it out loud -- does it sound like a real person?
```

## Step 6: Iteration Plan

Also provide an iteration plan:

### If the Post Flops

| Symptom | Diagnosis | Fix |
|---------|-----------|-----|
| No upvotes | Story not engaging | Stronger hook, better storytelling, more research |
| Upvotes but low views | Competitive subreddit | Try a different subreddit, recruit friends to upvote |
| Negative comments | Too promotional | Make product mention more subtle and natural |
| No link clicks | Product not tied to story | Rewrite the section where product appears |
| Removed by mods | Broke subreddit rules | Read rules again, message mods, try different sub |

**Delete the failed post**, figure out what went wrong, tweak, and try again in one of the other subreddits you shortlisted. No one remembers failed posts, so don't be afraid to post daily -- just delete the previous one to avoid leaving a visible trail.

### If It Goes Viral

Even if it goes viral, **delete the post after 48 hours** and start planning the next move. Two options:

1. **Keep post, kill the account** -- flood the account with 10-20 unrelated posts to mask the promotion. Good for SEO juice.
2. **Delete post, crosspost variants** -- rewrite for other subreddits on your list. Better for total reach. (This is usually the better play.)

**Rule of thumb: max 3 viral posts per angle, then move to a fresh concept for a month.** This keeps accounts from being banned or discovered by Redditors.

## Output Format

Present the full workflow as sections the user works through:

```
## Reddit Wizard: [Product Name] in r/[subreddit]

### Subreddit Analysis
[Ranked table of subreddits with scores]

### Top Post Patterns
[Title patterns, hook styles, format, personas, link usage]

### Your Persona
[Persona card]

### Draft Post
**Title:** [title]
**Subreddit:** r/[subreddit]

[Full post in Reddit markdown]

### Posting Strategy
[Timing, verification, monitoring plan]

### Pre-Post Checklist
[Checklist]

### Iteration Plan
[What to do if it flops or goes viral]
```

## Tips

- **One ICP per post.** Don't try to appeal to everyone. Pick one persona and commit.
- **Delete failed posts.** No evidence = no harm. This is a volume game.
- **The persona is everything.** If you can't live a day as this person, the post will feel fake.
- **3 links, not 1.** Two decoy links protect your brand if the post gets called out.
- **Write the story yourself first.** Use AI only to polish formatting. Redditors can smell AI-written content.
- **Monitor actively.** The first hour decides everything. Be ready to engage or delete.
- **Reply to every comment.** Comments boost the algorithm AND make the persona feel real.
- **Max 3 viral posts per concept.** Then rotate to a new angle for a month.
- **1 live post per account.** Use separate accounts if you want to run multiple posts.
- **Old Reddit for scraping.** old.reddit.com gives cleaner data than new Reddit.
- **Don't post and ghost.** The first hour of engagement is critical.
- **Delete after 48 hours.** Even viral posts should come down to protect the account.
