# Morning Plan Meeting Notes Enhancement — Design Spec

## Overview

Enhance the `/morning-plan` skill to include an interactive meeting note creation flow. After presenting the daily schedule, Claude walks through each meeting and offers to create Obsidian meeting notes with pre-filled context.

---

## Meeting Note Flow

Added as a new **Step 5: Meeting Notes** in the morning-plan skill. Steps are renumbered: Preflight (1), Gather Data (2), Analyze (3), Present (4), **Meeting Notes (5)**, Confirm & Save (6).

### Flow per meeting

Skip all-day events, declined events, and cancelled events. Only prompt for timed meetings.

**For work calendar events (full details visible):**

```
Meeting: "Q1 Treasury Review" at 10:00 AM (45min)
  Attendees: Jane Smith, Bob Chen, Sarah Lee
  → Create meeting note? (y/n/skip all)
```

- **y** — create the note with pre-filled context
- **n** — skip this meeting (it's a focus block or not worth a note)
- **skip all** — stop asking for remaining meetings; list skipped meetings briefly ("Skipped notes for: 11:30 AM Team Standup, 3:00 PM 1:1 with Sarah")

**For personal calendar events (free/busy only):**

```
Personal block: 2:00 PM - 3:00 PM (busy)
  → Add a meeting note for this? (y/n/skip all)
  If y → "What's the meeting name?"
```

User provides a title, Claude creates the note with just the template (no attendees or context lookup since we can't see event details).

**Batch approach:** Collect all yes/no responses first, then create all notes in parallel to avoid a slow sequential flow. Present the full meeting list, let the user mark which ones get notes, then execute.

### What gets created

**File:** `~/Documents/PersonalOS/Meetings/YYYY-MM-DD-meeting-title.md`

**Filename slugification rules:**
- Lowercase the title
- Replace spaces, colons, slashes with hyphens
- Collapse consecutive hyphens into one
- Trim leading/trailing hyphens
- Strip remaining special characters
- Example: "1:1 with Jane" → `2026-03-20-1-1-with-jane.md`

**Pre-filled content (moderate level):**

1. **Frontmatter** — date, attendees (as Obsidian wikilinks: `["[[People/Jane-Smith]]", "[[People/Bob-Chen]]"]`), calendar (work/personal), project (inferred from meeting title if possible, otherwise blank), otter_id (blank)
2. **Context section** — 2-3 sentence summary pulled from:
   - Previous meeting notes in `Meetings/` that mention the same attendees (search by name)
   - People notes in `People/` for each attendee (if they exist)
   - The calendar event description (if any)
3. **Everything else** — left empty using the Meeting Note template structure (Summary, Key Points, Action Items, Follow-ups, Transcript Highlights)

The `[[People/First-Last]]` wikilink format is used for attendees even if the Person note doesn't exist yet — the links will resolve once `/reflect` creates them.

**For personal calendar meetings** (user-named): only frontmatter (date, calendar: personal, attendees blank) and empty template sections. No attendee lookup since we can't see event details.

---

## Daily Note Integration

After creating meeting notes, update the Meetings section in `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md` with wikilinks to the created notes:

```markdown
### Meetings
- 10:00 AM: [[Meetings/2026-03-20-q1-treasury-review|Q1 Treasury Review]]
- 2:00 PM: [[Meetings/2026-03-20-dentist-appointment|Dentist Appointment]]
```

This preserves the Obsidian graph relationship between daily notes and meeting notes. Only add links for meetings where notes were created — meetings the user skipped are not linked.

---

## Context Lookup Strategy

For each work meeting where user says "yes":

1. **Search People folder** — look for `People/First-Last.md` for each attendee (up to 5 attendees). If found, read the Context and Key Topics sections.
2. **Search Meetings folder** — glob for recent meeting notes (last 30 days) and grep for attendee names. If found, note the meeting title and date.
3. **Calendar event description** — if the event has a description/body, include it.

Synthesize into a 2-3 sentence Context block like:

> "Recurring weekly sync with Jane Smith (VP Treasury) and Bob Chen (Risk). Last met on 2026-03-13 for 'Treasury Pipeline Review' — discussed stablecoin custody requirements. Jane's key focus areas: regulatory compliance, APAC expansion."

If no prior context exists, write: "No prior meeting notes found for these attendees."

Use parallel tool calls for context lookups across multiple meetings.

---

## People Note Auto-Creation

If an attendee doesn't have a People note and this is a work meeting, **do not auto-create one**. The `/reflect` skill already handles People note creation/updates from meeting history. Morning plan just reads what exists.

---

## Interaction with `/reflect`

The `/reflect` skill also creates meeting notes from Otter.ai transcripts. To avoid duplicates:

- `/reflect` should check for existing meeting notes matching the same date and similar title before creating new ones from transcripts
- If a matching note exists (created by morning-plan), `/reflect` fills in the transcript-derived sections (Summary, Key Points, Transcript Highlights) rather than creating a duplicate
- The `otter_id` field in frontmatter is set by `/reflect` when it links a transcript

This is a note for future `/reflect` updates — not part of this morning-plan spec.

---

## Changes to morning-plan.md

1. **Renumber steps** — Preflight (1), Gather Data (2), Analyze (3), Present (4), Meeting Notes (5), Confirm & Save (6)
2. **Add Step 5: Meeting Notes** — the interactive flow described above
3. **Update preflight check** — add Obsidian vault check: attempt to read `~/Documents/PersonalOS/Templates/Meeting Note.md`. If it fails, skip meeting note flow with a warning. Mark as optional (not blocking).
4. **Update Step 6 (Confirm & Save)** — when writing to the Daily Note, include wikilinks to any meeting notes created in Step 5

The rest of the skill (task categories, free slots, inbox) stays unchanged.

---

## Edge Cases

- **All-day events** — skip in the meeting note flow (usually OOO or holidays)
- **Declined/cancelled events** — skip (filter by RSVP status)
- **Recurring 1:1s** — treat the same as any meeting; context lookup is valuable here
- **Meetings with 10+ attendees** — only look up People notes for the first 5 attendees to avoid context overflow. Note "and X others" in the meeting note.
- **No Obsidian vault access** — if the vault path is unreachable, skip the meeting note flow entirely with a warning
- **Duplicate notes** — if `Meetings/YYYY-MM-DD-meeting-title.md` already exists, warn and ask if they want to overwrite or skip
- **Filename edge cases** — "1:1 with Jane" → `1-1-with-jane`, "Q1/Q2 Review" → `q1-q2-review`
