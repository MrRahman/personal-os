---
name: prep
description: Prep for any conversation — generates a one-pager from People notes, meetings, commitments, Todoist tasks, and KB resources
---

# Conversation Prep

Generate a one-pager to prepare for any conversation — a scheduled meeting, networking call, interview, or personal catch-up. Works with a person name or company name.

## Instructions

### 1. Parse Input

Accept one of:
- **Person name**: `/prep John` or `/prep Jane Smith`
- **Company name**: `/prep Stripe` or `/prep Acme Corp`
- **Calendar event**: `/prep next meeting` or `/prep 2pm meeting`

If bare (`/prep`), ask: "Who are you prepping for? (person name, company, or describe the meeting)"

### 2. Gather Context

Run these in parallel based on input type:

**If person:**

1. **People note**: Glob `~/Documents/PersonalOS/People/` for matching filename (fuzzy: "John" matches `John-Smith.md`). Read full note — Context, Meeting History (last 5 entries), Key Topics, Open Commitments, Notes.
2. **Recent meetings**: Glob `~/Documents/PersonalOS/Meetings/` for last 30 days, grep for the person's name. Read Summary and Key Points from the 2-3 most recent.
3. **Todoist**: Search for open tasks mentioning this person's name. Also search for `waiting-on` label tasks related to them.
4. **Resources**: Scan the person's Key Topics from their People note. For each topic, grep `~/Documents/PersonalOS/Resources/` for matching items saved in last 30 days.
5. **Projects**: Check if this person is a stakeholder on any active project (grep `~/Documents/PersonalOS/Projects/` for their name). Read project status.
6. **Calendar** (optional): Search today's + tomorrow's events for meetings with this person.

**If company:**

1. **People notes**: Grep `~/Documents/PersonalOS/People/` for the company name in frontmatter. List contacts at this company.
2. **Meetings**: Grep `~/Documents/PersonalOS/Meetings/` (last 60 days) for the company name. Read Summary from matches.
3. **Resources**: Grep `~/Documents/PersonalOS/Resources/` for the company name. Read matching notes.
4. **Readwise**: Use `reader_search_documents(vector_search_term="[company name]")` for relevant highlights.
5. **Projects**: Check if the company maps to an active project.

### 3. Generate One-Pager

Present a clean, scannable prep sheet:

```
# Prep: [Person Name or Company]

## At a Glance
- **Role:** [from People note or inferred]
- **Last interaction:** [date] — [meeting title or channel]
- **Relationship:** [work/family/networking/mentor]
- **Days since contact:** X days [flag if >21 for work, >14 for personal]

## Open Commitments
### I owe them
- [commitment with date and source meeting]
### They owe me
- [commitment with date and source meeting]

## Recent Context
- [2-3 bullet summary of recent meetings — decisions made, open threads, unresolved topics]

## Active Threads
- [Open Todoist tasks involving them]
- [Waiting-on items from them]
- [Unresolved topics from meetings]

## Smart Talking Points
- [Suggested topics based on open tasks, project status, recent KB resources, or relationship context]
- [If exec meeting: include strategic framing — what outcome to drive]

## From Your KB
- [[Resources/slug|Title]] — [one-line relevance to this conversation]
- ...
```

**For company prep**, adjust sections:
- Replace "At a Glance" with company overview (what they do, your contacts there)
- Replace "Open Commitments" with "Your History" (past meetings, interactions)
- Add "Research" section with Readwise highlights and Resource notes

### 4. Offer Actions

After presenting:
- "Write this to today's meeting note?" (if a matching meeting exists)
- "Create a Todoist task for any prep action?" (if something needs doing before the meeting)
- "Draft a message to warm up the relationship?" (if last_interaction > 21 days)

## Notes
- Fuzzy match person names: "John" → John-Smith, "JS" → John-Smith, "MK" → look for common abbreviations
- Keep the one-pager under 30 lines — concise, scannable
- If no People note exists: note it and work with whatever vault data is available
- If no data found at all: "No vault data for [name]. Want to create a People note?"
- Reference CLAUDE.md for paths and conventions
