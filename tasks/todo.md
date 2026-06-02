# v3.0 — Phase 1a: morning experience + meeting-note foundation

> **✅ Shipped this session (2026-06-01):** Subsystem 1 (A–E) — `/day` review skill + SessionStart-ensures trigger + opt-in morning launchd + `## Proposed Captures` staging + Check-In column fix (+ Notion filter + garbled-sentence fixes) + 11 command dupes deleted. Code-reviewed (superpowers:code-reviewer); fixed B1 (UTC-vs-local date bug) + N4 (managed-block checkbox contract) + S3/S5 polish. Subsystem 2 (G+H+I, meeting notes) deferred to the next cut. Not yet committed (awaiting user).

Branch: `v3.0-chief-of-staff`. Plan: `~/.claude/plans/it-s-been-a-while-declarative-flame.md`.
Done already: Phase 0 (spike), Phase 0.5 (/reflect non-blocking), Phase 1a CORE (`daily-brief` writes the draft).
Two subsystems now in flight (see `memory/project_pos_v3_redesign.md`, updated 2026-06-01):
1. **Morning review** — make the already-built draft *reviewable* (`/day`) + *automatic* (trigger).
2. **Meeting capture** — one deterministic dual-zone file per meeting; brief pre-creates shells, otter-sync fills them, neither ever clobbers the human's `## My Notes`.

## Locked design decisions
- **Model Y (daily-note semantics):** note `D.md` = *yesterday's (D-1) close-out* (`## Completed`/`## Reflection`, in the managed block) **+** *today's (D) plan* **+** blank `## My Reflection`. `/day` fills today's note's `## My Reflection` + `## Lead Indicators`; scores are **about yesterday**. Matches the brief's actual STEP 3 + the plan's day-in-life.
- **Canonical Check-In order:** `Energy | Focus | Impact | Balance | Mood`. Fix = brief copies the human-owned tail **verbatim** from the template, never regenerates.
- **HARD CONSTRAINT:** `/day` never auto-writes scores / Highlight / Adjustments — prompts + waits. Optional "give me a line, I'll propose the five" for low-energy days. Rest-day aware (`feedback_rest_days`).
- **Human-zone preservation = one contract, two surfaces:** daily note's `## My Reflection` and meeting note's `## My Notes` are both append-only/never-overwritten; auto content lives strictly inside `<!-- BEGIN/END:auto-* -->`.
- **Don't gut morning-plan/reflect yet** — the brief references them for gather logic. `/day` becomes primary; they stay callable with a thin "prefer /day" pointer.
- **Pull-not-push:** `/day` collapses the goal-accountability "wall of OVERDUE" to one line → `/week` (not the full Phase 2 re-tone).
- **Interactive work-calendar writes OK in `/day`** (user present + confirming). Read-only-work is the *background* hard line only.
- **Meeting shells are CREATE-ONLY in the brief; the destructive PRUNE lives in otter-sync** (conservative: status==shell + both zones empty + day in past). Keeps unattended deletion out of the daily brief.

## Subsystem 1 — Morning review (the high-value unlock)
- [ ] **A. Fix Check-In column bug.** Fix `Daily/2026-06-01.md` line 149; brief copies `## My Reflection` + `## Lead Indicators` verbatim from template.
- [ ] **B. Brief stages `## Proposed Captures`.** Lean checkbox section (text — source — →project) in managed block, from actions the brief already detects. `/day` consumes it.
- [ ] **C. Build `/day`** (`.claude/skills/day.md`). Locate draft + first-run-after-gap; close yesterday (recap + frictionless check-in, rest-day aware); set up today (present, no re-gather, collapse goal wall); confirm captures → Todoist; flip status; idempotent; graceful. Thin pointer on morning-plan/reflect.
- [ ] **D. SessionStart-ensures + morning launchd.** `sessionstart-ensure-brief.sh` (guard on `PERSONAL_OS_HEADLESS`+lockdir+draft-exists), wire into settings.json; `com.personalos.daily-brief.plist` weekday ~6am (after 5:45am refreshers — verify); verify `--bare` safety.
- [ ] **E. Delete stale `.claude/commands/*.md` dupes.** Verify resolution intact. Deferrable.

## Subsystem 2 — Meeting capture (user-requested 2026-06-01)
- [ ] **G. Dual-zone `Meeting Note` template.** Top `## My Notes` (human) + `<!-- BEGIN/END:auto-meeting -->` (Summary/Key Points/Decisions/Actions/Follow-ups/Transcript) + frontmatter `status: shell`, `event_uid`.
- [ ] **H. Brief pre-creates dual-zone SHELLS.** Today + tomorrow, real meetings only (2+ attendees or conf link, not blocks), therapy discreet, idempotent (match `event_uid`, fallback date+title+time), CREATE-ONLY. `### Meetings` wikilinks the shells. Reverses the brief's current "no meeting notes" rule for shells.
- [ ] **I. otter-sync launchd job (Phase 1b).** Find-or-create / fill the auto-meeting block only / flip `shell→transcribed` / conservative prune of empty past shells. Replaces standalone `sync-meetings`. (Naturally pairs with H.)

## F. Verify + finish
- Mechanical: column fix; brief edits; hook shellcheck+dry-run; plist valid XML; settings.json valid JSON; dupes gone + skills intact; template valid.
- `/day` is a prompt → static review vs plan + dependency-shape check + offer user a live walkthrough (cannot fabricate scores).
- Update memory + CLAUDE.md; commit logically (no release yet).

## Recommended sequencing (for the check)
**This session:** Subsystem 1 (A–E) — ships the review surface that unlocks the entire daily-brief investment; clean, testable, self-contained.
**Next session:** Subsystem 2 (G+H+I together) — the meeting subsystem is most coherent built as one unit (template + its creator + its filler), and keeps the destructive prune out of the brief until otter-sync exists.
*Alternative:* fold G+H into this session (I'm editing the brief + templates anyway) if prepping meetings the evening-before is wanted now, deferring only otter-sync (I).
