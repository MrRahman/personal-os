#!/usr/bin/env bash
# project-buildout.sh — v2.0+
#
# Manages Obsidian Project notes for the v2.0 agent-dispatch system:
#   --audit        List every Projects/*.md and v2.0 frontmatter status
#   --init         Scaffold v2.0 frontmatter for a project (one-time)
#   --refresh      (v2.1+) Pull live repo state into managed sections of the note
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
#
#   ./mcp-servers/project-buildout.sh --refresh <slug | --all>
#       Pull live repo state into the project note. Replaces a managed block
#       between <!-- BEGIN/END:project-buildout-refresh --> markers with:
#         - Recent Activity (last 10 commits)
#         - Open PRs (if git_url set)
#         - Repo README mirror (first 30 lines)
#       Idempotent. Only acts on projects with non-empty `repo:` frontmatter.

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

  --refresh)
    [ $# -lt 1 ] && { echo "ERROR: --refresh requires <slug> or --all"; exit 2; }
    TARGET="$1"

    refresh_project() {
      local slug="$1"
      local file="$PROJECTS_DIR/${slug}.md"

      if [ ! -f "$file" ]; then
        echo "  ✗ $slug: file not found"
        return 1
      fi

      # Extract repo from frontmatter (between --- delimiters)
      local repo
      repo=$(awk '/^---$/{f++; next} f==1 && /^repo:[ \t]/{sub(/^repo:[ \t]*/,""); gsub(/["'"'"']/,""); print; exit}' "$file")

      if [ -z "$repo" ]; then
        echo "  ⊘ $slug: no repo (Tier 1) — skipping"
        return 0
      fi

      if [ ! -d "$repo" ]; then
        echo "  ✗ $slug: repo path does not exist ($repo)"
        return 1
      fi

      # Build Recent Activity section
      local activity=""
      if [ -d "$repo/.git" ]; then
        activity=$(git -C "$repo" log --pretty=format:'- `%h` %ad — %s' --date=short -10 2>/dev/null || echo "")
      fi
      [ -z "$activity" ] && activity="(no commits)"

      # Build Open PRs section (only if git_url present)
      local git_url
      git_url=$(awk '/^---$/{f++; next} f==1 && /^git_url:[ \t]/{sub(/^git_url:[ \t]*/,""); gsub(/["'"'"']/,""); print; exit}' "$file")
      local pr_section=""
      if [ -n "$git_url" ]; then
        local owner_repo
        owner_repo=$(echo "$git_url" | sed -E 's|.*[:/]([^/]+/[^/.]+)(\.git)?$|\1|')
        local pr_list
        pr_list=$(gh pr list --repo "$owner_repo" --state open --json number,title,url --jq '.[] | "- [#\(.number)](\(.url)) — \(.title)"' 2>/dev/null || echo "")
        if [ -n "$pr_list" ]; then
          pr_section=$'\n\n## Open PRs\n\n'"$pr_list"
        else
          pr_section=$'\n\n## Open PRs\n\n(none)'
        fi
      fi

      # Build README mirror (first 30 lines)
      local readme_section=""
      if [ -f "$repo/README.md" ]; then
        local readme_content
        readme_content=$(head -30 "$repo/README.md")
        readme_section=$'\n\n## Repo README (mirrored)\n\n```markdown\n'"$readme_content"$'\n```'
      fi

      # Build full managed block
      local block_start='<!-- BEGIN:project-buildout-refresh -->'
      local block_end='<!-- END:project-buildout-refresh -->'
      local now
      now=$(date +"%Y-%m-%d %H:%M %Z")

      local managed_content
      managed_content="${block_start}
<!-- Last refreshed: ${now}. Auto-managed by project-buildout.sh --refresh — DO NOT edit by hand. -->

## Recent Activity

${activity}${pr_section}${readme_section}

${block_end}"

      # Replace block (if markers present) or append at end of file
      local start_line end_line
      start_line=$(grep -n "^${block_start}\$" "$file" | head -1 | cut -d: -f1)
      end_line=$(grep -n "^${block_end}\$" "$file" | head -1 | cut -d: -f1)

      local tmp
      tmp=$(mktemp)
      if [ -n "$start_line" ] && [ -n "$end_line" ]; then
        head -n $((start_line - 1)) "$file" > "$tmp"
        printf '%s\n' "$managed_content" >> "$tmp"
        tail -n +$((end_line + 1)) "$file" >> "$tmp"
      else
        cat "$file" > "$tmp"
        echo "" >> "$tmp"
        printf '%s\n' "$managed_content" >> "$tmp"
      fi
      mv "$tmp" "$file"

      echo "  ✓ $slug refreshed"
      return 0
    }

    if [ "$TARGET" = "--all" ]; then
      echo "Refreshing all projects with repo: set..."
      echo ""
      for f in "$PROJECTS_DIR"/*.md; do
        [ -f "$f" ] || continue
        slug=$(basename "$f" .md)
        refresh_project "$slug"
      done
      echo ""
      echo "Done."
    else
      refresh_project "$TARGET"
    fi
    exit 0
    ;;

  *)
    usage
    ;;
esac
