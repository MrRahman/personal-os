---
name: morning-plan
description: Generate a comprehensive morning plan by pulling data from Calendar, Todoist, Gmail, Slack, and Notion
---

# Morning Plan

Generate a structured morning plan by gathering data from all connected services.

## Instructions

Follow these steps in order. Use parallel tool calls wherever possible to minimize latency.

### 1. Preflight Check

Test access to each service. For each, make one lightweight call:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Google Calendar | `gcal_list_events` (today, any calendar) | Yes |
| Todoist | List projects or tasks | Yes |
| Gmail | `gmail_search_messages` (limit 1) | No |
| Slack | `slack_search_public_and_private` (limit 1) | No |
| Notion | `search_objects` (limit 1) | No |
| Otter.ai | `otter_list_transcripts` (limit 1) | No |

Report which services are available. If Calendar or Todoist fail, warn the user that the plan will be incomplete. Continue with whatever works.

### 2. Gather Data

Run these in parallel:

**Calendar:** Use `gcal_list_events` to get today's events from ALL calendars. The user has both work (srahman@ripple.com) and personal (1srahman@gmail.com) calendars. Use timezone America/Los_Angeles. Get events for today's full day.

**Todoist:** Fetch open tasks that are:
- Priority 1, 2, or 3
- Due today or overdue
Also fetch any tasks due in the next 3 days for awareness.

**Gmail:** Use `gmail_search_messages` to find messages from the last 12 hours. Limit to 10 messages. Focus on unread or messages that may need a response.

**Slack:** Use `slack_search_public_and_private` to find mentions and DMs from the last 12 hours. Limit to 10 results.

**Notion:** Use Notion MCP to query the "AI Knowledge Base" database for items where Status = "Inbox" or Action Required = true.

**Otter (if available):** Use `otter_list_transcripts` to check for any transcripts from yesterday that haven't been processed into Obsidian Meeting notes yet. Flag them as needing `/reflect` processing.

### 3. Analyze

From the gathered data:

**Free slots:** Look at today's calendar and find gaps of 30 minutes or more. List them with start/end times.

**Task categories:**
- **Must Do:** P1 tasks + anything due today + urgent email/Slack items
- **Should Do:** P2-P3 tasks + items due in next 3 days
- **Could Do:** Lower priority items, KB inbox items

**Flags:** Identify anything needing immediate attention — urgent emails, direct Slack messages with questions, overdue P1 tasks.

### 4. Present

Display a clean, scannable plan:

```
# Morning Plan — YYYY-MM-DD (Day of Week)

## Today's Schedule
[chronological list of meetings with times, attendees, and which calendar they're from]

## Must Do
- [ ] task description (source: todoist/email/slack)
- [ ] ...

## Should Do
- [ ] task description
- [ ] ...

## Free Slots
- HH:MM - HH:MM (Xmin) — suggested use
- ...

## Inbox & Notifications
- [flagged emails with subject + sender]
- [slack messages needing response]
- [notion KB items in inbox]

## Coming Up (Next 3 Days)
- [upcoming deadlines and events worth knowing about]
```

Use 12-hour time format for display (e.g., 9:00 AM). Keep descriptions concise — one line per item.

### 5. Confirm & Save

After presenting the plan, ask the user:

1. **"Write to Obsidian?"** — If yes, create or update `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`. Fill in the Plan section (Meetings, Must Do, Should Do, Proposed Schedule) while preserving any existing content in other sections.

2. **"Block focus time?"** — If yes, offer to create calendar events in free slots for deep work using `gcal_create_event`. Use 30-minute minimum blocks. Name them "Focus: [suggested task]".

## Notes
- All times in America/Los_Angeles
- Dates formatted as YYYY-MM-DD
- If a service is unavailable, skip its section with a brief note like "[Gmail unavailable — skipped]"
- Cap email and Slack results at 10 each to avoid context overflow
- Reference CLAUDE.md for paths and conventions
