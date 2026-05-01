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
| Google Calendar (Work) | `gcal_list_events` (today) | Yes |
| Google Calendar (Personal) | `manage_calendar(operation: "agenda")` via google-personal MCP | Yes |
| Todoist | List tasks | Yes |
| Obsidian vault | Read `~/Documents/PersonalOS/` | Yes |
| Otter.ai | `otter_list_transcripts` (limit 1) — see Otter cookie diagnosis below | Yes |
| iMessage | `list_conversations` (limit 1) | Yes |
| Readwise | `reader_list_documents` (limit 1) | Yes |

**All services are required.** Preflight output rule (matches `/morning-plan`):
- If every required service passes: print a single-line footer at the top: `✓ preflight ok (7/7 services + vault)`. Do not itemize.
- If any required service fails: STOP and print an `[ASK]` prompt with a one-sentence fix (e.g., `[ASK] Otter unreachable — run python3 mcp-servers/refresh-otter-cookie.py + restart Claude Code, then re-run /reflect.`).
- See CLAUDE.md Google Account Mapping for tool details.

**Otter cookie diagnosis (when `otter_list_transcripts` returns 401):**

The Otter MCP server reads `OTTER_SESSION_COOKIE` from `.mcp.json` once at session spawn. Mid-session refresh updates the file but not the running process. `/mcp reconnect otter` re-establishes the stdio pipe but does NOT restart the process. Distinguish the two failure modes before telling the user what to do:

1. Run `python3 /Users/sulaimanrahman/projects/personal-os/mcp-servers/refresh-otter-cookie.py --validate` via Bash. This validates the cookie currently in `.mcp.json` against the Otter API directly.
2. **If `--validate` exits 0 (cookie in config is valid) but MCP still 401s** → MCP process holds a stale env. Stop and tell the user exactly this:
   > The Otter cookie in `.mcp.json` is fresh, but the MCP server process hasn't picked it up. Exit Claude Code fully and restart — `/mcp reconnect` won't help. No refresh needed, just the restart.
3. **If `--validate` exits non-zero (cookie itself is expired)** → refresh is needed. Stop and tell the user:
   > Otter cookie expired. Run `python3 mcp-servers/refresh-otter-cookie.py`, then exit Claude Code fully and restart.
4. Otter is required for `/reflect` (transcript sync is a core step). STOP preflight and wait for the user to restart — do not proceed without it.

### 1b. Otter Transcript Freshness Gate

Hard gate — ensures all meeting recordings are uploaded before processing transcripts.

1. **Fetch today's calendars** (both work + personal, same dual-query pattern as Step 2). Cache these results for reuse in Step 2 — do not re-fetch later.
2. **Fetch today's Otter transcripts:** `otter_list_transcripts` filtered to today's date.
3. **Identify meetings that should have transcripts:** From calendar events, filter to meetings only (2+ human attendees, or has a conferencing link). Exclude blocks per CLAUDE.md Block Conventions. Exclude meetings that haven't happened yet (start time in the future). Exclude meetings shorter than 5 minutes.
4. **Compare:** For each qualifying meeting, check if a matching Otter transcript exists (match by title similarity + time proximity within 30 minutes).
5. **If gaps exist**, present them and wait:
   ```
   These meetings don't have Otter transcripts yet:
   - 10:00 AM — Q1 Treasury Review (3 attendees)
   - 2:00 PM — 1:1 with Sarah Lee

   Upload the recordings to Otter, then type "ready" to continue.
   ```
   Wait for the user to confirm "ready", then re-fetch Otter transcripts and re-check. Repeat until all gaps are resolved or the user explicitly says to proceed without them.
6. **If no gaps** (all meetings have transcripts, or no qualifying meetings today): proceed silently.

### 1c. Todoist Completion Freshness Gate

Hard gate — ensures Todoist reflects actual completions before calculating stats.

