---
name: dispatch
description: Spawn agents to work on approved Proposed Work Units across all active projects — hybrid architecture (background for research/docs, terminal for code). Enforces stage-only safety.
---

# Dispatch

Spawn agents to make progress on per-project work units. Hybrid architecture:
- **Autonomous (background)** — research, drafting, docs, planning. Uses `Agent` tool with `run_in_background: true` + `isolation: "worktree"`. Outputs land in `<project-repo>/.claude/staging/<unit-id>/` as staged content. No commits, no pushes.
- **Supervised (terminal spawn)** — code changes, refactors, feature work. AppleScript opens a new Terminal cd'd into the project repo with Claude pre-loaded. User supervises live.

**Output conventions:** Follows `.claude/skills/_conventions.md` — two-marker system (`[ASK]` / `[TODO]`), decisions-before-reference.

**Safety posture:** Stage-only, manual merge (per `memory/feedback_proactive_merge_prompts.md`). No agent auto-commits or auto-pushes. User reviews every diff.

## Instructions

### 1. Preflight

- Verify `.claude/state/health.json` is green (required MCPs ok). If not, surface `[ASK]` to fix first.
- Read all `~/Documents/PersonalOS/Projects/*.md` with `status: active` and `agent_dispatch: enabled`. Skip disabled or paused projects.
- Parse each project's `## Proposed Work Units` section for items marked ready but not yet dispatched.
- Count active agents via `ls <repo>/.claude/staging/*/` per project; enforce `agent_budget.max_parallel`.

### 2. Present Dispatch Plan

Show the user what's about to happen. **Budget ceiling: max 6 parallel agents across all projects.** If over budget, present the plan and ask user to pick 6.

```
## Dispatch Plan

Projects with approved work units:
  personal-brand-system (2 units)
    - autonomous: draft-homepage-hero-copy — est 10m
    - supervised: implement-rss-feed — est 20m
  job-search (1 unit)
    - autonomous: update-resume-bullets-for-april — est 8m
  ai-transformation (1 unit)
    - autonomous: research-anthropic-enterprise-pricing — est 12m

Total: 4 agents (3 autonomous, 1 supervised)
Budget: 4/6 parallel, 50m total time, 20m wall time (supervised blocks main session)

[ASK] Dispatch all 4? (y / select subset e.g. "1,3" / skip)
```

### 3. Dispatch — Autonomous (background)

For each autonomous unit:
1. Create worktree: `git -C <repo> worktree add <repo>/.claude/staging/<unit-id> -b agent/<unit-id>`
2. Call `Agent` tool with:
   - `isolation: "worktree"` — already set up
   - `run_in_background: true` — doesn't block main session
   - `subagent_type: "general-purpose"` — or specific agent if user annotated
   - `prompt`: concat of
     - project's `## Context for Agents` section (plain-English brief)
     - all `context_files` from frontmatter (read + inline)
     - the unit description from `## Proposed Work Units`
     - safety footer: "Write your output to `<repo>/.claude/staging/<unit-id>/output.md`. DO NOT commit. DO NOT push. DO NOT modify files outside staging/."
3. Record dispatch in `.claude/logs/dispatch-YYYY-MM-DD.jsonl`:
   ```json
   {"timestamp":"...", "project":"personal-brand-system", "unit_id":"draft-homepage-hero-copy", "type":"autonomous", "agent_id":"..."}
   ```

### 4. Dispatch — Supervised (terminal spawn)

For each supervised unit:
1. Create worktree: `git -C <repo> worktree add <repo>/.claude/staging/<unit-id> -b agent/<unit-id>`
2. Prepare a launch prompt file: `<repo>/.claude/staging/<unit-id>/PROMPT.md` with the unit description + context files + safety footer.
3. Invoke `mcp-servers/dispatch-agent.sh --supervised <repo>/.claude/staging/<unit-id>` which opens a new Terminal window via AppleScript with `cd <worktree> && claude --read-prompt PROMPT.md`.
4. Record in dispatch log.

