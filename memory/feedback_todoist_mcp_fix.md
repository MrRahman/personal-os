---
name: Todoist MCP permanent auth fix
description: Todoist MCP uses @doist/todoist-ai with API key — and all npx-based MCP servers need NPM_CONFIG_REGISTRY override due to corporate .npmrc
type: feedback
---

Todoist MCP uses `@doist/todoist-ai` (native MCP server) with `TODOIST_API_KEY` env var. The API token is permanent (from Todoist Settings > Integrations > Developer).

**Why:** The old OAuth flow via `mcp-remote` to `ai.todoist.net/mcp` failed to store a refresh_token, causing daily expiry. The native server with API key bypasses this entirely.

**How to apply:** If Todoist MCP fails, check `.mcp.json` has `@doist/todoist-ai` with the API key in env. Never revert to bare OAuth flow. The token is in `.mcp.json` which is gitignored.
