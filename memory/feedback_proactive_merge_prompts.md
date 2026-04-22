---
name: Proactive merge/review prompts for agent-staged work
description: When agents produce output that needs user review/merge, surface it proactively at SessionStart, then morning-plan, then weekly-review (aging). Never silent.
type: feedback
originSessionId: 245a0e08-14ef-4018-b5b0-ef74e18e7628
---
When agents (Batch 4 / project orchestration) stage work for review, the system MUST surface pending work proactively — user will not remember to check staging directories.

**Why:** User's explicit requirement during the v1.7-v2.0 overhaul plan (2026-04-21): "I'm good with stage-only manual merge, but need to be proactively prompted when there is something to manually merge/review."

**How to apply:**
- SessionStart health panel scans every project's `.claude/staging/` directory. Pending work = `[ASK]` at the top of the session context.
- morning-plan "Around the Corner" always includes staged work if any exists (counts against the 2-item budget).
- weekly-review surfaces staged work older than 3 days as aging: `[ASK] N units staged 4+ days ago. Merge, discard, or snooze?`
- Never rely on the user discovering pending merges on their own.
- Applies to: dispatched agent output, staged code changes, staged Obsidian notes, any artifact produced by background autonomous work.
