#!/usr/bin/env bash
# dispatch-agent.sh — v2.0
#
# Helpers for /dispatch skill:
#   --worktree <repo> <unit-id>   Create an agent worktree
#   --supervised <worktree-path>  Open a Terminal window with Claude cd'd in
#   --cleanup <repo> <unit-id>    Remove worktree + branch (after merge or discard)
#
# Called by the /dispatch skill. Not intended for direct user invocation.

set -u

usage() {
  cat <<'EOF'
Usage:
  dispatch-agent.sh --worktree <repo-path> <unit-id>
  dispatch-agent.sh --supervised <worktree-path>
  dispatch-agent.sh --cleanup <repo-path> <unit-id>
EOF
  exit 1
}

[ $# -lt 2 ] && usage

CMD="$1"; shift

case "$CMD" in
  --worktree)
    REPO="$1"
    UNIT_ID="$2"
    if [ ! -d "$REPO/.git" ] && [ ! -f "$REPO/.git" ]; then
      echo "ERROR: $REPO is not a git repo" >&2
      exit 2
    fi
    STAGING="$REPO/.claude/staging/$UNIT_ID"
    BRANCH="agent/$UNIT_ID"
    mkdir -p "$REPO/.claude/staging"
    # Ignore staging dir in the project repo's .gitignore (add if missing)
    if [ -f "$REPO/.gitignore" ] && ! grep -q '.claude/staging' "$REPO/.gitignore"; then
      echo '.claude/staging/' >> "$REPO/.gitignore"
    fi
    git -C "$REPO" worktree add "$STAGING" -b "$BRANCH" 2>/dev/null || {
      echo "WARNING: worktree or branch already exists for $UNIT_ID" >&2
      exit 3
    }
    echo "$STAGING"
    exit 0
    ;;

  --supervised)
    WORKTREE="$1"
    if [ ! -d "$WORKTREE" ]; then
      echo "ERROR: $WORKTREE does not exist" >&2
      exit 2
    fi
    PROMPT_FILE="$WORKTREE/PROMPT.md"
    if [ ! -f "$PROMPT_FILE" ]; then
      echo "WARNING: PROMPT.md not found in $WORKTREE. Opening Terminal anyway." >&2
    fi
    # Open a new Terminal window and cd into the worktree, then run claude.
    osascript <<OSAEOF
tell application "Terminal"
  activate
  do script "cd '$WORKTREE' && echo 'Dispatch agent session. Read PROMPT.md for task context.' && ls PROMPT.md 2>/dev/null && claude"
end tell
OSAEOF
    exit 0
    ;;

  --cleanup)
    REPO="$1"
    UNIT_ID="$2"
    STAGING="$REPO/.claude/staging/$UNIT_ID"
    BRANCH="agent/$UNIT_ID"
    if [ -d "$STAGING" ]; then
      git -C "$REPO" worktree remove "$STAGING" --force 2>/dev/null || rm -rf "$STAGING"
    fi
    git -C "$REPO" branch -D "$BRANCH" 2>/dev/null || true
    echo "✓ Cleaned up $UNIT_ID (worktree + branch)"
    exit 0
    ;;

  *)
    usage
    ;;
esac
