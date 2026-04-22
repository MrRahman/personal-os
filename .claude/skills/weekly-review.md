---
name: weekly-review
description: Full-week retrospective analyzing calendar, tasks, daily reflections, and KB captures to generate priorities for next week
---

# Weekly Review

Comprehensive week retrospective that analyzes calendar time, task completion, daily reflections, and knowledge base activity to produce an actionable summary and next-week priorities.

## Instructions

### 1. Preflight Check

Test access to:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Google Calendar (Work) | `gcal_list_events` | Yes |
| Google Calendar (Personal) | `manage_calendar(operation: "agenda")` via google-personal MCP | No |
| Todoist | List tasks | Yes |
| Notion | `search_objects` | No |
| Readwise | `reader_list_documents` (limit 1) | No |
| Obsidian vault | Read `~/Documents/PersonalOS/` | Yes |

See CLAUDE.md Google Account Mapping for tool-to-account details.

**Preflight output rule** (matches `/morning-plan`):
- If every required service passes: single-line footer at the top: `✓ preflight ok (N/N services + vault)`. Do not itemize.
- If any required service fails: STOP with `[ASK] <service> unreachable — <one-sentence fix>. Continue with what works (y/n)?`
- Skills use `[ASK]` for user prompts that need a response now, `[TODO]` for deferred action items. No other markers (per v1.7 convention).

### 2. Determine Week Range

Use the current ISO week (Monday to Sunday). Calculate:
- `week_number`: YYYY-WXX format
- `start_date`: Monday's date (YYYY-MM-DD)
- `end_date`: Sunday's date (YYYY-MM-DD)

Timezone: America/Los_Angeles.

### 3. Gather Data

Run in parallel where possible:

**Calendar (dual query — run both in parallel):**

1. **[Work]** Use `gcal_list_events` (claude.ai Google Calendar integration) to get all events from Monday through Sunday. This covers srahman@ripple.com calendars.
2. **[Personal]** Use `manage_calendar(operation: "agenda")` via the **google-personal** MCP server to get all events for the same Monday-through-Sunday range. This covers 1srahman@gmail.com calendars.

Merge both result sets into a single timeline. Tag every event **[Work]** or **[Personal]** based on which query returned it. If the personal calendar is unavailable (preflight failed), continue with work-only data and note the gap.

**Todoist — Completed:** Fetch tasks completed during the week.

**Todoist — Incomplete/Overdue:** Fetch tasks that were due this week but remain open.

**Obsidian Daily Notes:** Read all daily notes for this week from `~/Documents/PersonalOS/Daily/`. Look for files matching the week's dates (YYYY-MM-DD.md). Extract reflection sections from each. Track coverage: count days with a daily note, days with a completed reflection, and days skipped (file exists with `*Skipped — no reflection recorded.*` or no file at all). Report as "Reflected X/7 days" in the output. Do not backfill or create notes for missed days.

**Notion KB:** Query "AI Knowledge Base" for items where Date Captured falls within this week.

### 4. Analyze

**Completion rate:** Tasks completed / total tasks due this week. Break down by project if useful.

**Time analysis (work + personal split):**
- Work meeting hours (from [Work] calendar events)
- Personal event hours (from [Personal] calendar events)
- Total scheduled hours (work + personal combined)
- Estimated focus hours (gaps between ALL events during work hours, 9 AM - 6 PM)
- Meeting-heavy days breakdown by type: flag days with 4+ hours of [Work] meetings; separately flag days with significant [Personal] blocks that reduced focus time
- Work/personal balance ratio for the week

**Block adherence (if /plan-week was used):** Check if a `Weekly Reviews/YYYY-WXX-preview.md` file exists for this week. If so, read the planned blocks and compare against what actually happened on the calendar:
- Count plan-week blocks that survived (still on calendar at their original time)
- Count plan-week blocks that were displaced (moved or deleted due to new meetings)
- Report: `Block adherence: X/Y focus blocks kept (Z displaced by new meetings)`
- If adherence is below 50%, note which days lost the most blocks — this informs next week's `/plan-week` to deprioritize those days for deep work.

