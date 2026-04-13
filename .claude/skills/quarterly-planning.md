---
name: quarterly-planning
description: Quarterly retrospective and goal-setting — score current quarter, full retrospective, set next quarter's goals with WOOP and lead indicators
---

# Quarterly Planning

Comprehensive quarterly session that scores the outgoing quarter, runs a full retrospective, and sets goals for the incoming quarter. This is the highest-leverage planning session of the year. Takes 2-4 hours.

## Instructions

### 1. Preflight Check

Test access to:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Obsidian vault | Read `~/Documents/PersonalOS/Goals/` | Yes |
| Todoist | List tasks | Yes |
| Google Calendar (Work) | `gcal_list_events` | Yes |
| Google Calendar (Personal) | `manage_calendar(operation: "agenda")` | No |

All services except personal calendar are required.

### 2. Determine Quarter Transition

Identify:
- **Outgoing quarter:** The quarter being scored (e.g., Q2 2026)
- **Incoming quarter:** The quarter being planned (e.g., Q3 2026)
- **Quarter dates:** Start and end dates for both

### 3. Gather Data for Retrospective

Run in parallel:

**Quarterly Goals:** Read `~/Documents/PersonalOS/Goals/YYYY-QX.md` (outgoing quarter).

**Annual Goals:** Read `~/Documents/PersonalOS/Goals/YYYY.md` for theme, anti-goals, identity.

**Monthly Reviews:** Read all monthly reviews from the quarter: `~/Documents/PersonalOS/Monthly Reviews/YYYY-MM.md`.

**Weekly Reviews:** Read all weekly reviews from the quarter. Extract execution scores, patterns, chronic blockers.

**Calendar:** Get quarterly time allocation — total meeting hours per month, focus hours, work/personal split.

**Todoist:** Completed tasks for the quarter. Overdue/incomplete tasks.

**Incoming Quarter File:** Read `~/Documents/PersonalOS/Goals/YYYY-QX.md` for the incoming quarter (skeleton if it exists).

### 4. Score Each Goal (Interactive)

For each of the 8 goals, present:
- Milestone completion status (X/Y completed)
- Lead indicator performance over the quarter
- Execution score average
- Key wins and misses

Then ask the user to score each goal 0.0 to 1.0:
- **1.0:** Fully achieved — all milestones hit, outcome realized
- **0.7-0.9:** Strong progress — most milestones hit, outcome partially realized
- **0.4-0.6:** Mixed — some progress but significant gaps
- **0.1-0.3:** Minimal progress — goals largely unmet
- **0.0:** No meaningful progress

Present one goal at a time. Wait for user's score before moving to the next.

### 5. Theme Alignment Check

Ask: "Looking at the quarter as a whole — how well did it reflect the 'Year of Being Grounded' theme? Where did you feel most grounded? Where did you feel most scattered?"

Capture the response for the retrospective.

### 6. Retrospective

Present a synthesis:
- **What Worked:** Patterns that drove success (be specific — which habits, decisions, systems)
- **What Didn't:** Patterns that held you back (connect to WOOP obstacles — were they accurate?)
- **Key Learnings:** Insights that should inform next quarter
- **Anti-Goal Review:** Which anti-goals were maintained? Which crept back?

### 7. Plan Incoming Quarter

Read the incoming quarter's skeleton file (if it exists). For each of the 8 goals:

1. **Carry forward or adjust:** Ask: "This goal had [milestones]. Do these still make sense, or should we adjust?"
2. **Update milestones:** Based on retrospective insights and user input, refine milestones with specific dates
3. **Update lead indicators:** Adjust targets based on what was realistic last quarter
4. **WOOP refresh:** Ask: "Last quarter's obstacle was [X]. Is that still the primary obstacle, or has it shifted?"
5. **Update If-Then:** Refine implementation intention if needed

Present the updated goal and get approval before moving to the next.

### 8. Set Work Goals

For the incoming quarter, ask: "What are your 2-3 work/team goals for this quarter? Remember — these should serve the meta-goal of optimizing work to reclaim time, not expanding the grind."

Add these as a subsection under the Career goal.

### 9. Write

**Quarterly Review file:** Create `~/Documents/PersonalOS/Quarterly Reviews/YYYY-QX.md` using the Quarterly Review template. Fill in all sections including scores, retrospective, and learnings.

**Incoming Quarter Goals file:** Update `~/Documents/PersonalOS/Goals/YYYY-QX.md` with refined goals, milestones, lead indicators, and WOOP.

**Outgoing Quarter file:** Update status from `active` to `completed` in frontmatter.

### 10. Transition

After writing, prompt:
1. "Run `/plan-week` for the first week of the new quarter?"
2. "Any Todoist tasks to create for immediate Q[X] priorities?"

## Scoring Guide

| Score | Meaning | Example |
|-------|---------|---------|
| 1.0 | Nailed it | Website launched, posting weekly, 2 projects shipped |
| 0.8 | Strong | Website live, posting most weeks, 1 project shipped |
| 0.6 | Partial | Website live but posts inconsistent, no projects shipped |
| 0.4 | Behind | Website in progress but not live, no publishing |
| 0.2 | Minimal | Some work done but nothing shipped or visible |
| 0.0 | Didn't start | No meaningful progress |

## Notes
- Run in the last week of each quarter
- Takes 2-4 hours — this is the most important planning session
- Be honest with scores — the system only works if assessments are accurate
- This is both a retrospective AND a planning session — don't skip the forward-looking part
- If this is the annual transition (Q4 → Q1), also review the annual theme and consider a new one