1. **Fetch tasks due today that are still open:** Use `find-tasks-by-date` for today, excluding overdue tasks from prior days.
2. **If open tasks exist**, present them and wait:
   ```
   These tasks are still marked open in Todoist:
   - [ ] Submit expenses [exec-ops, p1]
   - [ ] Draft metrics framework [AI Transformation, p2]
   - [ ] Call dentist [health, p4]

   Mark any completed tasks in Todoist, then type "ready".
   ```
   Wait for the user to confirm "ready", then re-fetch completed and incomplete tasks for today. This refreshed data replaces what Step 2 would otherwise fetch for Todoist.
3. **If no open tasks due today**: proceed silently.

### 2. Gather Data

Run in parallel:

**Cross-step caching:** If Step 1b already fetched today's calendar events, reuse them — do not re-fetch. If Step 1c already fetched and re-fetched Todoist data (user said "ready"), reuse that — do not re-fetch.

**Calendar (Work):** Get today's work events using `gcal_list_events` (srahman@ripple.com). Timezone: America/Los_Angeles. Tag all results **[Work]**.

**Calendar (Personal):** Get today's personal events using `manage_calendar(operation: "agenda")` via google-personal MCP (1srahman@gmail.com). Timezone: America/Los_Angeles. Tag all results **[Personal]**.

**Todoist — Completed:** Fetch tasks completed today.

**Todoist — Incomplete:** Fetch tasks that were due today but are still open.

