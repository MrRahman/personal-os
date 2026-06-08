#!/bin/bash
set -euo pipefail

# Personal OS — Setup Script
# Run this after cloning to configure your instance.
#
# Subcommands:
#   ./setup.sh             Full interactive setup (first-time)
#   ./setup.sh --verify    Non-interactive verification of hooks + launchd + state dirs

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# ─────────────────────────────────────────────
# --verify subcommand (v1.8+)
# ─────────────────────────────────────────────

if [ "${1:-}" = "--verify" ]; then
  echo ""
  echo -e "${BOLD}Personal OS — Setup Verify${NC}"
  echo ""

  FAIL_COUNT=0
  HOSTNAME=$(uname -n)

  # 1. Check .mcp.json exists
  if [ -f "$REPO_DIR/.mcp.json" ]; then
    echo -e "  ${GREEN}✓${NC} .mcp.json present"
    # Credentials file must be owner-only (v3.0 Phase 1c).
    MCP_PERM="$(stat -f '%Lp' "$REPO_DIR/.mcp.json" 2>/dev/null || stat -c '%a' "$REPO_DIR/.mcp.json" 2>/dev/null)"
    if [ "$MCP_PERM" != "600" ]; then
      chmod 600 "$REPO_DIR/.mcp.json" && echo -e "  ${YELLOW}↺${NC} .mcp.json was $MCP_PERM — chmod'd to 600"
    fi
  else
    echo -e "  ${RED}✗${NC} .mcp.json missing — run ./setup.sh (without --verify) to configure"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  # 2. Check state + hooks + logs dirs
  for dir in ".claude/state" ".claude/hooks" ".claude/logs"; do
    if [ -d "$REPO_DIR/$dir" ]; then
      echo -e "  ${GREEN}✓${NC} $dir present"
    else
      echo -e "  ${YELLOW}⚠${NC} $dir missing — creating..."
      mkdir -p "$REPO_DIR/$dir"
      echo -e "  ${GREEN}✓${NC} $dir created"
    fi
  done

  # 3. Check hook scripts are executable
  for hook in "sessionstart-health.sh" "sessionstart-drift.sh"; do
    if [ -x "$REPO_DIR/.claude/hooks/$hook" ]; then
      echo -e "  ${GREEN}✓${NC} hook $hook executable"
    elif [ -f "$REPO_DIR/.claude/hooks/$hook" ]; then
      echo -e "  ${YELLOW}⚠${NC} hook $hook not executable — fixing..."
      chmod +x "$REPO_DIR/.claude/hooks/$hook"
      echo -e "  ${GREEN}✓${NC} fixed"
    else
      echo -e "  ${RED}✗${NC} hook $hook missing — check repo state"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done

  # 4. Check settings.json has hooks wired
  if jq -e '.hooks.SessionStart' "$REPO_DIR/.claude/settings.json" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} settings.json wires SessionStart hooks"
  else
    echo -e "  ${RED}✗${NC} settings.json missing hook configuration — pull latest from origin/main"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  # 5. Check launchd plist loaded
  if launchctl list 2>/dev/null | grep -q "com.personalos.otter-cookie-refresh"; then
    echo -e "  ${GREEN}✓${NC} launchd: otter-cookie-refresh loaded"
  else
    PLIST="$HOME/Library/LaunchAgents/com.personalos.otter-cookie-refresh.plist"
    if [ -f "$PLIST" ]; then
      echo -e "  ${YELLOW}⚠${NC} launchd plist present but not loaded — loading..."
      launchctl load "$PLIST"
      echo -e "  ${GREEN}✓${NC} loaded"
    else
      echo -e "  ${YELLOW}⚠${NC} launchd plist not installed. Otter cookie won't auto-refresh."
      echo -e "       To install: cp $REPO_DIR/launchd/com.personalos.otter-cookie-refresh.plist $PLIST && launchctl load $PLIST"
    fi
  fi

  # 5b. Slack token refresh: launchd + venv + global hook
  if launchctl list 2>/dev/null | grep -q "com.personalos.slack-token-refresh"; then
    echo -e "  ${GREEN}✓${NC} launchd: slack-token-refresh loaded"
  else
    SLACK_PLIST="$HOME/Library/LaunchAgents/com.personalos.slack-token-refresh.plist"
    if [ -f "$SLACK_PLIST" ]; then
      echo -e "  ${YELLOW}⚠${NC} slack-token-refresh plist present but not loaded — loading..."
      launchctl load "$SLACK_PLIST"
      echo -e "  ${GREEN}✓${NC} loaded"
    else
      echo -e "  ${YELLOW}⚠${NC} slack-token-refresh plist not installed. Slack tokens won't auto-refresh."
    fi
  fi

  SLACK_VENV="$HOME/.local/venvs/slack-refresh/bin/python"
  if [ -x "$SLACK_VENV" ]; then
    if "$SLACK_VENV" -c "import playwright" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} Slack refresh venv present with Playwright"
    else
      echo -e "  ${YELLOW}⚠${NC} Slack refresh venv exists but Playwright missing"
      echo -e "       Run: $HOME/.local/venvs/slack-refresh/bin/pip install playwright && $HOME/.local/venvs/slack-refresh/bin/playwright install chromium"
    fi
  else
    echo -e "  ${YELLOW}⚠${NC} Slack refresh venv missing. Slack tokens can't auto-refresh."
    echo -e "       One-time setup:"
    echo -e "         python3 -m venv ~/.local/venvs/slack-refresh"
    echo -e "         ~/.local/venvs/slack-refresh/bin/pip install playwright"
    echo -e "         ~/.local/venvs/slack-refresh/bin/playwright install chromium"
    echo -e "         ~/.local/venvs/slack-refresh/bin/python $REPO_DIR/mcp-servers/refresh-slack-tokens.py --login"
  fi

  if [ -x "$HOME/.claude/hooks/slack-token-preflight.sh" ]; then
    echo -e "  ${GREEN}✓${NC} global hook slack-token-preflight.sh installed"
  else
    echo -e "  ${YELLOW}⚠${NC} global hook slack-token-preflight.sh missing at ~/.claude/hooks/"
  fi

  # 5c. Project refresh launchd (v2.1+) — pulls live repo state into Obsidian Project notes daily
  if launchctl list 2>/dev/null | grep -q "com.personalos.project-refresh"; then
    echo -e "  ${GREEN}✓${NC} launchd: project-refresh loaded (daily 7:55am)"
  else
    PROJECT_REFRESH_PLIST="$HOME/Library/LaunchAgents/com.personalos.project-refresh.plist"
    if [ -f "$PROJECT_REFRESH_PLIST" ]; then
      echo -e "  ${YELLOW}⚠${NC} project-refresh plist present but not loaded — loading..."
      launchctl load "$PROJECT_REFRESH_PLIST"
      echo -e "  ${GREEN}✓${NC} loaded"
    else
      echo -e "  ${YELLOW}⚠${NC} project-refresh plist not installed. Obsidian project notes won't auto-sync recent commits/PRs."
      echo -e "       To install: cp $REPO_DIR/launchd/com.personalos.project-refresh.plist $PROJECT_REFRESH_PLIST && launchctl load $PROJECT_REFRESH_PLIST"
    fi
  fi

  # 5d. Daily-brief launchd (v3.0) — OPT-IN eager morning pre-build of the daily note.
  # The SessionStart-ensures hook (.claude/hooks/sessionstart-ensure-brief.sh) is always on
  # and builds the brief lazily on first open. This plist just makes the draft ready BEFORE
  # you wake. It runs a real LLM brief (~$0.84/run, sonnet) every weekday 6am, so unlike the
  # cheap token refreshers it is NOT auto-loaded — enable it deliberately.
  if launchctl list 2>/dev/null | grep -q "com.personalos.daily-brief"; then
    echo -e "  ${GREEN}✓${NC} launchd: daily-brief loaded (weekday 6:00am eager pre-build)"
  else
    DAILY_BRIEF_PLIST="$HOME/Library/LaunchAgents/com.personalos.daily-brief.plist"
    echo -e "  ${DIM}○${NC} daily-brief eager pre-build not enabled (optional — the SessionStart hook builds it lazily)."
    echo -e "       To enable an instant morning (≈\$0.84/weekday): cp $REPO_DIR/launchd/com.personalos.daily-brief.plist $DAILY_BRIEF_PLIST && launchctl load $DAILY_BRIEF_PLIST"
  fi

  # 5e. otter-sync launchd (v3.0 Phase 1b) — OPT-IN continuous intraday meeting capture.
  # Hourly 8am–8pm; a cheap non-LLM poll (otter-poll.py) gates a Haiku actor, so idle
  # hours cost ~nothing. NOT auto-loaded. IMPORTANT: enable on EXACTLY ONE machine —
  # the Obsidian vault is cloud-synced (iCloud/Google Drive), so two hosts running this
  # (or one host + /sync-meetings on another) will double-create notes. See tasks/lessons.md.
  if launchctl list 2>/dev/null | grep -q "com.personalos.otter-sync"; then
    echo -e "  ${GREEN}✓${NC} launchd: otter-sync loaded (hourly 8am–8pm meeting capture)"
  else
    OTTER_SYNC_PLIST="$HOME/Library/LaunchAgents/com.personalos.otter-sync.plist"
    echo -e "  ${DIM}○${NC} otter-sync continuous capture not enabled (optional; manual: bash mcp-servers/otter-sync.sh)."
    echo -e "       Enable on ONE machine only (vault is cloud-synced): cp $REPO_DIR/launchd/com.personalos.otter-sync.plist $OTTER_SYNC_PLIST && launchctl load $OTTER_SYNC_PLIST"
  fi

  # 5f. cadence-draft launchd (v3.0 Phase 3) — OPT-IN weekly/monthly/quarterly review pre-drafts.
  # One parameterized wrapper (cadence-draft.sh), three schedules. Read-only gather → a DRAFT
  # review note; /week, /month, /quarter then adjust+confirm. Single-host (vault is cloud-synced).
  for CAD in weekly monthly quarterly; do
    if launchctl list 2>/dev/null | grep -q "com.personalos.cadence-$CAD"; then
      echo -e "  ${GREEN}✓${NC} launchd: cadence-$CAD loaded (review pre-draft)"
    else
      echo -e "  ${DIM}○${NC} cadence-$CAD pre-draft not enabled (optional; manual: bash mcp-servers/cadence-draft.sh $CAD)."
      echo -e "       Enable on ONE machine: cp $REPO_DIR/launchd/com.personalos.cadence-$CAD.plist \$HOME/Library/LaunchAgents/ && launchctl bootstrap gui/\$(id -u) \$HOME/Library/LaunchAgents/com.personalos.cadence-$CAD.plist"
    fi
  done

  # 6. Check git pre-push hook
  if [ -x "$REPO_DIR/.git/hooks/pre-push" ]; then
    echo -e "  ${GREEN}✓${NC} git pre-push secret scanner installed"
  else
    echo -e "  ${YELLOW}⚠${NC} git pre-push hook missing. Secrets won't be scanned on push."
  fi

  # 7. Machine identity tracking
  KNOWN_MACHINES="$REPO_DIR/memory/known_machines.json"
  if [ -f "$KNOWN_MACHINES" ]; then
    if jq -e --arg h "$HOSTNAME" '.machines | index($h)' "$KNOWN_MACHINES" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} machine '$HOSTNAME' already registered"
    else
      echo -e "  ${YELLOW}⚠${NC} new machine detected: '$HOSTNAME'"
      echo -e "       Adding to known_machines.json..."
      TMP=$(mktemp)
      jq --arg h "$HOSTNAME" '.machines += [$h] | .machines |= unique' "$KNOWN_MACHINES" > "$TMP"
      mv "$TMP" "$KNOWN_MACHINES"
      echo -e "  ${GREEN}✓${NC} registered"
    fi
  fi

  # 8. Run healthcheck
  echo ""
  echo -e "${BOLD}Running healthcheck...${NC}"
  "$REPO_DIR/mcp-servers/healthcheck.sh" || true

  echo ""
  if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}${BOLD}Setup verified — all hooks + state dirs + plists in place.${NC}"
  else
    echo -e "${RED}${BOLD}$FAIL_COUNT issue(s) found. Fix and re-run ./setup.sh --verify${NC}"
    exit 1
  fi
  echo ""
  exit 0
