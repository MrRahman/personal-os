---
name: feedback-work-readonly-personal-ok
description: Background automation may never send/delete/modify Ripple (work) items; personal-account mutations are acceptable
metadata:
  type: feedback
---

For the Personal OS v3.0 chief-of-staff redesign, the user authorizes autonomous/background automation **as long as it never sends, deletes, or modifies WORK (Ripple) items.** Work Google Calendar/Gmail (the claude.ai connector) and any Ripple data stay strictly **read-only** in all unattended runs.

**Personal-account mutations are acceptable** — the user is okay with the risk of the system creating/modifying personal calendar events, personal email drafts, personal Todoist tasks, and the Obsidian vault.

**Why:** Work data carries the highest blast radius — a wrong send/delete on Ripple's account is the costly, hard-to-undo failure. Personal data is the user's own low-stakes domain. This is the dividing line for what background agents may mutate.

**How to apply:** Headless/background `claude -p` allowlists must EXCLUDE every work-mutating tool — no `mcp__claude_ai_Google_Calendar__create_event/delete_event/update_event/respond_to_event`, no `mcp__claude_ai_Gmail__*` send/draft/label. Work tools allowed = read-only only (`list_events`, `list_calendars`, `search_threads`, `get_thread`). Personal mutations (`google-personal` create/modify, personal Todoist add/complete) MAY be allowlisted. Vault writes always allowed via the managed-block contract. The Bash permission rules deliberately allowlist only `launchctl` + the named wrapper scripts, never raw `claude`, so flags can't be widened ad hoc. See the v3.0 redesign plan's Safety posture.
