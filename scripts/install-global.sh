#!/bin/bash
set -euo pipefail

# Install global Claude config from the repo's global/ directory.
# Run this after cloning on a new machine to sync global skills, commands, and settings.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
GLOBAL_SRC="$REPO_DIR/global"
CLAUDE_DIR="$HOME/.claude"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [ ! -d "$GLOBAL_SRC" ]; then
  echo -e "${YELLOW}No global/ directory found in repo. Nothing to install.${NC}"
  exit 1
fi

echo ""
echo -e "${BOLD}Installing global Claude config...${NC}"
echo ""

# Ensure target directories exist
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/commands"

# Copy claude.md (global workflow rules)
if [ -f "$GLOBAL_SRC/claude.md" ]; then
  if [ -f "$CLAUDE_DIR/claude.md" ]; then
    if ! diff -q "$GLOBAL_SRC/claude.md" "$CLAUDE_DIR/claude.md" > /dev/null 2>&1; then
      cp "$CLAUDE_DIR/claude.md" "$CLAUDE_DIR/claude.md.bak"
      echo -e "  ${DIM}Backed up existing claude.md → claude.md.bak${NC}"
    fi
  fi
  cp "$GLOBAL_SRC/claude.md" "$CLAUDE_DIR/claude.md"
  echo -e "  ${GREEN}✓${NC} claude.md"
fi

# Copy settings.json (plugin enablement, model preferences)
if [ -f "$GLOBAL_SRC/settings.json" ]; then
  if [ -f "$CLAUDE_DIR/settings.json" ]; then
    if ! diff -q "$GLOBAL_SRC/settings.json" "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
      cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
      echo -e "  ${DIM}Backed up existing settings.json → settings.json.bak${NC}"
    fi
  fi
  cp "$GLOBAL_SRC/settings.json" "$CLAUDE_DIR/settings.json"
  echo -e "  ${GREEN}✓${NC} settings.json"
fi

# Copy project-registry.md
if [ -f "$GLOBAL_SRC/project-registry.md" ]; then
  cp "$GLOBAL_SRC/project-registry.md" "$CLAUDE_DIR/project-registry.md"
  echo -e "  ${GREEN}✓${NC} project-registry.md"
fi

# Copy global skills
SKILL_COUNT=0
for skill in "$GLOBAL_SRC/skills/"*.md; do
  [ -f "$skill" ] || continue
  cp "$skill" "$CLAUDE_DIR/skills/$(basename "$skill")"
  ((SKILL_COUNT++))
done
echo -e "  ${GREEN}✓${NC} ${SKILL_COUNT} global skills"

# Copy global commands
CMD_COUNT=0
for cmd in "$GLOBAL_SRC/commands/"*.md; do
  [ -f "$cmd" ] || continue
  cp "$cmd" "$CLAUDE_DIR/commands/$(basename "$cmd")"
  ((CMD_COUNT++))
done
echo -e "  ${GREEN}✓${NC} ${CMD_COUNT} global commands"

echo ""
echo -e "${GREEN}Global config installed.${NC}"
echo ""
