# MCP Setup — Slack & Work Gmail

**Date:** 2026-04-17
**Why:** The claude.ai web integrations for Work Gmail (srahman@ripple.com) and Slack don't expose tools to Claude Code CLI. `/morning-plan` was silently missing the "Respond" (work email) and "Slack Later" sections. This runbook wires both into the project's stdio MCP config so they work in every Claude Code session.

## What changed in the repo

- `CLAUDE.md`
  - **MCP Services table** — replaced `claude.ai integration` rows for Work Gmail, Work Calendar, Slack with stdio MCP servers. Work Google now routes through the same `@aaronsb/google-workspace-mcp` server as the personal account (multi-account mode).
  - **Google Account Mapping** — updated to show both accounts using `manage_calendar` / `manage_email` with an explicit `email` argument. No more split-brain (claude.ai vs stdio).
  - **New `## Slack MCP` section** — documents `slack-mcp-server` (korotovsky), the `conversations_search_messages` tool, and how to use `is:saved` for morning-plan's Later section.

## What you must do (sandbox blocked me from writing these)

The Claude sandbox in this session prevented me from editing `.mcp.json` (contains credentials) and `~/.config/google-workspace-mcp/accounts.json` (outside working dir). Paste the two file contents below manually.

### Step 1 — Add the work account to google-workspace-mcp

Overwrite `~/.config/google-workspace-mcp/accounts.json` with:

```json
{
  "accounts": [
    {
      "email": "1srahman@gmail.com",
      "category": "personal"
    },
    {
      "email": "srahman@ripple.com",
      "category": "work"
    }
  ]
}
```

One-liner:

```bash
cat > ~/.config/google-workspace-mcp/accounts.json <<'EOF'
{
  "accounts": [
    { "email": "1srahman@gmail.com", "category": "personal" },
    { "email": "srahman@ripple.com", "category": "work" }
  ]
}
EOF
```

### Step 2 — Add the Slack MCP server to `.mcp.json`

Open `/Users/sulaimanrahman/projects/personal-os/.mcp.json` and add this block inside `mcpServers` (after the `google-personal` entry, before the closing brace):

```json
    ,"slack": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "slack-mcp-server@latest",
        "--transport",
        "stdio"
      ],
      "env": {
        "SLACK_MCP_XOXC_TOKEN": "PASTE_XOXC_HERE",
        "SLACK_MCP_XOXD_TOKEN": "PASTE_XOXD_HERE",
        "NPM_CONFIG_REGISTRY": "https://registry.npmjs.org"
      }
    }
```

(Fix up the comma placement if your editor/linter complains — the leading comma only belongs if `slack` is not the first key.)

### Step 3 — Grab your Slack browser tokens (automated via dedicated profile)

**Preferred path (eliminates the logout loop):** use the `refresh-slack-tokens.py` script + dedicated Playwright profile so extracting tokens doesn't kick your Slack desktop app session. See `CLAUDE.md` → "Slack Token Lifecycle" for the full design.

**One-time setup:**

```bash
# Create isolated venv (Playwright is a big dep; keep it scoped)
python3 -m venv ~/.local/venvs/slack-refresh
~/.local/venvs/slack-refresh/bin/pip install playwright
~/.local/venvs/slack-refresh/bin/playwright install chromium

# First-time login: opens a visible Chromium window
~/.local/venvs/slack-refresh/bin/python mcp-servers/refresh-slack-tokens.py --login
```

Log into Ripple Slack in the Chromium window that opens. The script waits up to 5 minutes for login to complete, then extracts `xoxc` + `xoxd` and writes them into `.mcp.json` automatically. The profile at `~/.config/personal-os/slack-browser/` persists, so future refreshes run headless.

**Ongoing refresh is automatic:**
- `launchd` runs the script every weekday at 8:03am + 4:33pm.
- SessionStart hook validates on every Claude Code startup.
- If tokens are rejected mid-session, run `python3 mcp-servers/refresh-slack-tokens.py` and restart Claude Code.

**On Enterprise Slack:** If Ripple's Slack rejects the user-agent, add to the `slack` env block in `.mcp.json`:

```json
"SLACK_MCP_USER_AGENT": "Mozilla/5.0 ...",  // copy from DevTools Network tab, any request
"SLACK_MCP_CUSTOM_TLS": "true"
```

The korotovsky README flags this for higher-security enterprises.

<details>
<summary><strong>Manual DevTools fallback</strong> (use if Playwright setup fails or you need a one-off extraction)</summary>

