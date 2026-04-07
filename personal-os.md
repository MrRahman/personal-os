# Personal Operating System — System Architecture

> A unified productivity system with Claude as the central brain — connecting tasks, calendar, notes, knowledge, and communication into automated daily workflows.

**Version:** 1.0
**Date:** March 2026
**Status:** V1 — Complete (all 11 components built)

---

## 01 — System Overview

Claude serves as the central intelligence layer, connecting five core services and multiple input channels into a single automated operating system.

### Core Services

| Service | Role | Details |
|---------|------|---------|
| **Todoist** | Tasks | All tasks — personal, work, shared with wife |
| **Google Calendar** | Time | Work + personal calendars |
| **Obsidian** | Second Brain | Meeting notes, daily notes, connected thinking |
| **Notion** | Knowledge Base | AI resource pipeline (structured database) |
| **Readwise Reader** | Capture + Read | Articles, YouTube, newsletters, highlights |

### Direct Inputs (MCP Connected)

| Input | Connection | What It Captures |
|-------|-----------|-----------------|
| **Gmail** | MCP (connected) | Action items from email |
| **Slack** | MCP (connected) | Mentions, DMs, threads |
| **iMessage** | Custom MCP (to build) | Action items from messages via chat.db |

### Capture Sources (via Readwise, Raindrop, iOS Shortcuts)

Reddit · YouTube · Instagram · Threads · WhatsApp / Signal

---

## 02 — Daily Workflows

### Morning Planning

Claude reviews your calendar, tasks, and inbox to propose a time-blocked daily plan.

1. Pull today's meetings from Google Calendar (work + personal)
2. Review open Todoist tasks by priority and due date
3. Scan Gmail & Slack for urgent items
4. Check Notion KB for due action items
5. Propose time-blocked plan with tasks in free slots
6. Create calendar blocks for deep work (optional)

**Inputs:** Google Calendar, Todoist, Gmail, Slack, Notion
**Output:** Daily plan (text) + optional calendar blocks

### Evening Reflection

Compare what was planned vs what happened. Roll over incomplete work.

1. Compare planned tasks vs completed
2. Review calendar — what actually happened
3. Identify patterns and blockers
4. Move incomplete tasks to tomorrow in Todoist
5. Generate brief reflection summary
6. Log to Obsidian as daily note

**Inputs:** Google Calendar, Todoist, morning plan
**Output:** Reflection summary in Obsidian + updated Todoist

### Weekly Review

Zoom out. Summarize the week, review knowledge, set next week's priorities.

1. Summarize completed vs incomplete work
2. Analyze time allocation across categories
3. Review AI knowledge base captures from the week
4. Promote KB items to action items in Todoist
5. Propose next week's priorities
6. Create tasks in Todoist for the week

**Inputs:** Google Calendar, Todoist, Notion KB, Obsidian daily notes
**Output:** Weekly review in Obsidian + Todoist tasks for next week

---

## 03 — Second Brain

### Obsidian — Thinking & Notes

Your private space for unstructured thinking, meeting capture, and connecting ideas.

- Meeting notes with templates
- Daily notes for capture & reflection
- Bidirectional links between ideas
- Images, PDFs, documents embedded
- Graph view to see connections
- Claude reads/writes directly (local markdown files)

**Vault Structure:**
```
My Vault/
├── Daily/              # Daily notes (auto-created)
├── Meetings/           # Meeting notes
├── Reflections/        # Evening reflections
├── Weekly Reviews/     # Weekly summaries
├── Projects/           # Project-specific notes
├── Ideas/              # Loose thoughts & connections
└── Templates/          # Note templates
    ├── Daily Note.md
    ├── Meeting Note.md
    └── Weekly Review.md
```

### Notion — Knowledge Base

Structured database for resources across all topics. Content flows in, Claude processes it, action items flow out.

- Pipeline: Inbox → To Review → Processed → Action Items → Archived
- Auto-typed (Article, Video, Podcast, Book, Tool, Instagram, Threads, Twitter, Other)
- Auto-tagged by topic with 87-tag taxonomy across 18 topics
- Claude-generated summaries & insights
- Action Required flag for items with specific actionable takeaways
- Action items pushed to Todoist
- Fed by Readwise, Raindrop, iOS Shortcuts

---

## 04 — AI Resource Pipeline

### Flow: Capture → Process → Action

**Capture:**
- Readwise Reader — articles, YouTube, newsletters, PDFs
- Raindrop.io — Reddit, Instagram, Threads, quick saves
- iOS Shortcuts — WhatsApp, Signal, texts
- Gmail forwards — email content

