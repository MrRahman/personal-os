---
name: release_strategy
description: Semantic versioning strategy for Personal OS — major.minor.patch, batch enhancements into minor releases
type: project
---

Use semantic versioning for Personal OS releases on GitHub:

- **v1, v2, v3 (major)** — Reserved for significant milestones: new skill categories, architectural rewrites, breaking changes to setup flow, or public launch moments. These should feel like a "new version of the product."
- **v1.1, v1.2, v1.3 (minor)** — Feature batches: group 2-5 related enhancements into a single minor release rather than releasing each commit individually. Examples: "connection gate + token efficiency" (v1.1), "People catch-all updates" (v1.2).
- **v1.1.1, v1.2.1 (patch)** — Bug fixes, typo corrections, small tweaks that don't add functionality.

**Why:** The user will continuously improve the system and doesn't want to burn through major version numbers. Going from v1 → v2 → v3 should represent real evolution, not incremental skill tweaks.

**How to apply:** When committing enhancements, accumulate them on main. When the user says "release" or a logical batch is complete, create a minor release. Only bump major version when the user explicitly decides to (e.g., "this is v2.0"). Prefer batching 2-5 related changes into one minor release over releasing every single commit.

**Current state (2026-04-10):**
- v1.0 — Initial public release (da37e69)
- v1.1 — Connection gate + token efficiency (914b4a0)
- v1.2 — Calendar catch-all People updates (dd52c3c)
- v1.3 — Plan-week skill, calendar-smart morning-plan, People reconciliation (7a13596)
- v1.4 — Freshness gates + smart reschedule for /reflect (8591b89)