1. Open `https://app.slack.com/client/...` (the Ripple Slack workspace) in Chrome or Firefox.
2. Open DevTools (Cmd+Option+I on macOS).
3. **Get `xoxc` token:**
   - Go to the **Console** tab.
   - Type `allow pasting` and hit Enter (browser safety gate).
   - Paste this and hit Enter:
     ```js
     JSON.parse(localStorage.localConfig_v2).teams[document.location.pathname.match(/^\/client\/([A-Z0-9]+)/)[1]].token
     ```
   - Copy the returned string (starts with `xoxc-`).
4. **Get `xoxd` token:**
   - Go to **Application** tab → **Storage** → **Cookies** → `https://app.slack.com`.
   - Find the cookie literally named `d` (single letter).
   - Double-click its Value, copy it. (Starts with `xoxd-`.)
5. Paste both into the `.mcp.json` block from Step 2 in place of `PASTE_XOXC_HERE` / `PASTE_XOXD_HERE`.

**Warning:** this path is what creates the auth loop — extracting from your main browser session is what Slack reads as "user switched devices," rotating the session and logging out your desktop app. Only use this as a last resort.

</details>

### Step 4 — Authenticate the work Google account

Start a **new** Claude Code session in this project (so the updated `.mcp.json` is picked up), then run this in the Claude chat:

```
Use manage_accounts to authenticate my work account.
```

Claude will invoke `mcp__google-personal__manage_accounts` with `{"operation": "authenticate"}`. A browser window opens. Sign in with `srahman@ripple.com` and grant the requested scopes. The server writes credentials to `~/.local/share/google-workspace-mcp/credentials/srahman_at_ripple_dot_com.json`.

Verify:

```
Use manage_accounts to list accounts.
```

Expect both emails, both status = authenticated.

### Step 5 — Validate in a fresh Claude Code session

```bash
cd ~/projects/personal-os
claude mcp list
```

You should see (in addition to the existing servers):

- `slack` — connected
- `google-personal` — still shows one process, but now serves both accounts

In-session sanity check:

```
Use manage_email to search my work inbox for messages from today.
Use conversations_search_messages with search_query "is:saved" to pull Slack saved items.
```

If both return data, `/morning-plan` will light up its "Respond" and "Slack Later" sections on the next run.

## Known blockers

### Ripple Slack OAuth app (not needed for stealth mode, but for the record)
The stealth mode (xoxc + xoxd) in Step 3 doesn't require any admin install. If you ever want to switch to `xoxp` (User OAuth) you'd need Ripple IT to either (a) whitelist a custom Slack app you create at api.slack.com/apps, or (b) allow installs from the Slack App Directory. Most orgs gate `search:read` scope behind IT approval because it can read anything the user can see. Ask pattern for IT:

> Hi IT, I'd like to install a custom Slack app (private, installed only to my user) with these User OAuth scopes: channels:history, groups:history, im:history, mpim:history, search:read, users:read. It's an MCP server (slack-mcp-server) that lets my local AI assistant summarize my own messages. The app is not published and only my user token will exist. Can you approve the install?

### Ripple Google Workspace OAuth (may block the authenticate flow)
When you run `manage_accounts authenticate` for srahman@ripple.com, Google will show the consent screen for the OAuth client ID baked into `.mcp.json` (`114049050453-pgpsc9p8l9vqaiq5t5mcbm6rvjj01mhi...`). If Ripple's Google Workspace admin has "Trust third-party apps" restricted (common at fintech/crypto companies), the flow will 403 with "This app is blocked by your administrator." Two fixes:

1. **Ask Ripple IT to allowlist the OAuth client ID** — paste them the client ID above and the scopes requested (Gmail, Calendar read/write).
2. **Create a new OAuth client in a Google Cloud project you own**, mark it Internal only if Ripple gives you GCP access, and replace `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` in `.mcp.json`. Requires Ripple-provisioned GCP, which you likely don't have.

Option 1 is the realistic path. If IT says no, work Gmail stays on claude.ai web only and `/morning-plan` in CLI will skip the work-email section (preflight check will note it).

### xoxc/xoxd token rotation
These expire when Slack rotates session cookies (roughly every few weeks, or on password change / forced re-auth). If Slack starts failing with 401 in Claude, repeat Step 3. Persistent refresh is only possible with xoxp (OAuth) which requires Step 1 of the blocker section above.

## Rollback

To undo everything: remove the `slack` block from `.mcp.json`, remove the srahman@ripple.com entry from `accounts.json`, delete `~/.local/share/google-workspace-mcp/credentials/srahman_at_ripple_dot_com.json`, and revert the CLAUDE.md MCP Services section. Git has the originals.
