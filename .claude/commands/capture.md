# KB Capture — Readwise → Notion

Pull reading content from Readwise Reader into the Notion Knowledge Base. Only imports items the user has actively engaged with (archived or shortlisted). Preserves highlights as Key Insights for `/triage` to enhance later.

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

Run two calls in parallel:

- `reader_list_documents(location="archive", updated_after=since, limit=50, response_fields=["url","title","author","category","tags","summary","reading_progress","published_date","saved_at","source_url"])`
- `reader_list_documents(location="shortlist", updated_after=since, limit=50, response_fields=["url","title","author","category","tags","summary","reading_progress","published_date","saved_at","source_url"])`

If either returns 50 items (the cap), note: "Showing 50 of potentially more items from [location]. Run again to capture more."

If both return 0 items: "No new items to capture. Save articles to Readwise and archive or shortlist them when you're ready." Stop here.

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

Found X items (Y archived, Z shortlisted). W already in Notion (skipped).

| # | Title | Type | Source | Highlights | Import? |
|---|-------|------|--------|------------|---------|
| 1 | Article Title | Article | archive | 3 | Yes |
| 2 | Video Title | Video | shortlist | 0 | Yes |

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
| published_date or saved_at | Date Captured | YYYY-MM-DD, prefer published_date, fall back to saved_at |
| summary | Summary | Readwise summary as seed text (enhanced by /triage later) |
| highlights | Key Insights | See formatting below |
| — | Status | "Inbox" |

**Key Insights formatting from highlights:**

Format as:
```
**Your highlights:**
- highlight text 1
- highlight text 2
- highlight text 3
```

Cap at 5-7 highlights (by position in document). If more exist, append: "\n\n*X more highlights available in Readwise.*"

Respect the 2000 character Notion rich_text limit — truncate if needed, noting truncation.

**Leave blank** (these are `/triage`'s responsibility): Topics, Tags, Action Required, Related Task, Date Reviewed.

### 7. Tag Readwise Documents

After each successful Notion page creation, tag the Readwise document:

`reader_add_tags_to_document(document_id, tags=["synced-to-notion"])`

This lets the user see what's been captured without leaving Reader.

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