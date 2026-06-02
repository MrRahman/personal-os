#!/bin/bash
# Personal OS v3.0 — daily-brief background pre-compute.
#
# Runs UNATTENDED via launchd (and on-demand by SessionStart-ensures). Self-heals,
# then invokes a headless `claude -p` to write today's DRAFT daily note + yesterday's
# factual close-out into the Obsidian vault. The human reviews it later via /day.
#
# SAFETY (see memory/feedback_work_readonly_personal_ok.md):
#   - WORK (Ripple) tools are READ-ONLY: list/get/search only. NO create/update/
#     delete/respond/send. Enforced by the --allowedTools allowlist below.
#   - Personal/local MCP servers MAY mutate (user-accepted, low blast radius).
#   - Vault writes go through the managed-block contract (the prompt enforces it).
#   - NO `--permission-mode bypassPermissions`. The allowlist IS the gate. Proven by
#     the Phase 0 spike: work connector reachable under launchd, permission_denials=[].
set -uo pipefail

REPO="/Users/sulaimanrahman/projects/personal-os"
CLAUDE="/Users/sulaimanrahman/.nvm/versions/node/v24.14.0/bin/claude"   # absolute — launchd PATH lacks nvm
PROMPT_FILE="$REPO/mcp-servers/prompts/daily-brief.md"
MODEL="sonnet"
TODAY="$(date +%Y-%m-%d)"
LOG_DIR="$REPO/.claude/logs"
RUNLOG="$LOG_DIR/${TODAY}-daily-brief.jsonl"
STATE_DIR="$REPO/.claude/state"
STATE="$STATE_DIR/brief.json"
LOCKDIR="/tmp/personalos-daily-brief.lock.d"

mkdir -p "$LOG_DIR" "$STATE_DIR"

# --- single-run lock (mkdir is atomic + portable; macOS has no flock) ---
# Prevents the launchd job and SessionStart-ensures from racing on the same morning.
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  # If the lock is stale (>30 min, e.g. a crashed prior run), reclaim it; else another run owns it.
  if [ -n "$(find "$LOCKDIR" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then
    rmdir "$LOCKDIR" 2>/dev/null && mkdir "$LOCKDIR" 2>/dev/null || true
  else
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"job\":\"daily-brief\",\"status\":\"skipped-locked\"}" >> "$RUNLOG"
    exit 0
  fi
fi
trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

cd "$REPO" || { echo "cd failed" >&2; exit 1; }
export PERSONAL_OS_HEADLESS=1   # SessionStart hooks early-exit on this sentinel (no recursion / fork-bomb)

# --- self-heal sweep ----------------------------------------------------------
# Cheap, read-only health snapshot now; full token auto-refresh (flock'd atomic
# .mcp.json writes + Enterprise-Grid frequency guard) lands in Phase 1c.
bash "$REPO/mcp-servers/healthcheck.sh" >/dev/null 2>&1 || true

# --- least-privilege tool allowlist ------------------------------------------
# WORK connectors: enumerated READ-ONLY tools only (the hard line — never mutate Ripple).
# Personal/local servers: server-level allow (mutations user-accepted).
ALLOWED_TOOLS=(
  Read Glob Grep Write
  # Work Google Calendar — READ ONLY (no create_event/update_event/delete_event/respond_to_event)
  "mcp__claude_ai_Google_Calendar__list_events"
  "mcp__claude_ai_Google_Calendar__list_calendars"
  "mcp__claude_ai_Google_Calendar__get_event"
  # Work Gmail — READ ONLY (no create_draft / label / send)
  "mcp__claude_ai_Gmail__search_threads"
  "mcp__claude_ai_Gmail__get_thread"
  "mcp__claude_ai_Gmail__list_labels"
  # Personal + local MCP servers (mutations user-accepted) — server-level allow
  "mcp__google-personal"
  "mcp__todoist-local"
  "mcp__notion-local"
  "mcp__readwise"
  "mcp__imessage"
  "mcp__otter"
)

# --- invoke the headless brief ------------------------------------------------
if [ ! -f "$PROMPT_FILE" ]; then
  echo "{\"ts\":\"$(date -u +%FT%TZ)\",\"job\":\"daily-brief\",\"status\":\"no-prompt\"}" >> "$RUNLOG"
  echo "daily-brief: prompt file missing: $PROMPT_FILE" >&2
  exit 1
fi

OUT="$("$CLAUDE" -p "$(cat "$PROMPT_FILE")" \
        --model "$MODEL" \
        --allowedTools "${ALLOWED_TOOLS[@]}" \
        --output-format json 2>>"$RUNLOG.err")"
RC=$?

# --- parse the JSON envelope -> run-log (JSONL) + state snapshot --------------
# Envelope fields confirmed by the Phase 0 spike: is_error, total_cost_usd,
# num_turns, permission_denials, result.
/usr/bin/python3 - "$OUT" "$RC" "$RUNLOG" "$STATE" <<'PY'
import sys, json, datetime
out, rc, runlog, state = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
rec = {"ts": datetime.datetime.utcnow().isoformat()+"Z", "job": "daily-brief", "rc": int(rc)}
try:
    d = json.loads(out)
    rec.update(
        status   = "error" if d.get("is_error") else "ok",
        cost_usd = d.get("total_cost_usd"),
        turns    = d.get("num_turns"),
        denials  = d.get("permission_denials"),
        result   = (d.get("result") or "")[:200],
    )
    # A non-empty permission_denials means the allowlist blocked something the
    # brief tried — surface it loudly (could be a needed read tool, or a blocked mutation).
    if d.get("permission_denials"):
        rec["status"] = "degraded-denials"
except Exception as e:
    rec.update(status="parse_error", err=str(e), raw=out[:300])
with open(runlog, "a") as f:
    f.write(json.dumps(rec) + "\n")
with open(state, "w") as f:
    json.dump({"last_run": rec["ts"], "status": rec.get("status"),
               "cost_usd": rec.get("cost_usd"), "denials": rec.get("denials")}, f, indent=2)
print("daily-brief:", rec.get("status"), "| cost", rec.get("cost_usd"), "| turns", rec.get("turns"))
PY
