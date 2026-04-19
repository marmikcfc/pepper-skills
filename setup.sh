#!/usr/bin/env bash
# One-time script to vendor upstream skills.
# Run this once to populate skills/ from source repos.
# Requires: gh CLI authenticated.

set -euo pipefail

SKILLS_DIR="$(dirname "$0")/skills"

fetch_skillssh() {
  local slug="$1"          # e.g. "copywriting"
  local owner="$2"         # e.g. "coreyhaines31"
  local repo="$3"          # e.g. "marketingskills"
  local upstream_path="$4" # e.g. "skills/copywriting/SKILL.md"
  local tier="$5"          # prompt-only | data-powered | strategic
  local dir="$SKILLS_DIR/$slug"

  mkdir -p "$dir"

  echo "→ Fetching $slug from $owner/$repo..."
  if gh api "repos/$owner/$repo/contents/$upstream_path" \
    --jq '.content' 2>/dev/null | base64 -d > "$dir/SKILL.md" 2>/dev/null && [ -s "$dir/SKILL.md" ]; then
    echo "  ✓ $slug (fetched from upstream)"
  else
    # Create a stub if upstream fetch fails
    cat > "$dir/SKILL.md" << STUBEOF
# ${slug}

> **Stub:** This skill was not found at upstream source \`$owner/$repo/$upstream_path\`.
> Replace this file with the actual skill content.

## Description

Skill for: ${slug//-/ }

## Instructions

[Add skill instructions here]
STUBEOF
    echo "  ⚠ $slug (stub created — upstream not found)"
  fi

  cat > "$dir/manifest.json" << EOF
{
  "upstream": "$owner/$repo/$upstream_path",
  "upstream_url": "https://github.com/$owner/$repo/blob/main/$upstream_path",
  "tier": "$tier",
  "forked_at": "$(date +%Y-%m-%d)",
  "modified": false,
  "changes": null,
  "data_sources": [],
  "cost_estimate_usd": null
}
EOF
}

fetch_gooseskills() {
  local slug="$1"
  local goose_path="$2"    # e.g. "skills/capabilities/brand-voice-extractor"
  local tier="$3"

  local dir="$SKILLS_DIR/$slug"
  mkdir -p "$dir"

  echo "→ Fetching $slug from goose-skills..."
  if gh api "repos/gooseworks-ai/goose-skills/contents/$goose_path/SKILL.md" \
    --jq '.content' 2>/dev/null | base64 -d > "$dir/SKILL.md" 2>/dev/null && [ -s "$dir/SKILL.md" ]; then
    echo "  ✓ $slug (fetched from upstream)"
  else
    cat > "$dir/SKILL.md" << STUBEOF
# ${slug}

> **Stub:** This skill was not found at upstream source \`gooseworks-ai/goose-skills/$goose_path\`.
> Replace this file with the actual skill content.

## Description

Skill for: ${slug//-/ }

## Instructions

[Add skill instructions here]
STUBEOF
    echo "  ⚠ $slug (stub created — upstream not found)"
  fi

  cat > "$dir/manifest.json" << EOF
{
  "upstream": "gooseworks-ai/goose-skills/$goose_path",
  "upstream_url": "https://github.com/gooseworks-ai/goose-skills/tree/main/$goose_path",
  "tier": "$tier",
  "forked_at": "$(date +%Y-%m-%d)",
  "modified": false,
  "changes": null,
  "data_sources": [],
  "cost_estimate_usd": null
}
EOF
}

echo "=== Vendoring skills.sh (coreyhaines31/marketingskills) ==="

# 22 prompt-only skills from skills.sh
fetch_skillssh "copywriting"       "coreyhaines31" "marketingskills" "skills/copywriting/SKILL.md"       "prompt-only"
fetch_skillssh "copy-editing"      "coreyhaines31" "marketingskills" "skills/copy-editing/SKILL.md"      "prompt-only"
fetch_skillssh "marketing-psychology" "coreyhaines31" "marketingskills" "skills/marketing-psychology/SKILL.md" "prompt-only"
fetch_skillssh "social-content"    "coreyhaines31" "marketingskills" "skills/social-content/SKILL.md"    "prompt-only"
fetch_skillssh "content-strategy"  "coreyhaines31" "marketingskills" "skills/content-strategy/SKILL.md"  "prompt-only"
fetch_skillssh "pricing-strategy"  "coreyhaines31" "marketingskills" "skills/pricing-strategy/SKILL.md"  "prompt-only"
fetch_skillssh "marketing-ideas"   "coreyhaines31" "marketingskills" "skills/marketing-ideas/SKILL.md"   "prompt-only"
fetch_skillssh "cold-email"        "coreyhaines31" "marketingskills" "skills/cold-email/SKILL.md"        "prompt-only"
fetch_skillssh "email-sequence"    "coreyhaines31" "marketingskills" "skills/email-sequence/SKILL.md"    "prompt-only"
fetch_skillssh "ad-creative"       "coreyhaines31" "marketingskills" "skills/ad-creative/SKILL.md"       "prompt-only"
fetch_skillssh "paid-ads"          "coreyhaines31" "marketingskills" "skills/paid-ads/SKILL.md"          "prompt-only"
fetch_skillssh "ab-test-setup"     "coreyhaines31" "marketingskills" "skills/ab-test-setup/SKILL.md"     "prompt-only"
fetch_skillssh "launch-strategy"   "coreyhaines31" "marketingskills" "skills/launch-strategy/SKILL.md"   "prompt-only"
fetch_skillssh "seo-audit"         "coreyhaines31" "marketingskills" "skills/seo-audit/SKILL.md"         "prompt-only"
fetch_skillssh "ai-seo"            "coreyhaines31" "marketingskills" "skills/ai-seo/SKILL.md"            "prompt-only"
fetch_skillssh "programmatic-seo"  "coreyhaines31" "marketingskills" "skills/programmatic-seo/SKILL.md"  "prompt-only"
fetch_skillssh "schema-markup"     "coreyhaines31" "marketingskills" "skills/schema-markup/SKILL.md"     "prompt-only"
fetch_skillssh "sales-enablement"  "coreyhaines31" "marketingskills" "skills/sales-enablement/SKILL.md"  "prompt-only"
fetch_skillssh "lead-magnets"      "coreyhaines31" "marketingskills" "skills/lead-magnets/SKILL.md"      "prompt-only"
fetch_skillssh "customer-research" "coreyhaines31" "marketingskills" "skills/customer-research/SKILL.md" "prompt-only"
fetch_skillssh "analytics-tracking" "coreyhaines31" "marketingskills" "skills/analytics-tracking/SKILL.md" "prompt-only"
fetch_skillssh "page-cro"          "coreyhaines31" "marketingskills" "skills/page-cro/SKILL.md"          "prompt-only"

echo ""
echo "=== Vendoring goose-skills (prompt-only subset) ==="

# 9 prompt-only skills from goose-skills
fetch_gooseskills "brand-voice-extractor"  "skills/capabilities/brand-voice-extractor"  "prompt-only"
fetch_gooseskills "visual-brand-extractor" "skills/capabilities/visual-brand-extractor" "prompt-only"
fetch_gooseskills "email-drafting"         "skills/capabilities/email-drafting"          "prompt-only"
fetch_gooseskills "messaging-ab-tester"    "skills/composites/messaging-ab-tester"       "prompt-only"
fetch_gooseskills "campaign-brief-generator" "skills/composites/campaign-brief-generator" "prompt-only"
fetch_gooseskills "feature-launch-playbook"  "skills/composites/feature-launch-playbook"  "prompt-only"
fetch_gooseskills "lead-qualification"     "skills/composites/lead-qualification"        "prompt-only"
fetch_gooseskills "inbound-lead-triage"    "skills/composites/inbound-lead-triage"       "prompt-only"
fetch_gooseskills "paid-channel-prioritizer" "skills/composites/paid-channel-prioritizer" "prompt-only"

echo ""
echo "=== Done. Run 'git add skills/ && git commit -m ...' to commit ==="