**Process (Claude via MCP):**
- Triage Notion inbox
- Auto-detect type and assign 1-3 topics
- Auto-tag from 87-tag taxonomy scoped to topics
- Auto-summarize & extract insights
- Flag actionable items for Todoist task creation

**Action:**
- Create Todoist tasks from insights
- Surface in weekly review
- Build skills & workflows
- Archive processed items

### Notion Database Schema

| Field | Type | Purpose |
|-------|------|---------|
| Title | title | Resource name |
| URL | url | Original link |
| Status | select | Inbox → To Review → Processed → Action Items → Archived |
| Type | select | Article, Video, Podcast, Book, Tool, Instagram, Threads, Twitter, Other |
| Topics | multi_select | 18 topics: AI, Crypto, Finance, Career, Leadership, Tech, Health, Fitness, Fashion, Travel, Food, Relationships, Productivity, Learning, Mindset, Culture, Sports, Music |
| Tags | multi_select | 87 granular tags scoped to topics (auto-assigned by /triage) |
| Summary | rich_text | Claude-generated summary (max 2000 chars) |
| Key Insights | rich_text | Claude-extracted takeaways (max 2000 chars) |
| Action Required | checkbox | Needs follow-up Todoist task |
| Related Task | url | Link to Todoist task if created |
| Date Captured | date | When it was saved |
| Date Reviewed | date | When Claude processed it |

---

## 05 — Todoist Structure

One tool for all tasks. Labels for organization, priorities for daily planning.

```
Personal (individual tasks)
  Labels: learning, to-buy, health, finances, career, social, creative, errands

Us (shared with wife)
  Labels: house, finances, family, travel, groceries

Work (by focus area)
  Labels: M&A: Treasury, M&A: Prime, M&A: Other, GE/Market Activation,
          AI Transformation, Other, follow-up

Inbox (unsorted — Claude triages daily)
```

Priority system: P1 (must do today), P2 (this week), P3 (when you can), P4 (someday).

---

## 06 — MCP Connections

| Service | Status | Details |
|---------|--------|---------|
| Google Calendar (work) | **Connected** | Work email — full read/write (owner) |
| Google Calendar (personal) | **Connected (Limited)** | Personal email — freeBusyReader only, needs full access |
| Gmail | **Connected** | Work email — search, read messages and threads |
| Slack | **Connected** | Your workspace — search, read channels, threads, DMs |
| Todoist | **Connected** | HTTP MCP — 4 projects: Inbox, Personal, Work, Us + 19 labels |
| Obsidian | **Connected** | Local filesystem — Claude reads/writes ~/Documents/PersonalOS directly |
| Notion | **Connected** | HTTP MCP — bot user in your workspace, AI Knowledge Base DB |
| Readwise Reader | **Connected** | mcp-remote via OAuth — highlights + Reader documents |
| iMessage | **Connected** | stdio MCP — reads ~/Library/Messages/chat.db via Full Disk Access |
| Otter.ai | **Connected** | stdio MCP via Python wrapper — transcripts, search |

---

## 07 — Build Plan

| # | Component | What It Does | Status |
|---|-----------|-------------|--------|
| 1 | Connect MCP Servers | Todoist, Obsidian, Notion, Readwise, personal calendar | **10/10 connected** |
| 2 | Set Up Obsidian Vault | Folder structure, templates, plugins | **Done** |
| 3 | Create Notion Knowledge Base | Database with pipeline schema | **Done** — DB created, /triage skill built |
| 4 | Set Up Todoist Structure | Projects, labels, task migration | **Done** — 4 projects, 19 labels |
| 5 | Build Morning Planner Skill | Daily planning from tasks + calendar | **Done** — /morning-plan with interactive meeting notes |
| 6 | Build Evening Reflection Skill | Review day, roll over tasks, write to Obsidian | **Done** — /reflect with plan comparison + Otter sync |
| 7 | Build Weekly Review Skill | Summarize week, plan next | **Done** — /weekly-review with Readwise gap analysis |
| 8 | Build KB Triage Skill | Process Notion inbox, summarize, tag, create tasks | **Done** — /triage with type detection + 87-tag taxonomy |
| 9 | Build KB Capture Pipeline | Readwise → Notion auto-capture | **Done** — /capture + /kb skills built |
| 10 | Build iMessage MCP Server | Extract action items from messages | **Done** — connected via Full Disk Access |
| 11 | Create iOS Shortcuts | Capture from WhatsApp/Signal → Todoist/Notion | **Done** — setup guide at docs/ios-shortcuts-setup.md |
