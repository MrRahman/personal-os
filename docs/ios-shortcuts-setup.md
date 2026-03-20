# iOS Shortcuts Setup Guide — Quick Task & Save to KB

Two iOS Shortcuts that capture content from any app's Share Sheet into your Personal OS pipeline.

```
iOS Share Sheet
    ├── "Quick Task" → Todoist Inbox → /morning-plan surfaces it
    └── "Save to KB" → Notion KB (Inbox) → /triage processes it
```

---

## Prerequisites

### Todoist API Token

1. Open [todoist.com/prefs/integrations](https://todoist.com/prefs/integrations)
2. Scroll to **Developer** → copy your **API token**
3. Keep it handy — you'll paste it into the shortcut

### Notion Integration Token

1. Open [notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click **New integration** → name it `iOS Shortcuts` → select your workspace → **Submit**
3. Copy the **Internal Integration Secret** (starts with `ntn_`)
4. Go to your **AI Knowledge Base** database in Notion → click `...` → **Connections** → add `iOS Shortcuts`

---

## Shortcut 1: Quick Task

Captures action items to Todoist Inbox from any app.

### API Details

- **Endpoint:** `POST https://api.todoist.com/rest/v2/tasks`
- **Auth:** `Bearer <your-todoist-api-token>`
- **Content-Type:** `application/json`

**Payload:**
```json
{
  "content": "[task title]",
  "description": "Captured via iOS Shortcut\n\n[original shared text]",
  "priority": 1
}
```

> Priority 1 = P4 (Todoist's default). `/morning-plan` will triage it.

### Step-by-Step Setup

1. Open **Shortcuts** app → tap **+** to create a new shortcut
2. Name it **Quick Task**
3. Tap the share icon at the top → enable **Show in Share Sheet**
4. Set **Receive** to: **Any** (text, URLs, Safari web pages, etc.)

Now add these actions in order:

#### Action 1 — Get shared text

- Add: **Get Text from Input**
  - Input: `Shortcut Input`

#### Action 2 — Save to variable

- Add: **Set Variable**
  - Variable name: `SharedText`
  - Input: output of previous action

#### Action 3 — Ask for task title

- Add: **Ask for Input**
  - Prompt: `Task title:`
  - Input type: **Text**
  - Default Answer: `SharedText` variable

#### Action 4 — Set variable for title

- Add: **Set Variable**
  - Variable name: `TaskTitle`
  - Input: output of Ask for Input

#### Action 5 — Build JSON body

- Add: **Dictionary**
  - Add these key-value pairs:
    | Key | Type | Value |
    |-----|------|-------|
    | `content` | Text | `TaskTitle` variable |
    | `description` | Text | `Captured via iOS Shortcut` + newline + newline + `SharedText` variable |
    | `priority` | Number | `1` |

#### Action 6 — POST to Todoist

- Add: **Get Contents of URL**
  - URL: `https://api.todoist.com/rest/v2/tasks`
  - Method: **POST**
  - Headers:
    | Key | Value |
    |-----|-------|
    | `Authorization` | `Bearer <your-todoist-api-token>` |
    | `Content-Type` | `application/json` |
  - Request Body: **JSON** → set to the Dictionary from Action 5

#### Action 7 — Show confirmation

- Add: **Show Notification**
  - Title: `Task added to Inbox`
  - Body: `TaskTitle` variable

---

## Shortcut 2: Save to KB

Saves articles, links, and content to Notion Knowledge Base as Inbox items.

### API Details

- **Endpoint:** `POST https://api.notion.com/v1/pages`
- **Auth:** `Bearer <your-notion-integration-token>`
- **Notion-Version:** `2022-06-28`
- **Content-Type:** `application/json`

**Payload:**
```json
{
  "parent": { "database_id": "32873b7c-bcd4-816c-8f24-e2585c9668ea" },
  "properties": {
    "Title": { "title": [{ "text": { "content": "[title]" } }] },
    "URL": { "url": "[url or null]" },
    "Status": { "select": { "name": "Inbox" } },
    "Date Captured": { "date": { "start": "YYYY-MM-DD" } }
  }
}
```

### Step-by-Step Setup

1. Open **Shortcuts** app → tap **+** to create a new shortcut
2. Name it **Save to KB**
3. Tap the share icon at the top → enable **Show in Share Sheet**
4. Set **Receive** to: **Any** (URLs, text, Safari web pages, articles)

Now add these actions in order:

#### Action 1 — Get URLs from input

- Add: **Get URLs from Input**
  - Input: `Shortcut Input`

#### Action 2 — Count URLs

- Add: **Count**
  - Input: output of Get URLs

#### Action 3 — Branch: URL vs plain text

- Add: **If**
  - Condition: Count **is greater than** `0`

**If branch (URL found):**

#### Action 4a — Get first URL

- Add: **Get Item from List**
  - Get: **First Item**
  - Input: output of Get URLs from Input (Action 1)

#### Action 5a — Set URL variable

- Add: **Set Variable**
  - Variable name: `PageURL`

#### Action 6a — Get page title

- Add: **Get Name of URL**
  - Input: `PageURL` variable

#### Action 7a — Set title variable

- Add: **Set Variable**
  - Variable name: `PageTitle`

**Otherwise branch (plain text):**

#### Action 4b — Get text from input

- Add: **Get Text from Input**
  - Input: `Shortcut Input`

#### Action 5b — Set title variable

- Add: **Set Variable**
  - Variable name: `PageTitle`

#### Action 6b — Set URL to nothing

- Add: **Text**
  - Content: (leave empty)
- Add: **Set Variable**
  - Variable name: `PageURL`

**End If**

#### Action 8 — Ask user to confirm title

- Add: **Ask for Input**
  - Prompt: `Title:`
  - Input type: **Text**
  - Default Answer: `PageTitle` variable

#### Action 9 — Update title variable

- Add: **Set Variable**
  - Variable name: `PageTitle`
  - Input: output of Ask for Input

#### Action 10 — Get today's date

- Add: **Date**
  - Set to: **Current Date**
- Add: **Format Date**
  - Format: **Custom** → `yyyy-MM-dd`

#### Action 11 — Set date variable

- Add: **Set Variable**
  - Variable name: `TodayDate`

#### Action 12 — Build JSON body

- Add: **Text**
  - Content (paste this exactly, replacing variables):

```
{"parent":{"database_id":"32873b7c-bcd4-816c-8f24-e2585c9668ea"},"properties":{"Title":{"title":[{"text":{"content":"[PageTitle]"}}]},"URL":{"url":"[PageURL]"},"Status":{"select":{"name":"Inbox"}},"Date Captured":{"date":{"start":"[TodayDate]"}}}}
```

> In Shortcuts, tap and hold each `[variable]` placeholder and replace with the corresponding variable. For `PageURL`, use the variable directly — if it's empty, Shortcuts will insert an empty string. See the Troubleshooting section if you get 400 errors from null URLs.

#### Action 13 — POST to Notion

- Add: **Get Contents of URL**
  - URL: `https://api.notion.com/v1/pages`
  - Method: **POST**
  - Headers:
    | Key | Value |
    |-----|-------|
    | `Authorization` | `Bearer <your-notion-integration-token>` |
    | `Content-Type` | `application/json` |
    | `Notion-Version` | `2022-06-28` |
  - Request Body: **File** → set to the Text output from Action 12

#### Action 14 — Show confirmation

- Add: **Show Notification**
  - Title: `Saved to Knowledge Base`
  - Body: `PageTitle` variable

---

## Testing Checklist

### Quick Task

- [ ] Share text from **WhatsApp** → task appears in Todoist Inbox
- [ ] Share text from **Signal** → task appears in Todoist Inbox
- [ ] Share a **Safari URL** → task title is editable, task appears in Inbox
- [ ] Share from **Instagram** (copy link) → task appears in Inbox
- [ ] Run `/morning-plan` → shortcut-captured tasks surface in Inbox section

### Save to KB

- [ ] Share a **Safari URL** → Notion page created with title + URL + Status=Inbox + today's date
- [ ] Share **plain text** (no URL) → Notion page created with text as title, no URL
- [ ] Share from **WhatsApp** (forwarded link) → URL extracted, page created
- [ ] Share from **Instagram** (copy link) → URL captured in Notion
- [ ] Run `/triage` → shortcut-captured items appear and get processed

---

## Troubleshooting

### 401 Unauthorized

- **Todoist:** Verify your API token at [todoist.com/prefs/integrations](https://todoist.com/prefs/integrations). Tokens don't expire but can be revoked.
- **Notion:** Verify your integration token. Make sure the integration is connected to the AI Knowledge Base database (database `...` menu → Connections).

### 400 Bad Request

- **Todoist:** Check that the Dictionary keys match exactly: `content`, `description`, `priority`. Priority must be a number, not text.
- **Notion:** The most common cause is the `URL` field receiving an empty string `""` instead of `null`. If sharing plain text, you may need to use an **If** block to build two separate JSON bodies — one with the URL field and one without it.
- **Notion:** Verify property names match your database exactly: `Title`, `URL`, `Status`, `Date Captured`. These are case-sensitive.

### Shortcut doesn't appear in Share Sheet

1. Go to **Settings** → **Shortcuts** → **Advanced** → enable **Allow Sharing Large Amounts of Data**
2. Make sure the shortcut has **Show in Share Sheet** enabled (tap the shortcut's share icon)
3. After creating a new shortcut, it may take a moment to appear. Try restarting the Shortcuts app.

### Notion URL field null handling

If you get errors when sharing plain text (no URL), modify the Save to KB shortcut:

- In the **If** branch (URL found): build the full JSON with `"URL": {"url": "[PageURL]"}`
- In the **Otherwise** branch: build the JSON without the URL property entirely, or set it as `"URL": {"url": null}`

The Notion API accepts `null` for URL fields but not empty strings.

### Share Sheet shows wrong input

Some apps share content differently. If the shortcut receives unexpected input:

- Add a **Show Alert** action at the start (temporarily) to inspect what `Shortcut Input` contains
- Adjust the input extraction actions based on what each app provides
