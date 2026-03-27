# Personal OS — Project Configuration

## Identity
- Work email: srahman@ripple.com
- Personal email: 1srahman@gmail.com
- Timezone: America/Los_Angeles

## Paths
- Obsidian vault: ~/Documents/PersonalOS
- iMessage MCP server: ./mcp-servers/imessage/

## Conventions
- Dates: YYYY-MM-DD
- Weeks: ISO week numbers (YYYY-WXX)
- Calendar blocks: 30-minute minimum
- Time format: 24h for internal, 12h for display

## Error Handling
All skills must preflight-check MCP connections before running. Report what's unavailable, then continue with what works. Never fail silently — always tell the user what was skipped and why.

## MCP Services
| Service | Transport | Purpose |
|---------|-----------|---------|
| Google Calendar | claude.ai integration | Work + personal calendars |
| Gmail | claude.ai integration | Email triage |
| Slack | claude.ai integration | Mentions and messages |
| Todoist | HTTP MCP | Task management |
| Notion | HTTP MCP | AI Knowledge Base |
| Readwise | stdio MCP (npx) | Reading highlights |
| iMessage | stdio MCP (local) | Message search |
| Otter.ai | stdio MCP (Python) | Meeting transcripts |

## Todoist Projects
- Personal, Us (shared with wife), Work, Inbox

## Notion Databases
- AI Knowledge Base (Database ID: 32873b7c-bcd4-816c-8f24-e2585c9668ea, Data Source ID: 32873b7c-bcd4-8167-a01c-000b91db06d7) — inbox for AI resources, articles, tools
- Use the **Data Source ID** when calling `API-query-data-source`; use **Database ID** for `API-retrieve-a-database`

## Obsidian Vault Structure
```
PersonalOS/
├── Daily/          # Daily notes (YYYY-MM-DD.md)
├── Meetings/       # Meeting notes (auto-generated from Otter transcripts)
│   └── Transcripts/ # Full Otter transcripts with speaker names
├── People/         # Contact profiles with meeting history and context
├── Resources/      # KB items — one note per article/video/tool from Readwise→Notion pipeline
├── Topics/         # Map of Content notes — one per topic (AI, Crypto, etc.), auto-populated
├── Projects/       # Active work initiatives — auto-detected from meetings, MOC-style with Dataview
├── Goals/          # Annual direction (YYYY.md) + quarterly goals (YYYY-QX.md)
├── Ideas/          # Quick idea capture via /idea — conversational, linked to vault
├── Weekly Reviews/ # YYYY-WXX.md
└── Templates/      # Daily Note, Meeting Note, Weekly Review, Person, Resource, Topic, Project, Idea, Goal

## Project Conventions
- Meeting notes should populate the `project:` frontmatter field when related to an active project
- Format: `project: "[[Projects/slug]]"` — creates Dataview-queryable link
- Projects are auto-detected from recurring meeting themes during /reflect and /weekly-review
- Use /idea for quick idea capture — ideas can optionally link to projects via `project:` field

## Goals
- Goals live in `~/Documents/PersonalOS/Goals/`
- Annual note: `Goals/YYYY.md` — big-picture direction, set once, reviewed quarterly
- Quarterly notes: `Goals/YYYY-QX.md` — 5-7 active goals with outcomes and milestones
- Goals link to Projects via wikilinks. Projects can serve multiple goals.
- Morning-plan surfaces approaching milestones and stale goals (no activity in 7+ days).
- Weekly-review tracks milestone progress and proposes weekly targets.
- `area` field: work | personal (no sub-categories)
```
