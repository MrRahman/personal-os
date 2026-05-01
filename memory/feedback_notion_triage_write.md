---
name: Notion triage must write to Notion, not just Obsidian
description: In /morning-plan Phase B (triage), the Notion API-patch-page call is synchronous — not deferred alongside vault writes. Computing tags/insights only in memory leaves the Notion inbox stuck with empty fields.
type: feedback
---

During /morning-plan Step 3 Phase B (triage), the Notion update (Tags, Topics, Key Insights, Action Required, Status, Date Reviewed) MUST happen immediately via `API-patch-page`. It is not part of the Step 8 "deferred writes" batch.

**Why:** On 2026-04-16, a /morning-plan run captured 4 items into Notion, then computed tags and insights for each, wrote them to Obsidian Resource notes, but never wrote the computed values back to Notion. Items stayed in Status="Inbox" with empty Tags/Topics/Key Insights and null Date Reviewed. The Obsidian notes looked complete, which masked the broken Notion state. Root cause: Phase B item 3 said "Update each Notion item" but adjacent items 4 and 5 explicitly deferred vault writes to Step 8, and the deferral pattern bled into the Notion step. Step 8's Write order only listed vault writes, so Notion was never updated. Backfilling after the fact required the user to notice a specific column (Date Reviewed / Key Insights) was empty.

**How to apply:** When running /morning-plan, treat the Notion `API-patch-page` call in Phase B step 3 as the one required synchronous write inside triage — independent of user confirmation and independent of the vault-write gate in Step 8. After Phase B completes, verify each processed item has non-empty Tags, non-empty Key Insights, and a Date Reviewed date; retry any item that failed. If the skill wording ever becomes ambiguous again, err on the side of writing to Notion during triage — the Obsidian Resource note is downstream and carries a `notion_id`, so Notion is the source of truth.
