---
name: project-pos-v3-redesign
description: Personal OS v3.0 "chief-of-staff" redesign — status, plan location, decisions, cost finding
metadata:
  type: project
---

Active multi-session build (started 2026-06-01): redesigning Personal OS into a self-running "chief of staff" so the (burnt-out) user's only jobs are **adjust, confirm, reflect**. Plan: `~/.claude/plans/it-s-been-a-while-declarative-flame.md`. Branch: `v3.0-chief-of-staff`. Ships as a major GitHub release **v3.0.0** when coherent.

**Core idea:** invert the workload — background headless `claude -p` jobs (launchd) pre-write DRAFT artifacts; the human reviews. The fix is automation, not a new purpose (execution-first, role-portable — see [[feedback-work-readonly-personal-ok]]).

**Done:**
- Phase 0.5 — `/reflect` blocking gates made non-blocking (committed).
- Phase 0 — backbone proven under launchd (spike: work claude.ai connector works headless → 11 real events; least-privilege allowlist held, `denials=[]`; vault write works; daemon PATH lacks nvm so absolute `claude` path required).
- Phase 1a CORE — `mcp-servers/daily-brief.sh` (wrapper: mkdir-lock, work-read-only allowlist, envelope→run-log) + `mcp-servers/prompts/daily-brief.md` (the unattended brief prompt) write a high-quality DRAFT daily note: `status: draft`, managed block `<!-- BEGIN/END:auto-draft -->`, `## My Reflection` + Lead-Indicator "Today" left untouched, graceful degradation, zero work mutations. Tested end-to-end 2026-06-01: $0.84/run, 28 turns, `denials=[]`.

**Next:** make it automatic ("ready when I open Claude" = SessionStart-ensures hook + optional morning launchd, guarded by `PERSONAL_OS_HEADLESS=1` against recursion); build `/day` (review skill that reads the draft, collects confirm + the full 5-score check-in); Phase 1b `otter-sync` (continuous capture — cheap non-LLM poll, Haiku extraction only on new transcripts; **MUST protect a human `## My Notes` section in each meeting note via the managed-block contract — auto content lives in `<!-- BEGIN/END:auto-meeting -->`, the user's own notes are never overwritten on re-run, same guarantee as the daily note's `## My Reflection`**); Phase 1c self-heal sweep + atomic `.mcp.json` writes + `chmod 600`; Phase 2 kinder reframing (pull accountability off the daily surface — the draft currently shows a wall of "⚠️ OVERDUE" goal milestones; Phase 2 must re-tone).

**Meeting-note design (user-requested 2026-06-01) — build this in Phase 1a/1b:** Eliminate the "user creates a note AND the system creates another" collision via ONE deterministic file per meeting: `Meetings/YYYY-MM-DD-<slug>.md` (slug from title + time-suffix for clashes; frontmatter stores calendar `event_uid`). The **daily-brief pre-creates SHELLS** for today's + tomorrow's real meetings (idempotent rolling 1-day horizon; only 2+-attendee/conf-link meetings, not blocks; therapy discreet) — dual-zone: top `## My Notes` (human, jot freely) + an empty `<!-- BEGIN/END:auto-meeting -->` block + `status: shell`. So the user can prep the evening before; brief `### Meetings` can wikilink the shells. **otter-sync = find-or-create, fill-block-only:** match by `event_uid` (fallback date+title+time), fill ONLY the auto-meeting block, flip `status: shell→transcribed`, never touch `## My Notes`; create fresh if no shell (same-day meeting). **Prune** shells that end a PAST day with BOTH zones empty (never-noted + never-transcribed) to avoid clutter. Update the `Meeting Note` template to this dual-zone structure. Same human-content-preservation guarantee as the daily note's `## My Reflection`.

**Cost finding:** $0.84/daily-brief run (sonnet, 28 turns) → ~$25/mo for the brief alone; optimize via Haiku for mechanical gather, batch reads (fewer turns), cheap non-LLM Otter polling. User accepts cost but flagged "work read-only" is the hard line.

**Permissions:** narrow Bash allow-rules added (launchctl + named wrapper scripts only, never raw `claude`) via `mcp-servers/add-automation-permissions.py` (also a portability helper for new machines).

**Minor bug to fix:** Check-In table column order came out `Energy|Focus|Balance|Impact|Mood` vs template's `Energy|Focus|Impact|Balance|Mood` — tighten the prompt's 5c block.