fi

echo ""
echo -e "${BOLD}Personal OS — Setup${NC}"
echo -e "${DIM}Two commands run the day. Let's get you configured.${NC}"
echo ""

# ─────────────────────────────────────────────
# Step 1: Collect user info
# ─────────────────────────────────────────────

echo -e "${BOLD}Step 1: Your identity${NC}"
echo ""

read -p "  Full name: " USER_NAME
read -p "  Short name (for action item detection, e.g. 'Sul'): " SHORT_NAME
read -p "  Work email: " WORK_EMAIL
read -p "  Personal email: " PERSONAL_EMAIL
read -p "  Timezone [America/Los_Angeles]: " TIMEZONE
TIMEZONE="${TIMEZONE:-America/Los_Angeles}"

# Derive People wikilink from name
PEOPLE_SLUG=$(echo "$USER_NAME" | sed 's/ /-/g')
echo -e "  ${DIM}People wikilink: [[People/${PEOPLE_SLUG}]]${NC}"
echo ""

# ─────────────────────────────────────────────
# Step 2: Notion setup
# ─────────────────────────────────────────────

echo -e "${BOLD}Step 2: Notion Knowledge Base${NC}"
echo -e "${DIM}  Create a Notion integration at https://www.notion.so/my-integrations${NC}"
echo -e "${DIM}  Then create an 'AI Knowledge Base' database and connect the integration to it.${NC}"
echo -e "${DIM}  Find the Database ID in the database URL: notion.so/<DATABASE_ID>?v=...${NC}"
echo ""

