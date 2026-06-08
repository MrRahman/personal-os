#!/bin/bash
# Personal OS v3.0 — otter-sync: continuous intraday meeting capture.
#
# Runs hourly (8am–8pm) via launchd. A CHEAP non-LLM poll (otter-poll.py) decides
# whether anything is worth doing; only then does it spend on a headless Haiku
# `claude -p` that fills meeting-note auto blocks from new transcripts. A
# deterministic prune sweep (meeting_notes.py) runs once/day. The human reviews
# nothing — by evening every meeting is captured.
#
# SAFETY (see memory/feedback_work_readonly_personal_ok.md + the v3.0 plan):
#   - WORK (WorkCo) Google is READ-ONLY (calendar list/get only — for matching +
#     attendee names). NO create/update/delete/respond/send. Enforced by the
#     --allowedTools allowlist below.
#   - All writes are to the personal Obsidian vault (Meetings/ + Transcripts/).
#   - The destructive PRUNE is a deterministic script step here — NEVER a model
#     action (the Haiku actor can only create/fill, never delete).
#   - NO `--permission-mode bypassPermissions`. The allowlist IS the gate.
set -uo pipefail

REPO="/Users/sulaimanrahman/projects/personal-os"
CLAUDE="/Users/sulaimanrahman/.nvm/versions/node/v24.14.0/bin/claude"   # absolute — launchd PATH lacks nvm
PROMPT_FILE="$REPO/mcp-servers/prompts/otter-sync.md"
MEETING_NOTES="$REPO/mcp-servers/meeting_notes.py"
OTTER_POLL="$REPO/mcp-servers/otter-poll.py"
MODEL="haiku"
VAULT="${PERSONAL_OS_VAULT:-/Users/sulaimanrahman/Documents/PersonalOS}"   # overridable for isolated testing
MAX_PER_RUN="${OTTER_SYNC_MAX:-6}"   # bound per-run cost/runtime; a backlog drains over cycles (env-overridable)
PRUNE_LOOKBACK_DAYS=7
TODAY="$(date +%Y-%m-%d)"
LOG_DIR="$REPO/.claude/logs"
RUNLOG="$LOG_DIR/${TODAY}-otter-sync.jsonl"
STATE_DIR="$REPO/.claude/state"
STATE="${PERSONAL_OS_STATE:-$STATE_DIR/otter-sync.json}"   # overridable for isolated testing
LOCKDIR="/tmp/personalos-otter-sync.lock.d"

mkdir -p "$LOG_DIR" "$STATE_DIR"
log() { echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"job\":\"otter-sync\",$1}" >> "$RUNLOG"; }

# --- single-run lock (mkdir is atomic + portable; macOS has no flock) ---
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  if [ -n "$(find "$LOCKDIR" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then
    rmdir "$LOCKDIR" 2>/dev/null && mkdir "$LOCKDIR" 2>/dev/null || true
  else
    log "\"status\":\"skipped-locked\""
    exit 0
  fi
fi
trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

cd "$REPO" || { echo "cd failed" >&2; exit 1; }
export PERSONAL_OS_HEADLESS=1   # SessionStart hooks early-exit on this sentinel (no recursion)
# The otter MCP (Python stdio) does a network login at startup and connects slowly;
# headless Haiku otherwise acts before its tools are ready ("still connecting") and
# falls back to denied Bash. Make claude WAIT for slow MCP servers during init.
# (Root cause #2 of the 2026-06-04 degraded loop; #1 was the wrapper's bare-name
# PATH lookup — see otter-wrapper.sh. Verified: MCP returns transcripts headless.)
export MCP_TIMEOUT=30000
export MCP_TOOL_TIMEOUT=30000

# --- 1. deterministic prune (once/day; the ONLY destructive step, never the model) ---
LAST_PRUNE="$(/usr/bin/python3 -c "import json;print(json.load(open('$STATE')).get('last_prune_day',''))" 2>/dev/null || true)"
if [ "$LAST_PRUNE" != "$TODAY" ]; then
  PRUNE_OUT="$(/usr/bin/python3 "$MEETING_NOTES" prune --vault "$VAULT" --today "$TODAY" --lookback-days "$PRUNE_LOOKBACK_DAYS" 2>>"$RUNLOG.err" || echo '{}')"
  PRUNED_N="$(echo "$PRUNE_OUT" | /usr/bin/python3 -c "import sys,json;print(len(json.load(sys.stdin).get('pruned',[])))" 2>/dev/null || echo 0)"
  log "\"step\":\"prune\",\"pruned\":${PRUNED_N},\"detail\":$(printf '%s' "$PRUNE_OUT" | /usr/bin/python3 -c "import sys,json;print(json.dumps(json.load(sys.stdin).get('pruned',[])))" 2>/dev/null || echo '[]')"
  /usr/bin/python3 - "$STATE" "$TODAY" <<'PY'
import json, sys
state, today = sys.argv[1], sys.argv[2]
try:    d = json.load(open(state))
except Exception: d = {}
d["last_prune_day"] = today
json.dump(d, open(state, "w"), indent=2)
PY
fi

# --- 2. cheap non-LLM poll: anything new? ---
POLL="$(/usr/bin/python3 "$OTTER_POLL" --vault "$VAULT" --state "$STATE" --mcp-json "$REPO/.mcp.json" 2>>"$RUNLOG.err")"
NEW_TOPN_JSON="$(printf '%s' "$POLL" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('new',[])[:$MAX_PER_RUN]))" 2>/dev/null || echo '[]')"
NEW_COUNT="$(printf '%s' "$NEW_TOPN_JSON" | /usr/bin/python3 -c "import sys,json;print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)"
POLL_ERR="$(printf '%s' "$POLL" | /usr/bin/python3 -c "import sys,json;print(json.load(sys.stdin).get('error',''))" 2>/dev/null || echo '')"

