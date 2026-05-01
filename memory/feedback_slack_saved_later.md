---
name: feedback_slack_saved_later
description: Slack is:saved API query is retired from daily skills — it returns ALL bookmarks not just Later items, and its scraping pattern triggers Enterprise Grid third-party-client detection
type: feedback
---

**Rule:** Do not use `slack_search_public_and_private(query="is:saved", ...)` in `/morning-plan`, `/reflect`, `/sync-meetings`, or any other skill. This query is retired from daily automation.

**Why:**
1. **Semantic mismatch:** `is:saved` returns ALL saved/bookmarked Slack messages, not just items in the user's "Later" list with due dates/reminders. User showed a screenshot on 2026-03 where the UI displayed 6 Later items but the API returned 20+ older bookmarks. The API cannot filter to reminder-based items.
2. **Detection trigger (2026-04-22 incident):** On Ripple Enterprise Grid, the `is:saved` query pattern was flagged as "third-party client" activity and signed the user out of Slack across all sessions (including desktop app). The Playwright-profile refresh pipeline fixed token extraction (Problem A) but not this detection (Problem B). See `memory/project_slack_auth_fix.md`.
3. **Replaced by workflow:** Actionable Slack items are now captured during the day via Todoist Quick Add (`Cmd+Shift+A`, paste Slack permalink). `/morning-plan` surfaces those tasks via the Todoist query with zero Slack API calls. See `memory/feedback_slack_todoist_capture.md`.

**How to apply:**
- Never reintroduce `is:saved` to skills unless the user has migrated to xoxp (User OAuth) tokens via Ripple IT approval.
- If a user asks Claude to "pull my Slack Saved items," answer: `is:saved` is retired for reliability; Slack Save for Later is now read-later only. Actionable items should be captured via Todoist Quick Add going forward, and Claude will surface them from Todoist in the next `/morning-plan`.
- If the user insists on a one-off manual Saved query, they can run it themselves in the Slack desktop app, not via MCP.
