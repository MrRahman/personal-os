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
| iMessage | `list_conversations` (limit 1) | No |
| Readwise | `reader_list_documents` (limit 1) | No |

Report availability. Calendar, Todoist, and Obsidian are important for a full reflection. Otter is optional but enables meeting summaries.

### 2. Gather Data

Run in parallel:

**Calendar:** Get today's events from all calendars (work + personal) using `gcal_list_events`. Timezone: America/Los_Angeles.

**Todoist — Completed:** Fetch tasks completed today.

**Todoist — Incomplete:** Fetch tasks that were due today but are still open.

**Morning Plan:** Read `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md` (using today's date). If it exists and has a Plan section, extract the planned items. If it doesn't exist, note that no morning plan was found.

**Otter Transcripts (if available):** Use `otter_list_transcripts` with today's date filter to find meeting transcripts from today. For each transcript, use `otter_get_transcript` to fetch the full text.

**iMessage (if available):** Use `extract_action_items(hours=16)` to scan today's messages for requests or commitments you may not have acted on. Awareness only — present what's found, do not auto-create tasks.

**Readwise (if available):** Run `reader_list_documents(location="new", limit=5)`. Count items not yet tagged with `synced-to-notion`. Awareness only — note in the reflection output. These will be auto-captured by tomorrow's `/morning-plan`.

### 3. Compare (Plan vs Actual)

If a morning plan exists, compare:
- **Planned meetings vs actual meetings** — any cancellations or additions?
- **Must Do tasks vs completed tasks** — what got done?
- **Unplanned work** — tasks or meetings that appeared after the morning plan
- **Completion rate** — X of Y planned tasks completed
- **Time analysis** — estimate hours in meetings vs hours of focus time based on calendar

If no morning plan exists, skip this comparison and note: "No morning plan found — showing today's activity without comparison."

### 4. Action Loop Closure

Check whether uncaptured actions surfaced by this morning's `/morning-plan` were addressed during the day. Skip this step if no morning plan exists or if it has no "Uncaptured Actions" section.

1. **Read today's daily note** (`~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`) and find the Uncaptured Actions section from the morning plan.
2. **For each uncaptured action that was surfaced**, check for evidence of follow-through:
   - **Todoist**: Search for tasks matching keywords from the proposed task title. If found → "Task created."
   - **Slack**: Search for replies or messages from the user related to this action (after morning-plan timestamp). If found → "Resolved via Slack."
   - **Gmail**: Search sent folder for replies to the original thread. If found → "Resolved via email."
   - **Meeting notes**: Check today's meeting notes for related action items or decisions. If found → "Addressed in [meeting name]."
3. **Classify each action** as:
   - **Resolved**: Clear evidence of follow-through found
   - **Task created, not done**: Todoist task exists but still open (this is normal — it may not be due today)
   - **Still unaddressed**: No evidence of action taken
4. **Present still-unaddressed items** with options per item:
   - Create Todoist task (due tomorrow, suggested priority from morning plan)
   - Intentionally skip (no further tracking — user made a conscious choice)
   - Defer to weekly review (will appear in Friday's `/weekly-review`)
5. **User batch-confirms** which items to create tasks for, skip, or defer.

**Output format:**
```
## Action Loop
- Morning surfaced: X uncaptured actions
- Resolved during the day: X
- Tasks created (pending): X
- Still unaddressed: X
  → [description] — Create task / Skip / Defer to weekly review
```

### 5. Reschedule

For incomplete tasks that are priority 1 or 2:
- List them with their current due dates
- Propose rescheduling each to tomorrow
- **Ask the user to confirm** before making any changes in Todoist
- Only update tasks the user approves

For priority 3+ incomplete tasks, just list them — don't auto-reschedule.

### 6. Sync Meeting Transcripts

**ALWAYS run sync-meetings as part of reflect.** Do not skip this step or defer it to a separate session. Inline the full `/sync-meetings` logic for today's date:

1. Fetch all Otter transcripts for today (`otter_list_transcripts` with today's date filter)
2. Match each transcript to existing meeting notes (by title + time + attendees)
3. For each match: fetch the full transcript (`otter_get_transcript`), extract summary/key points/action items/follow-ups/highlights, write the transcript file to `Meetings/Transcripts/`, and update the meeting note
4. Update People notes with meeting history
5. Run the Slack cross-check (Step 7 of sync-meetings) before presenting action items
6. Present action items for Todoist task creation (user confirms)

**Process all transcripts regardless of length.** If context is large, process them sequentially rather than skipping. The user should never have to run `/sync-meetings` separately after `/reflect`.

If Otter is unavailable (detected in preflight), skip with a note: "Otter unavailable — skipping meeting transcript sync."

If no transcripts found: "No transcripts found for today."

### 7. Generate Reflection

Write a 5-8 sentence reflection covering:
1. **What went well** — completed tasks, productive meetings, good focus blocks
2. **What didn't go as planned** — incomplete items, interruptions, context switching
3. **Pattern observation** — connect to broader trends if possible (e.g., "This is the third day this week where afternoon focus time got eaten by unplanned meetings")
4. **Tomorrow suggestion** — one concrete, actionable thing to try tomorrow

Tone: honest and constructive, like a thoughtful coach. Not overly positive or negative.

### 8. Write to Obsidian

Create or update `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`:

- If the file exists (from morning plan), **preserve the Plan section** and fill in:
  - `## Completed` — list of completed tasks
  - `## Incomplete` — list of incomplete tasks with new due dates if rescheduled
  - `## Reflection` — the auto-generated reflection text
  - `## My Reflection` — leave the following sections for the user to fill in:
    - `### Highlight` — "What's the one thing I'm most proud of or grateful for today?"
    - `### Adjustments` — "What would I do differently tomorrow?"
    - `### Check-In` — table with 5 scores (1-10): Energy, Focus, Impact, Balance, Mood

- **Frontmatter scores:** If the user provides Check-In scores, add them to the YAML frontmatter (`energy`, `focus`, `impact`, `balance`, `mood`). These are queryable by Tracker/Dataview/Bases for graphing over time. Leave blank if user hasn't provided scores yet.

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

## Action Loop
- Morning surfaced: X uncaptured actions
- Resolved during the day: X
- Tasks created (pending): X
- Still unaddressed: X
  → [description] — Create task / Skip / Defer

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
