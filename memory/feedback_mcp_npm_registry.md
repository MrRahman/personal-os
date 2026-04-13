---
name: MCP servers need NPM_CONFIG_REGISTRY override
description: All npx-based MCP servers fail if ~/.npmrc points to a private corporate registry — must add NPM_CONFIG_REGISTRY env var to each server in .mcp.json
type: feedback
---

Every npx-based MCP server in `.mcp.json` MUST include `"NPM_CONFIG_REGISTRY": "https://registry.npmjs.org"` in its `env` block.

**Why:** The user's `~/.npmrc` routes npm to Ripple's private Artifactory registry. Public npm packages (@doist/todoist-ai, @notionhq/notion-mcp-server, mcp-remote, @aaronsb/google-workspace-mcp) don't exist there, causing ETIMEDOUT errors on every session start. The env var overrides the registry for just the npx process without touching global config.

**How to apply:** When adding ANY new npx-based MCP server to `.mcp.json`, always include the `NPM_CONFIG_REGISTRY` env var. Servers that don't use npx (like Otter's pipx wrapper or iMessage's local node binary) don't need it. If an MCP server fails to connect and isn't an auth issue, check this first.