**Reflection themes:** Read through the week's daily reflections and identify:
- Recurring wins or positive patterns
- Recurring frustrations or blockers
- Any themes that appeared 3+ times

**Chronic blockers:** Tasks that were due early in the week and rolled forward repeatedly (appeared in multiple daily "Incomplete" lists). Flag anything that rolled 3+ days.

**Energy patterns:** Based on reflections and completion data, note which days felt most/least productive.

**Balance Analysis:**
- Calculate total work meeting hours for the week (from calendar data)
- Calculate total personal event hours for the week
- Calculate average mood score for the week (from daily note frontmatter)
- If mood average is below 5 AND work meeting hours exceed 20: flag "High work load + low mood correlation detected"
- Compare this week's lead indicator completion rate vs last week's. If declining, note the trend.
- Check anti-goals from `Goals/2026.md` and flag any that appeared this week (e.g., "Working 10-12 hour days regularly")
- Present the decision filter question: "Reviewing this week through 'Does this ground me or scatter me?' — which days grounded you? Which scattered you?"

**Decisions this week:** Scan all meeting notes from this week (glob `~/Documents/PersonalOS/Meetings/` for this week's dates). For each note that has a `## Decisions` section, extract the decisions. Aggregate into a list for the output.

### 5. KB Review

List knowledge base items captured this week, grouped by relevance:
- **High:** Items that should drive action
- **Medium:** Worth revisiting
- **Low:** Filed for reference

For High relevance items that don't have associated Todoist tasks yet, propose creating tasks.

**Readwise gap analysis (if Readwise available):** Check for uncaptured items by running:
- `reader_list_documents(location="new", updated_after=start_of_week)`

Cross-reference against Notion KB entries by URL (same dedup logic as `/capture` — normalize URLs, strip utm_* params). Report:

```
Readwise this week: X items in Reader inbox.
In KB: Z already captured. W not yet captured.
```

If uncaptured items exist, offer: "Run `/capture` to import remaining items?"

**Obsidian Resources (if available):** Scan `~/Documents/PersonalOS/Resources/` for notes created this week (by filename date prefix). Group by topic for the KB Highlights section.

### 5.5 Relationship Radar

**Relationship Radar is always included in the weekly review output**, even if no one is flagged (in that case, write "All relationships active — no flags."). This ensures the user sees the section every week.

Scan all People notes in `~/Documents/PersonalOS/People/`. For each, read the `last_interaction` frontmatter field and `relationship` field. Flag people who are going cold based on relationship type:

| Relationship | Threshold | Context |
|-------------|-----------|---------|
| `work` (+ stakeholder on active project) | 21+ days | Check if they're a stakeholder on any active Project note |
| `family` | 14+ days | Always flag |
| `personal` | 14+ days | Always flag |
| `networking` | 30+ days | Flag with note about job search relevance |
| `mentor` | 30+ days | Flag |

**Output:**
```
## Relationship Radar

### Work — Going Cold
- [Name] — X days, stakeholder on [[Projects/slug]]
- ...

### Personal — Check In
- [Name] — X days (family/personal)
- ...

### Network — Warm Up
- [Name] — X days
- ...
```

If no one is flagged in a category, omit that category. If no one is flagged at all, write: "All relationships active — no flags."

For each flagged person, connect to Q2 goals:
- Parents flagged + Family Roots goal → suggest: "Schedule a visit this weekend. Q2 target: 2x/month."
- Sister flagged + Family Roots goal → suggest: "Send a text today. Q2 target: 1 touchpoint/month per sister."
- Friend flagged + Friendships goal → suggest: "Reach out to [name]. Q2 target: 2 hangouts/month."
- Bonnie interaction low + Marriage & Home goal → suggest: "Plan this week's couple night. Q2 target: 1/week."

After presenting, offer: "Want me to create Todoist tasks for any of these? I'll set them as P2 in 'Personal' or 'Us' project."

### 5.6 People Note Reconciliation

Scan all meeting notes from this week: `~/Documents/PersonalOS/Meetings/YYYY-MM-DD-*.md` where the date falls within the review week.

For each meeting note with attendees:
1. Check if each attendee's People note exists in `~/Documents/PersonalOS/People/`
2. If the People note exists, check if this meeting appears in their `## Meeting History` section
3. Track gaps: missing People notes, missing meeting history entries

**Output (only if gaps found):**
```
## People Note Gaps

Missing People notes:
- [Name] — appeared in X meetings this week (most recent: [date])

Missing meeting history entries:
- [Person]: missing [meeting title] ([date])
```

If gaps are found, offer: "Backfill these gaps now? (y/n)" If yes, create missing People notes using the Person template and add missing meeting history entries with `— (backfilled)` suffix.

If no gaps, omit this section entirely.

### 6. Goal Progress Check-in

Read the current quarterly goals file (`~/Documents/PersonalOS/Goals/YYYY-QX.md`). For each active goal:

1. **Milestone status:** Which milestones were completed this week? Which are approaching (next 2 weeks)? Which are overdue?
2. **Activity signal:** Check related projects for status changes, meetings, or completed Todoist tasks this week. If no activity in 14+ days, flag as **STALE**.
3. **Weekly target check:** Did the user achieve the target in the goal's `This Week` section (if one was set last week)?
4. **Propose next week's target:**
   - For goals with weekly milestones (short initiatives): propose a specific deliverable
   - For goals with monthly milestones (complex/personal): propose the next incremental step
   - For habit goals (fitness, routines): propose the weekly cadence target

**Output section:**
```
## Goal Progress — QX YYYY

### [Goal Name]
- Milestones: X/Y completed | Next: [milestone] ([date], X days)
- This week: [summary of activity — tasks, meetings, or "No activity"]
- Last week's target: [achieved / not achieved / not set]
- **Proposed target for next week:** [specific, achievable action]

### [Goal Name] — STALE
- Milestones: X/Y completed | Next: [milestone] ([date])
- No activity in X days
- **Proposed target for next week:** [action to restart momentum]
```

**Execution Scoring (12 Week Year method):**

After checking each goal's `This Week` target (step 3 above), calculate:

1. **Count planned actions:** How many goals had a non-empty `This Week` target set last week?
2. **Count achieved:** How many of those targets were achieved (based on task completion, meeting outcomes, or observable progress)?
3. **Calculate score:** Achieved / Planned × 100% = Execution Score
4. **Trend check:** Read the previous weekly review note (`~/Documents/PersonalOS/Weekly Reviews/YYYY-WXX.md` for last week). Extract its Execution Score. Compare.

**Output** (add to the Goal Progress section):

```
### Execution Score
This week: X/Y targets achieved (Z%)
Last week: A% | Trend: ↑/↓/→
```

**Thresholds:**
- 85%+: On track. Acknowledge strong execution.
- 70-84%: Acceptable but watch for patterns. Note which goals' targets were missed.
- Below 70%: Flag as concern. If below 70% for 2 consecutive weeks, flag as **SYSTEMIC** — the issue isn't effort, it's how targets are being set or how time is being allocated.
- Below 50%: Urgent. Propose: "Reduce active goals to top 5 next week?" or "Are targets too ambitious?"

**Lead Indicator Summary (auto-populated):** Read all daily notes from the review week (`~/Documents/PersonalOS/Daily/YYYY-MM-DD.md` for each day Mon-Sun). For each day, read the `## Lead Indicators` section. Tally weekly totals per indicator. Compare against targets from the quarterly goals file. Present:

```
### Lead Indicators This Week
| Goal | Indicator | Target | Actual | Status |
|------|-----------|--------|--------|--------|
| Physical Health | Lift sessions | 3-4/week | 3 | On track |
| Physical Health | Mobility | 1/week | 0 | MISSED |
| Inner Life | Meditation | 5/week | 2 | Behind |
| Marriage & Home | Couple night | 1/week | 1 | On track |
| Family Roots | Parent visits | 2/month | 0 (MTD: 1) | Behind |
| Friendships | Friend hangouts | 2/month | 0 (MTD: 0) | Behind |
| Inner Life | Outdoor sessions | 2/week | 3 | On track |
| Inner Life | Pages read | 50+/week | 0 | Behind |
```

If daily notes don't have Lead Indicators sections yet (first week of tracking), note: "Lead indicator tracking starts this week — no prior data to tally."

After presenting Goal Progress, ask: **"Update 'This Week' section in each goal note with proposed targets? (y/n)"**

If yes, write the proposed targets into each goal's `## This Week` section in the quarterly goals file. Morning-plan will read these and display them.

### 7. Idea Review

Scan `~/Documents/PersonalOS/Ideas/` for all idea files. For each idea with `status: seed`:
- Calculate age (days since `date:` in frontmatter)
- If older than 14 days, flag it

Present:

```
## Idea Review
| Idea | Age | Status |
|------|-----|--------|
| Brain Wellness App | 14 days | seed |
| Friend Hangout Scheduler | 14 days | seed |
```

For ideas older than 14 days, ask: **"Any of these ready to promote (`/promote slug`), archive, or leave as seed?"**

If the user wants to archive, update that idea's `status: archived`.

### 8. Propose Next-Week Priorities

Based on the analysis, propose 3-5 priorities for next week. These should be a mix of:
- **Carryover:** High-priority incomplete work from this week
- **New initiatives:** Things surfaced from KB, reflections, or calendar
- **Habits/process:** Adjustments based on patterns (e.g., "Block 2 hours of focus time on Tuesday and Thursday mornings")

Each priority should be specific and actionable, not vague.

### 9. Confirm with User

Present the full review, then ask:
1. "Do these priorities look right? Any to add, remove, or reorder?"
2. "Which of the proposed Todoist tasks should I create?"
3. "Write to Obsidian?"

Wait for confirmation before proceeding.

### 10. Write & Create

**Obsidian:** Create `~/Documents/PersonalOS/Weekly Reviews/YYYY-WXX.md` using the Weekly Review template. Fill in all sections.

**Todoist:** Create confirmed tasks for next week. Assign appropriate priorities and due dates (generally Monday of next week unless specific).

After all weekly review content is written and confirmed:

**Coaching nudge:** Glob `~/Documents/PersonalOS/Coaching/*.md` for the most recent coaching session. If the most recent session is more than 16 days ago (or no sessions exist), add a single line: "It's been [N] days since your last coaching session. Run `/coach`?" If a session exists within 16 days, skip this entirely.

Then prompt:

> "Run `/plan-week` now to set up next week's blocks?"

If yes, invoke the plan-week skill. If no, end the session.

## Output Format

```
# Weekly Review — YYYY-WXX (Mon DD - Sun DD)

## By the Numbers
- Tasks completed: X / Y due (Z%)
- Work meeting hours: X
- Personal event hours: X
- Estimated focus hours: X
- KB items captured: X

## Accomplishments
- ...

## Incomplete / Rolled Over
- [ ] task — originally due YYYY-MM-DD, rolled X days
- ...

## Time Analysis
[Work] Meeting hours: X | [Personal] Event hours: X | Focus hours: X
Meeting-heavy days (4+ hrs work meetings): Mon, Wed
Personal-heavy days: Sat (X hrs personal events)
[day-by-day breakdown with work/personal split]

## Patterns from Reflections
- ...

## Chronic Blockers
- [tasks that rolled 3+ days with context]

## Decisions This Week
- [Date] [[Meetings/slug|Meeting Title]]: **[Topic]** — [Decision] (decided by [person])
- ...

## Goal Progress — QX YYYY
### [Goal Name]
- Milestones: X/Y | Next: [milestone] ([date], X days)
- This week: [activity summary]
- Proposed target for next week: [specific action]

## Relationship Radar

### Work — Going Cold
- [Name] — X days, stakeholder on [[Projects/slug]]

### Personal — Check In
- [Name] — X days (family/personal)

### Network — Warm Up
- [Name] — X days

## KB Highlights
### High Relevance
- item (tags) — one-line summary
### Medium
- ...

## Next Week Priorities
1. Priority (why)
2. ...

---
Obsidian note: ~/Documents/PersonalOS/Weekly Reviews/YYYY-WXX.md
Todoist tasks created: X
```

## Notes
- ISO weeks: Monday to Sunday
- Timezone: America/Los_Angeles
- Dates: YYYY-MM-DD
- If fewer than 3 daily reflections exist, note that data is limited and analysis may be incomplete
- Reference CLAUDE.md for paths and conventions
