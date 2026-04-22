#!/usr/bin/env bash
# SessionStart hook — Personal OS health panel (v1.8)
#
# Runs healthcheck.sh, then emits JSON to stdout that Claude Code loads into
# additionalContext. Silent on pass, verbose + stoppable on fail for required
# services.
#
# Format ref: https://code.claude.com/docs/en/hooks.md
# SessionStart hooks write `hookSpecificOutput.additionalContext` which becomes
# turn context for Claude (not shown in terminal unless Claude surfaces it).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HEALTHCHECK="${REPO_ROOT}/mcp-servers/healthcheck.sh"

if [ ! -x "$HEALTHCHECK" ]; then
  # Misconfigured — fail silently so we don't break sessions
  exit 0
fi

# Run healthcheck, capture stdout + exit code
OUTPUT=$("$HEALTHCHECK" 2>&1 || true)
EXIT_CODE=$?
HEALTH_JSON="${REPO_ROOT}/.claude/state/health.json"

# Google-routing reminder is appended regardless of pass/fail
ROUTING_REMINDER="Google routing rule: work (srahman@ripple.com) uses mcp__claude_ai_Google_Calendar__* and mcp__claude_ai_Gmail__* (pre-scoped to work, no email arg). Personal (1srahman@gmail.com) uses mcp__google-personal__manage_*. Never cross them — Ripple blocks the Breezy OAuth app with 403."

# Project orchestration (v2.0+): scan all active projects for staged agent work.
# For v1.8 we just stub this — Batch 4 fills it in with actual directory scanning.
STAGED_WORK_NOTE=""
# TODO v2.0: iterate ~/Documents/PersonalOS/Projects/*.md, read `repo:` frontmatter,
# check <repo>/.claude/staging/ for pending items, surface as [ASK] at top.

if [ $EXIT_CODE -eq 0 ]; then
  # All required services pass — minimal context
  CONTEXT="$OUTPUT

$ROUTING_REMINDER"
else
  # Required service failed — verbose panel
  CONTEXT="⚠ MCP preflight found failures. Next /morning-plan or /reflect may surface issues.

$OUTPUT

$ROUTING_REMINDER

If a required service is failing: fix per the detail above, then restart Claude Code (or run \`/mcp reconnect <service>\` for stdio fixes that don't require a cookie refresh)."
fi

# Emit JSON per Claude Code hook spec
jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'

exit 0
