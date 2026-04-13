---
name: monthly-review
description: Monthly trajectory check — RAG-status each goal, review execution trends, check anti-goal patterns, and propose adjustments
---

# Monthly Review

Lightweight monthly check-in that assesses goal trajectory, execution trends, and anti-goal compliance. Designed to catch problems before they compound. Takes 30-60 minutes.

## Instructions

### 1. Preflight Check

Test access to:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Obsidian vault | Read `~/Documents/PersonalOS/Goals/` | Yes |
| Todoist | List tasks | Yes |
| Google Calendar (Work) | `gcal_list_events` | No |
| Google Calendar (Personal) | `manage_calendar(operation: "agenda")` | No |

Report availability. Continue with what works.

### 2. Determine Month

Calculate the review month (previous month if running in the 1st week, current month if running later). Use YYYY-MM format.

### 3. Gather Data

Run in parallel:

**Quarterly Goals:** Read `~/Documents/PersonalOS/Goals/YYYY-QX.md` (current quarter).

**Weekly Reviews:** Read all weekly review notes from the review month: `~/Documents/PersonalOS/Weekly Reviews/YYYY-WXX.md`. Extract:
- Execution scores from each week
- Goal progress sections
- Patterns and observations
- Chronic blockers

**Annual Goals:** Read `~/Documents/PersonalOS/Goals/YYYY.md` for the anti-goals list and theme.

**Todoist:** Fetch tasks completed during the review month. Fetch overdue tasks.

**Calendar (if available):** Get high-level time allocation for the month — total meeting hours, focus hours estimate.

### 4. RAG Status Each Goal

For each of the 8 goals in the quarterly file:

**Green (On Track):**
- Milestones progressing on schedule
- Execution score targets being met
- Lead indicators trending in the right direction
- Activity in related projects/tasks

**Yellow (At Risk):**
- Milestone approaching with limited progress
- Execution score below 70% for 2+ weeks
- Lead indicators flat or declining
- No activity in 7+ days but not yet critical

**Red (Off Track):**
- Milestone overdue or will clearly miss deadline
- Execution score below 50%
- No activity in 14+ days
- WOOP obstacle is actively blocking progress

Present as a table:
```
## Goal RAG Status — [Month] [Year]

| # | Goal | Status | Signal |
|---|------|--------|--------|
| 1 | Career: From Grind to Growth | 🟢 | 2 external convos, AI saving 3hrs/wk |
| 2 | Marriage & Home | 🟡 | Date night missed 2 weeks, home projects stalled |
| ... | ... | ... | ... |
```

### 5. Execution Score Trend

Compile weekly execution scores from the month's weekly reviews:

```
## Execution Score Trend

| Week | Score | Trend |
|------|-------|-------|
| W15 | 75% | — |
| W16 | 85% | ↑ |
| W17 | 60% | ↓ |
| W18 | 80% | ↑ |

Monthly average: 75%
```

If monthly average is below 70%, flag: "Execution is consistently low. Consider: Are targets too ambitious? Is time allocation off? Are there systemic blockers?"

### 6. Trajectory Adjustments

For each RED or YELLOW goal, propose one of:
- **Adjust approach:** Change how you're pursuing the goal (different tactic, more/less time)
- **Extend deadline:** Push the milestone if circumstances changed
- **Break down:** The milestone is too big — split into smaller steps
- **Escalate:** Increase priority — move to Must Do in morning-plan
- **Seek help:** Identify someone who can unblock (advisor, coach, spouse, friend)

Present each proposal with reasoning.

### 7. Anti-Goal Check

Read the anti-goals from the annual file. For each, assess whether the pattern appeared this month:

```
## Anti-Goal Check

| Anti-Goal | Status | Evidence |
|-----------|--------|----------|
| Working 10-12 hour days | ⚠️ Appeared | 3 days with 10+ hrs per calendar |
| Losing sleep to anxiety | ✅ Managed | Sleep scores improving in reflections |
| Defaulting to drinking/screens | ✅ Clear | Alcohol 1x this month |
| ... | ... | ... |
```

For any anti-goal that appeared, connect it back to the affected goals: "The overwork pattern likely contributed to the Yellow status on Inner Life and Physical Health."

### 8. Present and Confirm

Present the full review. Ask:
1. "Any RAG statuses you'd adjust based on context I'm missing?"
2. "Accept the proposed trajectory adjustments?"
3. "Write to Obsidian?"

### 9. Write

Create `~/Documents/PersonalOS/Monthly Reviews/YYYY-MM.md` using the Monthly Review template. Fill in all sections.

## Output Format

```
# Monthly Review — [Month] [Year]

## Goal RAG Status
[table]

## Execution Score Trend
[table + monthly average]

## Trajectory Adjustments
[for RED/YELLOW goals]

## Anti-Goal Check
[table]

## Wins This Month
[top 3-5 accomplishments]

## Adjustments for Next Month
[specific, actionable changes]
```

## Notes
- Run in the 1st week of each month
- Takes 30-60 minutes
- This is a check-in, not a planning session — keep it focused on trajectory
- If a goal has been RED for 2 consecutive months, escalate to quarterly-planning level discussion
