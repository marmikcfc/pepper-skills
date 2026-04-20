# pepper-skills

Pepper's official skills catalog — the backend for `agentskills.io`.

Skills hosted here are available to any Pepper agent via:
`https://agentskills.io/<skill-name>`

## Structure

```
skills/
  <skill-name>/
    SKILL.md         -- skill prompt and metadata
    manifest.json    -- upstream source, tier, cost estimate
catalog.json         -- machine-readable index of all skills
setup.sh             -- vendor upstream skills from upstream repos
```

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md` with frontmatter:

```yaml
---
name: Human Readable Name
description: One-line description of what this skill does
---
```

2. Add it to `catalog.json`
3. Push to `main` — agents will pick it up on next startup

## CLI tools

`orth`, `exa`, `parallel`, `x-search` and other bash API wrappers live in
`pepper-railway/container/bin/` and are built into the Docker image.
They are no longer maintained here.
