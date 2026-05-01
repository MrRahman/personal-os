---
name: Never mix work and personal Google transports
description: Work Google (srahman@ripple.com) ONLY via claude.ai connectors; personal (1srahman@gmail.com) ONLY via google-personal MCP — they are different transports and cannot be swapped
type: feedback
---

Work and personal Google accounts use **different transports**, and they are not interchangeable:

- **Work — srahman@ripple.com**: ONLY `mcp__claude_ai_Gmail__*` and `mcp__claude_ai_Google_Calendar__*` (claude.ai desktop-app connectors). No `email` arg needed — the connector is pre-scoped.
- **Personal — 1srahman@gmail.com**: ONLY `mcp__google-personal__manage_*` with `email: "1srahman@gmail.com"` explicitly passed.

**Never** call `mcp__google-personal__manage_accounts` / `manage_email` / `manage_calendar` with `srahman@ripple.com`. The google-personal MCP authenticates via the "Breezy" OAuth app in GCP project `breezy-490018`, which is unverified. Ripple's Workspace admin blocks unverified third-party OAuth apps → `Error 403: access_denied`.

**Why:** The user hit this on 2026-04-17 when I incorrectly ran `manage_accounts(operation: "authenticate", email: "srahman@ripple.com")` and Google blocked it. They were frustrated because it looked like I was linking work data into a personal/unverified pipeline. This is both a correctness issue (403) and a trust issue (work data must stay on sanctioned Ripple-approved rails).

**How to apply:**
- When a skill needs work Gmail/Calendar data → use `mcp__claude_ai_Gmail__*` / `mcp__claude_ai_Google_Calendar__*`. Don't pass an `email` arg.
- When a skill needs personal Gmail/Calendar data → use `mcp__google-personal__*` with `email: "1srahman@gmail.com"`.
- Cross-account skills (morning-plan, reflect, sync-meetings) fire both transports in parallel and tag `[Work]` / `[Personal]`.
- If the user ever asks to "re-auth work Google" or "fix work calendar", the fix is in the claude.ai desktop app's Connectors panel, NOT `manage_accounts`.
- Personal account auth for `google-personal` is fine to run via `manage_accounts` with `email: "1srahman@gmail.com"` and `category: "personal"`.
