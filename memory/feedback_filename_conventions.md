---
name: Filename conventions — no redundant date prefixes
description: Only use date prefixes in filenames when the date is the primary identifier or prevents collisions. Never duplicate metadata already in frontmatter.
type: feedback
---

Don't add date prefixes to filenames when the date is already a field in the note's frontmatter — it's noise.

**Why:** The user navigates Obsidian by search, links, and graph view, not by scrolling a sorted folder. Readable filenames matter more than chronological sorting.

**How to apply:**
- **Resources/** — title-only slug (e.g., `claude-obsidian-true-ai-employee.md`), no date
- **Meetings/** — keep date prefix because the same meeting title recurs weekly (e.g., `2026-03-23-weekly-1x1-sul-christina.md`)
- **Daily/** — date IS the filename, correct
- **Weekly Reviews/** — week number IS the filename, correct
- **People/, Topics/** — name-based, no date, correct

General rule: only use a date prefix when it serves as a **disambiguator** (recurring events) or **primary key** (daily notes). If the date is just metadata, put it in frontmatter only.
