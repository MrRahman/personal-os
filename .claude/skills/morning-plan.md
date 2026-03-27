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

**Auto-populate `## Connections`:** After creating the Resource note, scan the vault for related content:
- **Search Meetings/** (last 30 days) — grep for keywords from the Resource's title and tags. If a meeting discussed this topic, add `[[Meetings/slug|Title]]` to Connections.
- **Search People/** — if the Resource mentions or is relevant to a known person (e.g., author is a contact, or topic matches a person's Key Topics), link them.
- **Search other Resources/** — find Resources with overlapping tags. If 2+ tags match, add as a related Resource link.
- Target 2-4 connection links per Resource. Only add clear, meaningful connections.

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

**Gmail:** Use `gmail_search_messages` to find messages since the last `/morning-plan` run. Default to `newer_than:24h` if no prior run date is known, but prefer `is:unread` to catch anything missed. Limit to 10 messages. **For any thread with an actionable subject (action requested, review, update tracker, etc.), use `gmail_read_thread` to read the full thread and extract action items** — don't rely solely on the snippet.

**Slack:** Use `slack_search_public_and_private` to find mentions and DMs since the last run. Default to `after:YYYY-MM-DD` using yesterday's date. Limit to 10 results.

**Notion:** Use `API-query-data-source` with the Data Source ID from CLAUDE.md to count items where Status = "Action Items" (items with pending Todoist tasks from triage). Use `{ "property": "Status", "select": { "equals": "Action Items" } }` (Status is a **select** field).

**Otter (if available):** Use `otter_list_transcripts` to check for any transcripts from yesterday that haven't been processed into Obsidian Meeting notes yet. Flag them as needing `/reflect` processing.

**iMessage (if available):** Use `extract_action_items(hours=24)` to scan the last 24 hours of messages for potential requests, commitments, or action items. This is awareness only — present what's found, do not auto-create tasks.

**Coverage principle:** All surfaces (Gmail, Slack, iMessage, Otter) should cover the period since the last `/morning-plan` or `/reflect` run — not a fixed time window. This prevents action items from falling through the cracks if a session runs at an unusual time. When in doubt, go wider (24h+) rather than narrower.

**Projects:** Read all files in `~/Documents/PersonalOS/Projects/`. For each with `status: active`:
- Extract `target_date` — flag if within 7 days
- Check if today's meetings relate to this project (match title/attendees)
- Note any open questions or recent status changes

**Goals:** Read `~/Documents/PersonalOS/Goals/` for the current quarter file (e.g., `2026-Q2.md`). For each goal section:
- Extract unchecked milestones with target dates
- Flag milestones due this week or overdue
- Flag goals with no related task activity in Todoist and no related meetings in the past 7 days ("Stale")
- Read the `This Week` section for any targets proposed by last week's `/weekly-review`
- Match goals to today's meetings via their linked Projects

#### 3a. Action Detection

After gathering data from Gmail, Slack, and iMessage, analyze each message for uncaptured work. **Time window:** since the last `/morning-plan` run (check the daily note's Plan section timestamp). Fall back to 24h if no prior run date is known.

For each Gmail thread and Slack message, classify as one or more of:

1. **Direct ask**: "Can you...", "Please send...", "Need you to...", "Would you be able to..."
2. **Question awaiting your response**: Someone asked you something and you haven't replied
3. **Commitment you made**: "I'll...", "Let me get back to you...", "I'll follow up on..."
4. **Deadline-bearing item**: Contains "by Friday", "before the offsite", "EOW", "end of week", specific dates
5. **FYI needing acknowledgment**: Shared a doc for review, asked "thoughts?", "let me know what you think", flagged something for your awareness
6. **CC'd thread where you should weigh in**: You're not the direct recipient but the topic maps to your domains (M&A integration, AI transformation, CEO ops) or involves your direct reports (Hope, Christina, David)
7. **Stale thread** (deep mode only): Conversation involving you that went quiet 3+ days without resolution

For iMessage: fold in results from `extract_action_items` directly — it already detects asks and commitments.

For each detected action, capture:
- **Source**: Gmail / Slack channel or DM / iMessage
- **From**: Person name
- **Ask**: One-line summary of what's needed
- **Deadline**: If mentioned (otherwise blank)
- **Detection type**: Which category (1-7) triggered it

#### 3b. Todoist Cross-Reference

For each detected action from 3a:

1. **Search Todoist** for existing tasks by keywords from the ask + person name. Use `get_tasks_list` with content search.
2. **Check today's calendar** — is this covered by a meeting today with the same person? If so, note "Covered in today's [meeting name]" instead of flagging as uncaptured.
3. **Check active Projects** — does this belong to an active workstream? If so, tag the action with the project name.

Classify each detected action as:
- **Already tracked**: Matching Todoist task found → skip
- **Covered by meeting**: Today's calendar has a meeting with this person on this topic → note it, don't flag
- **Uncaptured**: No match → include in Uncaptured Actions list

#### 3c. Meeting Attendee Batch Search

Collect unique attendees across ALL of today's confirmed meetings (deduplicate by name). For each unique person:

1. **Todoist**: Search for open tasks mentioning this person's name
2. **Obsidian Meetings/**: Grep for unchecked `- [ ]` items in meeting notes from the last 30 days where this person is an attendee
3. **Obsidian People/**: Read their People note if it exists — extract `last_interaction`, Key Topics, and recent Meeting History entries

Cache all results by person name. These will be distributed to relevant meeting notes in Step 6.

**Performance note:** This step only does vault reads and one Todoist search per unique person — no additional Gmail/Slack API calls. Deep mode (Step 5 opt-in) adds per-attendee Slack/email searches later.

### 4. Analyze

From the gathered data:

**Free slots:** Look at today's calendar and find gaps of 30 minutes or more. List them with start/end times.

**Task categories:**
- **Must Do:** P1 tasks + anything due today + urgent email/Slack items
- **Should Do:** P2-P3 tasks + items due in next 3 days
- **Could Do:** Lower priority items, KB inbox items

**Active Projects:** For each active project, show target date proximity and today's related meetings.

**Flags:** Identify anything needing immediate attention — urgent emails, direct Slack messages with questions, overdue P1 tasks, projects with approaching deadlines.

**Meeting → Project linking:** When creating meeting notes in Step 6, check if each meeting's title/attendees/description match an active project. If so, pre-populate the `project:` frontmatter field: `project: "[[Projects/slug]]"`.

**Uncaptured Actions:** From Step 3a/3b, compile the list of detected actions classified as "Uncaptured." For each, prepare a proposed Todoist task with:
- **Title**: concise action description
- **Priority**: P1 if deadline is today/tomorrow, P2 if within the week, P3 otherwise
- **Project**: Work (if from work Slack/Gmail) or Personal/Us (if from iMessage)
- **Due date**: from the deadline if mentioned, otherwise tomorrow
- **Description**: "Detected from [source]: [original message preview]"

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

## Active Goals
- **Goal Name** — Next: Milestone (due date, X days) | Project: [[Projects/slug]]
- **Goal Name** — STALE: no activity in X days | This week target: [from weekly-review]
- **Goal Name** — This week: X/Y sessions
[For each active quarterly goal: show next milestone + due date + days remaining. Flag STALE if no related task or meeting activity in 7+ days. Show "This Week" target if set by weekly-review. If a meeting today maps to a goal's project, note it.]

## Active Projects
- **Project Name** (target date) — status summary, today's related meeting
- ...

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

## Uncaptured Actions
[Table of actions detected in Gmail/Slack/iMessage that aren't in Todoist]
| Source | From | Ask | Proposed Task |
|--------|------|-----|---------------|
| [Gmail/Slack/iMessage] | [person] | [one-line summary] | [task title] (P[1-3], [project], [due]) |
Create all? (y/n) or select individually

## KB Sync
- Captured: X new items from Reader
- Triaged: Y items (Z actionable)
- Resource notes created: X in ~/Documents/PersonalOS/Resources/
- [list of actionable items with proposed Todoist tasks]
- Create tasks? (y/n for each, or "create all")

## Coming Up (Next 3 Days)
- [upcoming deadlines and events worth knowing about]
```

After presenting the plan, ask:

> "Run deep prep for today's meetings? This searches Slack/email threads per attendee for richer Suggested Topics (~2-3 min)."

If yes → proceed to Step 5b (Deep Mode) before creating meeting notes.
If no → skip to Step 6 with vault-based Suggested Topics only.

#### 5b. Deep Mode (opt-in)

Only runs if the user confirms. For each unique attendee from Step 3c:

1. **Slack search**: `slack_search_public_and_private` for messages involving this person (last 7 days). Look for unresolved threads — open questions, pending decisions, no clear conclusion.
2. **Gmail search**: `gmail_search_messages` for threads with this person's email (last 7 days). For actionable threads, use `gmail_read_thread` to get full context.
3. **Stale thread detection**: Flag any thread involving you that went quiet 3+ days without resolution.

Cache results by person name alongside Step 3c results. These will enrich Suggested Topics in Step 6.

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

#### Suggested Topics (per meeting)

For each confirmed work meeting, generate a **## Suggested Topics** section using the cached data from Steps 3c and 5b (if deep mode ran). Place this section between `## Context` and `## Summary` in the meeting note.

**Build topics from these sources (in priority order):**

1. **Open action items**: From the 3c cache, find Todoist tasks and unchecked meeting note items involving this meeting's attendees. Format: `**[Topic]** — Open action from [date]: [person] committed to [action text]`

2. **Unresolved follow-ups**: From the 3c cache, find unchecked Follow-up items from past meeting notes (last 30 days) with the same attendees. Format: `**[Topic]** — Follow-up from [date meeting]: [follow-up text] (still open)`

3. **Project status** (if meeting links to an active project): Read the project note's Current Status, Open Questions, and target_date. Format: `**[Project name]** — [deadline proximity], [key blocker or open question]`

4. **Recent Slack/email threads** (deep mode only): From the 5b cache, find unresolved threads with attendees. Format: `**[Thread topic]** — Active [Slack/email] thread ([last message date]), [status: awaiting decision/review/response]`

5. **Relationship context**: From People notes, flag if `last_interaction` was 3+ weeks ago. Format: `**Catch up with [person]** — Last met [date]. Key topics: [from People note]`

**Rules:**
- 3-7 topics max per meeting, prioritized by urgency (deadlines > open actions > follow-ups > threads > relationship)
- Each topic is 1-2 lines with enough context to be actionable during the meeting
- **Deduplication**: If an uncaptured action (from Step 3a) involves one of this meeting's attendees, surface it here as a Suggested Topic AND remove it from the standalone Uncaptured Actions list. Don't double-surface.
- If no relevant topics are found, write: `No suggested topics found — check vault connections after the meeting.`

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

## Suggested Topics
[Auto-populated from vault data + optional deep mode — see "Suggested Topics" section above]

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

1. **"Create uncaptured action tasks?"** — If Step 3a/3b found uncaptured actions, present the proposed Todoist tasks for batch confirmation. User can "create all", select individually, or skip. Create confirmed tasks with the suggested priority/project/due date from Step 4. Include "Detected from [source]: [original message preview]" in the task description.

2. **"Create KB tasks?"** — If the KB Sync step found actionable items, confirm which Todoist tasks to create. Create confirmed tasks in the "Personal" project with the `learning` label (default p3, due next week). Include the Notion item URL in the task description. Update each Notion item's `Related Task` field with the Todoist task URL.

3. **"Write to Obsidian?"** — If yes, create or update `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`. Fill in the Plan section (Meetings, Must Do, Should Do, Uncaptured Actions, KB Highlights, Proposed Schedule) while preserving any existing content in other sections. Include the Uncaptured Actions table in the Plan section so `/reflect` can reference it later.

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

4. **"Block focus time?"** — If yes, offer to create calendar events in free slots for deep work using `gcal_create_event`. Use 30-minute minimum blocks. Name them "Focus: [suggested task]".

## Notes
- All times in America/Los_Angeles
- Dates formatted as YYYY-MM-DD
- If a service is unavailable, skip its section with a brief note like "[Gmail unavailable — skipped]"
- Cap email and Slack results at 10 each to avoid context overflow
- Personal calendar events show as "busy" blocks — no titles or attendees visible
- Do not auto-create People notes — that is `/reflect`'s responsibility
- Reference CLAUDE.md for paths and conventions
