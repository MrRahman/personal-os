---
type: topic-moc
topic: {{topic_name}}
---

# {{topic_name}}

## Overview
<!-- What this topic means to you, why it matters -->

## Resources
<!-- Auto-populated by /morning-plan triage -->

## Key People
<!-- People connected to this topic -->

## Active Projects
<!-- Projects related to this topic -->

## Open Questions
<!-- Things you're still exploring -->

## All Tagged Notes (Dataview)
<!-- Install the Dataview plugin to enable this live query — surfaces every note tagged with this topic -->
```dataview
TABLE type as "Type", date as "Date"
FROM "Meetings" OR "Resources" OR "Daily" OR "Projects" OR "Ideas" OR "People"
WHERE contains(string(topics), this.file.name) OR contains(string(file.tags), "topic/" + this.file.name)
SORT date DESC
LIMIT 20
```

## Related Meetings (Dataview)
<!-- Meetings where this topic was discussed -->
```dataview
LIST
FROM "Meetings"
WHERE contains(file.outlinks, this.file.link) OR contains(string(file.content), this.file.name)
SORT file.mtime DESC
LIMIT 10
```
