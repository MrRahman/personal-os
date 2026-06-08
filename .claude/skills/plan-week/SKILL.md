---
name: plan-week
description: Scan next week's calendar, allocate focus/prep/admin blocks based on weekly review priorities and energy patterns, create calendar events
---

# Plan Week

Scan next week's calendar and create focused time blocks (focus, prep, admin, catch-up) based on weekly review priorities, energy patterns, and task durations. Designed to run after `/weekly-review` to eliminate daily block creation overhead.

**Output conventions:** Follows `.claude/skills/_conventions.md` — two-marker system (`[ASK]` / `[TODO]`), brief-on-pass preflight footer, decisions-before-reference ordering.

## Instructions

### 1. Preflight Check

Verify access to required services:
- **Required:** Google Calendar (gcal_list_events, gcal_create_event), Todoist (find-tasks), Obsidian vault (~/Documents/PersonalOS)
- **Optional:** Notion (KB action items)

If Google Calendar is unavailable, abort — this skill cannot run without it.

### 2. Determine Week Range

Calculate the target week:
- If today is **Friday**: target = next Monday through Friday
- If today is **Saturday or Sunday**: target = upcoming Monday through Friday
- If today is **Monday–Thursday**: target = next Monday through Friday (user is re-planning mid-week)

Store: `preview_week` (ISO format YYYY-WXX), `mon_date` through `fri_date` (YYYY-MM-DD).

If re-running mid-week (Mon–Thu), ask: "Plan the rest of this week, or next week?" and adjust range accordingly.

### 3. Gather Data (parallel)

Fetch all data sources in parallel where possible:

**A. Next week's calendar:**
- `gcal_list_events` for each day Mon–Fri, work calendar
- `gcal_list_events` for each day Mon–Fri, personal calendar (for personal blocks like APT, travel)
- Capture: event title, start/end time, attendees (names + emails), conferencing links, description

