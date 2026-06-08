---
name: idea
description: Conversational idea capture — talk about an idea and Claude creates a linked note in Obsidian Ideas/
---

# Idea Capture

Capture ideas through conversation. The user talks, Claude synthesizes and creates a linked note in the Obsidian vault. 30 seconds from thought to linked note.

## Instructions

### 1. Capture

If the user invoked `/idea` with text (e.g., `/idea we should build an AI dashboard for QBR prep`), use that directly.

If invoked bare (`/idea`), ask: "What's the idea? Just tell me about it."

Let the user talk freely. Don't interrupt with structure. Listen for:
- What the idea is
- Why it matters (if mentioned)
- How it might work (if mentioned)
- Who's involved (if mentioned)

### 2. Synthesize

From the conversation, generate:

- **Title** — concise, descriptive (like a meeting note title)
- **Spark** — 2-3 sentences capturing the essence of the idea
- **Why It Matters** — 1-2 sentences if inferrable from context (leave blank if not)
- **Shape** — any concrete details, constraints, or questions mentioned (leave blank if not)
- **Topics** — 1-2 from the standard taxonomy (AI, Crypto, Finance, Career, Leadership, Tech, Health, Fitness, Fashion, Travel, Food, Relationships, Productivity, Learning, Mindset, Culture, Sports, Music)
- **Tags** — 1-3 from the tag taxonomy (see `/triage` skill for full list)
- **Source** — `conversation` (default), `meeting` (if extracted during /reflect), `reading` (if from KB), `reflection` (if from daily reflection)

### 3. Scan Vault for Connections

Search the vault for related content:
- **Meetings/** (last 30 days) — grep for keywords from the idea title/description
- **People/** — names mentioned in conversation or relevant to the topic
- **Resources/** — overlapping topics or tags
- **Projects/** — check if the idea relates to an active project. If match found, suggest linking via `project:` field.

Build 2-4 connection links.

### 4. Present and Confirm

Show the draft:

```
## New Idea: [Title]

**Spark:** [2-3 sentences]

**Why It Matters:** [1-2 sentences or "—"]
**Topics:** [topic1, topic2]
**Tags:** [tag1, tag2]
**Connections:**
- [[Resources/related-resource]]
- [[Projects/related-project]]
- [[People/Relevant-Person]]

Save to Ideas/[slug].md? (y/n/edit)
```

If "edit" — ask what to change. If "y" — write the file.

### 5. Write and Cross-Link

Create the file at `~/Documents/PersonalOS/Ideas/slug.md` using the Idea template.

**Filename:** title-only slug, no date prefix. Lowercase, hyphens, strip special chars.

After writing:
- If the idea was linked to a Project, no extra action needed — Dataview query on the Project note will pick it up.
- If the idea matches a Topic, consider the Topic MOC. The Dataview query on Topic MOCs will surface it automatically if topics match.

### 6. Summary

```
Idea saved: Ideas/[slug].md
Topics: [topic1, topic2] | Tags: [tag1, tag2]
Connections: X links added
```

## Notes
- The user should be able to capture an idea in under 30 seconds
- Don't over-structure seed ideas — Spark is the only required section
- Ideas are cheap — encourage capturing, not perfecting
- Status starts as `seed` always. User can promote to project via `/promote`.
- If the idea has a substantial Shape section (3+ subsections or 10+ lines), suggest at the end: "This looks ready to build. Run `/promote {slug}` when you want to turn it into a project."
- Reference CLAUDE.md for paths and conventions
