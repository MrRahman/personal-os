#!/usr/bin/env bash
# Personal OS drift check (v1.8)
#
# Detects four kinds of drift that morning-plan, weekly-review, and reflect
# surface proactively:
#   - release drift: commits ahead of last git tag
#   - memory drift: memory files older than 30 days (one per week budget)
#   - goal drift: quarterly goals with no progress (skeleton — filled in by skills)
#   - waiting_on drift: Todoist tasks with waiting-on label aged 3+ days (skeleton)
#
# Outputs JSON to .claude/state/drift.json. Silent on stdout unless --verbose.
# Cached; skills read this file rather than re-running git/fs operations.

set -u

REPO_ROOT="${PERSONAL_OS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="${REPO_ROOT}/.claude/state"
DRIFT_FILE="${STATE_DIR}/drift.json"
VERBOSE=false

[ "${1:-}" = "--verbose" ] && VERBOSE=true

mkdir -p "$STATE_DIR"

cd "$REPO_ROOT"

# --- Release drift ---
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
  UNRELEASED_COUNT=$(git rev-list "${LAST_TAG}..HEAD" --count 2>/dev/null || echo "0")
  if [ "$UNRELEASED_COUNT" -gt 0 ]; then
    UNRELEASED_LOG=$(git log "${LAST_TAG}..HEAD" --oneline --format='%h %s' 2>/dev/null | jq -R -s -c 'split("\n") | map(select(length > 0))')
  else
    UNRELEASED_LOG='[]'
  fi
else
  UNRELEASED_COUNT=0
  UNRELEASED_LOG='[]'
  LAST_TAG="(none)"
fi

# Categorize commits: feat → minor, fix → patch, BREAKING → major
FEAT_COUNT=0
FIX_COUNT=0
BREAKING_COUNT=0
CHORE_COUNT=0
if [ "$UNRELEASED_COUNT" -gt 0 ]; then
  while IFS= read -r line; do
    subject=$(echo "$line" | cut -d' ' -f2-)
    if echo "$subject" | grep -qiE '^(feat|feature)(\(.*\))?!?:'; then
      FEAT_COUNT=$((FEAT_COUNT + 1))
    elif echo "$subject" | grep -qiE '^fix(\(.*\))?!?:'; then
      FIX_COUNT=$((FIX_COUNT + 1))
    elif echo "$subject" | grep -qiE '^(chore|docs|style|refactor|test|build|ci)(\(.*\))?:'; then
      CHORE_COUNT=$((CHORE_COUNT + 1))
    fi
    if echo "$subject" | grep -qiE '(^[a-z]+!:|BREAKING)'; then
      BREAKING_COUNT=$((BREAKING_COUNT + 1))
    fi
  done < <(git log "${LAST_TAG}..HEAD" --oneline --format='%h %s' 2>/dev/null)
fi

# Suggested bump
NEXT_VERSION=""
if [ -n "$LAST_TAG" ] && [ "$LAST_TAG" != "(none)" ]; then
  CURRENT_VER="${LAST_TAG#v}"  # strip leading 'v'
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VER"
  if [ "$BREAKING_COUNT" -gt 0 ]; then
    NEXT_VERSION="v$((MAJOR + 1)).0.0"
  elif [ "$FEAT_COUNT" -gt 0 ]; then
    NEXT_VERSION="v${MAJOR}.$((MINOR + 1))"
  elif [ "$FIX_COUNT" -gt 0 ] || [ "$CHORE_COUNT" -gt 0 ]; then
    NEXT_VERSION="v${MAJOR}.${MINOR}.$((${PATCH:-0} + 1))"
  fi
fi

RELEASE_SHOULD_SURFACE=false
if [ "$UNRELEASED_COUNT" -ge 3 ]; then
  RELEASE_SHOULD_SURFACE=true
fi

