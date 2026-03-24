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

Report which services are available. If Calendar or Todoist fail, warn the user that the plan will be incomplete. If Obsidian vault is unreachable, skip the meeting notes step (Step 6) with a warning. Continue with whatever works.

### 2. KB Sync (Capture + Triage)

Automatically capture new Readwise items and triage the Notion KB inbox. This runs silently — only pause for user confirmation on Todoist task creation (in Step 5).

**Phase A — Capture (Readwise → Notion):**

Skip if Readwise or Notion are unavailable. Otherwise:

1. Fetch `reader_list_documents(location="new", updated_after=7_days_ago, limit=50, response_fields=["url","title","author","category","tags","summary","reading_progress","published_date","saved_at","source_url"])`
2. For each item not already tagged `synced-to-notion`, fetch highlights: `reader_get_document_highlights(document_id)`. Batch in parallel.
3. Deduplicate against Notion KB by URL: prefer `source_url`, strip `utm_*`, `ref`, `source`, `fbclid`, `gclid` params, remove trailing slashes. Query Notion KB for matching URLs.
4. For new items: create Notion pages (Status="Inbox") using the same field mapping as `/capture` Step 6 (title, URL, type, date, summary, highlights as Key Insights).
5. Tag each captured Readwise item with `synced-to-notion`.

Track: `captured_count` (number of new items imported).

**Phase B — Triage (process Notion inbox + create Obsidian PKM notes):**

Skip if Notion is unavailable. Otherwise:

1. Query Notion KB for Status="Inbox" using `{ "property": "Status", "select": { "equals": "Inbox" } }` (Status is a **select** field). Limit to 10 items.
2. For each item:
   - **Fetch content** via WebFetch if the item has a URL. If fetch fails, proceed with title + existing summary.
   - **Detect Type:** Article, Video, Podcast, Book, Tool, Instagram, Threads, Twitter, Other
   - **Assign Topics** (1-3): AI, Crypto, Finance, Career, Leadership, Tech, Health, Fitness, Fashion, Travel, Food, Relationships, Productivity, Learning, Mindset, Culture, Sports, Music
   - **Auto-tag** (1-5) from the taxonomy in `/triage` Step 3d
   - **Summarize** (2-3 sentences, under 2000 chars)
   - **Extract insights** (2-4 key takeaways). If Key Insights field already has content from highlights, append under `**Claude's insights:**` header.
   - **Determine Action Required**: true for tools to try, techniques to implement, workflows to build, concepts to study. False for general interest.
3. Update each Notion item: Type, Topics, Tags, Summary, Key Insights, Action Required, Status ("Processed" or "Action Items"), Date Reviewed (today).
4. **Create Obsidian Resource note** for each triaged item at `~/Documents/PersonalOS/Resources/slug.md` (title-only slug, no date prefix — date is in frontmatter):

```markdown
---
date: {{date_captured}}
type: resource
content_type: {{type}}
source_url: {{url}}
notion_id: {{notion_page_id}}
topics:
  - {{topic1}}
tags:
  - {{tag1}}
---

# {{title}}

#topic/Topic1 #Topic1/tag1 #type/content_type

## Summary
{{summary}}

## Key Insights
{{key_insights}}

## My Notes
<!-- Your own thoughts, connections, applications -->

## Connections
<!-- Links to related People, Meetings, Projects, other Resources -->

## Source
[Original]({{url}})
```

Use the same slugification rules as meeting notes (lowercase, hyphens, strip special chars) but **without a date prefix** — the date is stored in frontmatter, not the filename.

5. **Update Topic MOC notes** — For each topic assigned, check if `~/Documents/PersonalOS/Topics/TopicName.md` exists. If not, create it from the Topic template. Append the new resource to the `## Resources` section:

```markdown
- [[Resources/YYYY-MM-DD-slug|Title]] — one-line summary #Tag1 #Tag2
```

Most recent first.

6. Collect action items (items where Action Required = true) for presentation in Step 5. Do **not** create Todoist tasks yet.

Track: `triaged_count`, `action_items` (list), `resource_notes_created` (count).

### 3. Gather Data

Run these in parallel:

