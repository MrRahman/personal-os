#!/usr/bin/env python3
"""Personal OS v3.0 — deterministic meeting-note core.

The single source of truth for the Meeting-Note Contract (see
.claude/skills/_conventions.md "Meeting-Note Contract"). The daily-brief
(shell pre-creation) and otter-sync (fill + prune) both call this so they can
never drift on *where* a meeting's file lives or *how* a shell is shaped.

Subcommands:
    path   --vault --date --title [--time HHMM] [--event-uid UID]
           → JSON {path, slug, exists, matches_uid, status}
    shells --vault --template --shells-json '[{date,title,time,event_uid,calendar,attendees}]'
           → JSON {created:[...], skipped:[...]}   (CREATE-ONLY, idempotent on event_uid)
    prune  --vault --today [--lookback-days N] [--dry-run]
           → JSON {pruned:[...], scanned:N}        (status==shell + untouched My Notes + past day)

No network, no MCP — pure filesystem. Importable for tests.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import date as _date, timedelta
from pathlib import Path


# ── slug + canonical path ─────────────────────────────────────────────────────

def slugify(title: str) -> str:
    """Lowercase; runs of non-[a-z0-9] (spaces, :, /, _, punctuation, existing
    hyphens) collapse to a single '-'; trim. Empty → 'meeting'."""
    s = re.sub(r"[^a-z0-9]+", "-", (title or "").lower()).strip("-")
    return s or "meeting"


def _read_frontmatter_text(text: str) -> dict:
    """Minimal scalar frontmatter parse (top-level `key: value` only; list items
    and nested keys are ignored). Sufficient for date/status/event_uid."""
    fm: dict = {}
    if not text.startswith("---"):
        return fm
    end = text.find("\n---", 3)
    if end == -1:
        return fm
    for line in text[3:end].splitlines():
        if not line.strip() or line.startswith((" ", "\t")) or line.lstrip().startswith("-"):
            continue
        if ":" in line:
            k, _, v = line.partition(":")
            fm[k.strip()] = v.strip()
    return fm


def _frontmatter_of(path: Path) -> dict:
    try:
        return _read_frontmatter_text(path.read_text())
    except OSError:
        return {}


def find_note_path(vault, date: str, title: str, time: str | None = None,
                   event_uid: str | None = None) -> dict:
    """Resolve the canonical meeting-note path. event_uid is the primary key:
    a same-date note whose event_uid matches is the same meeting (survives title
    rename). Else base slug path; else `-HHMM` on a same-day clash with a
    different meeting."""
    meetings = Path(vault) / "Meetings"
    slug = slugify(title)

    # 1. event_uid wins: any same-date note already carrying this uid is it.
    if event_uid:
        for p in sorted(meetings.glob(f"{date}-*.md")):
            fm = _frontmatter_of(p)
            if fm.get("event_uid") == event_uid:
                return {"path": str(p), "slug": slug, "exists": True,
                        "matches_uid": True, "status": fm.get("status")}

    base = meetings / f"{date}-{slug}.md"
    if not base.exists():
        return {"path": str(base), "slug": slug, "exists": False,
                "matches_uid": False, "status": None}

    base_fm = _frontmatter_of(base)
    if event_uid and base_fm.get("event_uid") == event_uid:
        return {"path": str(base), "slug": slug, "exists": True,
                "matches_uid": True, "status": base_fm.get("status")}

    # 2. slug clash with a different meeting → time-suffix (then numeric on rare double clash)
    if time:
        hhmm = re.sub(r"[^0-9]", "", time)[:4]
        cand = meetings / f"{date}-{slug}-{hhmm}.md"
        n = 2
        while cand.exists():
            if event_uid and _frontmatter_of(cand).get("event_uid") == event_uid:
                return {"path": str(cand), "slug": slug, "exists": True,
                        "matches_uid": True, "status": _frontmatter_of(cand).get("status")}
            cand = meetings / f"{date}-{slug}-{hhmm}-{n}.md"
            n += 1
        return {"path": str(cand), "slug": slug, "exists": False,
                "matches_uid": False, "status": None}

    # 3. no time to disambiguate → best-effort base
    return {"path": str(base), "slug": slug, "exists": True,
            "matches_uid": False, "status": base_fm.get("status")}


# ── shell creation (CREATE-ONLY) ──────────────────────────────────────────────

# Embedded fallback so shell creation never depends on the cloud-synced vault
# template being intact (it can be reverted/removed by sync from another machine).
_FALLBACK_BODY = """# {{title}}

## My Notes
<!-- Your space. Jot the agenda, prep, and live notes. Automation NEVER overwrites anything here. -->


<!-- BEGIN:auto-meeting -->
<!-- Auto-filled by otter-sync from the meeting transcript. Don't hand-edit inside these markers. Your notes belong in "## My Notes" above. -->

## Summary

## Key Points
-

## Decisions
-

## Action Items
- [ ]

## Follow-ups
- [ ]

## Transcript Highlights
-

## Transcript
<!-- END:auto-meeting -->
"""


def _template_body(template_text: str) -> str:
    """Everything after the template's frontmatter (we build frontmatter ourselves)."""
    if template_text.startswith("---"):
        end = template_text.find("\n---", 3)
        if end != -1:
            return template_text[end + 4:].lstrip("\n")
    return template_text


