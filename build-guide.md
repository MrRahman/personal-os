# Build Guide — Personal Operating System

> Step-by-step instructions for building an AI-powered productivity system with Claude as the brain.

**Time:** ~3 hours total
**Requirements:** Claude Code, macOS, Node.js 18+

---

## Prerequisites & Accounts

### Required Accounts

| Service | Plan | Cost |
|---------|------|------|
| Todoist | Pro (API + collaboration) | $5/mo |
| Google Calendar | Free (existing accounts) | Free |
| Obsidian | Free (Sync optional $5/mo) | Free |
| Notion | Free plan | Free |
| Readwise Reader | Full (30-day trial) | $10/mo |
| Raindrop.io | Free | Free |
| Claude Code | Max plan | $100/mo |

**Monthly total:** ~$115/mo

> **Minimum start:** Todoist + Google Calendar + Obsidian (all free). Add Readwise and Notion when ready for the knowledge base.

---

## Step 1: Connect MCP Servers

### Todoist

```bash
# Official MCP server from Doist
claude mcp add --transport http todoist https://ai.todoist.net/mcp

# Follow the OAuth flow to authenticate
```

### Google Calendar

Enable via Settings → Integrations in Claude desktop app or claude.ai. Connect both work and personal Google accounts.

### Notion

```bash
# Official MCP server (OAuth-based)
claude mcp add --transport http notion https://mcp.notion.com/sse

# Authorize Claude to access your workspace
```

### Readwise Reader

```bash
# Get your access token from readwise.io/access_token
claude mcp add readwise -- npx @readwise/readwise-mcp

# Set your token when prompted
```

### Obsidian

```bash
# Option A: Direct file access (no setup needed)
# Claude reads your vault directly — it's just markdown files

# Option B: Add MCP for search/index (optional)
claude mcp add obsidian -- npx @anthropic/mcp-obsidian
```

> **Tip:** Since Obsidian vaults are folders of markdown files, Claude Code can read and write them directly. The MCP server adds search indexing for large vaults.

### Gmail & Slack

Enable via Settings → Integrations in Claude desktop app. These are managed integrations — no MCP setup needed.

### Verify

Open Claude Code and ask: *"List all my connected MCP services and test each one."* Fix any auth issues before proceeding.

---

## Step 2: Set Up Obsidian Vault

### Folder Structure

Create this in your Obsidian vault:

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

### Meeting Note Template

```markdown
---
date: {{date}}
attendees:
project:
tags: [meeting]
---

# {{title}}

## Context
_Why is this meeting happening?_

## Notes

## Action Items
- [ ]

## Follow-ups
_Link to related notes: [[]]_
```

### Recommended Plugins

- **Daily Notes** — auto-creates daily note files (built-in, just enable)
- **Templater** — advanced templates with dynamic variables
- **Dataview** — query your notes like a database
- **Calendar** — visual calendar to navigate daily notes
- **Periodic Notes** — weekly/monthly note templates

---

## Step 3: Create Notion Knowledge Base

### Database Setup

Tell Claude:

> "Create a Notion database called 'AI Knowledge Base' with these properties: Title (text), Source (select: Reddit, YouTube, Article, Newsletter, Twitter, Podcast), URL (url), Status (select: Inbox, To Review, Processed, Action Items, Archived), Tags (multi-select: prompting, agents, MCP, workflows, coding, automation, tools), Summary (text), Key Insights (text), Relevance (select: High, Medium, Low), Action Required (checkbox), Related Task (url), Date Captured (date), Date Reviewed (date)"

### Connect Readwise Auto-Export

1. Open Readwise → Dashboard → Export → Notion
2. Connect your Notion workspace
3. Map highlights to your AI Knowledge Base database
4. Enable auto-export for new highlights

### Set Up Raindrop.io Capture

1. Create a Raindrop.io account (free)
2. Install the browser extension and iOS app
3. Create a collection called "AI Resources"
4. Use the share sheet on mobile to save from any app
5. Periodically review and move items to Notion (Claude can help)

---

## Step 4: Structure Todoist Projects

```
Work
  ├── [Your initiative/team names]
  └── Meeting Follow-ups

Personal               # Share these with your partner
  ├── Household
  ├── Groceries & Shopping
  ├── Finance & Admin
  └── Travel & Events

AI Learning
  ├── Things to Try
  ├── Skills to Build
  └── Tools to Evaluate

Inbox                  # Default capture bucket
```

> **Tip:** Share the Personal project with your partner by inviting them via email in Todoist. They can use the free plan.

