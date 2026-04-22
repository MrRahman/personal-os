#!/usr/bin/env bash
# Personal OS health check (v1.8)
#
# Verifies each MCP connector is reachable and its auth token is valid by
# calling the underlying REST API directly — shell hooks can't invoke MCP
# tools, so we test the auth layer one hop below.
#
# Outputs:
#   - JSON: .claude/state/health.json ({"service": "ok|fail", "detail": "..."})
#   - stdout: brief-on-pass footer ("✓ 6/6 ok") or detailed fix panel on fail
#
# Exit codes:
#   0 = all required services pass
#   1 = at least one required service failed
#   2 = configuration error (e.g., .mcp.json not found)

set -u

REPO_ROOT="${PERSONAL_OS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MCP_JSON="${REPO_ROOT}/.mcp.json"
STATE_DIR="${REPO_ROOT}/.claude/state"
HEALTH_FILE="${STATE_DIR}/health.json"

mkdir -p "$STATE_DIR"

if [ ! -f "$MCP_JSON" ]; then
  echo "ERROR: .mcp.json not found at $MCP_JSON" >&2
  exit 2
fi

# jq is required for parsing tokens out of .mcp.json
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not installed. Run: brew install jq" >&2
  exit 2
fi

# Track results
declare -a RESULTS=()
PASS_COUNT=0
FAIL_COUNT=0
TOTAL_REQUIRED=0

