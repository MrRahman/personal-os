# Todoist Structure — Design Spec

## Overview

Restructure Todoist from 6 flat projects into 3 purpose-driven projects (Personal, Us, Work) with labels for organization and priorities for daily planning. Migrate existing tasks, then delete old projects.

---

## Projects

| Project | Description | Shared? |
|---------|-------------|---------|
| **Personal** | Individual tasks — learning, health, errands, shopping, creative | No |
| **Us** | Shared tasks with wife — house, finances, family, travel, groceries | Yes — sharing must be done manually in Todoist app after creation |
| **Work** | Work tasks organized by focus area — starts empty, tasks created as work arises | No |
| **Inbox** | Default capture point (already exists) — triaged daily by `/morning-plan` | No |

---

## Labels

Labels are user-scoped in Todoist (not project-scoped). Wife will not see these labels on her account — they're for your organization and for Claude's skills to filter by.

### Personal
| Label | Use For |
|-------|---------|
| `learning` | Courses, skills, research, reading |
| `to-buy` | Shopping, things to purchase |
| `health` | Medical, fitness, wellness |
| `finances` | Money, insurance, investments, admin |
| `career` | Job search, networking, personal brand, resume |
| `social` | Texts to send, gifts, events, people |
| `creative` | Personal site, writing, side projects |
| `errands` | Returns, pickups, miscellaneous to-dos |

### Us (shared with wife)
| Label | Use For |
|-------|---------|
| `house` | Furniture, decor, organization, repairs |
| `finances` | Joint finances, insurance, bills |
| `family` | Family events, obligations, planning |
| `travel` | Trips, bookings |
| `groceries` | Food shopping |

### Work
| Label | Use For |
|-------|---------|
| `M&A: Treasury` | M&A Treasury project work |
| `M&A: Prime` | M&A Prime project work |
| `M&A: Other` | Other M&A work |
| `GE/Market Activation` | GE and market activation work |
| `AI Transformation` | AI transformation initiative |
| `Other` | Work that doesn't fit a specific project |
| `follow-up` | Meeting follow-ups, emails to send |

New work labels can be added as new projects arise.

---

## Priority System

Consistent across all projects. Used by `/morning-plan` to build daily plan.

| Priority | Meaning | When to use |
|----------|---------|-------------|
| P1 | Must do today / urgent | Deadlines, blockers, time-sensitive |
| P2 | Do this week / important | Meaningful progress items |
| P3 | Do when you can / normal | Default for most tasks |
| P4 | Someday / low priority | Nice-to-haves, ideas |

---

## Task Migration

### Implementation notes

- **Move and label are separate operations.** First move tasks to the correct project via `move_tasks`, then apply labels via `update_tasks`.
- **Subtasks follow their parent** when moving in Todoist. Only move parent tasks — subtasks come along automatically.
- **Verify before deleting.** Confirm all tasks landed in the correct projects before deleting old ones. Deletion via MCP is permanent (no archive available).

### Current → New mapping

**Inbox** (project `6CrfwxRXJCxp8mGV`) — top-level tasks only, subtasks follow parents:

| Task | → Project | Label |
|------|-----------|-------|
| Build goals for 2026 (+ 5 subtasks) | Personal | `creative` |
| Buy USA 2014 Away Soccer Jersey | Personal | `to-buy` |
| One Medical + Blood work | Personal | `health` |
| Call insurance for PT | Personal | `health` |
| Notion/AI Training Plan (+ 2 subtasks) | Personal | `learning` |
| Mini camera off instagram | Personal | `to-buy` |
| Ring insurance | Us | `finances` |
| Text pegah back | Personal | `social` |
| Wedding insurance add | Us | `finances` |
| Financial advisor tasks + | Personal | `finances` |
| Wedding photos + Ask for additional video | Personal | `social` |
| Bed | Us | `house` |
| Sixth | Personal | `errands` |
| All subscriptions + credit cards review | Personal | `finances` |
| Amazon Returns | Personal | `errands` |
| Amazon orders | Personal | `to-buy` |
| Try on all clothes | Personal | `errands` |
| Warren's gift | Personal | `social` |
| Thank you notes | Personal | `social` |
| Check apple tasks | Personal | `errands` |
| Watch one video on coding | Personal | `learning` |
| 401k check | Personal | `finances` |

**Personal - quick** (project `6CrfwxRXJX686JG4`) — 1 task:

| Task | → Project | Label |
|------|-----------|-------|
| Running equipment | Personal | `to-buy` |

**Personal - deep work** (project `6CrfwxRXJmxf9PpQ`) — 4 tasks:

| Task | → Project | Label |
|------|-----------|-------|
| Create a personal site | Personal | `creative` |
| Write obituary | Personal | `creative` |
| Learn SQL | Personal | `learning` |
| Handyman or install keyboard tray | Us | `house` |

**Home** (project `6Jc8RPXQXjwxvVMj`) — 2 tasks:

| Task | → Project | Label |
|------|-----------|-------|
| Side tables living room | Us | `house` |
| Organize home | Us | `house` |

**Grocery Shopping** (project `6JXwr6j9PgRCw48w`) — 0 tasks

**Amazon/Whole Foods** (project `6CrfwxRXMHgRrpMv`) — 10 tasks:

| Task | → Project | Label |
|------|-----------|-------|
| Pots and plans | Us | `house` |
| New hair brush | Personal | `to-buy` |
| Jewelry organizer | Us | `house` |
| Draino | Us | `house` |
| Bathroom organizer | Us | `house` |
| Hangers? | Us | `house` |
| Closet lights | Us | `house` |
| Vitamins/medication | Personal | `health` |
| Decoration/fake plants for entrance | Us | `house` |
| Something for smell in bedroom | Us | `house` |

### After migration

Delete old projects (permanent — no archive via MCP): Personal - quick, Personal - deep work, Home, Grocery Shopping, Amazon/Whole Foods. Keep Inbox as the default capture point.

---

## CLAUDE.md Updates

Update the Todoist Projects section from:
```
- Work, Personal (shared), AI Learning, Inbox
```
To:
```
- Personal, Us (shared with wife), Work, Inbox
```

---

## Skills Impact

- `/triage` — change "AI Learning" project reference to "Personal" project with `learning` label. This is the only hard-coded project name in the skills.
- `/morning-plan`, `/reflect`, `/weekly-review` — these fetch tasks by priority/date, not project name. No changes needed.

---

## Manual Steps (post-implementation)

1. **Share "Us" project with wife** in the Todoist app (MCP cannot share projects)
2. **Wife creates matching labels** if she wants to filter by them (labels are user-scoped)
