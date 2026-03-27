---
name: sync-meetings
description: Pull Otter transcripts, match to meeting notes, fill in summaries + action items, store transcripts, and update People notes
---

# Sync Meetings

Pull Otter.ai transcripts, match them to existing meeting notes (or create new ones), extract summaries and action items, store full transcripts, and update People notes. Default: today. Accepts a date parameter.

## Instructions

### 1. Preflight Check

Test access to each service:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Otter.ai | `otter_list_transcripts` (limit 1) | Yes — abort if unavailable, suggest `python3 refresh-otter-cookie.py` |
| Obsidian vault | Read `~/Documents/PersonalOS/Templates/Meeting Note.md` | Yes |
| Google Calendar | `gcal_list_events` (target date) | Recommended (enables time-proximity matching) |
| Todoist | List projects (limit 1) | No (only for optional action item task creation) |

Report availability. If Otter is unavailable, stop and tell the user to run the cookie refresh script. If Obsidian is unavailable, stop. Continue without Calendar or Todoist — just note reduced matching accuracy or skipped task creation.

### 2. Gather Data (parallel)

Determine the target date. Default is today (YYYY-MM-DD). If the user passes a date, use that.

Run all of these in parallel:

**Otter transcripts:** `otter_list_transcripts` filtered to the target date. Collect transcript IDs, titles, start times, durations.

**Existing meeting notes:** Glob `~/Documents/PersonalOS/Meetings/TARGET_DATE-*.md` — read each file's frontmatter (`otter_id`, `attendees`, `calendar`) and H1 title.

**Calendar events (if available):** `gcal_list_events` for the target date from all calendars. Collect event titles, start times, attendees.

**People directory:** Glob `~/Documents/PersonalOS/People/*.md` filenames — build a name resolution map (filename → display name). Only read filenames, not contents.

### 3. Filter Transcripts

Apply these filters to the Otter transcript list:

| Filter | Rule | Behavior |
|--------|------|----------|
| Already processed | A meeting note already has this `otter_id` in frontmatter | Silent skip |
| Too short | Duration < 5 minutes | Skip with message: "Skipped [title] — too short (Xm)" |
| Low substance | < 500 words of dialogue (check after fetching in Step 5) | Ask user whether to process or skip |

### 4. Match Transcripts → Meeting Notes

For each remaining transcript, score against each unmatched meeting note using three signals:

**Time proximity (0–40 pts):**
- Compare transcript start time → calendar event start time (if calendar available) or meeting note date
- Within 15 min = 40, within 30 min = 25, within 60 min = 10, beyond = 0

**Title match (0–30 pts):**
- Normalize both titles: lowercase, strip common words (meeting, sync, weekly, daily, standup, 1:1, one-on-one)
- Word overlap: exact match = 30, >50% shared words = 20, any shared meaningful word = 10, none = 0

**Attendee overlap (0–30 pts):**
- Compare Otter speaker names to meeting note attendee wikilinks and calendar event attendees
- 10 pts per matching attendee, capped at 30

**Scoring thresholds:**

| Score | Action |
|-------|--------|
| 50+ | Auto-match — announce: "Matched [transcript] → [meeting note] (score: X)" |
| 30–49 | Present to user: "Possible match: [transcript] → [meeting note] (score: X). Confirm? (y/n)" |
| < 30 | Unmatched — collect for later |

After matching, for any unmatched transcripts, ask the user:
- "These transcripts didn't match any existing meeting notes: [list]. Create new notes for them? (y/n for each)"

### 5. Process Each Match

For each confirmed match (auto or user-confirmed):

**a. Fetch transcript:**
`otter_get_transcript(transcript_id)` → full text

**b. Check substance:**
If the transcript has < 500 words of dialogue, flag to user: "[title] has very little dialogue (X words). Process anyway? (y/n)"

**c. Extract from transcript** — Claude analyzes the full transcript and produces:

- **Summary** (3–5 sentences): What was discussed, what was decided, what's the outcome
- **Key Points** (4–6 bullets): Decisions made, major discussion topics, important context shared
- **Action Items** as checkboxes with `@[[People/First-Last]]` owner + deadline if mentioned:
  - Explicit commitments ("I'll send that by Friday") → action item
  - Direct requests ("Can you pull those numbers?") → action item
  - Decisions requiring follow-through → action item
  - Vague ("we should think about...") → NOT an action item
  - Unclear owner → "owner unclear, raised by [[People/Speaker-Name]]"
