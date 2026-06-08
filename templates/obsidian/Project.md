---
type: project
status: active
area: work
start_date: {{date}}
target_date:
topics:
stakeholders:
code_project:
source_idea:
---

# {{title}}

## Overview
<!-- What is this project? 2-3 sentences on goal and scope -->

## Current Status
<!-- Auto-updated by /reflect — what's the latest? -->

## Key Decisions
<!-- Decisions made, with dates and context -->
-

## Open Questions
<!-- Unresolved items that need answers -->
-

## Resources
<!-- KB items relevant to this project -->

## Timeline
<!-- Key milestones and dates -->
-

## Action Items (Dataview)
```dataview
TASK
FROM "Meetings"
WHERE contains(string(project), this.file.name) AND !completed
SORT file.mtime DESC
LIMIT 20
```

## Related Meetings (Dataview)
```dataview
TABLE date as "Date", file.link as "Meeting"
FROM "Meetings"
WHERE contains(string(project), this.file.name)
SORT date DESC
LIMIT 15
```

## Related Ideas (Dataview)
```dataview
LIST
FROM "Ideas"
WHERE contains(string(project), this.file.name)
SORT date DESC
```

## Key People (Dataview)
```dataview
LIST
FROM "People"
WHERE contains(file.outlinks, this.file.link)
SORT file.mtime DESC
LIMIT 10
```
