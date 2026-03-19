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
- Work, Personal (shared), AI Learning, Inbox

## Notion Databases
- AI Knowledge Base (ID: 32873b7c-bcd4-816c-8f24-e2585c9668ea) — inbox for AI resources, articles, tools

## Obsidian Vault Structure
```
PersonalOS/
├── Daily/          # Daily notes (YYYY-MM-DD.md)
├── Meetings/       # Meeting notes (auto-generated from Otter transcripts)
├── People/         # Contact profiles with meeting history and context
├── Reflections/    # (unused, reflections go in Daily notes)
├── Weekly Reviews/ # YYYY-WXX.md
├── Projects/       # Project-specific notes
├── Ideas/          # Capture pad
└── Templates/      # Daily Note, Meeting Note, Weekly Review, Person
```
