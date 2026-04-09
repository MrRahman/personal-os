---
name: reflect
description: End-of-day reflection that compares planned vs actual, reschedules incomplete tasks, and writes to Obsidian
---

# Daily Reflection

End-of-day review that compares your morning plan against what actually happened, reschedules incomplete tasks, and writes a reflection to Obsidian.

## Instructions

### Missed-Day Policy

**Never backfill.** `/reflect` only processes today's date. If the user missed yesterday or any prior day, those days stay as-is. Do not offer to "catch up" on missed reflections, do not create daily notes for past dates, and do not retroactively fill in Completed/Reflection sections for prior days.

If today's daily note doesn't exist, create it fresh for today — but never for a past date.

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

**Write deferral:** Prepare all transcript files, meeting note updates, and People note updates in memory. Do NOT write to the vault until Step 10.

**Cross-skill caching:** Reuse calendar events from Step 2 for transcript-to-meeting matching. Do NOT re-fetch via `gcal_list_events`. Similarly, reuse Todoist task data from Step 2 for deduplication.

**ALWAYS run sync-meetings as part of reflect.** Do not skip this step or defer it to a separate session. Inline the full `/sync-meetings` logic for today's date (including the new decision detection, commitment detection, and waiting-on label features added to sync-meetings):

1. Fetch all Otter transcripts for today (`otter_list_transcripts` with today's date filter)
2. Match each transcript to existing meeting notes (by title + time + attendees)
3. For each match: fetch the full transcript (`otter_get_transcript`), extract summary/key points/action items/follow-ups/highlights, prepare the transcript file for `Meetings/Transcripts/`, and prepare the meeting note update (writes deferred to Step 10)
4. Prepare People note updates with meeting history (writes deferred to Step 10)
5. Run the Slack cross-check (Step 7 of sync-meetings) before presenting action items
6. Present action items for Todoist task creation (user confirms)

**Process all transcripts regardless of length.** If context is large, process them sequentially rather than skipping. The user should never have to run `/sync-meetings` separately after `/reflect`.

If Otter is unavailable (detected in preflight), skip with a note: "Otter unavailable — skipping meeting transcript sync."

If no transcripts found: "No transcripts found for today."

### 7. Sync Action Items to Todoist

After meeting notes are finalized (including transcript-extracted action items from Step 6), sweep today's meeting notes for action items assigned to the user and create corresponding Todoist tasks.

1. **Glob today's meeting notes:** `~/Documents/PersonalOS/Meetings/YYYY-MM-DD-*.md` (using today's date)
2. **Extract action items assigned to the user:** Scan each file for uncompleted checkboxes that contain the user's People wikilink or short name (see CLAUDE.md Identity section). Pattern: lines matching `- [ ]` that reference the user by name or People link.
3. **Dedup against Todoist:** For each extracted action item, search Todoist using `get_tasks_list(filter="search: <keywords>")` with 2-3 distinctive words from the task. If a matching task already exists, skip it.
4. **Present new items for confirmation:**
   ```
   ## Action Items → Todoist

   Found X action items assigned to you across Y meeting notes.
   Z already exist in Todoist (skipped).

   New items to create:
   1. [y/n] "Submit NYC reimbursement" — from Executive Staff Meeting
   2. [y/n] "Follow up with [exec] on slides" — from Debrief Meeting
   ...

   Confirm all, or y/n per item?
   ```
