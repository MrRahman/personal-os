#!/usr/bin/env python3
"""Redact secret-shaped strings before they reach logs.

Used by the background wrappers' run-log writers (otter-sync.sh, daily-brief.sh).
A denied actor Bash command that hard-coded a token (we saw exactly this in the
2026-06-04 otter-sync degraded loop — the actor pasted OTTER_SESSION_COOKIE into a
Bash fallback, which landed in .claude/logs/*.jsonl via the `permission_denials`
envelope) must never be persisted in cleartext.

Two layers:
  1. EXACT-MATCH the live secret values pulled from .mcp.json (`secrets_from_mcp`).
     Bulletproof regardless of JSON-escaping around the value — the value itself
     (a cookie/token body) contains no escapable chars.
  2. PATTERN backstop for tokens that never appear in .mcp.json (e.g. a Bearer
     token embedded in transcript text).

Importable (`from redact import redact_text, secrets_from_mcp`) or a stdin→stdout
filter (`… | python3 redact.py`).
"""
from __future__ import annotations

import json
import re
import sys

# (pattern, replacement) — keep the identifying prefix, mask the secret body.
_PATTERNS = [
    (re.compile(r'(OTTER_SESSION_COOKIE\s*[=:]\s*\\?["\']?)[A-Za-z0-9]{16,}'), r"\1[REDACTED]"),
    (re.compile(r"(sessionid=)[A-Za-z0-9]{16,}"), r"\1[REDACTED]"),
    (re.compile(r'(SLACK_MCP_XOX[CD]_TOKEN\s*[=:]\s*\\?["\']?)[A-Za-z0-9-]{8,}'), r"\1[REDACTED]"),
    (re.compile(r"\b(xox[cdbpsra]-)[A-Za-z0-9-]{8,}"), r"\1[REDACTED]"),
    (re.compile(r"\b(ntn_)[A-Za-z0-9]{8,}"), r"\1[REDACTED]"),
    (re.compile(r"\b(sk-ant-)[A-Za-z0-9._-]{12,}"), r"\1[REDACTED]"),
    (re.compile(r"(Bearer\s+)[A-Za-z0-9._-]{12,}"), r"\1[REDACTED]"),
]


def redact_text(s: str, extra_secrets=None) -> str:
    """Mask secret-shaped substrings. `extra_secrets`: exact strings (e.g. the live
    cookie/tokens from .mcp.json) replaced verbatim — escaping-proof — before the
    pattern pass. Non-secret text is left untouched."""
    if not s:
        return s
    for sec in (extra_secrets or []):
        if sec and len(sec) >= 8:
            s = s.replace(sec, "[REDACTED]")
    for rx, repl in _PATTERNS:
        s = rx.sub(repl, s)
    return s


def secrets_from_mcp(mcp_path: str) -> list:
    """Extract secret-shaped env *values* from .mcp.json for exact-match redaction.
    Best-effort: never raises (logging must not be blocked by a missing/garbled file)."""
    out = []
    try:
        d = json.load(open(mcp_path))
        for srv in d.get("mcpServers", {}).values():
            for k, v in (srv.get("env", {}) or {}).items():
                if isinstance(v, str) and len(v) >= 12 and re.search(
                        r"(COOKIE|TOKEN|KEY|SECRET|PASS)", k, re.I):
                    out.append(v)
    except Exception:
        pass
    return out


if __name__ == "__main__":
    # Filter mode: optional argv[1] = path to .mcp.json for exact-match secrets.
    extra = secrets_from_mcp(sys.argv[1]) if len(sys.argv) > 1 else None
    sys.stdout.write(redact_text(sys.stdin.read(), extra))
