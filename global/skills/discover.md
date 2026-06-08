---
name: discover
description: Scan all projects under ~/projects/ and rebuild the global project registry at ~/.claude/project-registry.md
---

# Discover Projects

Scan all project directories and rebuild the global project registry. Run this anytime to sync the registry with reality.

## Instructions

### 1. Scan Project Directories

List all directories under `~/projects/`. For each directory:

- Check if `CLAUDE.md` exists — read the first 5 lines to get the project title
- Check if `.claude/skills/` exists — list all `.md` files (skill names = filenames without extension)
- Check if `.claude/commands/` exists — list all `.md` files
- Check if `agents/` exists — list all `.md` files except `registry.md`
- Check if `~/.claude/agents/` exists — list global agents

### 2. Match to Obsidian Projects

For each discovered project directory, check if a matching Obsidian note exists at `~/Documents/PersonalOS/Projects/{slug}.md`. Record the match.

### 3. Rebuild Registry

Write `~/.claude/project-registry.md` with the full scan results:

```markdown
# Project Registry

Last updated: {today YYYY-MM-DD}

| Project | Path | Obsidian | Has CLAUDE.md | Skills | Agents |
|---------|------|----------|---------------|--------|--------|
| {name} | ~/projects/{slug}/ | Projects/{slug} | Yes/No | skill1, skill2 | agent1, agent2 |
```

Include ALL discovered projects, even those without CLAUDE.md or Obsidian notes.

### 4. Scan for Obsidian-Only Projects

Also scan `~/Documents/PersonalOS/Projects/` for project notes that have NO matching code directory. List these separately:

```markdown
## Obsidian-Only Projects (no code directory)
| Project | Obsidian Note | Status |
|---------|--------------|--------|
| {name} | Projects/{slug} | {status from frontmatter} |
```

### 5. List Global Agents

```markdown
## Global Agents (~/.claude/agents/)
| Agent | File | Description |
|-------|------|-------------|
| {name} | ~/.claude/agents/{file} | {description from frontmatter} |
```

If `~/.claude/agents/` doesn't exist or is empty, note: "(none yet)"

### 6. Update Per-Project Agent Registries

For each project that has an `agents/registry.md`, update the "Global Agents" section with the current contents of `~/.claude/agents/`.

### 7. Summary

```
Registry rebuilt: ~/.claude/project-registry.md

{N} code projects found
{M} Obsidian-only projects found
{X} global agents registered
{Y} project-level agents found across all projects
```

## Notes
- This is a read-and-write operation — it rebuilds the registry from scratch, not incrementally
- Safe to run anytime — it won't delete or modify any project files except registry files
- The registry is the source of truth for cross-project discovery
- Run after `/promote`, `/new-project`, or whenever you suspect the registry is stale
