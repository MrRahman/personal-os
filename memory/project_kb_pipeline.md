---
name: KB pipeline — automated with Obsidian PKM
description: Full knowledge base pipeline is automated inside /morning-plan — Readwise inbox → Notion → Obsidian Resources/Topics. Daily routine is just /morning-plan + /reflect.
type: project
---

Knowledge base pipeline updated 2026-03-23:

**Automated flow (runs inside `/morning-plan` Step 2 — KB Sync):**
1. Capture: pulls from Readwise Reader **inbox** (location="new") — no archiving required, just save via share sheet
2. Triage: summarizes, tags, extracts insights, detects type, assigns topics
3. Obsidian PKM: creates Resource notes in `Resources/`, updates Topic MOC notes in `Topics/`
4. Todoist: proposes tasks for actionable items (user confirms)

**Obsidian PKM structure added:**
- `Resources/` — one note per KB item (article, video, tool) with tags like `#topic/AI #AI/agents #type/article`
- `Topics/` — Map of Content notes created on-demand, auto-populated with resource links
- Daily Note template updated with `### KB Highlights` section
- Templates added: `Resource.md`, `Topic.md`

**Tag system:** `#topic/TopicName` for broad topics, `#TopicName/tag-name` for specific tags (maps to Notion taxonomy), `#type/content_type` for content type.

**Daily routine:** Just 2 commands — `/morning-plan` (AM) and `/reflect` (PM). KB capture + triage + PKM creation all happen automatically inside morning-plan.

**Why:** User wanted maximum automation with minimum manual steps. The old flow required running `/capture` and `/triage` separately. Now everything is folded into the morning routine.

**How to apply:** `/capture` and `/triage` still exist as standalone skills for on-demand use. The full taxonomy of 18 topics and 60+ tags is defined in triage.md.