read -p "  Notion API token (ntn_...): " NOTION_TOKEN
read -p "  Notion Database ID: " NOTION_DB_ID
read -p "  Notion Data Source ID (for API-query-data-source): " NOTION_DS_ID
echo ""

# ─────────────────────────────────────────────
# Step 3: Google Personal Account (optional)
# ─────────────────────────────────────────────

echo -e "${BOLD}Step 3: Google Personal Account (optional — press Enter to skip)${NC}"
echo -e "${DIM}  For personal Gmail + Calendar via @aaronsb/google-workspace-mcp.${NC}"
echo -e "${DIM}  Create OAuth credentials at https://console.cloud.google.com/apis/credentials${NC}"
echo ""

read -p "  Google Client ID [skip]: " GOOGLE_CLIENT_ID
read -p "  Google Client Secret [skip]: " GOOGLE_CLIENT_SECRET
echo ""

# ─────────────────────────────────────────────
# Step 4: Otter.ai (optional)
# ─────────────────────────────────────────────

echo -e "${BOLD}Step 4: Otter.ai (optional — press Enter to skip)${NC}"
echo -e "${DIM}  If you use Otter.ai for meeting transcripts, provide the session cookie.${NC}"
echo -e "${DIM}  Run: python3 mcp-servers/refresh-otter-cookie.py to extract it from Chrome.${NC}"
echo ""

