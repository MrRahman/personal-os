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

**Calendar:** Use `gcal_list_events` to get today's events from ALL calendars. The user has both work and personal calendars (see CLAUDE.md Identity section for email addresses — work calendar is the primary, personal is free/busy only). Use timezone America/Los_Angeles. Get events for today's full day.

**Todoist:** Fetch open tasks that are:
- Priority 1, 2, or 3
- Due today or overdue
Also fetch any tasks due in the next 3 days for awareness.

**Gmail:** Use `gmail_search_messages` to find messages from the last 12 hours. Limit to 10 messages. Focus on unread or messages that may need a response.

**Slack — Mentions:** Use `slack_search_public_and_private` to find mentions and DMs from the last 12 hours. Limit to 10 results.

**Slack — Saved for Later:** Use `slack_search_public_and_private(query="is:saved", sort="timestamp", sort_dir="desc", limit=20, include_context=false, response_format="concise")` to find messages marked "Save for later." Filter to last 7 days. For each: extract sender, channel/DM, message preview (100 chars), permalink. Dedup against Todoist (search for permalink in task descriptions). Present in Inbox for user to confirm as tasks.

**Notion:** Use Notion MCP to query the "AI Knowledge Base" database (see CLAUDE.md for database ID) for items where Status = "Inbox" or Action Required = true.

**Otter (if available):** Use `otter_list_transcripts` to check for any transcripts from yesterday that haven't been processed into Obsidian Meeting notes yet. Flag them as needing `/reflect` processing.

**iMessage (if available):** Use `extract_action_items(hours=24)` to scan the last 24 hours of messages for potential requests, commitments, or action items. This is awareness only — present what's found, do not auto-create tasks.

**Yesterday's Missed Actions:** Glob yesterday's meeting notes (`~/Documents/PersonalOS/Meetings/YYYY-MM-DD-*.md` using yesterday's date). Scan each file for uncompleted checkboxes (`- [ ]`) containing the user's People wikilink (e.g., `[[People/First-Last]]` or `@[[People/First-Last]]`) or the user's short name (see CLAUDE.md Identity section). For each found item, search Todoist for a matching task by keywords. Items with no Todoist match are added to the MISSED flags list with the source meeting name. If all items match, skip.

**Readwise (if available):** Auto-capture from Reader inbox to Notion KB:
1. Fetch: `reader_list_documents(location="new", updated_after=7_days_ago, limit=50, response_fields=["url","title","author","category","tags","summary","reading_progress","published_date","saved_at","source_url"])`
2. For each item not tagged `synced-to-notion`: fetch highlights, dedup against Notion KB by URL, create Notion page (Status="Inbox"), tag with `synced-to-notion`, then archive: `reader_move_documents(document_ids=[id], location="archive")`
3. Report count in Inbox & Notifications section. No user confirmation needed — this is fully automatic.

### 3. Analyze

From the gathered data:

**Free slots:** Look at today's calendar and find gaps of 30 minutes or more. List them with start/end times.

**Task categories:**
- **Must Do:** P1 tasks + anything due today + urgent email/Slack items
- **Should Do:** P2-P3 tasks + items due in next 3 days
- **Could Do:** Lower priority items, KB inbox items

**Flags:** Generate a prioritized flags list using three detection tiers:

**DEADLINE flags (automatic):** Todoist tasks due today/tomorrow with `exec-ops` or `team` labels; milestones from Goals/ due this week; calendar conflicts.

**STALE flags (automatic):** Uncompleted meeting note action items >3 days old with no Todoist match; `waiting-on` tasks older than 5 days; People notes where `last_interaction` >21 days (top 5 work contacts).

**MISSED flags (automatic):** Yesterday's meeting note action items assigned to the user (see CLAUDE.md Identity section for name/short name) with no Todoist match (from Gather Data scan).

**STRATEGIC flags (AI-generated, max 2):** Based on executive priorities (execution over process, accountability — see CLAUDE.md Executive Contacts section if present), what from today's schedule or open tasks would leadership ask about? Frame as a question, not a task. Only generate if genuinely warranted.

Present Flags immediately after Schedule in terminal output. If no flags, omit the section entirely.

### 4. Present

Display the morning plan in two tiers: a compact terminal view and a full Obsidian daily note.

**Terminal output (Quick View — default, 30-40 lines max):**

Only show these sections in the terminal:

```
# Morning Plan — YYYY-MM-DD (Day of Week)

## Today's Schedule
  7:30    You/[exec] || monthly skip level .......... [Exec], [EA]
  9:00    AI priority sync up ...................... [team]
 10:00    ---- Building Time (3h) ----
  2:00    1:1 || [Manager] & You ................... [Manager]
[Left-aligned times, dotted leaders to attendees, ---- dashes ---- for personal/focus blocks]

## Flags
DEADLINE  CEO proposal due tomorrow — no draft exists
STALE     Jon milestone conversation — 4 days, no follow-up
MISSED    2 action items from Every.to meeting not in Todoist
STRATEGIC QBR Tuesday — leadership expects execution proof. Your slides?
[Only show if flags exist. Omit section entirely if none.]

## Must Do
- [ ] Task description [label, due today]
[Compact: one line per task, inline details, label tags in brackets]

## Missed from Yesterday
- "Submit reimbursement" — from Executive Staff Meeting (no Todoist match)
[Only show if missed items found.]

## Respond
  - Sender (source): Subject or message preview
[Urgent inbox items only]

## Slack Later (X new)
  Check Slack app — X saved items pending triage

---
Should Do (N) + Coming Up + Free Slots → Obsidian | Readwise: X | Otter: X
```

**Obsidian daily note gets EVERYTHING:** All the above plus Should Do, Active Goals, Active Projects, Free Slots, Coming Up, full Inbox & Notifications, Uncaptured Actions, Waiting On, KB Sync.

**Expand mode:** If the user says "full" or "expand", show the complete output including Should Do, Goals, Projects, Free Slots, Coming Up, and Waiting On in the terminal.

Use 12-hour time format. Keep descriptions concise — one line per item.

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