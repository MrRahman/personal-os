---
name: promote
description: Promote an idea from Obsidian Ideas/ to a full project — creates Obsidian project note, optional code directory scaffold, updates registry
---

# Promote Idea to Project

Promote a seed idea into a real project. Creates the Obsidian project note, optionally scaffolds a code directory with CLAUDE.md and agents/, updates the global registry, and links everything together.

## Instructions

### 1. Select Idea

If invoked with an argument (`/promote brain-wellness-app`), read that idea from `~/Documents/PersonalOS/Ideas/{arg}.md`.

If invoked bare (`/promote`), scan `~/Documents/PersonalOS/Ideas/` for all files. Read their frontmatter and list ideas with `status: seed`:

```
Which idea do you want to promote?
1. Brain Wellness App (seed, 2026-03-28)
2. Friend Hangout Scheduler (seed, 2026-03-28)
```

Let the user pick.

### 2. Read and Parse the Idea

Read the full idea file. Extract:
- **Title** — from the `# heading`
- **Spark** — the Spark section content
- **Why It Matters** — if present
- **Shape** — if present, including subsections
- **Open Questions** — extract any questions from Shape (lines starting with `- ` that end with `?`)
- **Topics** — from frontmatter
- **Tags** — from frontmatter
- **Connections** — from the Connections section (wikilinks to People, Resources, etc.)

### 3. Confirm Project Details

Present the idea summary, then ask the user to confirm or adjust:

- **Project slug** — suggest based on idea filename (e.g., `brain-wellness-app`)
- **Area** — `work` or `personal` (infer from idea content, confirm with user)
- **Target date** — optional
- **Stakeholders** — suggest from idea's Connections (People links), let user add/remove
- **Link to a Goal?** — read `~/Documents/PersonalOS/Goals/` for the current year's quarterly goal file (e.g., `2026-Q2.md`). List active goals and let the user optionally link this project to one.
- **Needs a code project directory?** — yes/no. If the idea has technical/build elements, suggest yes.
- If yes: **Tech stack** — ask what tech stack (e.g., "Next.js, TypeScript, Vercel" or "Python, FastAPI"). Used to populate the CLAUDE.md.

### 4. Project Kickoff Conversation (context development)

This is the critical step. Before writing any files, have a focused conversation with the user to develop the project's CLAUDE.md context. This is NOT a template fill — it's a collaborative dialogue.

**Read the full idea** (Spark, Why It Matters, Shape, Open Questions, Connections), then ask targeted questions to develop context. Adapt questions to the project type:

**For build/code projects, explore:**
- What's the MVP scope? What's v1 vs. later?
- Who are the users? What are the primary use cases?
- Architecture direction — monolith, services, frontend-only?
- Key constraints — timeline, budget, platform requirements?
- What existing patterns from your other projects should carry over?
- Any external APIs, services, or data sources?
- How will you test/validate this with real users?

**For work/strategic projects, explore:**
- What does success look like? How will you know it's working?
- Who are the key stakeholders and what do they care about?
- What's the timeline and are there hard deadlines?
- What are the dependencies and blockers?
- What artifacts need to be produced?

**Keep it conversational** — 3-5 questions max, let the user's answers guide follow-ups. The goal is to generate a rich, project-specific CLAUDE.md that gives Claude everything it needs to be useful on this project from day one.

### 5. Hire Agents

Before scaffolding, surface available agents and let the user select which ones to bring onto this project.

**Scan for agents:**
1. Read `~/.claude/project-registry.md` — find all projects with agents listed
2. Read `~/.claude/agents/` — list all global agent files
3. For each project with agents, read the agent files to get their descriptions

**Present available agents:**

```
Available agents across your projects:

Global (~/.claude/agents/):
  (none yet)

From auto-redesign:
  - designer — generates HTML design artifacts from creative briefs
  - judge — evaluates design artifacts for coherence and impact

Want to hire any of these for {project}? Or describe new agents you'd like to create.
```

**For each selected agent:**
- Copy the agent file into the new project's `agents/` directory
- Add it to the project's `agents/registry.md`

**For new agents the user describes:**
- Create a new agent file in the project's `agents/` directory using the standard format
- If the user says the agent should be global (usable across projects), also write it to `~/.claude/agents/`
- Add it to the project's `agents/registry.md`

### 6. Create Obsidian Project Note

Write to `~/Documents/PersonalOS/Projects/{slug}.md`:

