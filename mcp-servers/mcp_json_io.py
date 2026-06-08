#!/usr/bin/env python3
"""Atomic, validated, 0600 writes to .mcp.json — the file holding every MCP's live
credentials.

The Slack (weekdays 8:03/16:33) and Otter (Mon/Thu 9am) refreshers, plus any future
self-heal, can fire close together. A plain `write_text()` after a regex-sub risks
a torn or invalid file that breaks ALL MCPs at once. This helper:
  - serializes writers with an flock (so two refreshers can't interleave);
  - validates the new content parses as JSON BEFORE swapping — a botched regex sub
    raises instead of corrupting the file;
  - writes a temp file in the same dir + os.replace() (atomic on POSIX);
  - enforces 0600 so credentials aren't group/world-readable.
"""
from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path

try:
    import fcntl
    _HAVE_FCNTL = True
except ImportError:  # pragma: no cover - non-POSIX
    _HAVE_FCNTL = False

_LOCK = "/tmp/personalos-mcp-json.lock"


def write_mcp_json_atomic(path, content: str) -> None:
    """Atomically replace `path` with `content` (validated JSON, mode 0600),
    serialized across processes via an flock. Raises ValueError if `content` is not
    valid JSON — the caller then aborts rather than persist a corrupt credentials
    file. The original file is left untouched on any failure."""
    path = Path(path)
    try:
        json.loads(content)
    except (json.JSONDecodeError, ValueError) as e:
        raise ValueError(f"refusing to write invalid JSON to {path}: {e}") from e

    lf = open(_LOCK, "w")
    try:
        if _HAVE_FCNTL:
            fcntl.flock(lf, fcntl.LOCK_EX)
        fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix=".mcp-", suffix=".tmp")
        try:
            with os.fdopen(fd, "w") as f:
                f.write(content)
                f.flush()
                os.fsync(f.fileno())
            os.chmod(tmp, 0o600)
            os.replace(tmp, path)   # atomic same-filesystem swap
            tmp = None
        finally:
            if tmp and os.path.exists(tmp):
                os.unlink(tmp)
    finally:
        if _HAVE_FCNTL:
            fcntl.flock(lf, fcntl.LOCK_UN)
        lf.close()
    try:
        os.chmod(path, 0o600)
    except OSError:  # pragma: no cover
        pass