read -p "  Otter session cookie [skip]: " OTTER_COOKIE
echo ""

# ─────────────────────────────────────────────
# Step 5: Obsidian vault path
# ─────────────────────────────────────────────

echo -e "${BOLD}Step 5: Obsidian vault${NC}"
echo ""

read -p "  Vault path [~/Documents/PersonalOS]: " VAULT_PATH
VAULT_PATH="${VAULT_PATH:-$HOME/Documents/PersonalOS}"
# Expand ~ if present
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"
echo ""

# ─────────────────────────────────────────────
# Generate CLAUDE.md
# ─────────────────────────────────────────────

echo -e "${BOLD}Generating CLAUDE.md...${NC}"

if [ -f "$REPO_DIR/CLAUDE.md" ]; then
  read -p "  CLAUDE.md already exists. Overwrite? [y/N]: " OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo -e "  ${YELLOW}Skipped${NC}"
  else
    GENERATE_CLAUDE=true
  fi
else
  GENERATE_CLAUDE=true
fi

if [ "${GENERATE_CLAUDE:-false}" = true ]; then
  sed -e "s|YOUR_FULL_NAME|${USER_NAME}|g" \
      -e "s|YOUR_SHORT_NAME|${SHORT_NAME}|g" \
      -e "s|YOUR_WORK_EMAIL|${WORK_EMAIL}|g" \
      -e "s|YOUR_PERSONAL_EMAIL|${PERSONAL_EMAIL}|g" \
      -e "s|America/Los_Angeles|${TIMEZONE}|g" \
      -e "s|YOUR_NOTION_DATABASE_ID|${NOTION_DB_ID}|g" \
      -e "s|YOUR_NOTION_DATA_SOURCE_ID|${NOTION_DS_ID}|g" \
      -e "s|\[\[People/Your-Name\]\]|[[People/${PEOPLE_SLUG}]]|g" \
      "$REPO_DIR/CLAUDE.md.example" > "$REPO_DIR/CLAUDE.md"
  echo -e "  ${GREEN}Created${NC}"
