---
name: capture
description: Pull Readwise Reader inbox items into the Notion Knowledge Base with highlights, then tag them as synced. Runs automatically in /morning-plan — use standalone for on-demand capture.
---

# KB Capture — Readwise → Notion

Pull reading content from Readwise Reader into the Notion Knowledge Base. Imports items from the user's Reader inbox (saved via share sheet, browser extension, etc.). The `synced-to-notion` tag prevents re-import, making this idempotent. Preserves highlights as Key Insights for `/triage` to enhance later.

> **Note:** This runs automatically as part of `/morning-plan`. Use this skill standalone for mid-day or on-demand capture.

## Instructions

### 1. Preflight Check

Test access to both services:

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Readwise | `reader_list_documents` (limit 1) | Yes |
| Notion | `API-query-data-source` (limit 1, KB database) | Yes |

Both are required. If either is unavailable, inform the user and stop.

### 2. Determine Sync Window

Accept an optional date parameter from the user (e.g., "last 3 days", "since 2026-03-15"). Default: last 7 days.

Convert to ISO datetime for `updated_after`. Example: 7 days ago → `2026-03-13T00:00:00Z`.

### 3. Fetch Candidates

Fetch items from the Reader inbox:

`reader_list_documents(location="new", updated_after=since, limit=50, response_fields=["url","title","author","category","tags","summary","reading_progress","published_date","saved_at","source_url"])`

If the call returns 50 items (the cap), note: "Showing 50 of potentially more items. Run again to capture more."

If it returns 0 items: "No new items in your Reader inbox. Save articles via share sheet and they'll appear here." Stop here.

Then fetch highlights for each candidate: `reader_get_document_highlights(document_id)`. Batch these calls in parallel.

### 4. Deduplicate Against Notion

For each candidate, normalize its URL before comparing:
- Prefer `source_url` (original) over the Readwise wrapper URL
- Strip query parameters: `utm_*`, `ref`, `source`, `fbclid`, `gclid`
- Remove trailing slashes

Query the Notion KB database (see CLAUDE.md for database ID) with a URL filter for each normalized URL. Remove items that already exist in Notion from the candidate list.

### 5. Present to User

```
## Readwise → KB Capture

Found X items from Reader inbox. W already in Notion (skipped).

| # | Title | Type | Highlights | Import? |
|---|-------|------|------------|---------|
| 1 | Article Title | Article | 3 | Yes |
| 2 | Video Title | Video | 0 | Yes |

Import all, or adjust? (e.g., "skip 2, 4")
```

Wait for user confirmation before proceeding.

### 6. Create Notion KB Pages

For each confirmed item, use `API-post-page` to create a page in the KB database (see CLAUDE.md for database ID):

| Readwise Field | Notion Field | Notes |
|----------------|-------------|-------|
| title | Title | Direct mapping |
| source_url or url | URL | Prefer source_url (original link) |
| category | Type | Map: article→Article, video→Video, podcast→Podcast, epub→Book, tweet→Twitter, pdf→Article, email→Article, rss→Article, note→Other. Default→Other |
| saved_at | Date Captured | YYYY-MM-DD. Always use saved_at (when the user captured it), NOT published_date (when the source was published) |
| summary | Summary | Readwise summary as seed text (enhanced by /triage later) |
| highlights | Key Insights | See formatting below |
| — | Status | "Inbox" |
| (AI-generated) | Tags | Infer 1-3 tags from content (reuse existing tags when possible: AI-tooling, developer-tools, workflows, automation, PKM, MCP, etc.) |
| (AI-generated) | Topics | Infer 1-2 topics from content (reuse existing: AI, Tech, Productivity, Career, Relationships, etc.) |
| (AI-generated) | Action Required | true if the item is a tool to try, a technique to implement, or directly applicable to an active project. false for reference/awareness items. |

**Key Insights formatting:**

If highlights exist, format as:
```
**Your highlights:**
- highlight text 1
- highlight text 2
```

If no highlights (common for Threads/social posts), generate Claude's insights from the summary:
```
**Claude's insights:**
- Key takeaway 1
- Key takeaway 2
- How it connects to the user's projects/goals (if applicable)
```

Cap at 3-5 insights. Respect the 2000 character Notion rich_text limit.

**Leave blank** (these are `/triage`'s responsibility): Related Task, Date Reviewed.

### 7. Tag and Archive Readwise Documents

After each successful Notion page creation:

1. Tag the document: `reader_add_tags_to_document(document_id, tag_names=["synced-to-notion"])`
2. Archive the document: `reader_move_documents(document_ids=[document_id], location="archive")`

This keeps the Reader inbox clean — synced items move to archive automatically so the user never needs to open Reader to triage.

### 8. Summary

```
## Capture Complete

Items imported: X | Highlights captured: Y
Skipped (already in Notion): Z | Readwise items tagged: X

Next: Run /triage to process these items
```

## Notes
- Date format: YYYY-MM-DD
- Prefer source_url over Readwise wrapper URL for both dedup and Notion storage
- One-way flow: Readwise → Notion only. No reverse sync.
- If a highlight fetch fails for a document, create the Notion page without highlights and note the failure
- Notion database: "AI Knowledge Base" (see CLAUDE.md for database ID)
- Reference CLAUDE.md for conventions
