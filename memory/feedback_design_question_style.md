---
name: Design question style — propose, don't quiz
description: When user says "take time and think through this," produce a complete reasoned recommendation, not a multi-choice questionnaire
type: feedback
originSessionId: d41ade61-d9ce-4aa8-86b2-e85ad6001eb5
---
When the user says some variant of "let's think through this more deeply" or "take your time and think through this," they want a **complete reasoned recommendation** — one preferred path with the tradeoffs surfaced — not a structured AskUserQuestion with 3 options × 4 multi-choice questions.

**Why:** A multi-choice question array with 3+ options each effectively passes the design work back to the user. They asked me to think through it; if I respond with a quiz, I'm avoiding the synthesis they explicitly asked for. Observed 2026-04-29: I asked 3 multi-choice questions about Drive vs Slack vs Atlassian, routing scope, and pull cadence. User rejected the AskUserQuestion outright.

**How to apply:**
- For "take your time" / "think through" prompts: deliver a complete plan with one recommended approach. Surface tradeoffs in prose, not as user-facing options.
- AskUserQuestion is appropriate for *requirements clarification* (what the user wants) — not for *design choices I should be making* (which carrier, which routing pattern).
- If a real decision is genuinely user's call (compliance trade-off, personal preference), ask one focused question with at most 2-3 options. Not three questions stacked.
- The bias should be: propose, don't quiz. The user can always redirect.

**Test for whether to ask vs. propose:** Could a senior architect on the same problem just pick one? If yes, pick one. If no (e.g., user must approve compliance impact), ask the one focused question.
