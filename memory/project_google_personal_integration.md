---
name: Google Personal Account Integration
description: Personal Gmail + Calendar (1srahman@gmail.com) added via @aaronsb/google-workspace-mcp MCP server alongside work claude.ai integration
type: project
---

Personal Google account (1srahman@gmail.com) integrated via hybrid approach:
- **Work**: claude.ai built-in integration (srahman@ripple.com) — gcal_list_events, gmail_search_messages
- **Personal**: @aaronsb/google-workspace-mcp stdio MCP server — manage_calendar, manage_email

**Why:** User wanted full access to personal Gmail and Calendar alongside work, with clear [Work]/[Personal] demarcation across all POS skills.

**How to apply:** All skills (morning-plan, reflect, weekly-review, sync-meetings, prep) make TWO parallel queries — one per account — and tag results [Work] or [Personal]. Personal email actions route to Todoist "Personal" project. See CLAUDE.md Google Account Mapping section for tool details.

**Auth**: OAuth credentials in GCP project "breezy-490018", Desktop app type. client_secret.json at ~/.config/gws/. Authenticated via `gws auth login -s gmail,calendar`.
