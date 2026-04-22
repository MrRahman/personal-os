#!/usr/bin/env bash
# project-buildout.sh — v2.0
#
# Scaffolds v2.0 agent-dispatch frontmatter into existing Obsidian Project notes.
# Run once per project after user confirms repo paths + context files.
#
# Usage:
#   ./mcp-servers/project-buildout.sh --audit
#       List every Projects/*.md and show which are missing v2.0 frontmatter.
#
#   ./mcp-servers/project-buildout.sh --init <project-slug> [options]
#       Add v2.0 frontmatter to a specific project note.
#       Options:
#         --repo <path>              Absolute path to code repo (or "" for Obsidian-only)
#         --git-url <url>            git@github.com:user/repo.git
#         --dispatch <enabled|disabled>   Default: enabled
#         --max-parallel <N>         Default: 2
#         --max-minutes <N>          Default: 15
#         --context-files <comma-list>    Paths agents should read
#         --goals <comma-list>       [[Goals/YYYY-QX#Name]] wikilinks

set -u

VAULT="${PERSONALOS_VAULT:-$HOME/Documents/PersonalOS}"
PROJECTS_DIR="$VAULT/Projects"

usage() {
  sed -n '3,20p' "$0"
  exit 1
}

[ $# -lt 1 ] && usage

CMD="$1"; shift

case "$CMD" in
  --audit)
    echo "Projects directory: $PROJECTS_DIR"
    echo ""
    FOUND=0
    MISSING=0
    for f in "$PROJECTS_DIR"/*.md; do
      [ -f "$f" ] || continue
      name=$(basename "$f" .md)
      if grep -q '^agent_dispatch:' "$f"; then
        echo "  ✓ $name  (v2.0 frontmatter present)"
        FOUND=$((FOUND + 1))
      else
        echo "  ⚠ $name  (needs v2.0 init)"
        MISSING=$((MISSING + 1))
      fi
    done
    echo ""
    echo "Summary: $FOUND initialized, $MISSING pending."
    if [ $MISSING -gt 0 ]; then
      echo ""
      echo "Next: run --init <project-slug> with repo/git-url/context details for each pending project."
    fi
    exit 0
    ;;

  --init)
    [ $# -lt 1 ] && { echo "ERROR: --init requires <project-slug>"; exit 2; }
    SLUG="$1"; shift
    PROJECT_FILE="$PROJECTS_DIR/${SLUG}.md"
    if [ ! -f "$PROJECT_FILE" ]; then
      echo "ERROR: $PROJECT_FILE does not exist"
      exit 2
    fi

    # Parse options
    REPO=""
    GIT_URL=""
    DISPATCH="enabled"
    MAX_PARALLEL="2"
    MAX_MINUTES="15"
    CONTEXT_FILES=""
    GOALS=""

    while [ $# -gt 0 ]; do
      case "$1" in
        --repo) REPO="$2"; shift 2 ;;
        --git-url) GIT_URL="$2"; shift 2 ;;
        --dispatch) DISPATCH="$2"; shift 2 ;;
        --max-parallel) MAX_PARALLEL="$2"; shift 2 ;;
        --max-minutes) MAX_MINUTES="$2"; shift 2 ;;
        --context-files) CONTEXT_FILES="$2"; shift 2 ;;
        --goals) GOALS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 2 ;;
      esac
    done

    # Build context_files YAML block
    CONTEXT_YAML=""
    if [ -n "$CONTEXT_FILES" ]; then
      IFS=',' read -ra CF_ARRAY <<< "$CONTEXT_FILES"
      for cf in "${CF_ARRAY[@]}"; do
        CONTEXT_YAML+="  - ${cf}"$'\n'
      done
    fi

    # Build goals YAML block
    GOALS_YAML=""
    if [ -n "$GOALS" ]; then
      IFS=',' read -ra G_ARRAY <<< "$GOALS"
      for g in "${G_ARRAY[@]}"; do
        GOALS_YAML+="  - \"${g}\""$'\n'
      done
    fi

    # Check if agent_dispatch field already exists
    if grep -q '^agent_dispatch:' "$PROJECT_FILE"; then
      echo "WARNING: $SLUG already has v2.0 frontmatter. Skipping (use manual edit to update)."
      exit 0
    fi

    # Find the closing --- of frontmatter (line 2+ looking for first `---`)
    CLOSE_LINE=$(awk '/^---$/{count++; if (count==2) {print NR; exit}}' "$PROJECT_FILE")
    if [ -z "$CLOSE_LINE" ]; then
      echo "ERROR: $PROJECT_FILE does not have a valid YAML frontmatter block"
      exit 2
    fi

    # Insert v2.0 fields BEFORE the closing ---
    INSERT_LINE=$((CLOSE_LINE - 1))
    TMP=$(mktemp)
    {
      head -n "$INSERT_LINE" "$PROJECT_FILE"
      echo ""
      echo "# v2.0 project-orchestration fields"
      echo "repo: ${REPO}"
      if [ -n "$GIT_URL" ]; then
        echo "git_url: ${GIT_URL}"
      fi
      echo "agent_dispatch: ${DISPATCH}"
      echo "agent_budget:"
      echo "  max_parallel: ${MAX_PARALLEL}"
      echo "  max_minutes: ${MAX_MINUTES}"
      if [ -n "$CONTEXT_YAML" ]; then
        echo "context_files:"
        printf '%s' "$CONTEXT_YAML"
      else
        echo "context_files: []"
      fi
      if [ -n "$GOALS_YAML" ]; then
        echo "goals:"
        printf '%s' "$GOALS_YAML"
      else
        echo "goals: []"
      fi
      tail -n +"$CLOSE_LINE" "$PROJECT_FILE"
    } > "$TMP"
    mv "$TMP" "$PROJECT_FILE"

    echo "✓ Added v2.0 frontmatter to $SLUG"
    exit 0
    ;;

  *)
    usage
    ;;
esac