**B. Weekly review priorities:**
- Read `~/Documents/PersonalOS/Weekly Reviews/YYYY-WXX.md` (current week's review)
- Extract the `## Next Week Priorities` section — expect 3-5 items
- If no weekly review exists yet, ask: "No weekly review found for this week. What are your top 3-5 priorities for next week?"

**C. Quarterly goals:**
- Read `~/Documents/PersonalOS/Goals/YYYY-QX.md`
- Extract each goal's `This Week` section and any milestones due within 14 days
- Flag approaching milestones that need dedicated block time

**D. Todoist tasks due next week:**
- `find-tasks-by-date` for the Monday–Friday range
- Also fetch overdue P1/P2 tasks
- Note the `duration` field on each task (e.g., "2h", "90m") — this drives time estimation

**E. Energy patterns (from daily reflections):**
- Read the past 5 workday daily notes: `~/Documents/PersonalOS/Daily/YYYY-MM-DD.md`
- From each, extract Check-In scores (energy, focus) from frontmatter or Check-In section
- Compute per-day-of-week averages:
  - Monday avg energy/focus, Tuesday avg, etc.
  - Classify: High (avg ≥ 7), Medium (4-6), Low (< 4)
- If fewer than 3 data points, skip energy-based placement and use default preferences (mornings for deep work)

**F. Recurring block patterns:**
- Scan the past 2 weeks of calendar events
- Identify user-created blocks by: title matching `Focus:*`, `Travel*`, `APT`, `Prep:*`, `Admin:*`, `Catch up*`, `Hold for*`, `DNS*`; OR single/no attendees with no conferencing link
- Build pattern map: e.g., "APT = Tue/Thu 3:15-5:15 PM", "Travel to office = Mon/Wed/Fri 7:15-8:00 AM"
- These patterns are auto-anchored in Pass 1 even if not yet on next week's calendar

### 4. Block Allocation Algorithm

Run four passes. Each pass is constrained by the outputs of the previous.

#### Pass 1: Anchor Immovable Events

Mark these as fixed on the per-day time grid:

**Real meetings** (cannot be moved):
- Events with 2+ attendees
- Events with a conferencing link (Zoom, Meet, Teams)
- Events matching meeting title patterns: contains names, "1:1", "1x1", "sync", "staff", "standup", "QBR", "offsite", "review", "interview"

**Recurring personal blocks** (carry forward from pattern scan):
- APT on known recurring days/times
- Travel to office on known office days
- DNS / dinner holds on recurring slots
- Any `Hold for*` events already on the calendar

**Output:** Per-day time grid showing occupied slots and open slots (gaps of 15+ minutes).

#### Pass 2: Allocate Priority Focus Blocks

For each of the 3-5 weekly priorities (from Step 3B):

**1. Estimate time needed:**
- If a matching Todoist task has a `duration` field → use it
- If multiple sub-tasks → sum their durations
- If no duration: P1 tasks → 2h, P2 → 1h, P3 → 30m
- For multi-day priorities (e.g., "Build competitive briefing"): split into 2-3 sessions across different days

**2. Score each day for placement:**
- **Contiguous free time (0-40 pts):** Prefer days with the largest unbroken free block. 3h gap = 40 pts, 2h = 30, 1h = 20, 30m = 10.
- **Energy match (0-30 pts):** For deep-focus priorities (writing, strategy, proposals), prefer high-energy days (from Step 3E). For admin/routine work, any day works. 30 pts for High, 15 for Medium, 0 for Low.
- **Deadline proximity (0-20 pts):** If priority has a due date, 20 pts for placing the block ≥2 days before deadline, 10 pts for 1 day before, 0 pts for same day.
- **Meeting context (0-10 pts):** If priority relates to a specific meeting (e.g., "Prep offsite slides" and offsite is Wednesday), 10 pts for placing the block the day before.

**3. Place the block:**
- Choose the highest-scoring day
- Within that day, prefer morning slots (before noon) for deep-focus work
- If the estimated time exceeds the largest contiguous gap, split across two slots on the same day or across two days

**Placement rules:**
- Focus blocks must be ≥ 60 min for P1 priorities, ≥ 30 min for P2/P3
- Maximum 2 focus blocks per day (prevent over-scheduling)
- Leave ≥ 15 min buffer between a focus block and the next meeting
- Name format: `Focus: [priority short name]` (e.g., `Focus: AI output metrics draft`)

#### Pass 3: Allocate Prep Blocks

Scan the meeting grid. For each meeting, determine if it warrants prep time:

**Prep rules:**
- **Executive-facing meetings** (attendees include Brad, Monica, Stuart, or other exec staff; OR title contains "staff", "QBR", "offsite", "skip level", "board"): **30 min** prep block before the meeting
- **1:1 meetings** (title contains "1:1", "1x1", "weekly", or exactly 2 attendees): **15 min** prep block before the meeting
- **External meetings** (attendees with non-@workco.com, non-@affiliate.com emails): **15 min** prep block
- **Large group meetings** (5+ attendees, non-recurring): **15 min** prep block

**Placement:**
- Place prep immediately before the meeting
- If no free time exists before the meeting (back-to-back), skip the prep block for that meeting
- Do NOT displace an already-allocated focus block for a prep block
- Name format: `Prep: [meeting name]`

**Also add transition buffers:**
- If two meetings have a 5-15 min gap: mark as `Buffer` (not usable, prevents scheduling into it)
- Buffers are informational — they don't create calendar events

#### Pass 4: Allocate Admin and Catch-Up Blocks

**Admin batch:**
- If there are 5+ small tasks (P3/P4, no duration or duration < 30m): propose one 30 min `Admin: Clear small tasks` block
- Prefer Monday morning (clear chronic rollers early in the week)
- If Monday morning is full, try Tuesday or Friday afternoon

**Catch-up blocks (from Relationship Radar):**
- If the weekly review's Relationship Radar flagged stale contacts: propose 30 min `Catch-up: [name]` blocks
- Prefer afternoons (lower-energy periods)
- Maximum 2 catch-up blocks per week

**Fitness / habit blocks:**
- If the quarterly goals include a fitness goal with a weekly cadence target, ensure hold times are preserved
- If known gym patterns exist from Step 3F, auto-anchor them
- If no pattern but goal exists, propose blocks based on the target (e.g., "4 lift sessions → Mon/Tue/Thu/Fri")

### 4b. Goal Decomposition (v2.0+)

After the standard week planning, decompose goals into per-project work units that can be dispatched to agents via `/dispatch`.

For each active goal in `Goals/YYYY-QX.md`, for each linked project in its `Projects:` field:
1. Read the project's Obsidian note (`~/Documents/PersonalOS/Projects/<slug>.md`). Check frontmatter for `agent_dispatch: enabled` — skip if disabled or if `repo:` is missing for code-touching work.
2. Review the goal's `## This Week` section + current milestone.
3. Propose 2-4 concrete work units for this week that advance the goal via this project. Each unit:
   - **id**: short slug, e.g. `draft-homepage-hero-copy`, `implement-rss-feed`
   - **description**: one line, action-oriented
   - **type**: `autonomous` (research, drafting, docs, planning — can run in background) or `supervised` (code changes — terminal session)
   - **estimated_time**: minutes
4. Append to the project note's `## Proposed Work Units (Week YYYY-WXX)` section:
   ```
   ## Proposed Work Units (Week 2026-W17)
   - [ ] draft-homepage-hero-copy: Draft homepage hero copy for sulaiman.co landing — autonomous — est 10m
   - [ ] review-seo-keywords: Review SEO keyword candidates — autonomous — est 8m
   - [ ] implement-rss-feed: Add RSS feed generator to sulaiman.co — supervised — est 20m
   ```

**Decision rule for type:**
- Touches source code / git diff? → **supervised**
- Pure content / research / docs? → **autonomous**
- When unclear: default to **supervised** (safer).

**Present the decomposition as `[ASK]`:**
```
## Goal Decomposition

Proposed work units (6 across 3 projects):

personal-brand-system (Goal: Personal Brand)
  - [ ] 1. draft-homepage-hero-copy — autonomous, 10m
  - [ ] 2. review-seo-keywords — autonomous, 8m
  - [ ] 3. implement-rss-feed — supervised, 20m

job-search (Goal: Career — From Grind to Growth)
  - [ ] 4. update-resume-bullets-for-april — autonomous, 8m
  - [ ] 5. draft-linkedin-post-ai-transformation — autonomous, 12m

ai-transformation (Goal: Career)
  - [ ] 6. research-anthropic-enterprise-pricing — autonomous, 12m

[ASK] Approve all work units? (y / select subset e.g. "1,3,4" / edit / skip)
```

On `y` or selected subset: append the approved units to each project's note (above). They are now eligible for `/dispatch` during the week.

### 5. Present Proposed Week

Display a day-by-day grid:

```
# Weekly Preview — YYYY-WXX (Mon [date] - Fri [date])

## Priorities This Week
1. [priority] — [estimated time] ([source: review / goal / carryover])
2. ...

## Proposed Schedule

### Monday [date]
  7:15    Travel to office (recurring)
  8:00    ---- Focus: AI output metrics draft (2h) ----
 10:00    SI Staff Weekly ........................ [team, 6 attendees]
 10:30    AI Priority Sync Up ................... [Hope, EvM]
 11:00    ---- Admin: Clear small tasks (30m) ----
 11:30    ---- Prep: 1:1 EvM (15m) ----
 11:45    1:1 EvM & Sul ......................... [EvM]
  1:00    ---- Focus: Competitive briefing prep (1h) ----
  2:00    ---- Prep: Hope 1:1 (15m) ----
  2:15    Hope <> Sul: Weekly 1:1 ............... [Hope]
  3:15    APT (2h, recurring)

### Tuesday [date]
  ...

[repeat for each day]

## Block Summary
| Type       | Count | Total Hours |
|------------|:-----:|:-----------:|
| Focus      |   X   |    Xh       |
| Prep       |   X   |    Xh       |
| Admin      |   X   |    Xh       |
| Catch-up   |   X   |    Xh       |
| Meetings   |   X   |    Xh       |
| Personal   |   X   |    Xh       |
| Unscheduled|   —   |    Xh       |

Focus-to-meeting ratio: X:Y
```

### 6. User Confirmation

Present options:

> "Create these blocks on Google Calendar?"
> - **"yes"** — create all proposed blocks
> - **"adjust"** — modify specific blocks before creating (e.g., "move Tuesday focus to Wednesday", "drop the catch-up block", "make admin 45 minutes")
> - **"focus only"** — only create Focus blocks, skip prep/admin/catch-up
> - **"skip"** — don't create calendar events, just save the plan to Obsidian

If "adjust": collect modifications, re-display the updated schedule, then confirm again.

### 7. Create Blocks + Save

**Calendar events:** For each confirmed block, use `gcal_create_event`:
- **Calendar:** work calendar (for work blocks) or personal (for personal blocks like fitness)
- **Title:** Block name (e.g., `Focus: AI output metrics draft`)
- **Description:** `Created by /plan-week — YYYY-WXX. Priority: [linked priority].`
- **Start/end:** Exact times from the allocation
- **Reminders:** None (avoid notification clutter)

**Obsidian note:** Write `~/Documents/PersonalOS/Weekly Reviews/YYYY-WXX-preview.md`:

```markdown
---
date: YYYY-MM-DD
type: weekly-preview
week: YYYY-WXX
source_review: "[[Weekly Reviews/YYYY-WXX]]"
---

# Weekly Preview — YYYY-WXX

## Priorities
1. [priority] — [estimated time], [source]
...

## Block Plan
### Monday [date]
- 8:00-10:00: Focus: AI output metrics draft
- 11:00-11:30: Admin: Clear small tasks
- 11:30-11:45: Prep: 1:1 EvM
...

### Tuesday [date]
...

## Energy Profile Used
| Day | Avg Energy | Avg Focus | Classification |
|-----|:----------:|:---------:|----------------|
| Mon |    5.3     |    6.7    | Medium         |
| Tue |    6.0     |    6.0    | Medium         |
| Wed |    5.0     |    8.0    | High focus     |
| Thu |    4.0     |    5.0    | Low            |
| Fri |    7.0     |    8.0    | Highest        |

## Blocks Created
- X focus blocks (Yh total)
- X prep blocks (Yh total)
- X admin/catch-up blocks (Yh total)
```

### 8. Wrap Up

Report what was created:

> "Created X blocks for YYYY-WXX: Y focus (Zh), Y prep (Zh), Y admin (Zh)."
> "Your morning-plan will auto-skip these blocks — you'll only be prompted for real meetings."

If run after `/weekly-review`, suggest: "All set. See you Monday morning with /morning-plan."

## Notes
- All times in America/Los_Angeles
- Dates formatted as YYYY-MM-DD
- If Google Calendar is unavailable, abort with clear error
- If no weekly review exists, prompt for manual priority input
- Do not over-schedule: leave at least 1h of unscheduled time per day for unexpected tasks
- Blocks with `Created by /plan-week` in the description are recognized by `/morning-plan` for auto-skipping
- Reference CLAUDE.md for paths, conventions, and identity