User will see N new Terminal windows open. They work on each in parallel.

### 5. Report Back

After all autonomous dispatches are queued (they run in background) and all supervised terminals are open:

```
Dispatched 4 agents:
  ✓ personal-brand-system/draft-homepage-hero-copy — autonomous, background-XXXX
  ✓ personal-brand-system/implement-rss-feed — supervised, Terminal window opened
  ✓ job-search/update-resume-bullets — autonomous, background-YYYY
  ✓ ai-transformation/research-anthropic-pricing — autonomous, background-ZZZZ

Autonomous agents complete in the background. Staging output lands in:
  personal-brand-system/.claude/staging/draft-homepage-hero-copy/output.md
  job-search/.claude/staging/update-resume-bullets/output.md
  ai-transformation/.claude/staging/research-anthropic-pricing/output.md

[ASK] Tomorrow's /morning-plan will surface staged output for your review. Or run /dispatch --status anytime to check progress.
```

### 6. Status Subcommand

`/dispatch --status` — read the dispatch log for the past 3 days, list all staged units, mark each as:
- **Completed** — `output.md` exists, not yet merged
- **In progress** — worktree exists, no output yet
- **Timeout** — `<unit-id>-timeout.md` exists (killed for exceeding max_minutes)

Format:
```
## Dispatch Status

personal-brand-system:
  ✓ draft-homepage-hero-copy — completed 2h ago, staged for review
  ⏳ implement-rss-feed — supervised session in progress (Terminal open)
job-search:
  ✓ update-resume-bullets — completed 4h ago
ai-transformation:
  ⚠ research-anthropic-pricing — TIMEOUT after 15m; partial output staged

[ASK] Review completed units now? (y / individual: 1,3 / skip)
```

### 7. Merge Subcommand

`/dispatch --merge <project-slug>/<unit-id>` — reviews and merges a staged unit:

1. Run secret scan on the worktree (extends `.git/hooks/pre-push` logic).
2. Show `git diff main...agent/<unit-id>` to user.
3. `[ASK] Merge as a squash commit? (y / view-more / discard / leave-for-later)`
4. On `y`: `git merge --squash agent/<unit-id> && git commit -m "..."`; delete worktree; tag `agent/<unit-id>-YYYYMMDDTHHMM`.
5. Update the project note: move unit from `## In Progress` to `## Completed` with tag.

### 8. Safety enforcement (hard rules)

- **Never auto-commit.** Every worktree creates on a feature branch `agent/<unit-id>`. Main branch is never touched by an agent.
- **Never auto-push.** User-initiated only.
- **Time budget per agent.** Agents exceeding `agent_budget.max_minutes` are killed; partial output preserved as `<unit-id>-timeout.md`.
- **Budget ceiling.** No more than 6 parallel agents across all projects.
- **Secret scan before merge.** Extends the pre-push hook pattern list.
- **One-click rollback.** Tag every merged agent branch; `git reset --hard <tag>` is always available.

## Staged-work surfacing contract

Per user's hard requirement (`memory/feedback_proactive_merge_prompts.md`), the system surfaces pending merges proactively:

1. **SessionStart hook** (`sessionstart-health.sh`, v2.0 extension) scans every registered project's `.claude/staging/` directory. If any has pending content, surfaces `[ASK]` AT THE TOP of the next skill output.
2. **morning-plan "Around the Corner"** always includes staged work (counted against the 2-item budget — staged work is EXEMPT from the limit).
3. **weekly-review** surfaces staged work older than 3 days as aging: `[ASK] N units staged 4+d. Merge, discard, or snooze?`

User should NEVER have to remember to check `.claude/staging/` manually.

## Notes

- The one new slash command in the entire Month-1 plan. Justified because orchestration is its own lifecycle with safety rules distinct from daily/weekly cadence.
- All dispatch logs land in `.claude/logs/dispatch-YYYY-MM-DD.jsonl` for weekly-review velocity analysis.
- `/dispatch --status` and `/dispatch --merge` share the skill; not separate commands.
