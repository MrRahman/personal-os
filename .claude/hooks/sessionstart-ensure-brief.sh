#!/usr/bin/env bash
# SessionStart hook — ensure today's daily brief exists (v3.0).
#
# Makes "ready when I open Claude" work without guessing a wake time: if today's
# DRAFT daily note is missing and no brief is in flight, kick daily-brief.sh in
# the background so /day has something to read. Emits a gentle pointer otherwise.
#
# This is the lazy/fallback trigger. The eager path is the weekday 6am launchd
# (launchd/com.personalos.daily-brief.plist, opt-in via setup.sh). Either way the
# single mkdir-lock in daily-brief.sh guarantees at most one run per morning.
#
# Format ref: SessionStart hooks emit hookSpecificOutput.additionalContext, which
# becomes turn context for Claude (not printed to the terminal unless Claude
# surfaces it). Pattern mirrors sessionstart-health.sh / sessionstart-drift.sh.

set -u

# --- recursion guard (CRITICAL) ----------------------------------------------
# daily-brief.sh exports PERSONAL_OS_HEADLESS=1. Its headless `claude -p` still
# fires SessionStart hooks (we do not pass --bare yet), so this hook re-runs
# inside the brief's own subprocess. Early-exit there or we fork-bomb.
[ "${PERSONAL_OS_HEADLESS:-0}" = "1" ] && exit 0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRIEF="${REPO_ROOT}/mcp-servers/daily-brief.sh"
STATE="${REPO_ROOT}/.claude/state/brief.json"
VAULT="${PERSONALOS_VAULT:-$HOME/Documents/PersonalOS}"
TODAY="$(date +%Y-%m-%d)"
NOTE="${VAULT}/Daily/${TODAY}.md"
LOCKDIR="/tmp/personalos-daily-brief.lock.d"

[ -f "$BRIEF" ] || exit 0   # misconfigured — never break a session (invoked via bash below, so no +x needed)

emit() { jq -n --arg ctx "$1" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'; }

# --- 1. draft already present? -----------------------------------------------
if [ -f "$NOTE" ] && grep -q "BEGIN:auto-draft" "$NOTE" 2>/dev/null; then
  # Reviewed already (status: final) → stay silent, no nag.
  if grep -qE '^status:[[:space:]]*final' "$NOTE" 2>/dev/null; then
    exit 0
  fi
  # Unreviewed draft → one gentle pointer that self-extinguishes after /day.
  emit "Today's daily brief is ready and unreviewed (Daily/${TODAY}.md). Suggest running /day to close out yesterday and confirm today."
  exit 0
fi

# --- 2. a build is in flight (launchd or another session kicked it)? ---------
if [ -d "$LOCKDIR" ]; then
  emit "Today's daily brief is building in the background — /day will pick it up in a couple of minutes."
  exit 0
fi

# --- 3. a run already happened today but produced no draft → it failed -------
# Don't burn another ~\$0.84 run automatically; surface it instead.
if [ -f "$STATE" ]; then
  LAST_RUN_DAY="$(jq -r '.day // ""' "$STATE" 2>/dev/null)"   # local date; NOT the UTC last_run
  if [ -n "$LAST_RUN_DAY" ] && [ "$LAST_RUN_DAY" = "$TODAY" ]; then
    STATUS="$(jq -r '.status // "?"' "$STATE" 2>/dev/null)"
    emit "A daily-brief run happened today (status=${STATUS}) but no draft exists — likely a failure. Check .claude/logs/${TODAY}-daily-brief.jsonl; run /day to build one live, or re-run mcp-servers/daily-brief.sh after fixing."
    exit 0
  fi
fi

# --- 4. missing + nothing running + no run today → kick it detached ----------
# The lock check above is advisory; daily-brief.sh's own mkdir-lock is authoritative.
# If the 6am launchd and this hook race, the second caller logs skipped-locked and exits 0.
nohup bash "$BRIEF" >/dev/null 2>&1 </dev/null &
emit "No brief yet for ${TODAY} — I kicked the daily-brief build in the background (~2-3 min). Run /day shortly; it will wait for the draft if it's still in flight."
exit 0