**Morning Plan:** Read `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md` (using today's date). If it exists and has a Plan section, extract the planned items. If it doesn't exist, note that no morning plan was found.

**Otter Transcripts:** Use `otter_list_transcripts` with today's date filter to find meeting transcripts from today. For each transcript, use `otter_get_transcript` to fetch the full text.

**iMessage:** Use `extract_action_items(hours=16)` to scan today's messages for requests or commitments you may not have acted on. Awareness only — present what's found, do not auto-create tasks.

**Readwise:** Run `reader_list_documents(location="new", limit=5)`. Count items not yet tagged with `synced-to-notion`. Awareness only — note in the reflection output. These will be auto-captured by tomorrow's `/morning-plan`.

**Quarterly Goals:** Read `~/Documents/PersonalOS/Goals/YYYY-QX.md` (current quarter). Extract: goal names, unchecked milestones with target dates, `This Week` targets, and linked Projects. If milestones are TBD or empty for a goal, note "milestones not yet defined" and skip goal-alignment analysis for that goal in Step 5.

**Tomorrow + 3-Day Calendar:** Fetch calendar events for tomorrow through day+3 (both work and personal). Also run `gcal_find_my_free_time` for tomorrow to calculate available hours. Cache for Step 5 (Smart Reschedule).

### 3. Compare (Plan vs Actual)

If a morning plan exists, compare:
- **Planned meetings vs actual meetings** — any cancellations or additions?
- **Must Do tasks vs completed tasks** — what got done?
- **Unplanned work** — tasks or meetings that appeared after the morning plan
- **Completion rate** — X of Y planned tasks completed
- **Time analysis** — estimate hours in work meetings [Work] vs personal events [Personal] vs focus time based on combined calendar data

If no morning plan exists, skip this comparison and note: "No morning plan found — showing today's activity without comparison."

### 4. Action Loop Closure

Check whether uncaptured actions surfaced by this morning's `/morning-plan` were addressed during the day. Skip this step if no morning plan exists or if it has no "Uncaptured Actions" section.

1. **Read today's daily note** (`~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`) and find the Uncaptured Actions section from the morning plan.
2. **For each uncaptured action that was surfaced**, check for evidence of follow-through:
   - **Todoist**: Search for tasks matching keywords from the proposed task title. If found → "Task created." Todoist is the authoritative source for "what was actioned" — if a Slack-origin item became a task (via Todoist Quick Add or confirmation in morning-plan), it shows up here.
   - **Gmail**: Search sent folder for replies to the original thread. If found → "Resolved via email."
   - **Meeting notes**: Check today's meeting notes for related action items or decisions. If found → "Addressed in [meeting name]."
   - **Do NOT search Slack** for evidence — action items captured via Todoist Quick Add already surface in the Todoist check above. Searching Slack for every uncaptured item is high-API-cost / low-signal and risks triggering Enterprise Grid third-party-client detection. See `memory/feedback_slack_todoist_capture.md`.
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

### 5. Smart Reschedule

Context-aware rescheduling for ALL incomplete tasks (P1–P4). Uses goal alignment, calendar capacity, and pattern detection to recommend the best action per task.

#### 5a. Gather Reschedule Context

Collect from earlier steps (do not re-fetch):
- **Incomplete tasks** from Step 2 — with metadata: priority, labels, project, description, `dueString`, `deadlineDate`, recurring status
- **Quarterly goals** from Step 2 — goal names, milestones with target dates, This Week targets, linked projects
- **Tomorrow's calendar + free time** from Step 2
- **3-day calendar** from Step 2

Gather additionally:
- **Reschedule history:** For each incomplete task, use `find-activity(objectId=task_id, objectType="task", eventType="updated", limit=10)` to check how many times the task's due date has been changed. Count date-change events in the last 14 days as "roll count." Note: `find-activity` has no date filter — fetch the last 10 events and count those within the 14-day window.
- **Tomorrow's task load:** Fetch tasks already due tomorrow, broken down by priority.

#### 5b. Generate Recommendations

For **each** incomplete task (all priorities P1–P4), apply this decision cascade in order:

**1. Chronic blocker check (first):**
If the task has been rescheduled 3+ times in the last 14 days → recommend **Drop or Break Down**. Reasoning: "Rescheduled X times in 14 days — consider breaking into smaller steps or dropping entirely."

**2. Goal alignment scan:**
Match the task to quarterly goals via: Todoist label → Obsidian Project (CLAUDE.md Label → Project Map) → Goal's `Projects:` field. Also match by keyword overlap between task content and goal names/milestones.
- If a linked goal has a milestone due within 7 days → **Escalate + specific date**. Reasoning: "Maps to [goal], milestone '[milestone]' due [date]."
- If no goal alignment and no `deadlineDate` → candidate for **Deprioritize**.

**3. Deadline check:**
- If `deadlineDate` exists and is within 3 days → **Tomorrow** (or next available day with capacity). Reasoning: "Hard deadline [date] — [N] days remaining."
- If `deadlineDate` exists but is 4+ days out → defer to 2 days before deadline.

**4. Calendar capacity check:**
- Calculate tomorrow's available hours = free time minus estimated load from existing tasks (P1=2h, P2=1h, P3/P4=30m, or use task `duration` field if set).
- If remaining capacity < 1 hour → tomorrow is **packed**. Look at day+2 and day+3 for the next day with 2+ hours free.

**5. Priority balancing:**
- If 4+ P1 tasks are already due tomorrow → defer P2–P4 tasks to a later day. Reasoning: "Already X P1 tasks due tomorrow — deferring to avoid overload."
- If all incomplete tasks are from the same area (all Work or all Personal) → note work/personal balance in the recommendation.

**6. Recommendation assignment** (in priority order):

| Condition | Recommendation |
|-----------|---------------|
| Rolled 3+ times in 14 days | Drop or Break Down |
| Goal milestone within 7 days | Escalate + Move: [date] |
| Hard deadline within 3 days | Move: Tomorrow (or next free day) |
| Tomorrow has capacity + aligns with priorities | Move: Tomorrow |
| Tomorrow packed, capacity day+2/+3 | Move: [Specific date] |
| No goal alignment, no deadline, P3/P4 | Deprioritize |

#### 5c. Present Recommendations

Display as a structured table:

```
## Reschedule Recommendations

Tomorrow (Fri 4/11): ~3h free, 2 tasks already due

| Task | P | Rec | Reason |
|------|---|-----|--------|
| Submit expenses | 1 | Move: Tomorrow (Fri) | Hard deadline Mon, 2h free block available |
| Draft metrics | 2 | Move: Mon 4/14 | Tomorrow packed; AI goal milestone 4/15 |
| Review slides | 2 | Escalate + Move: Tomorrow | QBR goal milestone 4/8, 3 days away |
| Organize photos | 3 | Deprioritize | No goal alignment, no deadline |
| Update CRM | 4 | Drop or Break Down | Rescheduled 4x in 14 days |
| Call dentist | 4 | Move: Wed 4/16 | Personal task, tomorrow all-work — balance |

Confirm all, adjust per task, or skip?
```

**User interaction:**
- **"confirm all"** — apply all recommendations
- **Per-task adjustments** — user modifies individual rows, then confirms
- **"skip"** — leave all tasks as-is (no rescheduling)

#### 5d. Apply Changes

For confirmed reschedules, use `reschedule-tasks` (never `update-tasks` for date changes — preserves recurrence). Batch confirmed tasks into a single call where possible.

For **Escalate** recommendations that include a priority bump, use `update-tasks` to change priority only (separate call from reschedule).

For **Deprioritize** where user confirms removing the due date, use `update-tasks(dueString: "remove")`.

For **Drop** recommendations, ask: "Remove from Todoist or mark complete?" — then `delete-object` or `complete-tasks` accordingly.

**Never reschedule without user confirmation.**

### 6. Sync Meeting Transcripts

**Write deferral:** Prepare all transcript files, meeting note updates, and People note updates in memory. Do NOT write to the vault until Step 10.

**Cross-skill caching:** Reuse calendar events from Step 2 (both [Work] and [Personal]) for transcript-to-meeting matching. Do NOT re-fetch via `gcal_list_events` or `manage_calendar`. Similarly, reuse Todoist task data from Step 2 for deduplication.

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

### 6b. People Notes — Calendar Catch-All

After sync-meetings (Step 6), ensure People notes are updated for ALL of today's meetings — not just those with transcripts.

1. Gather all today's meeting notes: Glob `~/Documents/PersonalOS/Meetings/YYYY-MM-DD-*.md` (using today's date)
2. For each meeting note, read the `attendees:` frontmatter field
3. For each attendee, check if their People note was ALREADY updated by sync-meetings in Step 6 (track which People were updated during transcript processing to avoid double-updating)
4. For attendees NOT already updated:
   - **If People note exists:** update `last_interaction` to today, prepend to `## Meeting History`: `- YYYY-MM-DD: [[Meetings/slug|Title]] — (no transcript)`
   - **If People note doesn't exist:** collect for user confirmation: "These attendees don't have People notes: [list]. Create notes for any? (y/n for each)"
   - For confirmed new People: create `People/First-Last.md` from the Person template with `first_met` and `last_interaction` set to today, add the meeting to `## Meeting History`
