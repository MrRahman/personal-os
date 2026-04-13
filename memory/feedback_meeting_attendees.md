---
name: Meeting notes must include all attendees from calendar invite
description: Always pull the full attendee list from Google Calendar when creating meeting notes — don't just list known People
type: feedback
---

When creating meeting notes in /morning-plan, pull ALL attendees from the Google Calendar invite (who accepted or haven't responded) and add them as wikilinks in the attendees frontmatter.

**Why:** The user noticed the Executive Staff Meeting note only had 2 people listed when the actual calendar invite had 14+ attendees. Meeting notes should reflect who was actually in the room.

**How to apply:**
- Use `condenseEventDetails=false` to get the full attendee list from gcal_list_events
- Add all attendees who accepted or haven't declined as `[[People/First-Last]]` wikilinks
- For large meetings (10+), still include all attendees — don't cap at 5
- This applies to meeting note creation in Step 6 of morning-plan AND to sync-meetings when updating notes