```markdown
---
type: project
status: active
area: {area}
start_date: {today YYYY-MM-DD}
target_date: {target_date or empty}
topics:
{topics from idea, as yaml list with wikilinks}
stakeholders:
{stakeholders as yaml list with wikilinks}
code_project: {~/projects/{slug}/ if scaffolded, else empty}
source_idea: "[[Ideas/{idea-slug}]]"
---

# {Title}

## Overview
{Spark content}

{Why It Matters content, if present}

## Current Status
Newly promoted from idea. Not yet started.

## Key Decisions
-

## Open Questions
{Open questions extracted from idea's Shape section, as bullet list}
{If none found, leave as single dash}

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

### 7. Update the Idea Note

Edit the idea file:
- Change `status: seed` to `status: project`
- Set `project: "[[Projects/{slug}]]"`

### 8. Scaffold Code Directory (if confirmed)

If the user wants a code project directory, create at `~/projects/{slug}/`:

```
{slug}/
├── CLAUDE.md
├── README.md
├── .gitignore
├── .claude/
│   ├── skills/          (empty, ready for project-specific skills)
│   └── commands/        (empty, ready for project-specific commands)
└── agents/
    └── registry.md
```

**CLAUDE.md** — generate from the kickoff conversation (step 4), not a thin template. Include:

```markdown
# {Title} — Project Context

## What This Is
{Developed from kickoff conversation — scope, users, goals, constraints}

## Tech Stack
{From user's tech stack answer}

## Architecture
{From kickoff conversation — how the system is structured, key components}

## Key Decisions
{Decisions made during the kickoff conversation}

## Shared Context
- Obsidian vault: ~/Documents/PersonalOS/
- Project note: ~/Documents/PersonalOS/Projects/{slug}.md
- Original idea: ~/Documents/PersonalOS/Ideas/{idea-slug}.md

## Agents
{List hired agents with their purpose}
See agents/registry.md for full agent definitions.
See ~/.claude/agents/ for global agents usable across projects.
```

The CLAUDE.md should be rich enough that Claude can start contributing immediately without re-asking context questions. This is the most important output of `/promote`.

**README.md**:

```markdown
# {Title}

{Spark content from the idea}

## Status
Active — promoted from idea on {today}.

## Links
- [Project Note](~/Documents/PersonalOS/Projects/{slug}.md)
- [Original Idea](~/Documents/PersonalOS/Ideas/{idea-slug}.md)
```

**.gitignore**:

```
node_modules/
.env
.env.local
.env*.local
.DS_Store
dist/
build/
.next/
```

**agents/registry.md**:

```markdown
# Agent Registry — {Title}

## Project Agents
| Agent | File | Purpose |
|-------|------|---------|
| (none yet) | | |

## Global Agents (from ~/.claude/agents/)
Run `/discover` to populate this section.
```

Initialize git: `git init` in the project directory.

Create the empty directories: `.claude/skills/`, `.claude/commands/` (use `mkdir -p`).

### 9. Update Global Registry

Read `~/.claude/project-registry.md`. Append a new row for this project with:
- Project name
- Path (`~/projects/{slug}/` or "—" if no code dir)
- Obsidian note (`Projects/{slug}`)
- Skills (none initially)
- Agents (none initially)

### 10. Link to Goal (if selected)

If the user linked this project to a goal, edit the goal file (e.g., `~/Documents/PersonalOS/Goals/2026-Q2.md`):
- Find the selected goal section
- Add `**Projects:** [[Projects/{slug}]]` if not already present, or append to existing projects line

### 11. Summary

```
Project created: {Title}

Obsidian: ~/Documents/PersonalOS/Projects/{slug}.md
{Code dir: ~/projects/{slug}/ (if scaffolded)}
Idea updated: Ideas/{idea-slug}.md → status: project
{Goal linked: {goal name} (if linked)}
Registry updated: ~/.claude/project-registry.md

Next steps:
- cd ~/projects/{slug}/ to start building
- Add agents to agents/ as you define them
- Add skills to .claude/skills/ for project-specific workflows
```

## Notes
- All paths follow conventions in CLAUDE.md (dates: YYYY-MM-DD, slugs: lowercase-hyphens)
- The Obsidian project note's Dataview queries will automatically pick up related meetings, ideas, and people
- The idea's `project:` field creates the bidirectional link — the project's Related Ideas query finds it
- If the project already exists in Obsidian (e.g., a work project created by /reflect), skip step 4 and just update the existing note with `source_idea:` and `code_project:` fields
