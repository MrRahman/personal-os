#!/usr/bin/env python3
"""Personal OS v3.0 — cheap, non-LLM Otter poll (otter-sync's cost gate).

Hits Otter's REST API directly with the session cookie from .mcp.json (same
pattern as refresh-otter-cookie.py) and reports transcripts that are READY and
NOT yet captured. otter-sync.sh only spends on a Haiku `claude -p` run when this
prints a non-empty `new` list — so idle hours cost nothing.

    python3 otter-poll.py --vault <vault> --state <state.json> --mcp-json <.mcp.json>
                          [--min-duration 300] [--page-size 20]
    → prints {"new": [{otid,title,date,start,start_time,end_time,duration}], "checked": N[, "error": ...]}
    (date = LA YYYY-MM-DD, start = LA ISO — pre-converted in-poll so the actor never converts timestamps)

Always exits 0 (it's a gate, not an actor). On auth/network failure it reports
`error` + an empty `new` list, so the wrapper simply doesn't spawn the actor.
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

USER_URL = "https://otter.ai/forward/api/v1/user"
SPEECHES_URL = "https://otter.ai/forward/api/v1/speeches?userid={uid}&folder=0&page_size={n}"


# ── pure logic (unit-tested) ──────────────────────────────────────────────────

_LA = ZoneInfo("America/Los_Angeles")


def _la_fields(start_time):
    """unix seconds → (LA local date 'YYYY-MM-DD', LA local ISO incl. offset).

    Derived in the deterministic poll so the Haiku actor never has to convert
    timestamps (it's unreliable at it — see tasks/lessons.md). Returns
    (None, None) when start_time is absent."""
    if not start_time:
        return None, None
    dt = datetime.fromtimestamp(start_time, _LA)
    return dt.date().isoformat(), dt.isoformat()


def filter_new(speeches: list[dict], exclude_otids: set, min_duration_s: int = 300) -> list[dict]:
    """Keep speeches that are finished processing, long enough to matter, and not
    already captured (in a note's otter_id or the processed-state). Normalized."""
    out = []
    for s in speeches:
        otid = s.get("otid")
        if not otid or otid in exclude_otids:
            continue
        if not s.get("process_finished"):
            continue
        if (s.get("duration") or 0) < min_duration_s:
            continue
        st = s.get("start_time")
        date, start_iso = _la_fields(st)
        out.append({"otid": otid, "title": s.get("title"),
                    "date": date, "start": start_iso,
                    "start_time": st, "end_time": s.get("end_time"),
                    "duration": s.get("duration")})
    return out


def scan_note_otids(vault) -> set:
    """Every non-empty otter_id already recorded in a meeting note (authoritative
    dedup — survives state-file loss)."""
    out = set()
    meetings = Path(vault) / "Meetings"
    if not meetings.is_dir():
        return out
    for p in meetings.glob("*.md"):
        try:
            # [ \t]* (not \s*) so an empty "otter_id:" can't swallow the newline
            # and capture the next line's token (e.g. "---").
            m = re.search(r"^otter_id:[ \t]*(\S+)[ \t]*$", p.read_text(), flags=re.MULTILINE)
        except OSError:
            continue
        if m and m.group(1).strip():
            out.add(m.group(1).strip())
    return out


def load_processed(state_path) -> set:
    try:
        return set(json.loads(Path(state_path).read_text()).get("processed_otids", []))
    except (OSError, ValueError):
        return set()


def save_processed(state_path, otids) -> None:
    p = Path(state_path)
    p.parent.mkdir(parents=True, exist_ok=True)
    try:
        data = json.loads(p.read_text())
    except (OSError, ValueError):
        data = {}
    data["processed_otids"] = sorted(set(otids))
    p.write_text(json.dumps(data, indent=2) + "\n")


# ── network (not unit-tested; verified live at build) ─────────────────────────

def read_cookie(mcp_json) -> str | None:
    m = re.search(r'"OTTER_SESSION_COOKIE"\s*:\s*"([^"]+)"', Path(mcp_json).read_text())
    return m.group(1) if m else None


def _get(url: str, cookie: str, timeout: int = 15):
    req = Request(url)
    req.add_header("Cookie", f"sessionid={cookie}")
    req.add_header("User-Agent", "Mozilla/5.0")
    with urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def get_userid(cookie: str):
    return _get(USER_URL, cookie).get("userid")


def list_speeches(cookie: str, userid, page_size: int = 20) -> list[dict]:
    return _get(SPEECHES_URL.format(uid=userid, n=page_size), cookie).get("speeches", [])


# ── CLI ───────────────────────────────────────────────────────────────────────

def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description="Cheap Otter poll — otter-sync cost gate.")
    ap.add_argument("--vault", required=True)
    ap.add_argument("--state", required=True)
    ap.add_argument("--mcp-json", dest="mcp_json", required=True)
    ap.add_argument("--min-duration", dest="min_duration", type=int, default=300)
    ap.add_argument("--page-size", dest="page_size", type=int, default=20)
    args = ap.parse_args(argv)

    result = {"new": [], "checked": 0}
    try:
        cookie = read_cookie(args.mcp_json)
        if not cookie:
            result["error"] = "no OTTER_SESSION_COOKIE in .mcp.json"
        else:
            userid = get_userid(cookie)
            speeches = list_speeches(cookie, userid, args.page_size)
            result["checked"] = len(speeches)
            exclude = scan_note_otids(args.vault) | load_processed(args.state)
            result["new"] = filter_new(speeches, exclude, args.min_duration)
    except (HTTPError, URLError, ValueError, OSError) as e:
        result["error"] = f"{type(e).__name__}: {e}"
    print(json.dumps(result))


if __name__ == "__main__":
    main()
