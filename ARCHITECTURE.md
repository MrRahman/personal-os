# Personal OS — Architecture Overview

A personal knowledge management and productivity system built on Claude Code, Obsidian, and a constellation of connected services. Two commands run the day. Everything else is automated.

---

## Daily Routine

| When | Command | What happens |
|------|---------|-------------|
| Morning | `/morning-plan` | KB sync (Readwise → Notion → Obsidian), calendar, tasks, email, Slack, iMessage, active projects, meeting notes, daily note |
| End of day | `/reflect` | Sync Otter transcripts with speaker names, compare plan vs actual, reschedule tasks, update People notes, write reflection + Check-In scores |

On-demand: `/idea` (capture ideas from any project), `/kb` (search knowledge base), `/weekly-review` (Friday retrospective)

---

## System Map

```
┌─────────────────────────────────────────────────────────┐
│                    CAPTURE LAYER                         │
│                                                         │
│  Readwise Reader ──► Notion KB ──► Obsidian Resources/  │
│  (share sheet)       (triage)      (tagged, linked)     │
│                                                         │
│  Otter.ai ──► Obsidian Meetings/ + Transcripts/         │
│  (auto-record)  (speaker names, summaries, action items)│
│                                                         │
│  Google Calendar ──► Obsidian Meetings/                  │
│  (attendees)         (scaffolded by /morning-plan)      │
│                                                         │
│  Conversations ──► Obsidian Ideas/                      │
│  (/idea command)    (30-second capture)                  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   OBSIDIAN VAULT                         │
│               ~/Documents/PersonalOS/                    │
│                                                         │
│  Daily/          Daily notes with plan + reflection      │
│                  + Check-In scores (energy/focus/        │
│                  impact/balance/mood 1-10)               │
│                                                         │
│  Meetings/       Meeting notes with attendees,           │
│   └─Transcripts/ summaries, action items, speaker names  │
│                                                         │
│  People/         Contact profiles with Dataview queries  │
│                  (auto-populated meeting history)         │
│                                                         │
│  Resources/      One note per KB item (article, video,   │
│                  tool) with tags and connections          │
│                                                         │
│  Topics/         Map of Content notes — AI, Productivity,│
│                  Tech, Career, Relationships + Dataview   │
│                                                         │
│  Projects/       Active work initiatives — auto-detected │
│                  from meetings, MOC-style with Dataview   │
│                                                         │
│  Ideas/          Quick captures from conversations        │
│                  (seed → developing → archived/project)   │
│                                                         │
│  Weekly Reviews/ Friday retrospectives                    │
│                                                         │
│  Templates/      Daily Note, Meeting Note, Person,        │
│                  Resource, Topic, Project, Idea           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                 CONNECTED SERVICES                        │
│                                                         │
│  Google Calendar ── work (claude.ai, srahman@ripple.com) │
│                    personal (MCP, 1srahman@gmail.com)    │
│  Gmail ─────────── work (claude.ai, srahman@ripple.com)  │
│                    personal (MCP, 1srahman@gmail.com)    │
│  Slack ─────────── mentions, DMs, cross-check actions    │
│  Todoist ───────── task management (Work/Personal/Us)    │
│  Notion ────────── AI Knowledge Base (structured data)   │
│  Readwise Reader ─ reading capture + highlights          │
│  Otter.ai ──────── meeting transcripts (speaker IDs)     │
│  iMessage ──────── action item extraction                │
└─────────────────────────────────────────────────────────┘

```

---

## Knowledge Flow

```
Save article ──► Readwise inbox
                     │
        /morning-plan (auto)
                     │
                     ▼
              Notion KB (Inbox)
                     │
           triage (auto, in morning-plan)
                     │
                     ▼
         Notion KB (Processed) ──► Obsidian Resource note
              │                         │
              │                    Tags: #topic/AI #AI/agents
              │                    Connections: related meetings,
              │                    people, other resources
              │                         │
              ▼                         ▼
        Todoist task            Topic MOC updated
        (if actionable)         (AI.md, Tech.md, etc.)
```

