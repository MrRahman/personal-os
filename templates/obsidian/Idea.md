---
date: {{date}}
type: idea
status: seed
topics:
tags:
source: conversation
project:
goal:
---

# {{title}}

## Spark
<!-- What's the idea? 2-3 sentences captured from conversation -->

## Why It Matters
<!-- Why is this worth pursuing? What problem does it solve? -->

## Shape
<!-- How might this work? Early thinking, constraints, questions -->

## Connections
<!-- Auto-populated: related People, Meetings, Resources, Projects -->

## Related Notes (Dataview)
```dataview
LIST
FROM "Meetings" OR "Resources" OR "Projects" OR "Daily"
WHERE contains(file.outlinks, this.file.link)
SORT file.mtime DESC
LIMIT 10
```
