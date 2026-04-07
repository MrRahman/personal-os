#!/bin/bash
set -euo pipefail

# Personal OS — Setup Script
# Run this after cloning to configure your instance.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

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
# Step 3: Otter.ai (optional)
# ─────────────────────────────────────────────

echo -e "${BOLD}Step 3: Otter.ai (optional — press Enter to skip)${NC}"
echo -e "${DIM}  If you use Otter.ai for meeting transcripts, provide the session cookie.${NC}"
echo -e "${DIM}  Run: python3 mcp-servers/refresh-otter-cookie.py to extract it from Chrome.${NC}"
echo ""

read -p "  Otter session cookie [skip]: " OTTER_COOKIE
echo ""

# ─────────────────────────────────────────────
# Step 4: Obsidian vault path
# ─────────────────────────────────────────────

echo -e "${BOLD}Step 4: Obsidian vault${NC}"
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
      "$REPO_DIR/.mcp.json.example" > "$REPO_DIR/.mcp.json"
  echo -e "  ${GREEN}Created${NC}"
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
echo -e "${BOLD}Step 5: iMessage MCP (optional — macOS only)${NC}"
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
# Summary
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}${GREEN}Setup complete!${NC}"
echo ""
echo "  Files generated:"
echo "    CLAUDE.md        — your personal configuration"
echo "    .mcp.json        — MCP server connections"
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
echo "  5. Set up iOS Shortcuts (see docs/ios-shortcuts-setup.md)"
echo ""
echo -e "  Run ${BOLD}/morning-plan${NC} tomorrow morning to start."
echo ""
