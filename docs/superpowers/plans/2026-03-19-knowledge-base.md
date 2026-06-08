# AI Knowledge Base Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the Notion AI Knowledge Base database with the full schema and update the `/triage` skill to use the new fields (Topics, Tags taxonomy, Type, Action Required).

**Architecture:** Two deliverables — (1) a Notion database created via MCP API with all properties pre-configured, and (2) an updated `/triage` skill file that references the new schema. The database ID gets stored in `CLAUDE.md` for other skills to reference.

**Tech Stack:** Notion MCP API, Claude Code skills (markdown)

**Spec:** `docs/superpowers/specs/2026-03-19-knowledge-base-design.md`

---

### Task 1: Search Notion for existing KB database or parent page

**Files:**
- Reference: `CLAUDE.md:36-37`

- [ ] **Step 1: Search Notion for "AI Knowledge Base"**

Use the Notion MCP search tool to check if a database or page already exists:

```
mcp__notion-local__API-post-search
  query: "AI Knowledge Base"
  page_size: 5
```

- [ ] **Step 2: Evaluate results**

If a database already exists with this name, note its ID — we may be able to reuse or replace it. If only a page exists, note its `page_id` to use as the parent. If nothing exists, we'll create a top-level page in the next task.

- [ ] **Step 3: Document the finding**

Record what was found (database ID, page ID, or nothing) before proceeding.

---

### Task 2: Create the Notion database

**Files:**
- Modify: `CLAUDE.md:36-37` (add database ID)

- [ ] **Step 1: Create parent page if needed**

If no suitable parent was found in Task 1, create a workspace-level page:

```
mcp__notion-local__API-post-page
  parent: { "type": "workspace" }
  properties: {
    "title": { "title": [{ "type": "text", "text": { "content": "AI Knowledge Base" } }] }
  }
```

Note the returned `page_id`.

- [ ] **Step 2: Create the database with full schema**

Use the parent page ID from Step 1 (or Task 1) to create the database:

```
mcp__notion-local__API-create-a-data-source
  parent: { "page_id": "<parent_page_id>" }
  title: [{ "type": "text", "text": { "content": "AI Knowledge Base" } }]
  properties: {
    "Title": { "title": {} },
    "URL": { "url": {} },
    "Status": {
      "select": {
        "options": [
          { "name": "Inbox", "color": "blue" },
          { "name": "To Review", "color": "yellow" },
          { "name": "Processed", "color": "green" },
          { "name": "Action Items", "color": "orange" },
          { "name": "Archived", "color": "gray" }
        ]
      }
    },
    "Type": {
      "select": {
        "options": [
          { "name": "Article", "color": "blue" },
          { "name": "Video", "color": "red" },
          { "name": "Podcast", "color": "purple" },
          { "name": "Book", "color": "brown" },
          { "name": "Tool", "color": "green" },
          { "name": "Instagram", "color": "pink" },
          { "name": "Threads", "color": "gray" },
          { "name": "Twitter", "color": "blue" },
          { "name": "Other", "color": "default" }
        ]
      }
    },
    "Topics": {
      "multi_select": {
        "options": [
          { "name": "AI", "color": "blue" },
          { "name": "Crypto", "color": "orange" },
          { "name": "Finance", "color": "green" },
          { "name": "Career", "color": "yellow" },
          { "name": "Leadership", "color": "red" },
          { "name": "Tech", "color": "purple" },
          { "name": "Health", "color": "green" },
          { "name": "Fitness", "color": "red" },
          { "name": "Fashion", "color": "pink" },
          { "name": "Travel", "color": "blue" },
          { "name": "Food", "color": "orange" },
          { "name": "Relationships", "color": "pink" },
          { "name": "Productivity", "color": "yellow" },
          { "name": "Learning", "color": "purple" },
          { "name": "Mindset", "color": "gray" },
          { "name": "Culture", "color": "brown" },
          { "name": "Sports", "color": "red" },
          { "name": "Music", "color": "purple" }
        ]
      }
    },
    "Tags": {
      "multi_select": {
        "options": [
          { "name": "prompt-engineering" },
          { "name": "agents" },
          { "name": "MCP" },
          { "name": "LLMs" },
          { "name": "fine-tuning" },
          { "name": "RAG" },
          { "name": "evals" },
          { "name": "computer-use" },
          { "name": "multimodal" },
          { "name": "AI-safety" },
          { "name": "AI-tooling" },
          { "name": "workflows" },
          { "name": "automation" },
          { "name": "tokenomics" },
          { "name": "DeFi" },
          { "name": "regulation" },
          { "name": "stablecoins" },
          { "name": "cross-border-payments" },
          { "name": "CBDCs" },
          { "name": "blockchain-infra" },
          { "name": "web3" },
          { "name": "investing" },
          { "name": "markets" },
          { "name": "personal-finance" },
          { "name": "fintech" },
          { "name": "payments" },
          { "name": "networking" },
          { "name": "job-strategy" },
          { "name": "negotiation" },
          { "name": "personal-brand" },
          { "name": "management" },
          { "name": "decision-making" },
          { "name": "team-building" },
          { "name": "communication" },
          { "name": "engineering" },
          { "name": "architecture" },
          { "name": "developer-tools" },
          { "name": "APIs" },
          { "name": "open-source" },
          { "name": "nutrition" },
          { "name": "mental-health" },
          { "name": "sleep" },
          { "name": "longevity" },
          { "name": "biohacking" },
          { "name": "strength-training" },
          { "name": "running" },
          { "name": "mobility" },
          { "name": "recovery" },
          { "name": "style" },
          { "name": "grooming" },
          { "name": "wardrobe" },
          { "name": "destinations" },
          { "name": "travel-hacking" },
          { "name": "gear" },
          { "name": "recipes" },
          { "name": "restaurants" },
          { "name": "cooking" },
          { "name": "dating" },
          { "name": "marriage" },
          { "name": "friendships" },
          { "name": "family" },
          { "name": "systems" },
          { "name": "habits" },
          { "name": "time-management" },
          { "name": "PKM" },
          { "name": "focus" },
          { "name": "reading" },
          { "name": "courses" },
          { "name": "skill-building" },
          { "name": "note-taking" },
          { "name": "stoicism" },
          { "name": "motivation" },
          { "name": "self-awareness" },
          { "name": "journaling" },
          { "name": "film" },
          { "name": "art" },
          { "name": "design" },
          { "name": "books" },
          { "name": "internet-culture" },
          { "name": "basketball" },
          { "name": "football" },
          { "name": "F1" },
          { "name": "combat-sports" },
          { "name": "hip-hop" },
          { "name": "R&B" },
          { "name": "production" },
          { "name": "playlists" }
        ]
      }
    },
    "Summary": { "rich_text": {} },
    "Key Insights": { "rich_text": {} },
    "Action Required": { "checkbox": {} },
    "Related Task": { "url": {} },
    "Date Captured": { "date": {} },
    "Date Reviewed": { "date": {} }
  }
```

