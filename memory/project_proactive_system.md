---
name: Proactive Surfacing System (v1.9+)
description: How Personal OS proactively surfaces drift, release readiness, staged work, and silent degradation. Budget-constrained to prevent nudge fatigue.
type: project
---

# Proactive Surfacing System (v1.9+)

The system nudges on things that drift without the user asking. Evidence-backed: trust decay from false-positive nudges is the #1 risk, so everything is dismissable and monthly-review tunes thresholds.

## Drift types + where they surface

| Drift | Detection | Surfaces in | Threshold | Dismissable |
|-------|-----------|-------------|-----------|-------------|
| Release | `mcp-servers/drift-check.sh` → `.claude/state/drift.json` | morning-plan "Around the Corner" + weekly-review Systems Health + SessionStart hook context | ≥3 commits unreleased | yes (snooze 7d / not-applicable / wrong-heuristic) |
| Goal | Skill parses `Goals/YYYY-QX.md` | morning-plan Around-the-Corner | Empty "This Week" + no milestone check-in 14+ days | yes |
| Waiting-on | Skill queries Todoist `waiting-on` label | morning-plan + weekly-review | 3+ days idle | yes |
| Memory | `drift-check.sh` finds files >30 days | weekly-review (once per week max) | 3+ stale files | yes |
| Staged agent work (v2.0+) | SessionStart scans `<project>/.claude/staging/` | SessionStart hook BEFORE morning-plan + morning-plan + weekly-review (aging) | Any pending items | no (user hard requirement) |
| Silent skill degradation | Weekly-review greps `.claude/logs/*.jsonl` | weekly-review Systems Health | 5+ `skipped` or 2+ `error` per skill/step in 7 days | yes |

## Surfacing budget

- **morning-plan "Around the Corner":** max 2 items per morning. Higher-priority items bump lower.
- **weekly-review Systems Health:** max 5 items. Staged work surfacing is BEFORE this budget (user hard requirement).
- **SessionStart hook context:** staged work + release drift only. Anything else waits for morning-plan.

Priority order for displacement:
1. Staged agent work (non-displaceable)
2. Release drift
3. Cross-goal energy alert (health-critical)
4. Stale goals
5. Waiting-on aging
6. Coaching follow-up
7. Memory drift (lowest; weekly cadence)

## Anti-nag infrastructure

Every surfaced item includes dismiss options. Dismissals write to `memory/nudge_feedback.jsonl`:

```json
{"timestamp": "2026-04-22T09:00:00Z", "source": "morning-plan", "alert_type": "release_drift", "dismissed_as": "wrong-heuristic", "context": {"count": 3, "since": "v1.8"}}
```

**Dismissal reason codes:**
- `snooze:7d` — suppress for 7 days; re-arm
- `not-applicable` — user made a deliberate decision; skip permanently for this instance
- `wrong-heuristic` — threshold is wrong; feeds monthly tuning

## Monthly anti-nag tuning

`/monthly-review` reads `nudge_feedback.jsonl` and surfaces:

```
Anti-nag review (last 30 days):
- release_drift: fired 8x, dismissed 6x as wrong-heuristic
  [ASK] Raise threshold from 3 commits to 5?
- waiting_on_aging: fired 4x, dismissed 0x, acted on 4x
  Working well; no change.
```

User accepts or rejects each tuning. Accepted changes update the thresholds in `drift-check.sh` (or skill-level config).

## Observability

Every skill invocation appends to `.claude/logs/YYYY-MM-DD-<skill>.jsonl` (see `_conventions.md` for schema). Weekly-review greps these to catch silent degradation (steps that catch their own exceptions).

## Where the config lives

- Thresholds: `mcp-servers/drift-check.sh` (shell variables at top)
- Skill-level heuristics: inside each skill file (morning-plan, weekly-review)
- User-stated hard requirements: `memory/feedback_proactive_merge_prompts.md` (staged work surfacing)
- User-stated preferences: `memory/feedback_fewer_skills.md` (no new commands; consolidate)

## What's NOT a nudge

- Informational facts (schedule, completed tasks, KB highlights) — unadorned prose in output
- Skill preflight results — brief `✓ preflight ok` footer
- Claude's reflection on the day — reference content, not an ask

Nudges are reserved for things the user needs to respond to or act on, with a clear path and a dismiss option.
