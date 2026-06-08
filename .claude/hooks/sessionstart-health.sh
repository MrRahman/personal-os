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

# Skip inside the unattended daily-brief subprocess (it exports this). No point
# running a healthcheck inside a headless brief, and it avoids wasted API calls.
[ "${PERSONAL_OS_HEADLESS:-0}" = "1" ] && exit 0

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
ROUTING_REMINDER="Google routing rule: work (you@workco.example) uses mcp__claude_ai_Google_Calendar__* and mcp__claude_ai_Gmail__* (pre-scoped to work, no email arg). Personal (you@personal.example) uses mcp__google-personal__manage_*. Never cross them — WorkCo blocks the third-party OAuth app with 403."

# Project orchestration (v2.0+): scan all active projects for staged agent work.
# Parses each Obsidian Project note's `repo:` frontmatter, checks the repo's
# .claude/staging/ dir for pending items. Surfaces as [ASK] at the top of
# Claude's context — before everything else per user's hard requirement.
STAGED_WORK_NOTE=""
VAULT="${PERSONALOS_VAULT:-$HOME/Documents/PersonalOS}"
if [ -d "$VAULT/Projects" ]; then
  declare -a STAGED_PROJECTS=()
  for project_note in "$VAULT/Projects"/*.md; do
    [ -f "$project_note" ] || continue
    # Read `repo:` from frontmatter (top YAML block)
    REPO=$(awk '/^---$/{f++; next} f==1 && /^repo:/{sub(/^repo:[ \t]*/,""); gsub(/[\"'"'"']/,""); print; exit}' "$project_note")
    [ -z "$REPO" ] && continue
    [ ! -d "$REPO/.claude/staging" ] && continue
    # Count non-empty staging dirs
    STAGED_COUNT=$(find "$REPO/.claude/staging" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    if [ "${STAGED_COUNT:-0}" -gt 0 ]; then
      PROJECT_SLUG=$(basename "$project_note" .md)
      STAGED_PROJECTS+=("${PROJECT_SLUG}: ${STAGED_COUNT} unit(s)")
    fi
  done
  if [ "${#STAGED_PROJECTS[@]:-0}" -gt 0 ]; then
    TOTAL=${#STAGED_PROJECTS[@]}
    STAGED_WORK_NOTE="[ASK] ${TOTAL} project(s) have pending agent output to review:
"
    for line in "${STAGED_PROJECTS[@]}"; do
      STAGED_WORK_NOTE="${STAGED_WORK_NOTE}  - ${line}
"
    done
    STAGED_WORK_NOTE="${STAGED_WORK_NOTE}Run /dispatch --status to see details, or /dispatch --merge <project>/<unit-id> to merge.

"
  fi
fi

if [ $EXIT_CODE -eq 0 ]; then
  # All required services pass — minimal context
  CONTEXT="${STAGED_WORK_NOTE}$OUTPUT

$ROUTING_REMINDER"
else
  # Required service failed — verbose panel
  CONTEXT="${STAGED_WORK_NOTE}⚠ MCP preflight found failures. Next /morning-plan or /reflect may surface issues.

$OUTPUT

$ROUTING_REMINDER

If a required service is failing: fix per the detail above, then restart Claude Code (or run \`/mcp reconnect <service>\` for stdio fixes that don't require a cookie refresh)."
fi

# Emit JSON per Claude Code hook spec
jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'

exit 0
