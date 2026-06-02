---
name: Rest-day reflections — don't reframe rest as failure
description: When user signals intentional disconnect (low motivation, "didn't work much," Balance≥9 with Impact/Focus≤4), skip the Action Items → Todoist sweep entirely and reframe Claude's reflection to honor the rest, not treat missed plan items as shipping failures
type: feedback
originSessionId: feaad9aa-eb75-413d-a272-3c63f6c1f2ed
---
Rule: On reflection days where the user explicitly frames the day as mental-health rest or disconnect (low motivation, "didn't work much," low Impact, low Focus, high Balance), **skip Step 7 (Action Items → Todoist) entirely**. Also rewrite Claude's auto-reflection so missed plan items are framed as *deliberately deprioritized*, not *dropped*.

**Why:** On 2026-05-11 reflection, after a 5-day disconnect leading into a meeting-heavy Monday, the user wrote: "Didn't work much at all, not motivated — focused on my personal mental health by disconnecting" and gave scores E:6 F:3 I:3 B:10 M:7. I'd just proposed 11 new Todoist tasks swept from meeting transcripts. User pushed back: "dont add any action items." The reflection I'd written framed the day as a discipline problem ("meetings expanded into focus blocks, rifle email didn't ship") — wrong frame entirely. The day was rest by design.

**How to apply:**
- **Trigger pattern:** in /reflect responses, watch for: `Balance ≥ 9` + `Impact ≤ 4` + `Focus ≤ 4`, OR phrases like "disconnect," "rest day," "didn't push," "low motivation," "mental health."
- **When triggered:**
  - Do not propose any new Todoist tasks from meeting transcripts (skip Step 7's sweep entirely; existing already-scheduled tasks stay as-is).
  - Rewrite Claude's auto-reflection: lead with "yesterday was a rest day — explicitly disconnecting"; acknowledge what still happened (meetings) but do NOT moralize about incomplete plan items; frame the carry-forward as a known load on the next workday, not a failure.
  - Still do all other Step 10 writes (transcript files, meeting notes, People notes, daily note) — the institutional record matters even on rest days.
- **Edge case:** if scores are mixed (e.g., Balance 10 but Impact 8 — productive AND balanced), don't apply this — the user is just having a good day, not a rest day.
- **Don't ask permission for the no-tasks pivot** — when triggers fire, just do it; if user wanted tasks they'd ask.
