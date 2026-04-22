---
name: Prefer fewer new slash commands; consolidate logic into existing skills
description: User has limited bandwidth to remember command surface. New capabilities should live inside existing skills or shared utilities, not new commands.
type: feedback
originSessionId: 245a0e08-14ef-4018-b5b0-ef74e18e7628
---
When adding a new capability to Personal OS, strongly prefer consolidating into existing skills (morning-plan, reflect, weekly-review, plan-week, etc.) or extracting to a shared utility (`mcp-servers/*.sh`). Only add a new slash command when the capability represents a genuinely distinct lifecycle that doesn't fit naturally inside an existing skill.

**Why:** User explicit preference during v1.7-v2.0 overhaul plan (2026-04-21): "would prefer fewer skills that I have to remember." Every new slash command is cognitive overhead — user has to recall when to invoke it. Consolidation keeps the command surface scannable.

**How to apply:**
- First default: can this logic live inside morning-plan / weekly-review / reflect?
- Second default: can this logic live in a shared utility (`mcp-servers/*.sh`) called by multiple skills?
- Third default: is this a genuinely distinct lifecycle (e.g., `/dispatch` for agent orchestration, separate from daily/weekly cadence)?
- Avoid: separate `/release-check`, `/doctor`, `/drift` commands — these are surfacing concerns, not lifecycles. Consolidate.
- `/dispatch` (Batch 4) was added as the one exception because agent orchestration is a distinct lifecycle with its own budget + safety rules.
