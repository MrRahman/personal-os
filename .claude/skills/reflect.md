---
name: reflect
description: End-of-day reflection that compares planned vs actual, reschedules incomplete tasks, and writes to Obsidian
---

# Daily Reflection

End-of-day review that compares your morning plan against what actually happened, reschedules incomplete tasks, and writes a reflection to Obsidian.

## Instructions

### 1. Preflight Check

Test access to these services:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Google Calendar | `gcal_list_events` (today) | Yes |
| Todoist | List tasks | Yes |
| Obsidian vault | Read `~/Documents/PersonalOS/` | Yes |
| Otter.ai | `otter_list_transcripts` (limit 1) | No |

Report availability. Calendar, Todoist, and Obsidian are important for a full reflection. Otter is optional but enables meeting summaries.

### 2. Gather Data

Run in parallel:

**Calendar:** Get today's events from all calendars (work + personal) using `gcal_list_events`. Timezone: America/Los_Angeles.

**Todoist — Completed:** Fetch tasks completed today.

**Todoist — Incomplete:** Fetch tasks that were due today but are still open.

**Morning Plan:** Read `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md` (using today's date). If it exists and has a Plan section, extract the planned items. If it doesn't exist, note that no morning plan was found.

**Otter Transcripts (if available):** Use `otter_list_transcripts` with today's date filter to find meeting transcripts from today. For each transcript, use `otter_get_transcript` to fetch the full text.

### 3. Compare (Plan vs Actual)

If a morning plan exists, compare:
- **Planned meetings vs actual meetings** — any cancellations or additions?
- **Must Do tasks vs completed tasks** — what got done?
- **Unplanned work** — tasks or meetings that appeared after the morning plan
- **Completion rate** — X of Y planned tasks completed
- **Time analysis** — estimate hours in meetings vs hours of focus time based on calendar

If no morning plan exists, skip this comparison and note: "No morning plan found — showing today's activity without comparison."

### 4. Reschedule

For incomplete tasks that are priority 1 or 2:
- List them with their current due dates
- Propose rescheduling each to tomorrow
- **Ask the user to confirm** before making any changes in Todoist
- Only update tasks the user approves

For priority 3+ incomplete tasks, just list them — don't auto-reschedule.

### 5. Process Meeting Transcripts (if Otter available)

For each Otter transcript from today:

**a. Create Meeting Note:** Write `~/Documents/PersonalOS/Meetings/YYYY-MM-DD-meeting-title.md` using the Meeting Note template. Fill in:
- Summary: 3-5 sentence summary of the meeting
- Key Points: main discussion topics and decisions
- Action Items: extract any action items or commitments mentioned
- Transcript Highlights: 2-3 notable quotes or key exchanges
- Set `otter_id` in frontmatter for future reference

**b. Update People Notes:** For each attendee mentioned in the transcript:
- Check if `~/Documents/PersonalOS/People/First-Last.md` exists
- If not, create it using the Person template with whatever info is available
- If it exists, append to the Meeting History section: `- YYYY-MM-DD: [[Meetings/YYYY-MM-DD-meeting-title|Meeting Title]] — one-line context`
- Update `last_interaction` in frontmatter

**c. Cross-reference:** Add `[[People/First-Last]]` links in the meeting note's attendees field so Obsidian builds the graph.

If Otter is unavailable, skip this step with a note.

### 6. Generate Reflection

Write a 5-8 sentence reflection covering:
1. **What went well** — completed tasks, productive meetings, good focus blocks
2. **What didn't go as planned** — incomplete items, interruptions, context switching
3. **Pattern observation** — connect to broader trends if possible (e.g., "This is the third day this week where afternoon focus time got eaten by unplanned meetings")
4. **Tomorrow suggestion** — one concrete, actionable thing to try tomorrow

Tone: honest and constructive, like a thoughtful coach. Not overly positive or negative.

### 7. Write to Obsidian

Create or update `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`:

- If the file exists (from morning plan), **preserve the Plan section** and fill in:
  - `## Completed` — list of completed tasks
  - `## Incomplete` — list of incomplete tasks with new due dates if rescheduled
  - `## Reflection` — the generated reflection text

- If the file doesn't exist, create it with all sections (Plan section will note "No morning plan recorded").

Display the full reflection in the terminal as well.

## Output Format

```
# Daily Reflection — YYYY-MM-DD

## Summary
- Meetings: X (Y hours)
- Tasks completed: X of Y planned
- Unplanned items: X

## Completed
- [x] task (source)
- ...

## Incomplete
- [ ] task — rescheduled to YYYY-MM-DD / not rescheduled
- ...

## Reflection
[5-8 sentence reflection]

---
Meeting notes created: X (from Otter transcripts)
People notes updated: X
Obsidian note updated: ~/Documents/PersonalOS/Daily/YYYY-MM-DD.md
Tasks rescheduled: X
```

## Notes
- Timezone: America/Los_Angeles
- Dates: YYYY-MM-DD
- Be empathetic but honest in reflections
- Never reschedule without user confirmation
- Reference CLAUDE.md for paths and conventions
