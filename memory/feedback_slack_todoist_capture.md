---
name: feedback_slack_todoist_capture
description: Actionable Slack messages are captured via Todoist Quick Add (paste permalink) during the day, not via Slack Save for Later + API scraping
type: feedback
---

**Rule:** For actionable Slack messages, use Todoist Quick Add (`Cmd+Shift+A` on macOS, or the Todoist browser extension) and paste the Slack permalink. Reserve Slack Save for Later for read-later content only (articles, reference threads, non-actionable context).

**Why:**
- Slack's `is:saved` API is unreliable on Ripple Enterprise Grid (returns all bookmarks, not just Later items) and its scraping pattern triggers third-party-client detection (see `memory/project_slack_auth_fix.md` Problem B + `memory/feedback_slack_saved_later.md`).
- Mixing "read later" and "action later" in the same Slack bucket forced `/morning-plan` to run expensive triage at morning time to separate them. Separating by intent AT CAPTURE eliminates the triage step entirely.
- Todoist is the authoritative action system. Capturing there directly means `/morning-plan` finds the task via its Todoist query (reliable, never breaks), not via any Slack API call (fragile).
- One-keystroke capture (Cmd+Shift+A) is the same friction as Slack's "Save for later." Same number of clicks, vastly better reliability.

**How to apply:**
- **During the day:** See actionable Slack message → `Cmd+Shift+A` → type a short title → paste Slack permalink → set priority (`p1`/`p2`/`p3`) and project (Work / Personal / Us) → Enter. Task lands immediately.
- **In morning-plan:** `/morning-plan` surfaces these tasks automatically in Must Do / Respond from the standard Todoist query. No Slack call involved.
- **For read-later content:** keep using Slack Save for Later. Process in-app on your own time. Claude does not triage these.
- **If tempted to reintroduce is:saved scraping:** don't. xoxp migration (via Ripple IT) is the only sanctioned path to re-add broad Slack queries. See `docs/mcp-setup-slack-and-work-gmail.md` "Known blockers."

**Escape hatch — priority-channel mentions are still automated.** The behavioral shift applies to user-curated saves, not to @mentions. `/morning-plan` still runs ONE scoped Slack call per day to pull mentions/DMs in priority channels (whitelist in `CLAUDE.md` → `## Slack Priority Channels`). Mentions outside priority channels are handled by the user in-app via Slack's native notifications.
