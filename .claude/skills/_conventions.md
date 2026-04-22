---
name: _conventions
description: Shared output + preflight + marker conventions across all Personal OS skills. Reference this from every user-facing skill. Introduced v1.7 (2026-04-22).
---

# Personal OS — Shared Skill Conventions

All user-facing skills (morning-plan, reflect, weekly-review, plan-week, sync-meetings, coach, prep, draft, triage, capture, kb, idea, monthly-review, quarterly-planning) follow these rules. **If a skill violates these, update the skill, not the convention.**

## Two-marker system

Only two markers exist in terminal output. They subsume what were previously `[DECISION]` / `[QUESTION]` / `[ACTION]` / `[INFO]`.

- **`[ASK]`** — user must respond NOW. Applies to every yes/no prompt, every `confirm all / adjust / skip`, every preflight failure prompt, every dispatch-plan approval, every check-in prompt. If the skill will wait for input, the line starts with `[ASK]`.
- **`[TODO]`** — something the user should act on later. Applies to staged agent output needing merge, proposed work units awaiting dispatch, drift-detected items that the user will address outside this session.
- **No markers on reference content.** Schedule, context, summaries, lists of completed tasks — unadorned prose.

Evidence-based rationale: clig.dev explicitly advises against bracketed log-level labels; NN/g + AHRQ alert-fatigue research shows proliferating markers train users to ignore all of them. Two markers is the boundary that preserves signal.

Add this legend at the top of every skill's terminal output:

```
[ASK] needs you to respond now. [TODO] = something to act on later. Everything else is context.
```

## Preflight behavior — brief on pass, loud on fail

- If every REQUIRED service passes AND every OPTIONAL service passes: single-line footer at the top of the output: `✓ preflight ok (N/N services + vault)`. Do not itemize.
- If an OPTIONAL service fails: continue silently, add a single warning line: `⚠ preflight: <service> unreachable — <feature> skipped. See .claude/state/health.json.`
- If a REQUIRED service fails: STOP. Print `[ASK] <service> unreachable (<error>). Fix with <one-sentence fix>, then re-run /<skill>.`
- Never itemize all services on pass. The footer proves the check ran; itemizing is noise.

Source: clig.dev Compatibility / "brief on success, verbose on failure."

## Output ordering

Every terminal output follows this order:

1. Header (title + preflight footer + marker legend)
2. `[ASK]` items — things needing a response now
3. `[TODO]` items — deferred action items
4. Reference content (schedule, summaries, lists, tables)
5. Footer / summary line

Do not reorder. Add a `<!-- Output order: ... -->` comment at the top of each skill's output-generation step to enforce.

## Never use these

- Emoji arrows for state (→ ⬆ ↓ 🛑) — use plain words: `Move:`, `Escalate + Move:`, `Deprioritize`, `Drop or Break Down`.
- Log-level labels (`[INFO]`, `[WARN]`, `[DEBUG]`) — inverts convention with the two markers.
- Multi-part check-in questionnaires — compress to single `[ASK]` line with auto-detected pre-fills.
- Full preflight service itemization on pass — one-line footer only.

## When to introduce a new skill

Default: don't. Consolidate into existing skills or into a shared utility (`mcp-servers/*.sh`). Per `memory/feedback_fewer_skills.md`, user has limited bandwidth to remember command surface. Only add a new slash command for a genuinely distinct lifecycle with its own budget + safety contract (e.g., `/dispatch` in v2.0 — agent orchestration is its own thing).

## Run logs (v1.9+)

Every skill invocation writes a structured run log to `.claude/logs/YYYY-MM-DD-<skill>.jsonl` (append-only JSONL). Captures silent degradation — a step that catches its own exception and skips is invisible to the user, but weekly-review can grep logs and surface the pattern.

**Schema per log line:**
```json
{
  "timestamp": "2026-04-22T09:15:00-07:00",
  "skill": "morning-plan",
  "step": "Slack triage",
  "status": "ok",      // or "skipped", "error"
  "reason": "",         // optional; use for skip/error explanation
  "ms": 1240            // optional; duration in ms
}
```

**When to emit:**
- `ok` — every major data-gather step (calendar fetch, email triage, etc.) and every write step (Obsidian writes, Notion patches, Todoist task creation).
- `skipped` — any step intentionally bypassed (preflight says the service is down; user answered "skip"; precondition not met).
- `error` — caught exception. Must include `reason`.

**When weekly-review greps these:**
- `morning-plan` step `Slack` with `status: skipped` ≥5× in the last 7 days → `[ASK]` refresh Slack tokens
- `reflect` step `sync-meetings` with `status: error` ≥2× → `[ASK]` investigate
- Budget: surface at most 2 observability alerts per weekly-review to keep noise down.

**Implementation:** append a JSON line to the log file. Shell: `echo "$(jq -nc ...)" >> "$CLAUDE_PROJECT_DIR/.claude/logs/$(date +%Y-%m-%d)-<skill>.jsonl"`. In-skill: use the same one-liner; Claude should emit it silently alongside actual work.
