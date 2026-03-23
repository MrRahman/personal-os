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
│   └── Transcripts/ # Full Otter transcripts linked from meeting notes
├── People/         # Contact profiles with meeting history and context
├── Resources/      # KB items — one note per article/video/tool from Readwise→Notion pipeline
├── Topics/         # Map of Content notes — one per topic (AI, Crypto, etc.), auto-populated
├── Reflections/    # (unused, reflections go in Daily notes)
├── Weekly Reviews/ # YYYY-WXX.md
├── Projects/       # Project-specific notes
├── Ideas/          # Capture pad
└── Templates/      # Daily Note, Meeting Note, Weekly Review, Person, Resource, Topic
```
