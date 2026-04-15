---
name: Coaching System Design
description: /coach skill with 3 personas (Executive, Life, Wellness) + "Around the Corner" proactive alerts in morning-plan
type: project
---

## Coaching System

**`/coach` skill** with 3 persona-based coaching modes:
- **Executive Coach** → Career, Personal Brand (strategy, positioning, leverage)
- **Life Coach** → Marriage, Family, Friendships, Finances (values, presence, ritual design)
- **Wellness Coach** → Physical Health, Inner Life (systems thinking, minimum effective dose)

Invocation: `/coach` (auto-select), `/coach executive`, `/coach life`, `/coach wellness`

**Key design decisions:**
- Personas auto-selected by goal triage scoring (which goals need attention most)
- 5 coaching protocols: Obstacle Troubleshooting, Cross-Goal Pattern Recognition, Adaptive Targeting, Stuck Goal Decision, Theme + Trade-off Alignment
- Interaction rules: one question at a time, never fill in user's answers, data-grounded, persona-consistent tone
- Coaching notes saved to `~/Documents/PersonalOS/Coaching/YYYY-MM-DD.md`
- Bi-weekly cadence suggested, on-demand always available

**Chief of Staff** behaviors woven into `/morning-plan` as "Around the Corner" section:
- Milestone lookahead (goal milestones at risk)
- Lead indicator streak detection (missed 3+ weeks)
- Coaching commitment follow-up
- Cross-goal energy alerts (Check-In scores + health indicators)
- Calendar-goal conflict detection

**Why:** The existing POS skills excel at tracking/accountability but lacked coaching — the "why is this stuck?" conversation. Separate personas because Career, Relationships, and Health require genuinely different frameworks and tones.

**How to apply:** When user mentions feeling stuck on a goal, suggest `/coach`. Morning-plan now proactively surfaces goal trajectory risks. Weekly-review nudges toward coaching if >16 days since last session.
