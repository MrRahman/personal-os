---
name: {{name}}
type: person
company:
role:
relationship: work | personal | family | networking | mentor
email:
phone:
first_met:
last_interaction:
---

# {{name}}

## Context
<!-- How you know this person, their role, what you work on together -->

## Meeting History
<!-- Auto-populated by /reflect — most recent first -->

## Key Topics
<!-- Themes that come up with this person — link to Topic MOCs -->
-

## Open Commitments
<!-- Auto-detected from meetings by /reflect. Resolved items get ~~strikethrough~~. -->
### I owe them
-
### They owe me
-

## Notes
<!-- Anything worth remembering — preferences, communication style, shared interests -->
-

## Recent Meetings (Dataview)
<!-- Install the Dataview plugin to enable this live query -->
```dataview
TABLE date as "Date", file.link as "Meeting"
FROM "Meetings"
WHERE contains(string(attendees), this.file.name)
SORT date DESC
LIMIT 10
```

## Mentioned In (Dataview)
<!-- Surfaces any note in the vault that mentions this person -->
```dataview
LIST
FROM "Meetings" OR "Resources" OR "Daily"
WHERE contains(file.outlinks, this.file.link)
SORT file.mtime DESC
LIMIT 10
```