**Calendar:** Use `gcal_list_events` to get today's events from ALL calendars. The user has both work (srahman@ripple.com) and personal (1srahman@gmail.com — free/busy only) calendars. Use timezone America/Los_Angeles. Get events for today's full day.

**Todoist:** Fetch open tasks that are:
- Priority 1, 2, or 3
- Due today or overdue
Also fetch any tasks due in the next 3 days for awareness.

**Gmail:** Use `gmail_search_messages` to find messages from the last 12 hours. Limit to 10 messages. Focus on unread or messages that may need a response.

**Slack:** Use `slack_search_public_and_private` to find mentions and DMs from the last 12 hours. Limit to 10 results.

**Notion:** Use `API-query-data-source` with the Data Source ID from CLAUDE.md to count items where Status = "Action Items" (items with pending Todoist tasks from triage). Use `{ "property": "Status", "select": { "equals": "Action Items" } }` (Status is a **select** field).

**Otter (if available):** Use `otter_list_transcripts` to check for any transcripts from yesterday that haven't been processed into Obsidian Meeting notes yet. Flag them as needing `/reflect` processing.

**iMessage (if available):** Use `extract_action_items(hours=24)` to scan the last 24 hours of messages for potential requests, commitments, or action items. This is awareness only — present what's found, do not auto-create tasks.

### 4. Analyze

From the gathered data:

**Free slots:** Look at today's calendar and find gaps of 30 minutes or more. List them with start/end times.

**Task categories:**
- **Must Do:** P1 tasks + anything due today + urgent email/Slack items
- **Should Do:** P2-P3 tasks + items due in next 3 days
- **Could Do:** Lower priority items, KB inbox items

**Flags:** Identify anything needing immediate attention — urgent emails, direct Slack messages with questions, overdue P1 tasks.

### 5. Present

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
- iMessage: X potential action items (from [contact]: "preview...")

## KB Sync
- Captured: X new items from Reader
- Triaged: Y items (Z actionable)
- Resource notes created: X in ~/Documents/PersonalOS/Resources/
- [list of actionable items with proposed Todoist tasks]
- Create tasks? (y/n for each, or "create all")

## Coming Up (Next 3 Days)
- [upcoming deadlines and events worth knowing about]
```

Use 12-hour time format for display (e.g., 9:00 AM). Keep descriptions concise — one line per item.

### 6. Meeting Notes

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

### 7. Confirm & Save

After presenting the plan and creating any meeting notes, ask the user:

1. **"Create KB tasks?"** — If the KB Sync step found actionable items, confirm which Todoist tasks to create. Create confirmed tasks in the "Personal" project with the `learning` label (default p3, due next week). Include the Notion item URL in the task description. Update each Notion item's `Related Task` field with the Todoist task URL.

2. **"Write to Obsidian?"** — If yes, create or update `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`. Fill in the Plan section (Meetings, Must Do, Should Do, KB Highlights, Proposed Schedule) while preserving any existing content in other sections.

In the KB Highlights section, include wikilinks to Resource notes created in Step 2:

```markdown
### KB Highlights
- [[Resources/2026-03-23-article-slug|Article Title]] — one-line summary #topic/AI
- [[Resources/2026-03-23-tool-slug|Tool Name]] — one-line summary #topic/Tech
```

In the Meetings section, include wikilinks to any meeting notes created in Step 6:

```markdown
### Meetings
- 10:00 AM: [[Meetings/2026-03-20-q1-treasury-review|Q1 Treasury Review]]
- 2:00 PM: [[Meetings/2026-03-20-dentist-appointment|Dentist Appointment]]
```

Only link meetings where notes were created — skipped meetings are not linked.

3. **"Block focus time?"** — If yes, offer to create calendar events in free slots for deep work using `gcal_create_event`. Use 30-minute minimum blocks. Name them "Focus: [suggested task]".

## Notes
- All times in America/Los_Angeles
- Dates formatted as YYYY-MM-DD
- If a service is unavailable, skip its section with a brief note like "[Gmail unavailable — skipped]"
- Cap email and Slack results at 10 each to avoid context overflow
- Personal calendar events show as "busy" blocks — no titles or attendees visible
- Do not auto-create People notes — that is `/reflect`'s responsibility
- Reference CLAUDE.md for paths and conventions