fi

# ─────────────────────────────────────────────
# Generate .mcp.json
# ─────────────────────────────────────────────

echo -e "${BOLD}Generating .mcp.json...${NC}"

if [ -f "$REPO_DIR/.mcp.json" ]; then
  read -p "  .mcp.json already exists. Overwrite? [y/N]: " OVERWRITE_MCP
  if [[ ! "$OVERWRITE_MCP" =~ ^[Yy]$ ]]; then
    echo -e "  ${YELLOW}Skipped${NC}"
  else
    GENERATE_MCP=true
  fi
else
  GENERATE_MCP=true
fi

if [ "${GENERATE_MCP:-false}" = true ]; then
  sed -e "s|YOUR_NOTION_TOKEN|${NOTION_TOKEN}|g" \
      -e "s|YOUR_OTTER_SESSION_COOKIE|${OTTER_COOKIE:-SKIP}|g" \
      -e "s|YOUR_GOOGLE_CLIENT_ID|${GOOGLE_CLIENT_ID:-YOUR_GOOGLE_CLIENT_ID}|g" \
      -e "s|YOUR_GOOGLE_CLIENT_SECRET|${GOOGLE_CLIENT_SECRET:-YOUR_GOOGLE_CLIENT_SECRET}|g" \
      "$REPO_DIR/.mcp.json.example" > "$REPO_DIR/.mcp.json"
  chmod 600 "$REPO_DIR/.mcp.json"   # credentials file — owner-only (v3.0 Phase 1c)
  echo -e "  ${GREEN}Created${NC} (chmod 600)"
fi

# ─────────────────────────────────────────────
# Create Obsidian vault structure
# ─────────────────────────────────────────────

echo -e "${BOLD}Creating Obsidian vault at ${VAULT_PATH}...${NC}"

FOLDERS=(
  "Daily"
  "Meetings"
  "Meetings/Transcripts"
  "People"
  "Resources"
  "Topics"
  "Projects"
  "Goals"
  "Ideas"
  "Weekly Reviews"
  "Templates"
)

for folder in "${FOLDERS[@]}"; do
  mkdir -p "$VAULT_PATH/$folder"
done
echo -e "  ${GREEN}Created ${#FOLDERS[@]} directories${NC}"