- [ ] **Step 3: Verify the database was created**

```
mcp__notion-local__API-retrieve-a-data-source
  data_source_id: "<new_database_id>"
```

Confirm all 12 properties exist with correct types.

- [ ] **Step 4: Store the database ID in CLAUDE.md**

Update `CLAUDE.md` line 37 from:

```markdown
- AI Knowledge Base — inbox for AI resources, articles, tools
```

to:

```markdown
- AI Knowledge Base (ID: <database_id>) — inbox for AI resources, articles, tools
```

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: create Notion AI Knowledge Base database and store ID in CLAUDE.md"
```

---

### Task 3: Update the `/triage` skill

**Files:**
- Modify: `.claude/skills/triage.md`

- [ ] **Step 1: Rewrite the triage skill**

Replace the contents of `.claude/skills/triage.md` with the updated version that:

1. Updates the description to remove "rate relevance"
2. Keeps the same preflight check structure
3. Keeps the same fetch inbox items logic (batch of 10)
4. Updates "Process Each Item" section:
   - **Fetch content** — same as before
   - **Detect Type** — infer from URL/content: Article, Video, Podcast, Book, Tool, Instagram, Threads, Twitter, Other
   - **Assign Topics** — 1-3 from the 18 topics (AI, Crypto, Finance, Career, Leadership, Tech, Health, Fitness, Fashion, Travel, Food, Relationships, Productivity, Learning, Mindset, Culture, Sports, Music)
   - **Auto-tag** — replace the old 7-tag list with the full taxonomy (87 tags across 18 topics), scoped to assigned topics, 1-5 per item
   - **Summarize** — same but add 2000-char limit note
   - **Extract insights** — same but add 2000-char limit note
   - **Determine Action Required** — replaces relevance rating. True when content has a specific actionable takeaway (tool to try, technique to implement, workflow to build, concept to study). General interest = false.
5. Updates "Review with User" table to show Type, Topics, Tags, Action Required instead of Source, Relevance
6. Updates "Apply Changes" to use new field names and Action Required logic instead of High relevance
7. Updates "Summary" section to show Action Required counts instead of relevance breakdown

The full updated skill content:

```markdown
---
name: triage
description: Process Notion Knowledge Base inbox items — summarize, tag, detect type, assign topics, and create action items in Todoist
---

