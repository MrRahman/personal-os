# KB Search

Search and query the Knowledge Base. Combines Notion KB structured data with Readwise highlight search for deep recall.

## Instructions

### 1. Preflight Check

| Service | Test Call | Required? |
|---------|-----------|-----------|
| Notion | `API-query-data-source` (limit 1, KB database) | Yes |
| Readwise | `reader_list_documents` (limit 1) | No — enables highlight search |

Notion is required. If Readwise is unavailable, note it and continue with Notion-only results.

### 2. Parse Query

Accept natural language queries. Detect intent and map to filters:

| Intent | Example | Filter Strategy |
|--------|---------|----------------|
| By topic | "AI items" | Notion: Topics contains "AI" |
| By tag | "tagged prompt-engineering" | Notion: Tags contains "prompt-engineering" |
| By type | "all videos" | Notion: Type equals "Video" |
| By status | "inbox items" | Notion: Status equals "Inbox" |
| By action | "items needing action" | Notion: Action Required equals true |
| Free text | "MCP servers" | Notion: title search + Readwise vector search |
| Recent | "captured this week" | Notion: Date Captured within date range |
| Combined | "AI articles from this month" | Notion: Topics + Type + Date Captured filters |

Convert relative dates to absolute dates using today's date (see CLAUDE.md conventions).

### 3. Query Notion

Use `API-query-data-source` with the KB database ID (see CLAUDE.md) and appropriate filters.

- Limit: 20 results
- Sort: Date Captured descending
- For free-text queries, use a title search filter

### 4. Search Readwise (optional)

For free-text queries (not pure filter queries), also run:

`readwise_search_highlights(vector_search_term=query)`

This surfaces relevant highlights from across all reading, including items not yet in Notion. Limit to top 5-10 results.

### 5. Present Results

```
## KB Results — "query"

| # | Title | Type | Topics | Status | Date |
|---|-------|------|--------|--------|------|
| 1 | Article Title | Article | AI, Tech | Processed | 2026-03-15 |
| 2 | Video Title | Video | Fitness | Inbox | 2026-03-18 |

### Related Highlights (from Readwise)
- "highlight quote text" — from *Source Title*
- "another highlight" — from *Another Source*
```

If no Notion results found, say so clearly. If Readwise highlights exist but no Notion matches, note: "No KB entries found, but Readwise has relevant highlights. Run `/capture` to import them."

### 6. Offer Actions

Based on results, offer relevant next steps:

- If any results have Status = "Inbox": "Run `/triage` on inbox items?"
- If results surface an actionable insight: "Create a Todoist task from any of these?"
- If Readwise highlights reference uncaptured items: "Run `/capture` to import these to KB?"

## Notes
- Notion database: "AI Knowledge Base" (see CLAUDE.md for database ID)
- Date format: YYYY-MM-DD
- Keep results scannable — one line per item in the table
- For large result sets (20+), note total count and suggest narrowing the query
- Reference CLAUDE.md for conventions