if [ -n "$POLL_ERR" ]; then
  log "\"step\":\"poll\",\"status\":\"degraded\",\"error\":$(printf '%s' "$POLL_ERR" | /usr/bin/python3 -c "import sys,json;print(json.dumps(sys.stdin.read()))")"
fi

if [ "$NEW_COUNT" -eq 0 ]; then
  log "\"step\":\"poll\",\"status\":\"no-new\""
  echo "otter-sync: no new transcripts."
  exit 0
fi

# --- 3. least-privilege allowlist (tighter than daily-brief: no Gmail/Todoist/Notion) ---
ALLOWED_TOOLS=(
  Read Glob Grep Write
  "Bash(python3 /Users/sulaimanrahman/projects/personal-os/mcp-servers/meeting_notes.py:*)"
  # Work calendar — READ ONLY (matching + attendee names)
  "mcp__claude_ai_Google_Calendar__list_events"
  "mcp__claude_ai_Google_Calendar__get_event"
  "mcp__claude_ai_Google_Calendar__list_calendars"
  # Personal calendar + Otter transcripts (read)
  "mcp__google-personal"
  "mcp__otter"
)

# --- 4. invoke the headless Haiku actor on just the new (capped) transcripts ---
if [ ! -f "$PROMPT_FILE" ]; then
  log "\"status\":\"no-prompt\""
  echo "otter-sync: prompt file missing: $PROMPT_FILE" >&2
  exit 1
fi

FULL_PROMPT="$(cat "$PROMPT_FILE")

---
NEW_TRANSCRIPTS (process ONLY these; JSON):
${NEW_TOPN_JSON}"

OUT="$("$CLAUDE" -p "$FULL_PROMPT" \
        --model "$MODEL" \
        --allowedTools "${ALLOWED_TOOLS[@]}" \
        --output-format json 2>>"$RUNLOG.err")"
RC=$?

# --- 5. envelope -> run-log + state; mark the handled otids processed on success ---
/usr/bin/python3 - "$OUT" "$RC" "$RUNLOG" "$STATE" "$NEW_TOPN_JSON" "$TODAY" <<'PY'
import sys, json, datetime
sys.path.insert(0, "/Users/sulaimanrahman/projects/personal-os/mcp-servers")
from redact import redact_text, secrets_from_mcp
_SECRETS = secrets_from_mcp("/Users/sulaimanrahman/projects/personal-os/.mcp.json")
out, rc, runlog, state, topn_json, today = sys.argv[1:7]
rec = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "job": "otter-sync",
       "step": "actor", "rc": int(rc)}
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

# state: preserve last_prune_day + existing processed_otids; refresh run fields.
try:    st = json.load(open(state))
except Exception: st = {}
st["last_run"] = rec["ts"]
st["day"] = datetime.datetime.now().strftime("%Y-%m-%d")   # LOCAL date (matches daily-brief convention)
st["status"] = rec.get("status")
st["cost_usd"] = rec.get("cost_usd")
st["denials"] = rec.get("denials")
# Mark the handled otids processed ONLY on a clean run, so a transcript the actor
# skipped (too short / unmatched) won't re-trigger every hour. Note otter_id in the
# written notes is the durable dedup; this is the belt-and-suspenders for skips.
if rec.get("status") == "ok":
    handled = [t.get("otid") for t in json.loads(topn_json) if t.get("otid")]
    st["processed_otids"] = sorted(set(st.get("processed_otids", [])) | set(handled))
open(state, "w").write(redact_text(json.dumps(st, indent=2), _SECRETS))
print("otter-sync:", rec.get("status"), "| handled", len(json.loads(topn_json)),
      "| cost", rec.get("cost_usd"), "| turns", rec.get("turns"))
PY
