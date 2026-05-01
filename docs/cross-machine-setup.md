# Cross-Machine Personal OS Setup

**Date:** 2026-04-12
**Status:** Implemented on work machine, pending personal machine setup

## What Was Done

Commit `e962166` added cross-machine sync support to Personal OS. The changes solve the problem of working on POS from both work and personal laptops without drift.

### The 5 Sync Layers

| Layer | Solution | Status |
|-------|----------|--------|
| **Code** (skills, commands, templates) | Git (already worked) | Done |
| **Obsidian vault** (daily notes, meetings, etc.) | Obsidian Sync ($4/mo, already paying) | Already syncing |
| **Claude memory** (18 feedback/project files) | Moved into repo `memory/`, symlinked to `~/.claude/projects/` | Done |
| **Global Claude config** (claude.md, settings, global skills) | Tracked in repo `global/`, installed via `scripts/install-global.sh` | Done |
| **Credentials** (.mcp.json, OAuth tokens) | Copy `.mcp.json` once, re-auth Google personal MCP | Pending on personal machine |

### New Repo Structure

```
personal-os/
  memory/           # 18 Claude memory files (tracked, symlinked to ~/.claude/projects/)
  global/           # Canonical global Claude config
    claude.md       # ~/.claude/claude.md
    settings.json   # ~/.claude/settings.json (plugins, model prefs)
    project-registry.md
    skills/         # 5 global skills (discover, idea, kb, new-project, promote)
    commands/       # 5 global commands
  scripts/
    install-global.sh  # Deploys global/ to ~/.claude/
```

### Changes to Existing Files

- `setup.sh` — added: memory symlink creation, install-global call, Google OAuth prompts, Obsidian Sync reminder
- `.mcp.json.example` — added `NPM_CONFIG_REGISTRY` to all npx-based servers
- `CLAUDE.md.example` + `CLAUDE.md` — added `## Memory` section

## Personal Machine Setup (TODO)

### Prerequisites
- macOS with Git, Node.js 18+, Claude Code installed
- Obsidian installed and syncing to same vault

### Steps

1. **Clone:**
   ```bash
   mkdir -p ~/projects && cd ~/projects
   git clone https://github.com/MrRahman/personal-os.git
   cd personal-os
   ```

2. **Copy `.mcp.json` from work machine** (has all API keys):
   ```bash
   scp work-machine:~/projects/personal-os/.mcp.json .
   ```
   Or AirDrop / paste manually.

3. **Run setup.sh** — answer N when asked to overwrite `.mcp.json`:
   ```bash
   ./setup.sh
   ```
   This will: generate CLAUDE.md, create vault dirs, symlink memory, install global config.

4. **Connect Claude.ai integrations:**
   - Settings > Integrations > Google Calendar, Gmail, Slack

5. **Auth Google personal MCP** (first use triggers OAuth, or run manually):
   ```bash
   npx @aaronsb/google-workspace-mcp
   ```

6. **Test:** Run `/morning-plan` — preflight check reports service status.

## Keeping in Sync (Daily)

```bash
# Leaving a machine:
cd ~/projects/personal-os
git add memory/ global/
git commit -m "sync: memory and global config"
git push

# Arriving at the other:
cd ~/projects/personal-os
git pull
```

Obsidian vault syncs automatically. Cloud services (Todoist, Calendar, Notion, Readwise) are cloud-native.

## What Doesn't Sync (and doesn't need to)

- `.mcp.json` — same credentials, copied once
- `.claude/settings.local.json` — permission allowlists build per-machine
- iMessage DB — machine-local, skills degrade gracefully
- Otter cookie refresh — machine-specific Chrome store
