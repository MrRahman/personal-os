---
name: feedback_completed_tasks
description: Always fetch completed tasks properly during /reflect — never estimate from incomplete task list
type: feedback
---

The Todoist `get_completed_tasks` MCP endpoint requires `since` and `until` as ISO datetime strings and `limit` as a number (not string — omit the param entirely, don't pass as string). When this call fails, do NOT silently skip it and estimate completions from the incomplete list — that dramatically undercounts.

**Critical: Use Pacific timezone offset, not UTC.** The user is in America/Los_Angeles (UTC-7 PDT). Querying with `Z` (UTC) shifts the day boundary by 7 hours, including yesterday's late-night tasks and missing today's evening tasks.

**Correct call:** `get_completed_tasks(since="YYYY-MM-DDT07:00:00Z", until="YYYY-MM-DDT+1T07:00:00Z")` — this maps midnight-to-midnight Pacific.

**Why:** User completed 10 tasks but API returned 9 (5 from previous day's late night) because UTC boundaries don't match Pacific day boundaries.

**How to apply:** In /reflect Step 2, always use timezone-adjusted boundaries. If it fails, retry with correct params. Never present a completion count based on inference.