---

## Meeting Flow

```
Calendar event
      │
  /morning-plan
      │
      ▼
Meeting note created ◄── attendees from calendar
(project: field linked)   (ALL attendees, not just known)
      │
   [meeting happens, Otter records]
      │
  /reflect (end of day)
      │
      ▼
Otter transcript fetched ◄── speaker names resolved
      │                       (speaker_id → name via API)
      │
      ▼
Meeting note filled:
  - Summary (3-5 sentences)
  - Key Points (4-6 bullets)
  - Action Items (with @[[People/Owner]])
  - Follow-ups
  - Transcript Highlights (attributed quotes)
      │
      ▼
People notes updated ◄── meeting history prepended
Transcript file saved ◄── full text with speaker names
Slack cross-checked ◄── resolved items flagged
Todoist tasks proposed ◄── user confirms
Vault connections scanned ◄── cross-links to Resources, Topics, Projects
```

---

## Tag System

```
#topic/AI              ── broad topic (18 topics in taxonomy)
#AI/prompt-engineering  ── specific tag under topic (60+ tags)
#AI/agents
#AI/MCP
#type/article          ── content type
#type/video
#type/tool
```

Nested tags mean searching `#AI` in Obsidian returns everything: `#topic/AI`, `#AI/prompt-engineering`, `#AI/agents`, etc.

---

## Multi-Project Architecture

```
~/.claude/CLAUDE.md              ← identity, voice, preferences (loads everywhere)
~/.claude/skills/idea.md         ← global /idea command (works in any project)
~/.claude/skills/kb.md           ← global /kb command (works in any project)

~/Documents/PersonalOS/          ← shared data layer (Obsidian vault)
                                   readable + writable from any project

~/projects/personal-os/          ← hub: daily routines, 8 skills, all automation
~/projects/your-project-a/       ← other projects read from vault for context
~/projects/your-project-b/       ← each project has its own skills + workflows
```

**Rule:** Projects are independent workspaces. Obsidian is shared memory. Universal skills go global (`~/.claude/`). Project-specific workflows stay in their project.

---

## Reflection System

Daily notes include a personal Check-In with 5 scored dimensions:

| Score | Descriptor | 1 = | 10 = |
|-------|-----------|-----|------|
| Energy | Mental + physical battery | Drained | Fully charged |
| Focus | Ability to stay present | Scattered | Locked in |
| Impact | Moved the needle today | Spinning wheels | Crushed it |
| Balance | Work-life integration | All work | Healthy boundaries |
| Mood | Overall emotional state | Rough | Great |

Scores stored in YAML frontmatter for graphing over time via Dataview/Tracker plugin.

Each reflection also includes:
- **Highlight** — one thing I'm most proud of or grateful for
- **Adjustments** — what I'd do differently tomorrow

---

## Cost

~$237/month personal investment:
- Claude Max: $200/mo
- Obsidian Sync: $4/mo
- Otter.ai Business: $20/mo ($240/yr)
- Readwise Reader: $8/mo
- Todoist Pro: $5/mo
- Notion, Gmail, Slack, Calendar, iMessage: free / employer-covered

---

## What Makes It Work

1. **Two commands, not twenty.** `/morning-plan` and `/reflect` handle everything. KB capture, triage, meeting sync, transcripts, action items, reflections — all automated within those two flows.

2. **Obsidian is memory, not storage.** Every note links to People, Topics, Projects, and Resources. The graph compounds over time. Dataview queries make connections self-maintaining.

3. **Speaker names in transcripts.** Patched the Otter MCP to resolve speaker IDs to real names via the speakers API. Every transcript shows who said what.

4. **Ideas are cheap, projects are earned.** `/idea` captures in 30 seconds. Projects are auto-detected from meeting patterns. The flow is: save → capture → triage → connect → surface.

5. **Nothing falls through the cracks.** Email threads are read in full (not just snippets). Slack is cross-checked before creating tasks. Coverage spans since-last-run, not a fixed window.