- **Decisions** — explicit decisions made during the meeting:
  - "We decided to...", "The decision is...", "We're going with...", "Brad approved...", "Agreed to...", "[Person] signed off on..."
  - NOT vague direction ("we should think about...") or preferences ("I'd prefer...")
  - Format: `- **[Topic]**: [Decision made] — decided by [[People/First-Last]], context: [one-line why]`
- **Commitments** — promises made by or to the user:
  - Detect: "I'll...", "Let me...", "I'll send you...", "Can you send me...", "I'll follow up with...", "[Person] will..."
  - Capture: who committed, what they committed to, deadline if mentioned, and which direction (user → them, or them → user)
  - These will be written to People notes in Step 6.
- **Follow-ups** (future attention items, not immediate actions)
- **Transcript Highlights** (2–4 notable quotes with speaker name + approximate timestamp)

**d. Write full transcript file:**

Path: `~/Documents/PersonalOS/Meetings/Transcripts/YYYY-MM-DD-slug.md`

Use the same slugification rules as morning-plan: lowercase, replace spaces/colons/slashes with hyphens, collapse consecutive hyphens, trim, strip special chars.

```markdown
---
date: YYYY-MM-DD
meeting: "[[Meetings/YYYY-MM-DD-slug]]"
otter_id: transcript_id_here
speakers:
  - Speaker One
  - Speaker Two
duration: XXm
---

# Meeting Title — Transcript

**Speaker One** (0:00): First line of dialogue...
**Speaker Two** (0:45): Response...
[full transcript content, preserving speaker labels and timestamps]
```

Create the `Meetings/Transcripts/` directory if it doesn't exist.

**e. Update meeting note:**

Fill in the meeting note sections — replace placeholder content but preserve frontmatter structure:

- Set `otter_id` in frontmatter to the Otter transcript ID
- Fill `## Summary` with the extracted summary
- Fill `## Key Points` with extracted bullets
- Fill `## Decisions` with extracted decisions. If no decisions were made, omit this section rather than leaving it empty.
- Fill `## Action Items` with extracted action items (checkbox format)
- Fill `## Follow-ups` with extracted follow-ups
- Fill `## Transcript Highlights` with extracted quotes
- Add `## Transcript` section at the bottom with a link: `Full transcript: [[Meetings/Transcripts/YYYY-MM-DD-slug|View Transcript]]`

If the match is to a NEW note (no existing file), create the note using the Meeting Note template with all sections filled in.

**f. Resolve speaker names:**

Speaker resolution is critical for building the Obsidian knowledge graph. Use ALL available signals:

1. **Otter speaker labels** — if Otter identified speakers by name, map directly to `[[People/First-Last]]`
2. **Calendar attendees** — cross-reference the meeting's attendee list from Google Calendar
3. **Context clues in dialogue** — look for names mentioned in conversation ("Monica reported on Brazil", "Mark's team", "as Brad said"), someone being addressed directly, or self-identification
4. **User's My Notes section** — if the user added notes to the meeting file with speaker names (e.g., "Brad - heading to DC"), use these to confirm speaker identity
5. **People directory** — match against existing `People/*.md` files for known contacts

Apply resolved names in:
- `## Transcript Highlights` — use `[[People/First-Last]]` for speaker attribution (e.g., "[[People/Brad-Garlinghouse]] (~5min): 'One of the problem statements...'")
- `## Key Points` — attribute key decisions and updates to specific people where clear
- `## Action Items` — use `@[[People/First-Last]]` for owners
- Transcript files — replace generic "Speaker:" labels with resolved names where confident

If a speaker cannot be confidently identified, use "Unknown Speaker" rather than guessing. Flag in the summary: "X of Y speakers could not be identified."

**g. Vault connection scan:**

After extracting content from the transcript, scan the vault for related notes and auto-populate the meeting note's connections:

