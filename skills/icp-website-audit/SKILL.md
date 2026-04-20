---
name: icp-website-audit
description: Audit a website's messaging alignment with a target ICP — does the copy speak to the right buyer, address their pain, and make the right promise? Use when asked to audit a website, review website messaging, or check if a site speaks to the ICP.
---

# ICP Website Audit

Audit a website's messaging to evaluate how well it speaks to your target ICP. Score messaging alignment and identify what's missing.

## When to Use
- "Audit our website for ICP fit"
- "Does [company]'s website speak to [buyer role]?"
- "Review the messaging on [website]"
- "Score this website's ICP alignment"

## Prerequisites
- `ORTHOGONAL_API_KEY`
- `ANTHROPIC_API_KEY`
- `PEPPER_EVENT_SECRET` + `PEPPER_CLOUD_URL` (for ICP context)

## Workflow

**Step 1: Load ICP context**
```bash
state_read() { curl -sf "$PEPPER_CLOUD_URL/api/state?path=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1")" -H "Authorization: Bearer $PEPPER_EVENT_SECRET" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content',''))"; }
ICP=$(state_read "strategy/icp.md")
```
If empty, ask user to describe their ICP before proceeding.

**Step 2: Screenshot for visual assessment**
```bash
orth run screenshot-website /screenshot \
  --body '{"url": "<website_url>"}'
```

**Step 3: Scrape website content**
```bash
orth run scrape "<website_url>" --body '{"format": "markdown"}'
orth run scrape "<website_url>/pricing" --body '{"format": "markdown"}'
```

**Step 4: SEO and technical audit**
```bash
orth run seo-analyzer /analyze \
  --body '{"url": "<website_url>"}'
```

**Step 5: LLM messaging audit**
Pass ICP + scraped content to Claude:
> "Audit this website's messaging against our ICP. Score each dimension 1-10 and explain:
> 1. Problem clarity — does the homepage clearly state who has what problem?
> 2. ICP specificity — does it speak to our specific buyer role and company type?
> 3. Value proposition clarity — is the core promise clear in 5 seconds?
> 4. Proof and credibility — do they have relevant social proof for our ICP?
> 5. CTA effectiveness — is the call to action appropriate for the buyer's stage?
> 6. Language alignment — does the copy use the language our ICP uses?
> 7. Overall messaging alignment score: X/10
> Top 3 specific improvements with example rewrites."

## Output
Website messaging audit with per-dimension scores, overall alignment score, and top 3 rewrite recommendations.
