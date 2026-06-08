#!/bin/bash
# Force cookie auth, unset email/password to prevent fallback
unset OTTER_EMAIL
unset OTTER_PASSWORD
# OTTER_SESSION_COOKIE is passed via .mcp.json env.
# Absolute path: launchd's PATH (/usr/bin:/bin:/usr/sbin:/sbin) lacks ~/.local/bin
# (pipx), so a bare `otter-mcp` is "command not found" under the background job —
# the same PATH class of bug the plan hit with claude/nvm. This was the root cause
# of the 2026-06-04 otter-sync degraded loop (MCP "unavailable" headless despite a
# valid cookie). See memory/project_pos_v3_redesign.md.
OTTER_MCP="/Users/sulaimanrahman/.local/bin/otter-mcp"
[ -x "$OTTER_MCP" ] || OTTER_MCP="/Users/sulaimanrahman/.local/pipx/venvs/otter-mcp/bin/otter-mcp"
exec "$OTTER_MCP"