1. **Search Resources/** — grep for topic keywords from the meeting (e.g., if the meeting discussed "AI metrics", search Resources for files tagged `#topic/AI`). Add up to 3 most relevant as wikilinks in a `## Related Resources` section or append to Key Points where contextually relevant.

2. **Search recent Meetings/** — glob for meeting notes from the last 14 days involving the same attendees. If found, add a link in Context: "Last met on YYYY-MM-DD in [[Meetings/slug|Title]]". This creates continuity threads across meetings.

3. **Cross-link Topics** — if the meeting covered topics that have Topic MOCs (e.g., `Topics/AI.md`, `Topics/Career.md`), add the meeting as a reference in the relevant Topic MOC's `## Key People` or a new `## Related Meetings` section.

4. **People → Topics** — if a person is clearly associated with a topic (e.g., Hope works on AI, Treasury; Marc on Prime, Crypto), add `[[Topics/TopicName]]` links to their People note's `## Key Topics` section if not already there.

Keep links conservative — only add when the connection is clear and meaningful. 3-5 cross-links per meeting note is the target, not exhaustive.

### 6. Update People Notes

For each person mentioned across all processed transcripts:

**Known people** (file exists in `People/`):
- Read the current file
- Prepend to `## Meeting History`: `- YYYY-MM-DD: [[Meetings/YYYY-MM-DD-slug|Meeting Title]] — one-line context from summary`
- Update `last_interaction` in frontmatter to the target date
- **Write commitments to `## Open Commitments`** (if the section exists):
  - From the Commitments extracted in Step 5c, find ones involving this person
  - Under `### I owe them`: add commitments the user made to this person. Format: `- (YYYY-MM-DD) [commitment text] — from [[Meetings/slug]]`
  - Under `### They owe me`: add commitments this person made to the user. Format: `- (YYYY-MM-DD) [commitment text] — from [[Meetings/slug]]`
  - Before writing new commitments, scan existing ones: if a matching Todoist task is completed or a Slack/email shows follow-through, mark the old commitment with ~~strikethrough~~
  - If the People note doesn't have an `## Open Commitments` section yet, create it (following the Person template structure)

**Unknown speakers** (no matching file):
- Collect all unknown names
- Present to user: "These speakers don't have People notes: [list]. Create notes for any? (y/n for each)"
- For confirmed ones, create `People/First-Last.md` using the Person template:
  - Set `name`, `first_met` to target date, `last_interaction` to target date, `relationship: work`
  - Add the meeting to `## Meeting History`
  - Leave other fields empty for manual fill

### 7. Slack Cross-Check (optional, if Slack available)

Before presenting action items, cross-reference them against recent Slack activity to avoid creating tasks for things already resolved:

For each action item owned by the user:
1. Search Slack using `slack_search_public_and_private` with keywords from the action item + attendee names, filtered to `after:TARGET_DATE`
2. If a matching Slack message indicates the action was completed (e.g., "sent", "done", "shared", "updated"), mark it as **resolved** and note the Slack evidence
3. If Slack shows additional context (e.g., someone responded with more info), append that context to the action item description

Present resolved items separately: "These action items appear resolved based on Slack activity: [list with evidence]"

Skip this step if Slack is unavailable.

### 8. Todoist (optional, user-confirmed)

Collect all **unresolved** action items where the owner is the user (Sulaiman / me / I) across all processed transcripts.

If there are any:
- Present the list: "You have X action items from today's meetings. Create Todoist tasks? (y/n)"
- Clearly mark any items that were flagged as potentially resolved by Slack cross-check
- If confirmed, create tasks in the **Work** project with:
  - `follow-up` label
  - **`waiting-on` label** (in addition to `follow-up`) if the action item owner is someone other than the user — i.e., the user is waiting on someone else to deliver. Detection: if the owner `@[[People/...]]` is NOT Sul/Sulaiman/me/I, add `waiting-on`.
  - Due date from the action item if mentioned, otherwise tomorrow
  - Description: "From [[Meetings/YYYY-MM-DD-slug|Meeting Title]]"

### 9. Summary Display

Show a compact summary:

```
## Sync Complete — YYYY-MM-DD

Transcripts processed: X | Notes updated: X | People updated: X
Action items: X (Y yours) | Todoist tasks created: X
Skipped: X (reasons)
Transcript files: ~/Documents/PersonalOS/Meetings/Transcripts/
```

## Edge Cases

- **No morning plan was run:** All transcripts are unmatched → skill creates new meeting notes from scratch using the template
- **Multiple transcripts for one meeting:** If two transcripts score 50+ against the same note, flag to user: "Multiple transcripts match [meeting]. Concatenate them? (y/n)"
- **Very long transcripts (60+ min):** Process fully — do not truncate. Note that processing may take longer.
- **Unidentified speakers:** Use "Unknown Speaker" in action items and highlights. Flag in summary.
- **Otter auth expired:** Preflight catches this → tell user: "Otter connection failed. Run: `python3 mcp-servers/refresh-otter-cookie.py`"
- **No transcripts found:** "No Otter transcripts found for YYYY-MM-DD. Nothing to sync."
- **Transcript already processed:** Silent skip — idempotent by design

## Notes
- Timezone: America/Los_Angeles
- Dates: YYYY-MM-DD
- Slugification: lowercase, hyphens for spaces/colons/slashes, collapse consecutive hyphens, strip special chars
- Never auto-create People notes without user confirmation
- Never auto-create Todoist tasks without user confirmation
- Reference CLAUDE.md for paths and conventions
