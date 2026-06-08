# AI Knowledge Base — Design Spec

## Overview

Create a Notion database serving as the central knowledge base for the Personal OS. Items flow in from capture sources, get auto-processed by Claude via the `/triage` skill, and surface as actionable tasks in Todoist.

**Scope (Phase 1):** Notion database creation + updated `/triage` skill with auto-tagging. Capture pipeline and additional KB skills deferred until Readwise MCP is connected.

**Note:** This spec replaces the schema defined in `personal-os.md` section 04. The `Source` field is intentionally removed (replaced by `Type` which captures content format rather than origin). The `Relevance` field is also removed (replaced by `Action Required` checkbox). `personal-os.md` should be updated to match after implementation.

---

## Database Creation

The database will be created via the Notion MCP `API-create-a-data-source` tool under an existing parent page. During implementation:

1. Search Notion for an existing "AI Knowledge Base" page or suitable parent using `API-post-search`
2. If no parent exists, create one via `API-post-page`
3. Create the database with the schema below
4. Store the resulting database ID in `CLAUDE.md` under the "Notion Databases" section

---

## Notion Database Schema

| Field          | Notion Type  | Details                                                                 |
|----------------|-------------|-------------------------------------------------------------------------|
| Title          | title        | Resource name                                                           |
| URL            | url          | Original link                                                           |
| Status         | select       | Options: `Inbox`, `To Review`, `Processed`, `Action Items`, `Archived`  |
| Type           | select       | Options: `Article`, `Video`, `Podcast`, `Book`, `Tool`, `Instagram`, `Threads`, `Twitter`, `Other` |
| Topics         | multi_select | Top-level categories (see taxonomy below)                               |
| Tags           | multi_select | Granular tags auto-assigned by `/triage` (see taxonomy below)           |
| Summary        | rich_text    | Claude-generated summary (max 2000 chars per Notion limit)              |
| Key Insights   | rich_text    | Claude-extracted takeaways (max 2000 chars per Notion limit)            |
| Action Required| checkbox     | Needs follow-up Todoist task                                            |
| Related Task   | url          | Link to Todoist task if created                                         |
| Date Captured  | date         | When the resource was saved                                             |
| Date Reviewed  | date         | When Claude processed it                                                |

---

## Topic & Tag Taxonomy

Topics are the top-level multi-select. Tags are granular labels auto-assigned during triage.

**All 18 Topics:** AI, Crypto, Finance, Career, Leadership, Tech, Health, Fitness, Fashion, Travel, Food, Relationships, Productivity, Learning, Mindset, Culture, Sports, Music

### Professional

**AI:** prompt-engineering, agents, MCP, LLMs, fine-tuning, RAG, evals, computer-use, multimodal, AI-safety, AI-tooling, workflows, automation

**Crypto:** tokenomics, DeFi, regulation, stablecoins, cross-border-payments, CBDCs, blockchain-infra, web3

**Finance:** investing, markets, personal-finance, fintech, payments

**Career:** networking, job-strategy, negotiation, personal-brand

**Leadership:** management, decision-making, team-building, communication

**Tech:** engineering, architecture, developer-tools, APIs, open-source

### Life

**Health:** nutrition, mental-health, sleep, longevity, biohacking

**Fitness:** strength-training, running, mobility, recovery

**Fashion:** style, grooming, wardrobe

**Travel:** destinations, travel-hacking, gear

**Food:** recipes, restaurants, cooking

**Relationships:** dating, marriage, friendships, family

### Growth

**Productivity:** systems, habits, time-management, PKM, focus

**Learning:** reading, courses, skill-building, note-taking

**Mindset:** stoicism, motivation, self-awareness, journaling

### Fun

**Culture:** film, art, design, books, internet-culture

**Sports:** basketball, football, F1, combat-sports

**Music:** hip-hop, R&B, production, playlists

---

## Auto-Tagging Behavior

When `/triage` processes an inbox item:

1. **Fetch** the item's URL content via WebFetch
2. **Analyze** the content to determine:
   - 1-3 Topics (from the 18 topic options)
   - 1-5 Tags (from the tag taxonomy, scoped to the assigned topics)
3. **Generate** Summary (2-3 sentences, under 2000 chars) and Key Insights (bullet points, under 2000 chars)
4. **Determine** Action Required — true when the content contains a specific, actionable takeaway: a tool to try, a technique to implement, a workflow to build, or a concept to study in depth. General interest content = false.
5. **Present to user for review** — show a summary table of proposed changes (Topics, Tags, Type, Summary, Key Insights, Action Required) and wait for confirmation before applying
6. **Update** the Notion item with all fields + set Status to `Processed`
7. If Action Required, create a Todoist task in the appropriate project and link it via Related Task

Tags are drawn from the predefined taxonomy only. The taxonomy is enforced in the skill prompt, not by Notion (which would auto-create new multi_select options). If content doesn't fit existing tags, the skill assigns the closest match — it does not create new tags ad hoc.

---

## Status Pipeline

```
Inbox → (triage processes) → Processed
                           → Action Items (if Action Required = true)
                           → Archived (manual, or via weekly review)
```

- `Inbox`: Newly captured, unprocessed
- `To Review`: Manual-only status for human review — no automated flow sets this
- `Processed`: Claude has summarized and tagged
- `Action Items`: Has an associated Todoist task
- `Archived`: No longer active, retained for reference

---

## `/triage` Skill Updates

The existing `/triage` skill needs these changes:

1. **Remove** Relevance scoring (field removed from schema)
2. **Remove** Source field references
3. **Add** Type detection (infer from URL/content: article, video, podcast, etc.)
4. **Add** Topics assignment (1-3 from the 18 topic options)
5. **Replace** existing tag list with the full taxonomy (scoped to assigned topics)
6. **Retain** the user-review confirmation step before applying changes
7. **Add** Action Required heuristic (replaces relevance-based task creation)
8. **Update** Notion API calls to match new schema field names
9. **Add** 2000-char truncation for Summary and Key Insights fields

---

## What's Deferred (Post-Readwise)

- Capture pipeline automation (Readwise → Notion, Raindrop → Notion, iOS Shortcuts, Gmail)
- KB search/query skill
- Related resource linking
- Surfacing KB items in `/morning-plan` and `/weekly-review`
