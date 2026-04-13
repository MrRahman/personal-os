---
name: new-project
description: Create a new project from scratch — Obsidian project note, optional code directory scaffold, registry update. For projects that don't start as ideas.
---

# New Project

Create a new project without a prior idea. Use this for work initiatives, ad-hoc projects, or anything that doesn't start in the idea pipeline.

## Instructions

### 1. Gather Project Details

Ask the user for:

- **Project name** — what is this project?
- **Description** — 2-3 sentences on goal and scope
- **Project slug** — suggest from name (lowercase, hyphens)
- **Area** — `work` or `personal`
- **Target date** — optional
- **Topics** — 1-2 from standard taxonomy (AI, Crypto, Finance, Career, Leadership, Tech, Health, Fitness, Fashion, Travel, Food, Relationships, Productivity, Learning, Mindset, Culture, Sports, Music)
- **Stakeholders** — people involved (search `~/Documents/PersonalOS/People/` for matches)
- **Link to a Goal?** — read current quarterly goal file, list active goals
- **Needs a code project directory?** — yes/no
- If yes: **Tech stack** — what tech stack to note in CLAUDE.md

### 2. Create Obsidian Project Note

Write to `~/Documents/PersonalOS/Projects/{slug}.md`:

```markdown
---
type: project
status: active
area: {area}
start_date: {today YYYY-MM-DD}
target_date: {target_date or empty}
topics:
{topics as yaml list with wikilinks}
stakeholders:
{stakeholders as yaml list with wikilinks}
code_project: {~/projects/{slug}/ if scaffolded, else empty}
source_idea:
---

# {Project Name}

## Overview
{Description from user}

## Current Status
Newly created.

## Key Decisions
-

## Open Questions
-

## Resources

## Timeline
-

## Action Items (Dataview)
```dataview
TASK
FROM "Meetings"
WHERE contains(string(project), this.file.name) AND !completed
SORT file.mtime DESC
LIMIT 20
```

## Related Meetings (Dataview)
```dataview
TABLE date as "Date", file.link as "Meeting"
FROM "Meetings"
WHERE contains(string(project), this.file.name)
SORT date DESC
LIMIT 15
```

## Related Ideas (Dataview)
```dataview
LIST
FROM "Ideas"
WHERE contains(string(project), this.file.name)
SORT date DESC
```

## Key People (Dataview)
```dataview
LIST
FROM "People"
WHERE contains(file.outlinks, this.file.link)
SORT file.mtime DESC
LIMIT 10
```
```

### 3. Scaffold Code Directory (if confirmed)

Same as `/promote` step 6. Create at `~/projects/{slug}/`:

```
{slug}/
├── CLAUDE.md
├── README.md
├── .gitignore
├── .claude/
│   ├── skills/
│   └── commands/
└── agents/
    └── registry.md
```

**CLAUDE.md**:

```markdown
# {Project Name} — Project Context

## What This Is
{Description from user}

## Tech Stack
{From user's answer}

## Shared Context
- Obsidian vault: ~/Documents/PersonalOS/
- Project note: ~/Documents/PersonalOS/Projects/{slug}.md

## Agents
See agents/registry.md for available agent definitions.
See ~/.claude/agents/ for global agents usable across projects.
```

**README.md**:

```markdown
# {Project Name}

{Description}

## Status
Active — created on {today}.

## Links
- [Project Note](~/Documents/PersonalOS/Projects/{slug}.md)
```

**.gitignore**: Standard (node_modules, .env, .env.local, .env*.local, .DS_Store, dist, build, .next)

**agents/registry.md**:

```markdown
# Agent Registry — {Project Name}

## Project Agents
| Agent | File | Purpose |
|-------|------|---------|
| (none yet) | | |

## Global Agents (from ~/.claude/agents/)
Run `/discover` to populate this section.
```

Initialize git: `git init` in the project directory.
Create empty directories: `.claude/skills/`, `.claude/commands/` (use `mkdir -p`).

### 4. Update Global Registry

Read `~/.claude/project-registry.md`. Append a new row for this project.

### 5. Link to Goal (if selected)

Same as `/promote` step 8.

### 6. Summary

```
Project created: {Project Name}

Obsidian: ~/Documents/PersonalOS/Projects/{slug}.md
{Code dir: ~/projects/{slug}/ (if scaffolded)}
{Goal linked: {goal name} (if linked)}
Registry updated: ~/.claude/project-registry.md

Next steps:
- cd ~/projects/{slug}/ to start building
- Add agents to agents/ as you define them
- Add skills to .claude/skills/ for project-specific workflows
```

## Notes
- For work projects that already have an Obsidian note (created by /reflect or manually), check if the file exists first and update it instead of overwriting
- All paths follow CLAUDE.md conventions
- This is the non-idea-originated version of /promote — same scaffolding, just no source idea to pull from