# KB Triage

Process items in the Notion "AI Knowledge Base" inbox — summarize content, extract insights, auto-tag with the full taxonomy, detect content type, assign topics, and create Todoist tasks for actionable items.

## Instructions

### 1. Preflight Check

Test access to:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Notion | `search_objects` (limit 1) | Yes |
| Todoist | List projects | Yes |
| WebFetch | N/A (tested per-item) | No |

Both Notion and Todoist are required. If either is unavailable, inform the user and stop.

### 2. Fetch Inbox Items

Query the Notion "AI Knowledge Base" database (see CLAUDE.md for database ID) for items where **Status = "Inbox"**.

Batch up to 10 items. If more than 10 exist, process the first 10 and tell the user how many remain.

### 3. Process Each Item

For each inbox item:

**a. Fetch content** — If the item has a URL, use WebFetch to retrieve the page content. If the fetch fails, proceed with just the title and any existing notes.

**b. Detect Type** — Infer the content type from the URL and content:
- `Article` — blog posts, news articles, written pieces
- `Video` — YouTube, Vimeo, video content
- `Podcast` — audio episodes, podcast links
- `Book` — book references, book summaries
- `Tool` — software tools, libraries, products
- `Instagram` — Instagram posts or reels
- `Threads` — Threads posts
- `Twitter` — tweets, Twitter/X threads
- `Other` — anything that doesn't fit above

**c. Assign Topics** — Select 1-3 topics from this list:

| Category | Topics |
|----------|--------|
| Professional | AI, Crypto, Finance, Career, Leadership, Tech |
| Life | Health, Fitness, Fashion, Travel, Food, Relationships |
| Growth | Productivity, Learning, Mindset |
| Fun | Culture, Sports, Music |

**d. Auto-tag** — Assign 1-5 tags from the taxonomy below, scoped to the assigned topics:

**AI:** prompt-engineering, agents, MCP, LLMs, fine-tuning, RAG, evals, computer-use, multimodal, AI-safety, AI-tooling, workflows, automation
**Crypto:** tokenomics, DeFi, regulation, stablecoins, cross-border-payments, CBDCs, blockchain-infra, web3
**Finance:** investing, markets, personal-finance, fintech, payments
**Career:** networking, job-strategy, negotiation, personal-brand
**Leadership:** management, decision-making, team-building, communication
**Tech:** engineering, architecture, developer-tools, APIs, open-source
**Health:** nutrition, mental-health, sleep, longevity, biohacking
**Fitness:** strength-training, running, mobility, recovery
**Fashion:** style, grooming, wardrobe
**Travel:** destinations, travel-hacking, gear
**Food:** recipes, restaurants, cooking
**Relationships:** dating, marriage, friendships, family
**Productivity:** systems, habits, time-management, PKM, focus
**Learning:** reading, courses, skill-building, note-taking
**Mindset:** stoicism, motivation, self-awareness, journaling
**Culture:** film, art, design, books, internet-culture
**Sports:** basketball, football, F1, combat-sports
**Music:** hip-hop, R&B, production, playlists

Only use tags from this list. Do not create new tags. If content doesn't fit, assign the closest match.

**e. Summarize** — Write a 2-3 sentence summary of the content. Focus on what it is and why it matters. Keep under 2000 characters (Notion rich_text limit).

**f. Extract insights** — Pull out 2-4 key insights or takeaways. These should be specific and actionable, not generic. Keep under 2000 characters.

**g. Determine Action Required** — Set to true when the content contains a specific, actionable takeaway:
- A tool to try or evaluate
- A technique to implement in current work
- A workflow or automation to build
- A concept to study in depth or experiment with

General interest content (news, opinion, entertainment) = false.

### 4. Review with User

Present a summary table:

```
| # | Title | Type | Topics | Tags | Action? | Summary |
|---|-------|------|--------|------|---------|---------|
| 1 | ...   | Article | AI, Tech | agents, MCP | Yes | One-line summary... |
| 2 | ...   | Video | Fitness | strength-training | No | One-line summary... |
```

Then for each item, show the full summary and key insights.

Ask the user:
- "Any adjustments to type, topics, tags, or action items?"
- "Ready to apply?"

Wait for confirmation before proceeding.

### 5. Apply Changes

After user confirms:

