# START HERE — bringing Personal OS to life on a new machine

You've cloned this repo onto a machine that isn't your primary one (e.g. a travel/personal laptop).
This file is the bootstrap. **Fastest path: open `claude` in this folder and say
*"Read START-HERE.md and walk me through getting Personal OS running on this machine."*** —
or just follow the steps yourself.

## Prerequisites
- macOS with **Node 18+**, **git**, **gh**, and **Claude Code** installed
- **Obsidian** installed and signed into your sync (the vault is NOT in git — see below)

## Setup (one time on this machine)
1. **You already cloned `personal-os`.** Good.
2. **Get your credentials over (NOT in git).** AirDrop `.mcp.json` from your primary Mac into this
   repo's root. It holds every API token and is intentionally gitignored — **never commit it.**
3. **Run setup:** `./setup.sh` — answer **N** when asked to overwrite `.mcp.json`. This symlinks
   `memory/` into Claude's expected path, installs the global config, and creates vault dirs.
4. **Re-auth the things that are machine-bound:**
   - Google **personal** MCP: in Claude, call `manage_accounts` → `operation: authenticate, category: personal`, approve in browser. (Running `npx … auth` does NOT re-auth — it only starts the server.)
   - Work Google + Slack: reconnect the **claude.ai connectors** (Settings → Integrations).
   - Otter / Slack browser tokens may need a refresh — see `CLAUDE.md` recovery paths if they 401.
5. **The Obsidian vault syncs itself.** Once Obsidian is signed in, `~/Documents/PersonalOS/`
   appears via your sync. Do not copy it by hand.

## ⚠️ Single-host rule (important on a second machine)
Your vault is **cloud-synced** across machines. The background automation (`daily-brief`,
`otter-sync` launchd jobs) must run on **exactly one** machine or you'll get duplicate notes.
**Do NOT load the launchd plists here.** Use Personal OS **interactively only** on this machine —
run `claude`, then `/day`, `/prep`, `/weekly-review`, etc. That's safe and won't collide.

## To resume daily use
```
claude
/day        # reads the brief (or builds one on first open), then adjust / confirm / reflect
```

## What is NOT in this repo (and how it gets here)
| Thing | Why not in git | How to get it |
|---|---|---|
| `.mcp.json` | secrets | AirDrop from primary Mac (step 2) |
| Obsidian vault | cloud-synced | auto via Obsidian sign-in |
| `.claude/state`, `.claude/logs` | machine-local | regenerated automatically |
| `v3.0-chief-of-staff` branch | local only | leave it — do not push or rely on it |

When you're back on your primary Mac, that machine remains the single host for background
automation. Nothing you do interactively here needs to be "merged back" beyond a normal `git pull`.
