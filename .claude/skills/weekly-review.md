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
| Google Calendar | `gcal_list_events` | Yes |
| Todoist | List tasks | Yes |
| Notion | `search_objects` | No |
| Readwise | `reader_list_documents` (limit 1) | No |
| Obsidian vault | Read `~/Documents/PersonalOS/` | Yes |

Report availability. Continue with what works, noting any gaps.

### 2. Determine Week Range

Use the current ISO week (Monday to Sunday). Calculate:
- `week_number`: YYYY-WXX format
- `start_date`: Monday's date (YYYY-MM-DD)
- `end_date`: Sunday's date (YYYY-MM-DD)

Timezone: America/Los_Angeles.

### 3. Gather Data

Run in parallel where possible:

**Calendar:** Use `gcal_list_events` to get ALL events from Monday through Sunday, all calendars (work + personal).

**Todoist — Completed:** Fetch tasks completed during the week.

**Todoist — Incomplete/Overdue:** Fetch tasks that were due this week but remain open.

**Obsidian Daily Notes:** Read all daily notes for this week from `~/Documents/PersonalOS/Daily/`. Look for files matching the week's dates (YYYY-MM-DD.md). Extract reflection sections from each.

**Notion KB:** Query "AI Knowledge Base" for items where Date Captured falls within this week.

### 4. Analyze

**Completion rate:** Tasks completed / total tasks due this week. Break down by project if useful.

**Time analysis:**
- Total meeting hours (from calendar events)
- Estimated focus hours (gaps between meetings during work hours, 9 AM - 6 PM)
- Meeting-heavy days vs focus-heavy days
- Personal vs work event split

**Reflection themes:** Read through the week's daily reflections and identify:
- Recurring wins or positive patterns
- Recurring frustrations or blockers
- Any themes that appeared 3+ times

**Chronic blockers:** Tasks that were due early in the week and rolled forward repeatedly (appeared in multiple daily "Incomplete" lists). Flag anything that rolled 3+ days.

**Energy patterns:** Based on reflections and completion data, note which days felt most/least productive.

### 5. KB Review

List knowledge base items captured this week, grouped by relevance:
- **High:** Items that should drive action
- **Medium:** Worth revisiting
- **Low:** Filed for reference

For High relevance items that don't have associated Todoist tasks yet, propose creating tasks.

**Readwise gap analysis (if Readwise available):** Check for uncaptured items by running:
- `reader_list_documents(location="archive", updated_after=start_of_week)`
- `reader_list_documents(location="shortlist", updated_after=start_of_week)`

Cross-reference against Notion KB entries by URL (same dedup logic as `/capture` — normalize URLs, strip utm_* params). Report:

```
Readwise this week: You archived X items and shortlisted Y items.
In KB: Z already captured. W not yet captured.
```

If uncaptured items exist, offer: "Run `/capture` to import remaining items?"

### 6. Propose Next-Week Priorities

Based on the analysis, propose 3-5 priorities for next week. These should be a mix of:
- **Carryover:** High-priority incomplete work from this week
- **New initiatives:** Things surfaced from KB, reflections, or calendar
- **Habits/process:** Adjustments based on patterns (e.g., "Block 2 hours of focus time on Tuesday and Thursday mornings")

Each priority should be specific and actionable, not vague.

### 7. Confirm with User

Present the full review, then ask:
1. "Do these priorities look right? Any to add, remove, or reorder?"
2. "Which of the proposed Todoist tasks should I create?"
3. "Write to Obsidian?"

Wait for confirmation before proceeding.

### 8. Write & Create

**Obsidian:** Create `~/Documents/PersonalOS/Weekly Reviews/YYYY-WXX.md` using the Weekly Review template. Fill in all sections.

**Todoist:** Create confirmed tasks for next week. Assign appropriate priorities and due dates (generally Monday of next week unless specific).

## Output Format

```
# Weekly Review — YYYY-WXX (Mon DD - Sun DD)

## By the Numbers
- Tasks completed: X / Y due (Z%)
- Meeting hours: X
- Estimated focus hours: X
- KB items captured: X

## Accomplishments
- ...

## Incomplete / Rolled Over
- [ ] task — originally due YYYY-MM-DD, rolled X days
- ...

## Time Analysis
[day-by-day breakdown or summary of meeting vs focus time]

## Patterns from Reflections
- ...

## Chronic Blockers
- [tasks that rolled 3+ days with context]

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