# Copy templates
TEMPLATE_SRC="$REPO_DIR/templates/obsidian"
if [ -d "$TEMPLATE_SRC" ]; then
  COPIED=0
  for template in "$TEMPLATE_SRC"/*.md; do
    [ -f "$template" ] || continue
    BASENAME=$(basename "$template")
    if [ ! -f "$VAULT_PATH/Templates/$BASENAME" ]; then
      cp "$template" "$VAULT_PATH/Templates/$BASENAME"
      ((COPIED++))
    fi
  done
  echo -e "  ${GREEN}Copied ${COPIED} new templates${NC} (existing templates preserved)"
else
  echo -e "  ${YELLOW}No template source found at ${TEMPLATE_SRC}${NC}"
fi

# ─────────────────────────────────────────────
# Build iMessage MCP (optional)
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}Step 6: iMessage MCP (optional — macOS only)${NC}"
echo -e "${DIM}  Requires Full Disk Access for your terminal app.${NC}"
echo ""

read -p "  Build iMessage MCP server? [y/N]: " BUILD_IMESSAGE

if [[ "$BUILD_IMESSAGE" =~ ^[Yy]$ ]]; then
  echo "  Building..."
  (cd "$REPO_DIR/mcp-servers/imessage" && npm install --silent && npm run build --silent 2>/dev/null)
  echo -e "  ${GREEN}Built successfully${NC}"
else
  echo -e "  ${YELLOW}Skipped${NC}"
fi

# ─────────────────────────────────────────────
# Link Claude memory to repo
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}Linking Claude memory...${NC}"

# Claude encodes the project path as the directory name:
# /Users/foo/projects/personal-os → -Users-foo-projects-personal-os
CLAUDE_PROJECT_SLUG="$(echo "$REPO_DIR" | sed 's|^/|-|; s|/|-|g')"
CLAUDE_PROJECT_DIR="$HOME/.claude/projects/$CLAUDE_PROJECT_SLUG"

mkdir -p "$CLAUDE_PROJECT_DIR"

if [ -L "$CLAUDE_PROJECT_DIR/memory" ]; then
  echo -e "  ${DIM}Symlink already exists${NC}"
elif [ -d "$CLAUDE_PROJECT_DIR/memory" ]; then
  # Memory dir exists with files — back it up, then symlink
  mv "$CLAUDE_PROJECT_DIR/memory" "$CLAUDE_PROJECT_DIR/memory.bak"
  echo -e "  ${DIM}Backed up existing memory → memory.bak${NC}"
  ln -sfn "$REPO_DIR/memory" "$CLAUDE_PROJECT_DIR/memory"
  echo -e "  ${GREEN}Linked${NC}"
else
  ln -sfn "$REPO_DIR/memory" "$CLAUDE_PROJECT_DIR/memory"
  echo -e "  ${GREEN}Linked${NC}"
fi

# ─────────────────────────────────────────────
# Install global Claude config
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}Installing global Claude config...${NC}"

if [ -x "$REPO_DIR/scripts/install-global.sh" ]; then
  "$REPO_DIR/scripts/install-global.sh"
else
  echo -e "  ${YELLOW}scripts/install-global.sh not found — skipping${NC}"
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}${GREEN}Setup complete!${NC}"
echo ""
echo "  Files generated:"
echo "    CLAUDE.md        — your personal configuration"
echo "    .mcp.json        — MCP server connections"
echo "    memory/ → ~/.claude symlink"
echo ""
echo "  Obsidian vault created at: $VAULT_PATH"
echo ""
echo -e "${BOLD}Still needed (manual):${NC}"
echo "  1. Connect Google Calendar, Gmail, and Slack in Claude desktop app"
echo "     (Settings > Integrations)"
echo "  2. Todoist and Readwise will prompt for OAuth on first use"
if [ -z "${OTTER_COOKIE:-}" ]; then
  echo "  3. Set up Otter.ai cookie if you want transcript sync"
fi
echo "  4. Grant Full Disk Access to your terminal (for iMessage MCP)"
echo "  5. Enable Obsidian Sync and connect to your remote vault"
echo "     (Settings > Sync in Obsidian)"
echo ""
echo -e "  Run ${BOLD}/morning-plan${NC} tomorrow morning to start."
echo ""
