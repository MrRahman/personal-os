# Personal OS

A personal productivity system with Claude as the central brain — connecting tasks, calendar, notes, knowledge, and communication into automated daily workflows.

**Two commands run the day: `/morning-plan` and `/reflect`. Everything else is automated.**

## What It Does

Claude orchestrates 8 connected services into a unified operating system for your day. The morning plan syncs your calendar, tasks, email, Slack, iMessage, and knowledge base into a single daily brief with scaffolded meeting notes. The evening reflection syncs meeting transcripts, compares plan vs actual, and writes structured reflections. A knowledge pipeline automatically captures articles through Readwise, triages them in Notion, and surfaces insights as Obsidian notes.

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CAPTURE LAYER                         │
│                                                         │
│  Readwise Reader ──► Notion KB ──► Obsidian Resources/  │
│  Otter.ai ──► Obsidian Meetings/ + Transcripts/         │
│  Google Calendar ──► Obsidian Meetings/                  │
│  Conversations ──► Obsidian Ideas/                       │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   OBSIDIAN VAULT                         │
│               ~/Documents/PersonalOS/                    │
│                                                         │
│  Daily/ · Meetings/ · People/ · Resources/ · Topics/    │
│  Projects/ · Goals/ · Ideas/ · Weekly Reviews/           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                 CONNECTED SERVICES                       │
│                                                         │
│  Google Calendar · Gmail · Slack · Todoist · Notion     │
│  Readwise Reader · Otter.ai · iMessage                  │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

- **macOS** (required for iMessage MCP — everything else works on Linux)
- **Claude Code** with Max or Pro plan
- **Node.js 18+**
- **Python 3.9+** (for Otter.ai cookie refresh, optional)

## Required Accounts

| Service | Cost | Required? |
|---------|------|-----------|
| Claude Code | $20-200/mo | Yes |
| Todoist Pro | $5/mo | Yes |
| Obsidian | Free ($4/mo for Sync) | Yes |
| Notion | Free | Yes (for KB pipeline) |
| Readwise Reader | $8/mo | Recommended |
| Google Calendar | Free | Yes |
| Gmail | Free | Yes |
| Slack | Free | If you use Slack |
| Otter.ai | $20/mo | Optional (meeting transcripts) |

**Minimum viable setup:** Claude Code + Todoist + Google Calendar + Obsidian (all free except Claude).

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/MrRahman/personal-os.git
cd personal-os

# 2. Run the setup script
./setup.sh

# 3. Connect integrations in Claude desktop app
#    Settings > Integrations > Google Calendar, Gmail, Slack

# 4. Start using it
#    /morning-plan
```

## Skills

| Command | When | What It Does |
|---------|------|-------------|
| `/morning-plan` | Every morning | Calendar, tasks, email, Slack, iMessage, KB sync, meeting scaffolding, daily note |
| `/reflect` | End of day | Otter transcript sync, plan vs actual, task rescheduling, People notes, Check-In scores |
| `/weekly-review` | Friday | Week analysis, time allocation, KB review, next week priorities |
| `/sync-meetings` | On demand | Fetch Otter transcripts, resolve speaker names, fill meeting notes |
| `/capture` | On demand | Readwise → Notion pipeline (deduped, URL-normalized) |
| `/triage` | On demand | Process Notion KB inbox: type detection, tagging, summarization |
| `/idea` | On demand | 30-second idea capture, linked to vault |
| `/kb` | On demand | Search knowledge base (Notion + Readwise) |
| `/prep` | Before meetings | Pull People notes, meeting history, open commitments |
| `/draft` | On demand | Email drafting with context from vault |

## Obsidian Vault Structure

```
PersonalOS/
├── Daily/          # Daily notes (YYYY-MM-DD.md)
├── Meetings/       # Meeting notes (auto-generated)
│   └── Transcripts/ # Full Otter transcripts with speaker names
├── People/         # Contact profiles with meeting history
├── Resources/      # KB items from Readwise → Notion pipeline
├── Topics/         # Map of Content notes (AI, Crypto, etc.)
├── Projects/       # Active work initiatives
├── Goals/          # Annual + quarterly goals
├── Ideas/          # Quick captures from /idea
├── Weekly Reviews/ # YYYY-WXX.md retrospectives
└── Templates/      # 9 note templates (copied by setup.sh)
```

## MCP Services

| Service | Transport | Setup |
|---------|-----------|-------|
| Google Calendar | claude.ai integration | Connect in Settings > Integrations |
| Gmail | claude.ai integration | Connect in Settings > Integrations |
| Slack | claude.ai integration | Connect in Settings > Integrations |
| Todoist | HTTP MCP | OAuth prompt on first use |
| Notion | HTTP MCP | Token in .mcp.json (setup.sh configures this) |
| Readwise | HTTP MCP | OAuth prompt on first use |
| iMessage | stdio MCP (local) | Built by setup.sh, requires Full Disk Access |
| Otter.ai | stdio MCP (Python) | Session cookie in .mcp.json (optional) |

## Customization

### Todoist Labels
Edit the label-to-project map in `CLAUDE.md` to match your work structure. Labels without a project mapping (marked `—`) are cross-cutting concerns that don't map to a single Obsidian project.

### Executive Contacts
Add names to the `Executive Contacts` section in `CLAUDE.md` to trigger Strategic Frame in meeting notes — extra strategic context for senior leadership meetings.

### Knowledge Base Topics
The 18-topic, 87-tag taxonomy is defined in the `/triage` skill. Modify `.claude/skills/triage.md` to adjust topics and tags for your interests.

### Adding New Skills
Skills live in `.claude/skills/` and commands in `.claude/commands/`. See existing skills for the pattern. Each skill is a markdown file with instructions that Claude follows.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full system design, including knowledge flow, meeting flow, tag system, and reflection system.

## Cost

| Tier | Monthly | What You Get |
|------|---------|-------------|
| Minimum | ~$25/mo | Claude Pro + Todoist. Calendar, tasks, daily planning |
| Recommended | ~$40/mo | + Readwise + Obsidian Sync. Full KB pipeline |
| Full | ~$60/mo | + Otter.ai. Meeting transcripts with speaker names |

## FAQ

**Do I need all 8 MCP services?**
No. Todoist + Calendar + Obsidian is the minimum. Add services as needed — each skill gracefully handles missing connections.

**Does this work on Linux?**
Partially. iMessage requires macOS (it reads `~/Library/Messages/chat.db`). Everything else works on Linux.

**Can I use a different note-taking app?**
The system is built around Obsidian's local markdown files. Obsidian is free and Claude reads/writes the files directly — no plugins needed.

**How do I update?**
`git pull` to get skill updates. Your `CLAUDE.md` and `.mcp.json` are gitignored and won't be overwritten.

## License

MIT
