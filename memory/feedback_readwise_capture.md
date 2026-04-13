---
name: readwise_capture_always_runs
description: Readwise → Notion capture must execute during morning-plan, not just report counts — user never opens Readwise
type: feedback
---

Always execute the full Readwise → Notion capture flow (Phase A) during /morning-plan. Never just report "9 items pending" — actually sync them. The user never opens Readwise Reader; the whole point of the pipeline is that items flow automatically from Readwise → Notion → Obsidian without manual intervention.

**Why:** The capture pipeline was built specifically so the user never needs to open Readwise. Reporting a count without acting on it defeats the purpose of the automation.

**How to apply:** In /morning-plan Step 3 Phase A, always execute the full capture: fetch documents, fetch highlights, deduplicate against Notion, create Notion pages, tag as synced, archive in Reader. Do this silently before presenting the plan.
