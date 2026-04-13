---
name: sync-meetings should run inside reflect
description: /sync-meetings should execute automatically as part of /reflect — user should never have to invoke it separately
type: feedback
---

Always run /sync-meetings as part of the /reflect flow (Step 5) without asking the user. Don't prompt "want me to run /sync-meetings?" — just do it.

**Why:** The user considers meeting transcript sync a natural part of the daily reflection. Asking whether to run it adds friction and an unnecessary decision point.

**How to apply:** During /reflect, after presenting the reflection and collecting check-in scores, automatically invoke /sync-meetings for today's date. Only skip if Otter is unavailable (detected in preflight).
