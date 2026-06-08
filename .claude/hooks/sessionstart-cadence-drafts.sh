#!/usr/bin/env bash
# SessionStart hook — surface unreviewed cadence-draft reviews (v3.0 Phase 5).
#
# cadence-draft.sh pre-writes the weekly/monthly/quarterly review as `status: draft`.
# This nudges the user to adjust+confirm via the review skill, so a pre-drafted
# review never sits unreviewed and unseen. Gentle [TODO]; never blocks a session.
#
# Emits hookSpecificOutput.additionalContext (turn context for Claude), mirroring
# sessionstart-ensure-brief.sh / -health.sh / -drift.sh.
set -u

# Recursion guard: headless background runs (PERSONAL_OS_HEADLESS=1) also fire
# SessionStart hooks; exit there so we never run inside a background job.
[ "${PERSONAL_OS_HEADLESS:-0}" = "1" ] && exit 0

VAULT="${PERSONALOS_VAULT:-$HOME/Documents/PersonalOS}"
command -v jq >/dev/null 2>&1 || exit 0   # emit needs jq; never break a session

emit() { jq -n --arg ctx "$1" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'; }

lines=""
check() {  # $1 = subdir, $2 = label, $3 = skill command
  local dir="$VAULT/$1" newest name
  [ -d "$dir" ] || return 0
  # most-recent note still in draft (unreviewed) in this cadence's dir
  newest="$(grep -lE '^status:[[:space:]]*draft[[:space:]]*$' "$dir"/*.md 2>/dev/null | sort | tail -1)"
  [ -n "$newest" ] || return 0
  name="$(basename "$newest" .md)"
  lines="${lines}[TODO] ${2} review draft ${name} is ready — run ${3} for a quick adjust + confirm.\n"
}
check "Weekly Reviews"    "Weekly"    "/weekly-review"
check "Monthly Reviews"   "Monthly"   "/monthly-review"
check "Quarterly Reviews" "Quarterly" "/quarterly-planning"

if [ -n "$lines" ]; then
  emit "$(printf "Pending pre-built reviews (drafted in the background by cadence-draft):\n%bReviewing is a quick adjust+confirm, not a rebuild. No rush — surfaced as a [TODO], not an [ASK]." "$lines")"
fi
exit 0