5. **Create confirmed tasks** in Todoist:
   - **Content:** The action item text (without the People wikilink prefix)
   - **Description:** `From [[Meetings/YYYY-MM-DD-slug|Meeting Title]]`
   - **Due date:** Extract from action item text if present (e.g., "by Friday" → next Friday's date). If no date hint, set to tomorrow.
   - **Priority:** 1 (default, user can adjust)
   - **Labels:** `meeting-action` + any label mapped from the source meeting's `project:` frontmatter. Check the source meeting note's `project:` field and look up the Todoist Label → Obsidian Project Map in CLAUDE.md. If the meeting has `project: "[[Projects/ai-transformation]]"`, add label `AI Transformation`. If no mapping exists or no project is set, use `meeting-action` only.
6. **Report:** "Created X Todoist tasks from today's meeting notes."

If no meeting notes exist for today, or no action items are found assigned to the user, skip with: "No new action items found in today's meeting notes."

### 8. Generate Reflection (Claude's Analysis)

Write a 5-8 sentence reflection covering:
1. **What went well** — completed tasks, productive meetings, good focus blocks
2. **What didn't go as planned** — incomplete items, interruptions, context switching
3. **Pattern observation** — connect to broader trends if possible (e.g., "This is the third day this week where afternoon focus time got eaten by unplanned meetings")
4. **Tomorrow suggestion** — one concrete, actionable thing to try tomorrow

Tone: honest and constructive, like a thoughtful coach. Not overly positive or negative.

**This is Claude's perspective only.** Present it in the terminal, then proceed to Step 8 to get the user's own reflection.

### 9. Interactive Check-In (User's Reflection)

**STOP and ask the user before writing anything to Obsidian.** Present Claude's reflection from Step 8, then prompt:

> "That's my read on the day. Now yours —"
>
> **Highlight:** What's the one thing you're most proud of or grateful for today?
>
> **Adjustments:** What would you do differently tomorrow?
>
> **Check-In scores (1-10):** Energy, Focus, Impact, Balance, Mood
>
> **Personal wins:** Anything outside work worth noting? Workout, family time, networking call, personal project progress? (type or skip)

**Wait for the user's response.** Do NOT fill in Highlight, Adjustments, or Check-In scores yourself. Do NOT write to Obsidian until the user provides their input. If the user says "skip" or doesn't want to fill these in, leave the sections with placeholder comments in Obsidian.

### 10. Write to Obsidian

**Only run this step after the user has responded to Step 9 (or explicitly skipped it).**

**Vault gate:** Before writing anything, re-verify Obsidian vault access by reading `~/Documents/PersonalOS/Templates/Meeting Note.md`. If this fails, display all prepared content in the terminal and warn the user.

**Write order:** Execute all vault writes in this sequence:
1. Transcript files — `Meetings/Transcripts/*.md`
2. Meeting note updates — `Meetings/*.md`
3. People note updates — `People/*.md`
4. Daily note — `Daily/YYYY-MM-DD.md`

If any write fails, report which files succeeded and which failed.

Create or update `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`:

- If the file exists (from morning plan), **preserve the Plan section** and fill in:
  - `## Completed` — list of completed tasks
  - `## Incomplete` — list of incomplete tasks with new due dates if rescheduled
  - `## Reflection` — Claude's auto-generated reflection text (clearly labeled: `<!-- Claude's analysis -->`)
  - `## My Reflection` — the user's own words from Step 8:
    - `### Highlight` — user's response (or placeholder comment if skipped)
    - `### Adjustments` — user's response (or placeholder comment if skipped)
    - `### Check-In` — table with 5 scores from user (or blank if skipped)
  - `## Personal` — user's personal wins from Step 8 (only if provided; omit section entirely if skipped)

- **Frontmatter scores:** Only write scores to YAML frontmatter if the user provided them in Step 8. Never fill in scores from Claude's perspective. Leave blank if user hasn't provided scores.

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
[Generate bar using █ (filled) and ░ (empty), 10 chars wide. Score at end.]

---
Transcripts: X | People: X | Tasks: X created | Full → Obsidian
```

**Obsidian daily note gets EVERYTHING:**

The full reflection written to `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md` includes all of the above plus:

- `## Incomplete` — list of incomplete tasks with rescheduled dates and labels
- `## Action Loop` — morning surfaced count, resolved, pending, unaddressed with options
- `## Action Items → Todoist` — from meeting note sweep (Step 7), per-item confirmation
- Meeting-by-meeting transcript summaries from Step 6

**Note:** The Obsidian daily note retains the standard markdown table format for Check-In scores (for Dataview compatibility). The visual bars are terminal-only.

## Notes
- Timezone: America/Los_Angeles
- Dates: YYYY-MM-DD
- Be empathetic but honest in reflections
- Never reschedule without user confirmation
- Reference CLAUDE.md for paths and conventions