---

## Step 5: Build Morning Planner Skill

Tell Claude:

> "Build a Claude Code skill called 'morning-plan' that I can run with /morning-plan. It should:
> 1. Get today's date and pull all calendar events
> 2. Get my open Todoist tasks (priority 1-3, due today or overdue)
> 3. Search Gmail for unread emails from the last 12 hours
> 4. Search Slack for unread mentions
> 5. Find my free time slots between meetings
> 6. Present a proposed daily plan with tasks assigned to time blocks
> 7. Ask me to confirm or adjust before creating calendar blocks
> Output should be clean and scannable, not a wall of text."

---

## Step 6: Build Evening Reflection Skill

Tell Claude:

> "Build a skill called 'evening-reflect' invoked with /reflect. It should:
> 1. Pull today's completed Todoist tasks
> 2. Compare against what was planned this morning
> 3. Summarize what happened on my calendar today
> 4. Move any incomplete priority tasks to tomorrow
> 5. Create a daily note in Obsidian at Daily/YYYY-MM-DD.md
> 6. Include: what got done, what didn't, one pattern observation
> 7. Keep the reflection concise (5-8 sentences max)"

---

## Step 7: Build Weekly Review Skill

Tell Claude:

> "Build a skill called 'weekly-review' invoked with /weekly-review. It should:
> 1. Summarize this week's completed tasks from Todoist
> 2. Analyze calendar — hours in meetings vs free time
> 3. Read daily reflections from Obsidian Daily/ folder
> 4. Query Notion KB for items captured this week
> 5. Promote high-relevance KB items to Todoist tasks
> 6. Propose top 3-5 priorities for next week
> 7. Save to Obsidian at Weekly Reviews/YYYY-WXX.md"

---

## Step 8: Build KB Triage Skill

Tell Claude:

> "Build a skill called 'triage-kb' invoked with /triage. It should:
> 1. Query Notion for all items with Status = 'Inbox'
> 2. For each item, fetch the URL content if possible
> 3. Write a 2-3 sentence summary
> 4. Extract key takeaways into Key Insights
> 5. Auto-tag based on content
> 6. Rate relevance (High/Medium/Low)
> 7. For High relevance, create a Todoist task in AI Learning
> 8. Update status to Processed (or To Review if uncertain)"

---

## Step 9: Build iMessage MCP Server

**Technical details:**

- macOS stores iMessage data at `~/Library/Messages/chat.db` (SQLite)
- Read-only access — cannot send or delete messages
- Requires Full Disk Access for terminal app (System Settings → Privacy & Security)

**Capabilities:**
- Search messages by contact name or keyword
- Get recent messages (last 24h, 7d, etc.)
- Extract messages that look like requests/action items
- List recent conversations

---

## Step 10: Create iOS Shortcuts

### Quick Capture to Todoist

1. Open Shortcuts app → New Shortcut
2. Set input to "Receive **Text** from **Share Sheet**"
3. Add action: "Ask for Input" with prompt "Any notes?" (optional)
4. Add action: "Add Todoist Task" with title = Shortcut Input, project = Inbox
5. Name it "Quick Task" and enable "Show in Share Sheet"

### Save to Knowledge Base

1. Open Shortcuts app → New Shortcut
2. Set input to "Receive **URLs** and **Text** from **Share Sheet**"
3. Add action: "Get Contents of URL" (Notion API endpoint)
4. Configure POST request to create a new page in your KB database with Status = Inbox
5. Name it "Save to KB" and enable "Show in Share Sheet"

> You'll need a Notion API key from notion.so/my-integrations.

---

## Step 11: Test the Full System

### Verification Checklist

- [ ] Run `/morning-plan` — does it pull calendar, tasks, and inbox?
- [ ] Ask Claude to create a Todoist task — does it appear in the right project?
- [ ] Ask Claude to read your Obsidian vault — can it find and read notes?
- [ ] Ask Claude to query your Notion KB — can it read the database?
- [ ] Ask Claude to search your Readwise highlights — does it find results?
- [ ] Test the iOS "Quick Task" shortcut from WhatsApp or Signal
- [ ] Test the iOS "Save to KB" shortcut from Instagram or Reddit
- [ ] Run `/reflect` — does it write to Obsidian and update Todoist?
- [ ] Ask Claude to search your recent iMessages for action items
- [ ] Verify your partner can see shared Todoist projects

---

**You're done.** Run `/morning-plan` tomorrow morning to start using the system. It compounds — the more data flows through, the smarter your planning and reflections become.
