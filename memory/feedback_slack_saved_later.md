---
name: feedback_slack_saved_later
description: Slack is:saved search returns ALL bookmarks, not just "Later" items with reminders — cannot reliably filter to reminder-based items via API
type: feedback
---

The `is:saved` Slack search query returns ALL saved/bookmarked messages, not just items in the "Later" list with due dates/reminders. The user's "Later" view in Slack shows items with specific due dates ("Overdue by 12 minutes", "Due in 1 day") which the API cannot filter for.

**Why:** User showed screenshot of their Slack "Later" list with 6 items (Desmond Fang, Maggie Marshall, Mariel Kelley, self/Hope thread, Tony O'Rourke #ai, Stephanie Tan x2) but the API returned 20 items including many older bookmarks without reminders.

**How to apply:** When presenting Slack Saved items in /morning-plan, note this limitation. Present the `is:saved` results but flag that they may include items without active reminders. The user should cross-reference with their actual Slack "Later" view. Consider filtering to items saved in the last 3-7 days to reduce noise, but acknowledge this is an approximation.
