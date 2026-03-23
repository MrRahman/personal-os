---
name: morning-plan
description: Generate a comprehensive morning plan by pulling data from Calendar, Todoist, Gmail, Slack, and Notion, then create meeting notes in Obsidian
---

# Morning Plan

Generate a structured morning plan by gathering data from all connected services, then optionally create meeting notes for the day.

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
| Obsidian vault | Read `~/Documents/PersonalOS/Templates/Meeting Note.md` | No |
| Readwise | `reader_list_documents` (limit 1) | No |
| iMessage | `list_conversations` (limit 1) | No |

Report which services are available. If Calendar or Todoist fail, warn the user that the plan will be incomplete. If Obsidian vault is unreachable, skip the meeting notes step (Step 5) with a warning. Continue with whatever works.

### 2. Gather Data

Run these in parallel:

**Calendar:** Use `gcal_list_events` to get today's events from ALL calendars. The user has both work (srahman@ripple.com) and personal (1srahman@gmail.com — free/busy only) calendars. Use timezone America/Los_Angeles. Get events for today's full day.

**Todoist:** Fetch open tasks that are:
- Priority 1, 2, or 3
- Due today or overdue
Also fetch any tasks due in the next 3 days for awareness.

**Gmail:** Use `gmail_search_messages` to find messages from the last 12 hours. Limit to 10 messages. Focus on unread or messages that may need a response.

**Slack:** Use `slack_search_public_and_private` to find mentions and DMs from the last 12 hours. Limit to 10 results.

**Notion:** Use `API-query-data-source` with the Data Source ID from CLAUDE.md. Filter for Status = "Inbox" using `{ "property": "Status", "select": { "equals": "Inbox" } }` (Status is a **select** field, not a status field). Also count items where Action Required = true.

**Otter (if available):** Use `otter_list_transcripts` to check for any transcripts from yesterday that haven't been processed into Obsidian Meeting notes yet. Flag them as needing `/reflect` processing.

**iMessage (if available):** Use `extract_action_items(hours=24)` to scan the last 24 hours of messages for potential requests, commitments, or action items. This is awareness only — present what's found, do not auto-create tasks.

**Readwise (if available):** Run in parallel:
- `reader_list_documents(location="archive", limit=5)`
- `reader_list_documents(location="shortlist", limit=5)`

Count items not yet tagged with `synced-to-notion` (i.e., not yet captured to KB). This is awareness only — do not auto-import.

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
[personal calendar events show as "Personal block: HH:MM - HH:MM (busy)"]

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
- iMessage: X potential action items (from [contact]: "preview...")
- Readwise: X items not yet in KB. Run `/capture` to sync.

## Coming Up (Next 3 Days)
- [upcoming deadlines and events worth knowing about]
```

Use 12-hour time format for display (e.g., 9:00 AM). Keep descriptions concise — one line per item.

### 5. Meeting Notes

If Obsidian vault is available, walk through today's meetings and offer to create meeting notes. Skip all-day events, declined events, and cancelled events.

**Present the full meeting list and collect responses in a batch:**

```
## Meeting Notes

Which meetings need notes? (y/n for each, or "skip all")

1. [y/n] 10:00 AM — Q1 Treasury Review (Jane Smith, Bob Chen, Sarah Lee)
2. [y/n] 11:30 AM — Team Standup (full team)
3. [y/n] 2:00 PM — Personal block (busy)
4. [y/n] 3:30 PM — 1:1 with Sarah Lee
```

**For work calendar events:** show title + attendees. If user says yes, create note with context.

**For personal calendar events (free/busy only):** show as "Personal block (busy)". If user says yes, ask: "What's the meeting name?" Then create note with just the template (no attendees or context lookup).

**If user says "skip all":** list what was skipped ("Skipped notes for: 11:30 AM Team Standup, 3:30 PM 1:1 with Sarah Lee").

**After collecting all responses, create notes in parallel.**

#### Meeting note creation

**File:** `~/Documents/PersonalOS/Meetings/YYYY-MM-DD-slug.md`

**Filename slugification:** lowercase, replace spaces/colons/slashes with hyphens, collapse consecutive hyphens, trim leading/trailing hyphens, strip remaining special characters.
Examples: "1:1 with Jane" → `1-1-with-jane`, "Q1/Q2 Review" → `q1-q2-review`

**If file already exists:** warn and ask if they want to overwrite or skip.

**For work meetings — pre-fill:**

```markdown
---
date: YYYY-MM-DD
type: meeting
project:
attendees:
  - "[[People/Jane-Smith]]"
  - "[[People/Bob-Chen]]"
otter_id:
calendar: work
---

# Meeting Title

## Context
[2-3 sentence summary from context lookup — see below]

## Summary

## Key Points
-

## Action Items
- [ ]

## Follow-ups
- [ ]

## Transcript Highlights
-
```

Use `[[People/First-Last]]` wikilinks for attendees even if the Person note doesn't exist yet — links resolve once `/reflect` creates them.

**For personal meetings — minimal:**

```markdown
---
date: YYYY-MM-DD
type: meeting
project:
attendees:
otter_id:
calendar: personal
---

# User-Provided Title

## Context

## Summary

## Key Points
-

## Action Items
- [ ]

## Follow-ups
- [ ]

## Transcript Highlights
-
```

#### Context lookup (work meetings only)

For each work meeting, run these in parallel:

1. **Search People folder** — look for `People/First-Last.md` for each attendee (up to first 5 if 10+ attendees; note "and X others" in the note). Read Context and Key Topics sections if found.
2. **Search Meetings folder** — glob for recent meeting notes (last 30 days) and grep for attendee names. Note the meeting title and date if found.
3. **Calendar event description** — include if the event has one.

Synthesize into a 2-3 sentence Context block like:

> "Recurring weekly sync with Jane Smith (VP Treasury) and Bob Chen (Risk). Last met on 2026-03-13 for 'Treasury Pipeline Review' — discussed stablecoin custody requirements. Jane's key focus areas: regulatory compliance, APAC expansion."

If no prior context exists, write: "No prior meeting notes found for these attendees."

### 6. Confirm & Save

After presenting the plan and creating any meeting notes, ask the user:

1. **"Write to Obsidian?"** — If yes, create or update `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`. Fill in the Plan section (Meetings, Must Do, Should Do, Proposed Schedule) while preserving any existing content in other sections. In the Meetings section, include wikilinks to any meeting notes created in Step 5:

```markdown
### Meetings
- 10:00 AM: [[Meetings/2026-03-20-q1-treasury-review|Q1 Treasury Review]]
- 2:00 PM: [[Meetings/2026-03-20-dentist-appointment|Dentist Appointment]]
```

Only link meetings where notes were created — skipped meetings are not linked.

2. **"Block focus time?"** — If yes, offer to create calendar events in free slots for deep work using `gcal_create_event`. Use 30-minute minimum blocks. Name them "Focus: [suggested task]".

## Notes
- All times in America/Los_Angeles
- Dates formatted as YYYY-MM-DD
- If a service is unavailable, skip its section with a brief note like "[Gmail unavailable — skipped]"
- Cap email and Slack results at 10 each to avoid context overflow
- Personal calendar events show as "busy" blocks — no titles or attendees visible
- Do not auto-create People notes — that is `/reflect`'s responsibility
- Reference CLAUDE.md for paths and conventions