**Update Notion items** — For each processed item, update:
- `Type` — the detected content type
- `Topics` — the assigned topics
- `Tags` — the assigned tags
- `Summary` — the generated summary
- `Key Insights` — the extracted insights
- `Action Required` — true/false
- `Status` — change from "Inbox" to "Processed" (or "Action Items" if Action Required)
- `Date Reviewed` — today's date (YYYY-MM-DD)

**Create Todoist tasks** — For each item where **Action Required = true**:
- Create a task in the "AI Learning" project
- Task title: descriptive action (e.g., "Try [tool name]", "Read [article] in depth", "Implement [technique]")
- Include the Notion item URL in the task description
- Set priority based on urgency (default p3)
- Store the Todoist task URL in the Notion item's `Related Task` field

### 6. Summary

Display final results:

```
## Triage Complete

- Items processed: X
- Action items created: X
- Remaining in inbox: X

### Tasks Created
- [ ] Task name (AI Learning)
- ...
```

## Notes
- Date format: YYYY-MM-DD
- If URL fetch fails for an item, note it and process based on title/existing content
- Notion database: "AI Knowledge Base" (see CLAUDE.md for database ID)
- Todoist project: "AI Learning"
- Reference CLAUDE.md for conventions
```

- [ ] **Step 2: Verify the skill renders correctly**

Read back `.claude/skills/triage.md` and confirm it parses as valid markdown with correct frontmatter.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/triage.md
git commit -m "feat: update /triage skill with Topics, Tags taxonomy, Type, and Action Required"
```

---

### Task 4: Update `personal-os.md` to match new schema

**Files:**
- Modify: `personal-os.md:113-163`

- [ ] **Step 1: Update the Notion Knowledge Base section (lines 113-122)**

Replace:
```markdown
### Notion — Knowledge Base

Structured database for AI resources. Content flows in, Claude processes it, action items flow out.

- Pipeline: Inbox → To Review → Processed → Action Items → Archived
- Auto-tagged by source & topic
- Claude-generated summaries & insights
- Relevance scoring (High/Med/Low)
- Action items pushed to Todoist
- Fed by Readwise, Raindrop, iOS Shortcuts
```

With:
```markdown
### Notion — Knowledge Base

Structured database for resources across all topics. Content flows in, Claude processes it, action items flow out.

- Pipeline: Inbox → To Review → Processed → Action Items → Archived
- Auto-typed (Article, Video, Podcast, Book, Tool, Instagram, Threads, Twitter, Other)
- Auto-tagged by topic with 87-tag taxonomy across 18 topics
- Claude-generated summaries & insights
- Action Required flag for items with specific actionable takeaways
- Action items pushed to Todoist
- Fed by Readwise, Raindrop, iOS Shortcuts
```

- [ ] **Step 2: Update the Process section (lines 136-140)**

Replace:
```markdown
**Process (Claude via MCP):**
- Triage Notion inbox
- Auto-summarize & extract insights
- Tag by topic & rate relevance
- Connect to related resources
```

With:
```markdown
**Process (Claude via MCP):**
- Triage Notion inbox
- Auto-detect type and assign 1-3 topics
- Auto-tag from 87-tag taxonomy scoped to topics
- Auto-summarize & extract insights
- Flag actionable items for Todoist task creation
```

- [ ] **Step 3: Update the schema table (lines 148-163)**

Replace the existing schema table with:
```markdown
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
```

- [ ] **Step 4: Commit**

```bash
git add personal-os.md
git commit -m "docs: update personal-os.md schema to match new KB design"
```

---

### Task 5: Verify end-to-end

- [ ] **Step 1: Verify Notion database is accessible**

```
mcp__notion-local__API-query-data-source
  data_source_id: "<database_id>"
  page_size: 1
```

Confirm the query returns successfully (even if empty).

- [ ] **Step 2: Create a test item in the database**

```
mcp__notion-local__API-post-page
  parent: { "database_id": "<database_id>", "type": "database_id" }
  properties: {
    "Title": { "title": [{ "type": "text", "text": { "content": "Test Item — Delete Me" } }] },
    "Status": { "select": { "name": "Inbox" } },
    "Date Captured": { "date": { "start": "2026-03-19" } }
  }
```

- [ ] **Step 3: Verify the test item appears in an Inbox query**

```
mcp__notion-local__API-query-data-source
  data_source_id: "<database_id>"
  filter: { "property": "Status", "select": { "equals": "Inbox" } }
```

Confirm the test item is returned.

- [ ] **Step 4: Delete the test item**

Remove the test page to leave the database clean.

- [ ] **Step 5: Final commit with all files**

Verify git status is clean. If any uncommitted changes remain, commit them.
