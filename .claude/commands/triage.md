# KB Triage

Process items in the Notion "AI Knowledge Base" inbox — summarize content, extract insights, auto-tag with the full taxonomy, detect content type, assign topics, and create Todoist tasks for actionable items.

## Instructions

### 1. Preflight Check

Test access to:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Notion | `search_objects` (limit 1) | Yes |
| Todoist | List projects | Yes |
| WebFetch | N/A (tested per-item) | No |

Both Notion and Todoist are required. If either is unavailable, inform the user and stop.

### 2. Fetch Inbox Items

Query the Notion "AI Knowledge Base" database (see CLAUDE.md for database ID) for items where **Status = "Inbox"**.

Use `mcp__notion-local__API-query-data-source` with the database ID from CLAUDE.md and filter: `{ "property": "Status", "select": { "equals": "Inbox" } }`.

Batch up to 10 items. If more than 10 exist, process the first 10 and tell the user how many remain.

### 3. Process Each Item

For each inbox item:

**a. Fetch content** — If the item has a URL, use WebFetch to retrieve the page content. If the fetch fails, proceed with just the title and any existing notes.

**b. Detect Type** — Infer the content type from the URL and content:
- `Article` — blog posts, news articles, written pieces
- `Video` — YouTube, Vimeo, video content
- `Podcast` — audio episodes, podcast links
- `Book` — book references, book summaries
- `Tool` — software tools, libraries, products
- `Instagram` — Instagram posts or reels
- `Threads` — Threads posts
- `Twitter` — tweets, Twitter/X threads
- `Other` — anything that doesn't fit above

**c. Assign Topics** — Select 1-3 topics from this list:

| Category | Topics |
|----------|--------|
| Professional | AI, Crypto, Finance, Career, Leadership, Tech |
| Life | Health, Fitness, Fashion, Travel, Food, Relationships |
| Growth | Productivity, Learning, Mindset |
| Fun | Culture, Sports, Music |

**d. Auto-tag** — Assign 1-5 tags from the taxonomy below, scoped to the assigned topics:

**AI:** prompt-engineering, agents, MCP, LLMs, fine-tuning, RAG, evals, computer-use, multimodal, AI-safety, AI-tooling, workflows, automation
**Crypto:** tokenomics, DeFi, regulation, stablecoins, cross-border-payments, CBDCs, blockchain-infra, web3
**Finance:** investing, markets, personal-finance, fintech, payments
**Career:** networking, job-strategy, negotiation, personal-brand
**Leadership:** management, decision-making, team-building, communication
**Tech:** engineering, architecture, developer-tools, APIs, open-source
**Health:** nutrition, mental-health, sleep, longevity, biohacking
**Fitness:** strength-training, running, mobility, recovery
**Fashion:** style, grooming, wardrobe
**Travel:** destinations, travel-hacking, gear
**Food:** recipes, restaurants, cooking
**Relationships:** dating, marriage, friendships, family
**Productivity:** systems, habits, time-management, PKM, focus
**Learning:** reading, courses, skill-building, note-taking
**Mindset:** stoicism, motivation, self-awareness, journaling
**Culture:** film, art, design, books, internet-culture
**Sports:** basketball, football, F1, combat-sports
**Music:** hip-hop, R&B, production, playlists

Only use tags from this list. Do not create new tags. If content doesn't fit, assign the closest match.

**e. Summarize** — Write a 2-3 sentence summary of the content. Focus on what it is and why it matters. Keep under 2000 characters (Notion rich_text limit).

**f. Extract insights** — Pull out 2-4 key insights or takeaways. These should be specific and actionable, not generic. Keep under 2000 characters.

Before writing Key Insights, check if the field already has content (populated by `/capture` with the user's Readwise highlights). If content exists, **append** Claude's insights below the existing text under a `**Claude's insights:**` header rather than overwriting. This preserves the user's own highlights. Example:

```
**Your highlights:**
- existing highlight 1
- existing highlight 2

**Claude's insights:**
- Claude-generated insight 1
- Claude-generated insight 2
```

Respect the 2000 character total limit — if existing highlights are long, summarize Claude's insights more concisely.

**g. Determine Action Required** — Set to true when the content contains a specific, actionable takeaway:
- A tool to try or evaluate
- A technique to implement in current work
- A workflow or automation to build
- A concept to study in depth or experiment with

General interest content (news, opinion, entertainment) = false.

### 4. Review with User

Present a summary table:

```
| # | Title | Type | Topics | Tags | Action? | Summary |
|---|-------|------|--------|------|---------|---------|
| 1 | ...   | Article | AI, Tech | agents, MCP | Yes | One-line summary... |
| 2 | ...   | Video | Fitness | strength-training | No | One-line summary... |
```

Then for each item, show the full summary and key insights.

Ask the user:
- "Any adjustments to type, topics, tags, or action items?"
- "Ready to apply?"

Wait for confirmation before proceeding.

### 5. Apply Changes

After user confirms:

**Update Notion items** — For each processed item, update:
- `Type` — the detected content type
- `Topics` — the assigned topics
- `Tags` — the assigned tags
- `Summary` — the generated summary
- `Key Insights` — the extracted insights
- `Action Required` — true/false
- `Status` — change from "Inbox" to "Processed" (or "Action Items" if Action Required)
- `Date Reviewed` — today's date (YYYY-MM-DD)

**Create Todoist tasks** — For each item where **Action Required = true**:
- Create a task in the "Personal" project with the `learning` label
- Task title: descriptive action (e.g., "Try [tool name]", "Read [article] in depth", "Implement [technique]")
- Include the Notion item URL in the task description
- Set priority based on urgency (default p3)
- Store the Todoist task URL in the Notion item's `Related Task` field

### 6. Summary

Display final results:

```
## Triage Complete

- Items processed: X
- Action items created: X
- Remaining in inbox: X

### Tasks Created
- [ ] Task name (Personal)
- ...
```

## Notes
- Date format: YYYY-MM-DD
- If URL fetch fails for an item, note it and process based on title/existing content
- Notion database: "AI Knowledge Base" (see CLAUDE.md for database ID)
- Todoist project: "Personal"
- Reference CLAUDE.md for conventions