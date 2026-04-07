---
name: draft
description: Generate personal brand content from vault material — LinkedIn posts, blog articles, talk outlines — in the user's voice
---

# Content Draft

Generate a first draft of personal brand content by pulling from the Obsidian vault. Turns your meetings, resources, reflections, and ideas into publishable content.

## Instructions

### 1. Capture Intent

Accept a topic or prompt:
- `/draft LinkedIn post about AI adoption learnings`
- `/draft blog article about building a personal operating system`
- `/draft talk outline on leading AI transformation`
- `/draft` (bare) — ask: "What do you want to write about? And what format — LinkedIn post, blog article, or talk outline?"

Detect format from input:
- **LinkedIn post**: short, punchy, 150-300 words, hook → insight → example → takeaway
- **Blog article**: 800-1500 words, deeper exploration, multiple examples, clear structure
- **Talk outline**: bullets + key messages, designed for a presentation or speaking engagement
- If format unclear, default to LinkedIn post (lowest friction to publish).

### 2. Gather Vault Material

Search the vault for relevant content. Run in parallel:

**Resources/**: Grep `~/Documents/PersonalOS/Resources/` for topic keywords. Read matching notes — Summary, Key Insights, My Notes (if populated). Prioritize resources with populated My Notes (user's own thinking).

**Meetings/**: Grep `~/Documents/PersonalOS/Meetings/` (last 60 days) for topic keywords. Extract relevant Key Points, Decisions, and Transcript Highlights. Look for real examples, decisions, and outcomes — these make content concrete.

**Daily/**: Grep `~/Documents/PersonalOS/Daily/` for topic keywords in Reflection sections. Extract patterns and insights from daily thinking.

**Ideas/**: Read all files in `~/Documents/PersonalOS/Ideas/`. Check if any idea titles or Spark sections relate to the topic.

**Projects/**: If the topic maps to an active project (e.g., "AI transformation" → `Projects/ai-transformation.md`), read the project's Overview, Current Status, and Key Decisions.

### 3. Generate Draft

Write the draft using these principles:

**Voice** (from CLAUDE.md):
- Direct, no buzzwords, no "leveraging" or "harnessing"
- Practical and authentic — write like someone who actually does the work
- Specific over general — use real examples, not hypothetical ones
- No filler praise, no "Great insight!" energy
- Tight sentences, strong verbs, clean structure

**Content rules:**
- **Sanitize by default**: Replace internal names, financial figures, and confidential details with generic placeholders. Example: "Our CEO" instead of "[executive name]", "the company" instead of "[company name]", "a $X deal" instead of specific numbers. Note what was sanitized.
- **Source from vault**: Every claim or example should trace back to vault content (a meeting, resource, reflection, or project). Don't fabricate examples.
- **Lead with insight, not resume**: The reader should learn something, not just hear about the user's role.
- **End with action**: Every piece should end with something the reader can do or think about differently.

**Format-specific:**

*LinkedIn post (150-300 words):*
- Hook line (unexpected insight or contrarian take)
- 2-3 short paragraphs with one key example
- Takeaway or question to drive engagement
- No hashtags unless user requests them

*Blog article (800-1500 words):*
- Title + subtitle
- Opening that frames the problem or question
- 3-5 sections with headers
- Real examples from vault material
- Conclusion with forward-looking insight
- No "In conclusion..." — just land the point

*Talk outline (bullet format):*
- Title + one-line thesis
- 3-5 key messages with supporting points
- Opening hook suggestion
- Closing line suggestion
- Audience callouts (what they care about)

### 4. Present with Attribution

Show the draft, followed by:

```
---
**Sources from your vault:**
- [[Resources/slug|Title]] — used for [which insight]
- [[Meetings/slug|Meeting]] — example from [what]
- [[Daily/date|Reflection]] — pattern about [what]
- [[Projects/slug|Project]] — context about [what]

**Sanitized:** [list of what was genericized — e.g. "[exec name] → 'our CEO'", "[company] → 'the company'"]
```

### 5. Iterate

After presenting, ask:
- "Revise, or good to go?"
- If user wants changes: edit in place, re-present
- If user approves: offer to save to `~/Documents/PersonalOS/Ideas/draft-slug.md` with `status: developing` and `source: /draft`

## Notes
- Never publish vault content verbatim — always synthesize and add perspective
- Sanitization is the default. Only de-sanitize if the user explicitly says to use real names.
- If no vault material found on the topic: say so honestly, then offer to write from general knowledge (clearly labeled as not vault-sourced)
- The goal is a publishable first draft, not a perfect final product. User will iterate.
- Reference CLAUDE.md for paths, conventions, and the user's writing style
