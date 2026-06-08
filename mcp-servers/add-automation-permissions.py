#!/usr/bin/env python3
"""Add Personal OS v3.0 automation permission rules to project settings.local.json.

One-time helper for the user to grant the narrow run-permissions the v3.0
background jobs need. Idempotent — safe to run more than once.

Run:  python3 mcp-servers/add-automation-permissions.py

Grants ONLY: launchctl (the job manager) + the named wrapper/spike scripts.
NOT raw `claude` — so no arbitrary headless agent can be launched, and the
work-read-only allowlists baked into the scripts remain the safety boundary.
"""
import json
import pathlib

SETTINGS = pathlib.Path(
    "/Users/sulaimanrahman/projects/personal-os/.claude/settings.local.json"
)

NEW_RULES = [
    "Bash(launchctl:*)",
    "Bash(bash /tmp/personalos-spike.sh:*)",
    "Bash(bash /Users/sulaimanrahman/projects/personal-os/mcp-servers/daily-brief.sh:*)",
    "Bash(bash /Users/sulaimanrahman/projects/personal-os/mcp-servers/otter-sync.sh:*)",
    "Bash(bash /Users/sulaimanrahman/projects/personal-os/mcp-servers/cadence-draft.sh:*)",
    # Deterministic meeting-note helper used by the brief (shell pre-creation) +
    # otter-sync (fresh-note path) + /sync-meetings. Read-only path logic +
    # CREATE-ONLY shell stamping; no deletes. Safe to allow.
    "Bash(python3 /Users/sulaimanrahman/projects/personal-os/mcp-servers/meeting_notes.py:*)",
]


def main() -> None:
    data = json.loads(SETTINGS.read_text())
    allow = data.setdefault("permissions", {}).setdefault("allow", [])
    added = [r for r in NEW_RULES if r not in allow]
    allow.extend(added)
    SETTINGS.write_text(json.dumps(data, indent=2) + "\n")
    print(f"added {len(added)} rule(s) — {len(allow)} total in permissions.allow")
    for r in added:
        print("  +", r)
    if not added:
        print("  (all rules already present — nothing to do)")


if __name__ == "__main__":
    main()