def _resolve_body(template) -> str:
    """The dual-zone body to stamp. Prefer the vault template; fall back to the
    embedded body if the template is missing or was reverted to a pre-v3
    (no dual-zone markers) structure — so shells are ALWAYS dual-zone."""
    try:
        body = _template_body(Path(template).read_text())
        if "BEGIN:auto-meeting" in body:
            return body
    except OSError:
        pass
    return _FALLBACK_BODY


def _shell_frontmatter(date: str, start, event_uid, calendar, attendees) -> str:
    lines = ["---", f"date: {date}", "type: meeting", "status: shell",
             f"event_uid: {event_uid or ''}", f"start: {start or ''}",
             f"calendar: {calendar or ''}", "project:", "attendees:"]
    for a in (attendees or []):
        lines.append(f'  - "{a}"')
    lines += ["otter_id:", "---"]
    return "\n".join(lines)


def create_shells(vault, meetings: list[dict], template) -> dict:
    """Create empty dual-zone shells for meetings missing a note. Idempotent on
    event_uid; never overwrites an existing note (preserves any human My Notes)."""
    body_tmpl = _resolve_body(template)
    created, skipped = [], []
    for m in meetings:
        info = find_note_path(vault, m["date"], m["title"],
                              time=m.get("time"), event_uid=m.get("event_uid"))
        path = Path(info["path"])
        if info["exists"]:
            skipped.append(str(path))
            continue
        body = body_tmpl.replace("{{title}}", m["title"]).replace("{{date}}", m["date"])
        fm = _shell_frontmatter(m["date"], m.get("start"), m.get("event_uid"),
                                m.get("calendar"), m.get("attendees"))
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fm + "\n\n" + body)
        created.append(str(path))
    return {"created": created, "skipped": skipped}


# ── prune (conservative; caller is the otter-sync wrapper) ────────────────────

def my_notes_is_untouched(my_notes_text: str) -> bool:
    """True when the My Notes zone holds only HTML comments + whitespace (the
    user never wrote anything)."""
    return re.sub(r"<!--.*?-->", "", my_notes_text, flags=re.DOTALL).strip() == ""


def _extract_my_notes(text: str) -> str | None:
    m = re.search(r"^##\s+My Notes\s*$", text, flags=re.MULTILINE)
    if not m:
        return None
    rest = text[m.end():]
    ends = []
    bm = re.search(r"<!--\s*BEGIN:auto-meeting\s*-->", rest)
    if bm:
        ends.append(bm.start())
    h2 = re.search(r"^##\s+", rest, flags=re.MULTILINE)
    if h2:
        ends.append(h2.start())
    return rest[: min(ends)] if ends else rest


def _parse_date(s: str):
    try:
        return _date.fromisoformat((s or "").strip())
    except ValueError:
        return None


def prune(vault, today: str, lookback_days: int = 7, dry_run: bool = False) -> dict:
    """Delete a note ONLY if status==shell AND My Notes untouched AND its date is
    in [today-lookback, today). status==shell already guarantees the auto block
    was never filled. Never touches noted / transcribed / today / future notes."""
    meetings = Path(vault) / "Meetings"
    today_d = _parse_date(today)
    pruned, scanned = [], 0
    if today_d is None or not meetings.is_dir():
        return {"pruned": pruned, "scanned": scanned}
    for p in sorted(meetings.glob("*.md")):
        text = p.read_text()
        fm = _read_frontmatter_text(text)
        d = _parse_date(fm.get("date", "")) or _parse_date(p.name[:10])
        if d is None or not (today_d - timedelta(days=lookback_days) <= d < today_d):
            continue
        scanned += 1
        if fm.get("status") != "shell":
            continue
        my_notes = _extract_my_notes(text)
        if my_notes is None or not my_notes_is_untouched(my_notes):
            continue
        pruned.append(str(p))
        if not dry_run:
            p.unlink()
    return {"pruned": pruned, "scanned": scanned}


# ── CLI ───────────────────────────────────────────────────────────────────────

def main(argv=None) -> None:
    import argparse
    ap = argparse.ArgumentParser(description="Deterministic meeting-note core.")
    sub = ap.add_subparsers(dest="cmd", required=True)

    pp = sub.add_parser("path", help="resolve canonical meeting-note path")
    pp.add_argument("--vault", required=True)
    pp.add_argument("--date", required=True)
    pp.add_argument("--title", required=True)
    pp.add_argument("--time")
    pp.add_argument("--event-uid", dest="event_uid")

    ps = sub.add_parser("shells", help="create-or-skip dual-zone shells")
    ps.add_argument("--vault", required=True)
    ps.add_argument("--template", required=True)
    ps.add_argument("--shells-json", dest="shells_json", required=True)

    pr = sub.add_parser("prune", help="conservatively prune empty past shells")
    pr.add_argument("--vault", required=True)
    pr.add_argument("--today", required=True)
    pr.add_argument("--lookback-days", dest="lookback_days", type=int, default=7)
    pr.add_argument("--dry-run", dest="dry_run", action="store_true")

    args = ap.parse_args(argv)
    if args.cmd == "path":
        out = find_note_path(args.vault, args.date, args.title, args.time, args.event_uid)
    elif args.cmd == "shells":
        out = create_shells(args.vault, json.loads(args.shells_json), args.template)
    elif args.cmd == "prune":
        out = prune(args.vault, args.today, args.lookback_days, args.dry_run)
    else:  # pragma: no cover
        ap.error("unknown command")
    json.dump(out, sys.stdout)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