5. Skip attendees that are the user themselves (match against CLAUDE.md Identity section)

This ensures every person you met today has an up-to-date `last_interaction` and Meeting History entry, regardless of whether a transcript was recorded.

Prepare all People note updates in memory — writes happen in Step 10.

### 6c. People Notes — Relationship Catch-All

After calendar-based People note updates (Step 6b), also update People notes for non-meeting interactions detected today:

1. **iMessage family contacts:** If iMessage data from Step 2 shows conversations with core family members (Bonnie-Rahman, Asiya-Rahman, Malik-Rahman, Sadia-Rahman, Zakia-Rahman) today, update their People note `last_interaction` to today's date. Add to Meeting History as: `- YYYY-MM-DD: iMessage conversation — [brief topic if action items were detected, otherwise "check-in"]`
2. **Personal email contacts:** If personal email data from Step 2 included exchanges with people who have People notes, update `last_interaction` accordingly.
3. This ensures family and friend People notes stay current even when interactions are informal (texts, calls) rather than calendar meetings.

Prepare all updates in memory — writes happen in Step 10.

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
   - **Project routing:** If the source event was tagged **[Personal]** (from personal calendar), route the task to Todoist project "Personal" instead of "Work". If the source event was tagged **[Work]**, route to "Work" (or use default project logic).
   - **Labels:** `meeting-action` + any label mapped from the source meeting's `project:` frontmatter. Check the source meeting note's `project:` field and look up the Todoist Label → Obsidian Project Map in CLAUDE.md. If the meeting has `project: "[[Projects/ai-transformation]]"`, add label `AI Transformation`. If no mapping exists or no project is set, use `meeting-action` only.