check() {
  local name="$1"
  local required="$2"  # true|false
  local status="$3"    # ok|fail|skip
  local detail="$4"

  if [ "$required" = "true" ]; then
    TOTAL_REQUIRED=$((TOTAL_REQUIRED + 1))
  fi

  if [ "$status" = "ok" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
  elif [ "$status" = "fail" ]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  RESULTS+=("$(jq -n --arg name "$name" --arg req "$required" --arg st "$status" --arg det "$detail" \
    '{service: $name, required: ($req == "true"), status: $st, detail: $det}')")
}

# --- Todoist ---
TODOIST_KEY=$(jq -r '.mcpServers["todoist-local"].env.TODOIST_API_KEY // empty' "$MCP_JSON")
if [ -n "$TODOIST_KEY" ]; then
  HTTP=$(curl -sS -o /dev/null -w "%{http_code}" -m 5 \
    -H "Authorization: Bearer $TODOIST_KEY" \
    "https://api.todoist.com/api/v1/user" 2>/dev/null || echo "000")
  if [ "$HTTP" = "200" ]; then
    check "todoist" "true" "ok" ""
  elif [ "$HTTP" = "401" ] || [ "$HTTP" = "403" ]; then
    check "todoist" "true" "fail" "Auth failed ($HTTP). API key expired or revoked. Update TODOIST_API_KEY in .mcp.json."
  else
    check "todoist" "true" "fail" "HTTP $HTTP — network or API issue. Retry or check https://status.todoist.com"
  fi
else
  check "todoist" "true" "fail" "TODOIST_API_KEY missing from .mcp.json"
fi

# --- Notion ---
NOTION_HEADERS=$(jq -r '.mcpServers["notion-local"].env.OPENAPI_MCP_HEADERS // empty' "$MCP_JSON")
if [ -n "$NOTION_HEADERS" ]; then
  NOTION_TOKEN=$(echo "$NOTION_HEADERS" | jq -r '.Authorization // empty' | sed 's/^Bearer //')
  NOTION_VERSION=$(echo "$NOTION_HEADERS" | jq -r '."Notion-Version" // "2025-09-03"')
  if [ -n "$NOTION_TOKEN" ]; then
    HTTP=$(curl -sS -o /dev/null -w "%{http_code}" -m 5 \
      -H "Authorization: Bearer $NOTION_TOKEN" \
      -H "Notion-Version: $NOTION_VERSION" \
      "https://api.notion.com/v1/users/me" 2>/dev/null || echo "000")
    if [ "$HTTP" = "200" ]; then
      check "notion" "false" "ok" ""
    elif [ "$HTTP" = "401" ]; then
      check "notion" "false" "fail" "Token expired. Regenerate at https://www.notion.so/profile/integrations and update .mcp.json."
    else
      check "notion" "false" "fail" "HTTP $HTTP — Notion unreachable or token invalid."
    fi
  else
    check "notion" "false" "fail" "Notion token not parseable from OPENAPI_MCP_HEADERS"
  fi
else
  check "notion" "false" "skip" "Notion not configured"
fi

# --- Slack ---
SLACK_XOXC=$(jq -r '.mcpServers.slack.env.SLACK_MCP_XOXC_TOKEN // empty' "$MCP_JSON")
SLACK_XOXD=$(jq -r '.mcpServers.slack.env.SLACK_MCP_XOXD_TOKEN // empty' "$MCP_JSON")
if [ -n "$SLACK_XOXC" ] && [ -n "$SLACK_XOXD" ]; then
  # Slack stealth auth uses cookie + token. auth.test is the cheapest verification.
  RESP=$(curl -sS -m 5 \
    -H "Cookie: d=$SLACK_XOXD" \
    -F "token=$SLACK_XOXC" \
    "https://slack.com/api/auth.test" 2>/dev/null || echo '{"ok":false,"error":"network"}')
  OK=$(echo "$RESP" | jq -r '.ok // false')
  if [ "$OK" = "true" ]; then
    check "slack" "false" "ok" ""
  else
    ERR=$(echo "$RESP" | jq -r '.error // "unknown"')
    check "slack" "false" "fail" "Auth failed ($ERR). Slack tokens rotated — refresh xoxc + xoxd in .mcp.json from Slack browser session."
  fi
else
  check "slack" "false" "skip" "Slack not configured"
fi

# --- Readwise ---
# Readwise is a remote MCP (mcp-remote → https://mcp2.readwise.io/mcp). Auth is
# handled by the remote server; we can't easily test from here. Mark as ok if
# the wrapper exists; real failures surface during skill invocation.
if jq -e '.mcpServers.readwise' "$MCP_JSON" >/dev/null 2>&1; then
  check "readwise" "false" "ok" "(remote — not health-checked directly)"
else
  check "readwise" "false" "skip" "Readwise not configured"
fi

# --- Otter ---
if [ -f "${REPO_ROOT}/mcp-servers/refresh-otter-cookie.py" ]; then
  if python3 "${REPO_ROOT}/mcp-servers/refresh-otter-cookie.py" --validate >/dev/null 2>&1; then
    check "otter" "false" "ok" ""
  else
    check "otter" "false" "fail" "Otter cookie expired or invalid. Run: python3 mcp-servers/refresh-otter-cookie.py; then restart Claude Code."
  fi
else
  check "otter" "false" "skip" "Otter refresh script missing"
fi

# --- Google (personal) ---
# The google-personal MCP stores OAuth tokens in the package's config dir.
# Easier check: verify the config directory exists and has a recent token file.
GOOGLE_CONFIG="$HOME/.config/google-workspace-mcp"
if [ -d "$GOOGLE_CONFIG" ]; then
  # Look for recent auth file; if older than 30 days, flag (tokens rotate)
  RECENT_AUTH=$(find "$GOOGLE_CONFIG" -name "*.json" -mtime -30 -type f 2>/dev/null | head -1)
  if [ -n "$RECENT_AUTH" ]; then
    check "google-personal" "false" "ok" ""
  else
    check "google-personal" "false" "fail" "No recent Google auth token. MCP will prompt re-auth on first use."
  fi
else
  check "google-personal" "false" "skip" "google-personal not yet authenticated"
fi

# --- Obsidian vault ---
VAULT="$HOME/Documents/PersonalOS"
if [ -d "$VAULT" ] && [ -f "$VAULT/Templates/Meeting Note.md" ]; then
  check "vault" "true" "ok" ""
else
  check "vault" "true" "fail" "Obsidian vault missing or incomplete at $VAULT"
fi

# --- Write JSON state file ---
jq -n --argjson results "[$(IFS=,; echo "${RESULTS[*]}")]" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson pass "$PASS_COUNT" \
  --argjson fail "$FAIL_COUNT" \
  '{timestamp: $ts, pass: $pass, fail: $fail, services: $results}' > "$HEALTH_FILE"

# --- Output to stdout ---
TOTAL=$((PASS_COUNT + FAIL_COUNT))

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "✓ preflight ok ($PASS_COUNT/$TOTAL services + vault)"
  exit 0
fi

# At least one failure — print fix panel
echo "⚠ preflight: $FAIL_COUNT of $TOTAL services failed"
echo ""
for row in "${RESULTS[@]}"; do
  STATUS=$(echo "$row" | jq -r '.status')
  if [ "$STATUS" = "fail" ]; then
    NAME=$(echo "$row" | jq -r '.service')
    REQUIRED=$(echo "$row" | jq -r '.required')
    DETAIL=$(echo "$row" | jq -r '.detail')
    PREFIX=$([ "$REQUIRED" = "true" ] && echo "[REQUIRED]" || echo "[optional]")
    echo "  ✗ $NAME $PREFIX"
    echo "    $DETAIL"
  fi
done
echo ""
echo "Full details: $HEALTH_FILE"

# Exit 1 only if a REQUIRED service failed
REQUIRED_FAILED=false
for row in "${RESULTS[@]}"; do
  if [ "$(echo "$row" | jq -r '.required')" = "true" ] && [ "$(echo "$row" | jq -r '.status')" = "fail" ]; then
    REQUIRED_FAILED=true
    break
  fi
done

if [ "$REQUIRED_FAILED" = "true" ]; then
  exit 1
fi
exit 0
