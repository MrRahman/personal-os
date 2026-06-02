#!/usr/bin/env bash
# SessionStart hook — Personal OS drift cache (v1.8)
#
# Runs drift-check.sh to populate .claude/state/drift.json. Surfaces a release
# nudge if 3+ commits are unreleased since the last tag.
#
# Silent when nothing is drifting. Adds to Claude's additionalContext when
# surfaceable drift is detected, so the next /morning-plan can read it.

set -u

# Skip inside the unattended daily-brief subprocess (it exports this).
[ "${PERSONAL_OS_HEADLESS:-0}" = "1" ] && exit 0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRIFT_CHECK="${REPO_ROOT}/mcp-servers/drift-check.sh"
DRIFT_FILE="${REPO_ROOT}/.claude/state/drift.json"

if [ ! -x "$DRIFT_CHECK" ]; then
  exit 0
fi

# Run drift-check silently; it writes drift.json
"$DRIFT_CHECK" >/dev/null 2>&1 || true

if [ ! -f "$DRIFT_FILE" ]; then
  exit 0
fi

# Check if anything warrants surfacing
RELEASE_SURFACE=$(jq -r '.releases.should_surface // false' "$DRIFT_FILE")
MEMORY_SURFACE=$(jq -r '.memory.should_surface // false' "$DRIFT_FILE")

CONTEXT=""

if [ "$RELEASE_SURFACE" = "true" ]; then
  COUNT=$(jq -r '.releases.unreleased_count' "$DRIFT_FILE")
  LAST_TAG=$(jq -r '.releases.last_tag' "$DRIFT_FILE")
  NEXT=$(jq -r '.releases.suggested_next_version' "$DRIFT_FILE")
  FEAT=$(jq -r '.releases.commits_by_type.feat' "$DRIFT_FILE")
  FIX=$(jq -r '.releases.commits_by_type.fix' "$DRIFT_FILE")
  CONTEXT="${CONTEXT}[ASK] Release drift: ${COUNT} commits unreleased since ${LAST_TAG} (${FEAT} feat, ${FIX} fix). Suggested bump: ${NEXT}. morning-plan will surface a release proposal; confirm with y to cut it.

"
fi

if [ "$MEMORY_SURFACE" = "true" ]; then
  STALE_COUNT=$(jq -r '.memory.stale_count' "$DRIFT_FILE")
  CONTEXT="${CONTEXT}[TODO] Memory drift: ${STALE_COUNT} memory files >30 days old. Next quarterly-planning run will propose audit.

"
fi

if [ -z "$CONTEXT" ]; then
  # Nothing to surface — emit empty context so hook is a no-op
  exit 0
fi

jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'

exit 0
