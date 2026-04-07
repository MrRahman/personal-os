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

**Readwise (if available):** Run in parallel:
- `reader_list_documents(location="archive", limit=5)`
- `reader_list_documents(location="shortlist", limit=5)`

Count items not yet tagged with `synced-to-notion`. Awareness only — note in the reflection output.

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

### 5. Sync Meeting Transcripts

Invoke `/sync-meetings` for today's date. This handles:
- Pulling Otter transcripts and matching them to existing meeting notes
- Filling in summaries, action items, key points, and highlights
- Storing full transcripts in `Meetings/Transcripts/`
- Updating People notes with meeting history

If Otter is unavailable (detected in preflight), skip this step with a note: "Otter unavailable — skipping meeting transcript sync. Run `/sync-meetings` later when available."

If `/sync-meetings` finds no transcripts, note: "No transcripts found for today."

### 6. Sync Action Items to Todoist

After meeting notes are finalized, sweep today's notes for action items assigned to the user and send them to Todoist.

1. **Glob today's meeting notes:** `~/Documents/PersonalOS/Meetings/YYYY-MM-DD-*.md`
2. **Extract action items:** Scan for uncompleted checkboxes (`- [ ]`) containing the user's People wikilink or short name (see CLAUDE.md Identity section)
3. **Dedup:** Search Todoist for each item using distinctive keywords. Skip if already exists.
4. **Present for confirmation:** Show new items with source meeting, ask user to confirm all or y/n per item.
5. **Create tasks:** Content = action text, Description = `From [[Meetings/YYYY-MM-DD-slug|Title]]`, Due = extracted date hint or tomorrow, Labels = `meeting-action` + any label mapped from the source meeting's `project:` frontmatter per the Todoist Label → Obsidian Project Map in CLAUDE.md (e.g., meeting with `project: "[[Projects/ai-transformation]]"` gets label `AI Transformation`)
6. **Report:** "Created X Todoist tasks from today's meeting notes."

Skip if no meeting notes exist for today or no action items found.

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
  - `## Reflection` — the generated reflection text

- If the file doesn't exist, create it with all sections (Plan section will note "No morning plan recorded").

Display the full reflection in the terminal as well.

## Output Format

Display the reflection in two tiers: a compact terminal view and a full Obsidian daily note.

**Terminal output (Quick View):**

```
# Daily Reflection — YYYY-MM-DD

Meetings: X (Yh)  |  Tasks: A/B completed (Z%)  |  Unplanned: X

## Completed
- [x] task [label]

## Flags for Tomorrow
DEADLINE  Oracle go-live tomorrow — prep checklist needed
STALE     Jon milestone conversation — 4 days, no follow-up
STRATEGIC QBR Thursday — leadership expects execution proof. Where are your slides?
[Only show if flags exist. Omit section entirely if none.
DEADLINE: anything due tomorrow. STALE: anything >3 days without progress.
STRATEGIC: what leadership would ask about based on this week's trajectory. Max 2, skip if nothing warrants it.]

## Reflection
What went well: [1-2 sentences]
What's at risk: [1-2 sentences]
Pattern: [1 sentence connecting to broader trends]
Tomorrow: [1 concrete action]

## Check-In (after user provides scores)
Energy    ██████░░░░ 6
Focus     ██████░░░░ 6
Impact    █████████░ 9
Balance   ████████░░ 8
Mood      ███████░░░ 7

---
Transcripts: X | People: X | Tasks: X created | Full → Obsidian
```

**Obsidian daily note gets EVERYTHING:** All the above plus Incomplete list, Action Loop, Action Items to Todoist details, meeting-by-meeting transcript summaries.

Note: Obsidian daily note keeps standard markdown table for Check-In scores (Dataview compatibility). Visual bars are terminal-only.

## Notes
- Timezone: America/Los_Angeles
- Dates: YYYY-MM-DD
- Be empathetic but honest in reflections
- Never reschedule without user confirmation
- Reference CLAUDE.md for paths and conventions