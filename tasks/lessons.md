# Lessons

Patterns to not repeat. Review at session start.

## Resumed multi-session builds: re-read the spec/memory fresh before locking a plan
The v3.0 plan + `memory/project_pos_v3_redesign.md` can be edited between sessions (and even mid-session). On 2026-06-01 the user added the whole "meeting-note dual-zone" design to the memory doc after my initial context load — I'd have planned against a stale spec if I hadn't re-read it. **Rule:** when resuming a long-running build, re-Read the plan file and the project memory doc before finalizing scope, even if a version was in the recalled context. Recalled `<system-reminder>` memory reflects when it was written, not necessarily now.

## Background jobs: one clock. Don't compare UTC timestamps to local dates.
`daily-brief.sh` wrote `last_run` as `datetime.utcnow()` (UTC, `…Z`), but `sessionstart-ensure-brief.sh` and `/day` compared "did a run happen today?" against `date +%Y-%m-%d` (local, America/Los_Angeles). For ~7 hours each local evening the UTC date is already tomorrow, so the guard broke — risking a redundant $0.84 build or a missed-failure surface. Caught in code review. **Rule:** when one process writes a timestamp another process consumes for date comparisons, fix the clock explicitly. Here: the wrapper now writes a local-date `day` field and consumers compare against that, not the UTC `last_run`.

## Write tool doesn't set the executable bit; check `-x` assumptions
`daily-brief.sh` was created via Write (mode 644) while every sibling wrapper was 755. The launchd plist invoked it via `bash -lc "path"` so it "worked," masking the missing bit — but the new hook's `[ -x "$BRIEF" ]` guard silently no-op'd (never nudged, never built). **Rule:** scripts meant to be executed need `chmod +x` after Write (and git tracks the bit); when a hook will run a script, invoke via `bash "$script"` and guard on `-f`, not `-x`, so a lost bit can't silently disable it.