RELEASES_JSON=$(jq -n \
  --arg last_tag "$LAST_TAG" \
  --argjson count "$UNRELEASED_COUNT" \
  --argjson feat "$FEAT_COUNT" \
  --argjson fix "$FIX_COUNT" \
  --argjson breaking "$BREAKING_COUNT" \
  --argjson chore "$CHORE_COUNT" \
  --arg next_version "$NEXT_VERSION" \
  --argjson commits "$UNRELEASED_LOG" \
  --argjson surface "$RELEASE_SHOULD_SURFACE" \
  '{
    last_tag: $last_tag,
    unreleased_count: $count,
    commits_by_type: {feat: $feat, fix: $fix, breaking: $breaking, chore: $chore},
    suggested_next_version: $next_version,
    commits: $commits,
    should_surface: $surface
  }')

# --- Memory drift ---
MEMORY_DIR="${REPO_ROOT}/memory"
STALE_MEMORY=()
if [ -d "$MEMORY_DIR" ]; then
  while IFS= read -r file; do
    # Files older than 30 days
    if [ -f "$file" ] && [ -n "$(find "$file" -mtime +30 2>/dev/null)" ]; then
      STALE_MEMORY+=("$(basename "$file")")
    fi
  done < <(find "$MEMORY_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null)
fi

if [ "${#STALE_MEMORY[@]:-0}" -gt 0 ]; then
  STALE_MEMORY_JSON=$(printf '%s\n' "${STALE_MEMORY[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))')
else
  STALE_MEMORY_JSON='[]'
fi
MEMORY_SHOULD_SURFACE=false
if [ "${#STALE_MEMORY[@]:-0}" -ge 3 ]; then
  MEMORY_SHOULD_SURFACE=true
fi

MEMORY_JSON=$(jq -n \
  --argjson stale "$STALE_MEMORY_JSON" \
  --argjson surface "$MEMORY_SHOULD_SURFACE" \
  '{stale_files: $stale, stale_count: ($stale | length), should_surface: $surface}')

# --- Goal drift (skeleton) ---
# Full parsing of Goals/YYYY-QX.md requires YAML-aware parsing of the "This Week"
# and milestone sections per goal. This is easier to do inside the morning-plan
# skill (it's already reading the file for goal surfacing). drift-check.sh
# emits a placeholder; morning-plan enriches it.
CURRENT_QUARTER=$(date +"%Y-Q$(( ($(date +%-m) - 1) / 3 + 1 ))")
GOAL_FILE="${HOME}/Documents/PersonalOS/Goals/${CURRENT_QUARTER}.md"
GOAL_FILE_EXISTS=false
[ -f "$GOAL_FILE" ] && GOAL_FILE_EXISTS=true

GOALS_JSON=$(jq -n \
  --arg quarter "$CURRENT_QUARTER" \
  --arg file "$GOAL_FILE" \
  --argjson exists "$GOAL_FILE_EXISTS" \
  '{current_quarter: $quarter, file: $file, file_exists: $exists, stale: [], note: "Skill-level parsing enriches this — see morning-plan Around-the-Corner"}')

# --- Waiting-on drift (skeleton) ---
# Requires Todoist API access (see healthcheck.sh for token). drift-check.sh
# emits placeholder; morning-plan calls Todoist for label-filtered tasks and
# computes age in-skill (cheaper than re-authing here).
WAITING_ON_JSON='{"aged_tasks": [], "aged_count": 0, "note": "Skill-level enrichment"}'

# --- Assemble output ---
jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson releases "$RELEASES_JSON" \
  --argjson memory "$MEMORY_JSON" \
  --argjson goals "$GOALS_JSON" \
  --argjson waiting_on "$WAITING_ON_JSON" \
  '{
    timestamp: $ts,
    releases: $releases,
    memory: $memory,
    goals: $goals,
    waiting_on: $waiting_on
  }' > "$DRIFT_FILE"

# --- Output ---
if [ "$VERBOSE" = "true" ]; then
  cat "$DRIFT_FILE"
elif [ "$RELEASE_SHOULD_SURFACE" = "true" ]; then
  echo "⚠ ${UNRELEASED_COUNT} commits unreleased since ${LAST_TAG} (suggested: ${NEXT_VERSION})"
fi

exit 0
