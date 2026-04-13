---
name: Multi-project architecture — Obsidian as shared layer, global skills for universal tools
description: Projects are independent workspaces. Obsidian vault is the shared data layer. Universal skills (/idea, /kb) go in ~/.claude/. Project-specific workflows stay in their project.
type: feedback
---

Multi-project architecture decided 2026-03-25:

**Shared layers:**
- Global CLAUDE.md (~/.claude/CLAUDE.md) = identity, voice, preferences — loads everywhere
- Obsidian vault (~/Documents/PersonalOS/) = shared memory — any project can read/write
- Global skills (~/.claude/skills/ + commands/) = /idea, /kb — available from any project

**Project-specific:**
- Project CLAUDE.md = project tools, instructions, shared context references
- Project skills = workflows that depend on project-specific services (morning-plan, reflect, sync-meetings)

**Why:** Projects are workspaces, not silos. Don't build cross-project skill imports — just share data (Obsidian) and identity (global CLAUDE.md). Promoted /idea and /kb to global because they write to Obsidian and are useful from any project.

**How to apply:** When creating a new skill, evaluate if it's universal (→ global) or project-specific. Skills that touch the Obsidian vault are almost always global candidates. Added "Skill Development Convention" to global CLAUDE.md to enforce this at creation time.