6. **Report:** "Created X Todoist tasks from today's meeting notes."

If no meeting notes exist for today, or no action items are found assigned to the user, skip with: "No new action items found in today's meeting notes."

### 8. Generate Reflection (Claude's Analysis)

Write a 5-8 sentence reflection covering:
1. **What went well** — completed tasks, productive meetings, good focus blocks
2. **What didn't go as planned** — incomplete items, interruptions, context switching
3. **Pattern observation** — connect to broader trends if possible (e.g., "This is the third day this week where afternoon focus time got eaten by unplanned meetings")
4. **Tomorrow suggestion** — one concrete, actionable thing to try tomorrow
5. **Work-life balance signal** — compare today's [Work] meeting hours vs [Personal] events. If the ratio is heavily skewed (4:0 or worse) for 3+ consecutive days, name it. Reference the user's anti-goals from `Goals/2026.md` and their decision filter ("Does this ground me or scatter me?"). Connect to mood trend if mood has been below 5 for 2+ days. Frame as observation, not judgment.

Tone: honest and constructive, like a thoughtful life coach — not just a work coach. Not overly positive or negative.

**This is Claude's perspective only.** Present it in the terminal, then proceed to Step 8 to get the user's own reflection.

### 9. Interactive Check-In (User's Reflection)

**STOP and ask the user before writing anything to Obsidian.** Present Claude's reflection from Step 8, then the compressed prompt below.

**Auto-detect before prompting** (silent; used to pre-fill lead-indicator answers):
- Todoist completed tasks for keywords: "lift", "gym", "trainer", "yoga", "mobility", "meditation", "breathwork", "walk", "run", "hike", "outdoor"
- Today's calendar for personal events matching fitness, social, or family activities
- iMessage data for conversations with family members (Bonnie, parents, sisters)

**Single-line compressed prompt:**

> **[ASK] Your turn** — Highlight (one thing proud of / grateful for), Adjustments (one thing to do differently tomorrow), scores 1-10 for Energy / Focus / Impact / Balance / Mood, and any Personal wins (skip if none).
>
> **Auto-detected from today:** [e.g., "1 lift session (APT 3:15 PM), no meditation, 1 outdoor walk, couple time detected (Big Fish dinner)"]. Correct any errors; otherwise I'll use these for lead indicators.

Generate the auto-detected summary dynamically from current quarter's lead indicators (`Goals/YYYY-QX.md`) — daily/weekly frequency indicators only. The goal: user answers one prompt, not a multi-part questionnaire.

**Sunday micro-planning (Sunday only)** — add this after the standard check-in, as a separate `[ASK]` block:

> **[ASK] Sunday preview** — Family (parents + sisters this week?), Marriage (couple night when?), Health (lift schedule? meditation?), Social (who to reach out to?). Capture as Todoist tasks in "Personal" / "Us" at P2.

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
  - `## Incomplete` — Smart Reschedule table from Step 5: task, priority, recommendation, reason, and new date if rescheduled
  - `## Reflection` — Claude's auto-generated reflection text (clearly labeled: `<!-- Claude's analysis -->`)
  - `## My Reflection` — the user's own words from Step 8:
    - `### Highlight` — user's response (or placeholder comment if skipped)
    - `### Adjustments` — user's response (or placeholder comment if skipped)
    - `### Check-In` — table with 5 scores from user (or blank if skipped)
  - `## Lead Indicators` — table with today's lead indicator responses and running weekly totals:
    ```markdown
    ## Lead Indicators
    | Indicator | Today | Week Total |
    |-----------|-------|------------|
    | Lift session | y | 2/3-4 |
    | Meditation | n | 1/5 |
    | Couple time | n | 0/1 |
    | Outdoor time | y | 2/2 |
    | Friend/family outreach | — | 0/2 (monthly) |
    ```
    To calculate Week Total: read all daily notes from the current week (Monday through today), tally each indicator's "y" responses. Compare against targets from the quarterly goals file. If no prior daily notes have Lead Indicators sections yet, start fresh with today as the first data point.
  - `## Personal` — user's personal wins from Step 9 (only if provided; omit section entirely if skipped)

- **Frontmatter scores:** Only write scores to YAML frontmatter if the user provided them in Step 8. Never fill in scores from Claude's perspective. Leave blank if user hasn't provided scores.

- If the file doesn't exist, create it with all sections (Plan section will note "No morning plan recorded").

Display the full reflection in the terminal as well.

## Output Format

Display the reflection in two tiers: a compact terminal view and a full Obsidian daily note.

**Terminal output (Quick View):**

<!-- Output order: header stats → Completed (progress) → Flags for Tomorrow (decisions) → Reflection (Claude's take) → Check-In (user response) → summary line. Do not reorder. -->

Legend for the one-line header at the top of output:
`[ASK] needs you to respond now. [TODO] = something to act on later. Everything else is context.`

```
# Daily Reflection — YYYY-MM-DD
✓ preflight ok (N/N services + vault)
[ASK] needs you to respond now. [TODO] = something to act on later. Everything else is context.

Meetings: X (Yh) [W work / P personal]  |  Tasks: A/B completed (Z%)  |  Unplanned: X

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

**Marker usage rules** (apply across output above):
- `[ASK]` tag prefixes any line that needs the user to respond now (e.g., the compressed check-in prompt in Step 9, Smart Reschedule `confirm all / adjust / skip`, action-item Todoist creation).
- `[TODO]` tag prefixes any line representing a deferred action item surfaced from the reflection (rare in terminal output — Obsidian daily note is where TODO items land).
- Do not introduce `[INFO]`, `[DECISION]`, `[QUESTION]`, `[ACTION]` — only two markers. Unadorned prose = reference.
- `/reflect` preflight behavior matches `/morning-plan`: print single-line footer on pass, loud prompt on fail (`[ASK] Todoist unreachable — continue with calendar data only?`).

**Obsidian daily note gets EVERYTHING:**

The full reflection written to `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md` includes all of the above plus:

- `## Incomplete` — Smart Reschedule recommendation table with per-task reasoning and applied dates
- `## Action Loop` — morning surfaced count, resolved, pending, unaddressed with options
- `## Action Items → Todoist` — from meeting note sweep (Step 7), per-item confirmation
- Meeting-by-meeting transcript summaries from Step 6

**Note:** The Obsidian daily note retains the standard markdown table format for Check-In scores (for Dataview compatibility). The visual bars are terminal-only.

## Notes
- Timezone: America/Los_Angeles
- Dates: YYYY-MM-DD
- Be empathetic but honest in reflections
- Never reschedule without user confirmation
- **Smart Reschedule tools:** Use `reschedule-tasks` for date changes (preserves recurrence), `update-tasks` only for priority changes or due date removal, `complete-tasks` or `delete-object` for drops. Never use `update-tasks` for date changes.
- Reference CLAUDE.md for paths and conventions
- **Dual calendar:** Work calendar via `gcal_list_events` (srahman@ripple.com), personal calendar via `manage_calendar(operation: "agenda")` on google-personal MCP (1srahman@gmail.com). Personal events show full details with [Personal] tag. See CLAUDE.md Google Account Mapping for tool routing.
