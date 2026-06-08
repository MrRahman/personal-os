#!/bin/bash
# Personal OS v3.0 — cadence-draft: pre-compute the weekly / monthly / quarterly
# review DRAFT so the review surface (/week, /month, /quarter) is a thin review,
# not a 2-4 hour cold start. These are exactly the willpower-dependent rituals that
# died in burnout; pre-drafting them is the point (same thesis as the daily brief).
#
# Usage:  cadence-draft.sh <weekly|monthly|quarterly>
#
# SAFETY (same posture as daily-brief.sh; see memory/feedback_work_readonly_personal_ok.md):
#   - WORK (WorkCo) tools are READ-ONLY (list/get/search). No mutations. Allowlist is the gate.
#   - Personal/local servers read-only here too (a review only GATHERS).
#   - Vault writes go through the managed-block contract (prompt-enforced); coach voice (Phase 2).
#   - NO bypassPermissions. Envelope -> run-log is redacted (Phase 1c).
set -uo pipefail

CADENCE="${1:-}"
case "$CADENCE" in
  weekly|monthly|quarterly) ;;
  *) echo "usage: cadence-draft.sh <weekly|monthly|quarterly>" >&2; exit 2 ;;
esac

REPO="/Users/sulaimanrahman/projects/personal-os"
CLAUDE="/Users/sulaimanrahman/.nvm/versions/node/v24.14.0/bin/claude"   # absolute — launchd PATH lacks nvm
PROMPT_FILE="$REPO/mcp-servers/prompts/cadence-draft.md"
MODEL="sonnet"
VAULT="${PERSONAL_OS_VAULT:-/Users/sulaimanrahman/Documents/PersonalOS}"   # overridable for isolated testing
TODAY="$(date +%Y-%m-%d)"
LOG_DIR="$REPO/.claude/logs"
RUNLOG="$LOG_DIR/${TODAY}-cadence-${CADENCE}.jsonl"
STATE_DIR="$REPO/.claude/state"
STATE="${PERSONAL_OS_STATE:-$STATE_DIR/cadence-${CADENCE}.json}"
LOCKDIR="/tmp/personalos-cadence-${CADENCE}.lock.d"

mkdir -p "$LOG_DIR" "$STATE_DIR"
log() { echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"job\":\"cadence-${CADENCE}\",$1}" >> "$RUNLOG"; }

# --- single-run lock (mkdir is atomic + portable; macOS has no flock) ---
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  if [ -n "$(find "$LOCKDIR" -maxdepth 0 -mmin +60 2>/dev/null)" ]; then
    rmdir "$LOCKDIR" 2>/dev/null && mkdir "$LOCKDIR" 2>/dev/null || true
  else
    log "\"status\":\"skipped-locked\""; exit 0
  fi
fi
trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

cd "$REPO" || { echo "cd failed" >&2; exit 1; }
export PERSONAL_OS_HEADLESS=1   # SessionStart hooks early-exit on this sentinel (no recursion)
# Slow stdio MCP servers (e.g. otter) connect lazily; make claude wait during init
# rather than acting before tools are ready (root cause of the 2026-06-04 loop).
export MCP_TIMEOUT=30000
export MCP_TOOL_TIMEOUT=30000

bash "$REPO/mcp-servers/healthcheck.sh" >/dev/null 2>&1 || true

# --- least-privilege allowlist: a review only GATHERS — read-only everywhere ---
ALLOWED_TOOLS=(
  Read Glob Grep Write
  "mcp__claude_ai_Google_Calendar__list_events"
  "mcp__claude_ai_Google_Calendar__list_calendars"
  "mcp__claude_ai_Google_Calendar__get_event"
  "mcp__claude_ai_Gmail__search_threads"
  "mcp__claude_ai_Gmail__get_thread"
  "mcp__google-personal"
  "mcp__todoist-local"
  "mcp__notion-local"
)

if [ ! -f "$PROMPT_FILE" ]; then
  log "\"status\":\"no-prompt\""; echo "cadence-draft: prompt missing: $PROMPT_FILE" >&2; exit 1
fi

FULL_PROMPT="$(cat "$PROMPT_FILE")

---
CADENCE: ${CADENCE}
TODAY: ${TODAY}
VAULT: ${VAULT}"

OUT="$("$CLAUDE" -p "$FULL_PROMPT" \
        --model "$MODEL" \
        --allowedTools "${ALLOWED_TOOLS[@]}" \
        --output-format json 2>>"$RUNLOG.err")"
RC=$?

# --- envelope -> run-log + state (redacted; Phase 1c) ---
/usr/bin/python3 - "$OUT" "$RC" "$RUNLOG" "$STATE" "$CADENCE" <<'PY'
import sys, json, datetime
sys.path.insert(0, "/Users/sulaimanrahman/projects/personal-os/mcp-servers")
from redact import redact_text, secrets_from_mcp
_SECRETS = secrets_from_mcp("/Users/sulaimanrahman/projects/personal-os/.mcp.json")
out, rc, runlog, state, cadence = sys.argv[1:6]
rec = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "job": f"cadence-{cadence}", "rc": int(rc)}
try:
    d = json.loads(out)
    rec.update(status="error" if d.get("is_error") else "ok",
               cost_usd=d.get("total_cost_usd"), turns=d.get("num_turns"),
               denials=d.get("permission_denials"), result=(d.get("result") or "")[:200])
    if d.get("permission_denials"):
        rec["status"] = "degraded-denials"
except Exception as e:
    rec.update(status="parse_error", err=str(e), raw=(out or "")[:300])
with open(runlog, "a") as f:
    f.write(redact_text(json.dumps(rec), _SECRETS) + "\n")
try:
    st = json.load(open(state))
except Exception:
    st = {}
st["last_run"] = rec["ts"]
st["day"] = datetime.datetime.now().strftime("%Y-%m-%d")
st["status"] = rec.get("status")
st["cost_usd"] = rec.get("cost_usd")
st["denials"] = rec.get("denials")
open(state, "w").write(redact_text(json.dumps(st, indent=2), _SECRETS))
print(f"cadence-{cadence}:", rec.get("status"), "| cost", rec.get("cost_usd"), "| turns", rec.get("turns"))
PY
