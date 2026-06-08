"""Unit tests for meeting_notes.py — the deterministic meeting-note core.

Hermetic: every test runs against a temp vault + an inline fixture template.
No live vault, no network. Run: python3 -m unittest discover mcp-servers/tests
"""
import sys
import json
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import meeting_notes as mn  # noqa: E402

# A fixture template that mirrors the real Meeting Note template's *structure*
# (dual zone) without depending on the vault. The My Notes placeholder comment
# is deliberately different text from the real one, to prove "untouched"
# detection keys on "comments+whitespace only", not on specific comment text.
FIXTURE_TEMPLATE = """---
date: {{date}}
type: meeting
status: shell
event_uid:
calendar: work | personal
project:
attendees:
otter_id:
---

# {{title}}

## My Notes
<!-- fixture placeholder comment -->


<!-- BEGIN:auto-meeting -->
<!-- auto fill marker -->

## Summary
<!-- s -->

## Transcript
<!-- END:auto-meeting -->
"""


def write(p: Path, text: str):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)


def make_note(status="shell", date="2026-06-01", event_uid="uid-x",
              my_notes_body="", title="Some Meeting"):
    """Build a meeting-note file body for prune/path tests."""
    return f"""---
date: {date}
type: meeting
status: {status}
event_uid: {event_uid}
calendar: work
---

# {title}

## My Notes
<!-- placeholder -->
{my_notes_body}

<!-- BEGIN:auto-meeting -->
## Summary
<!-- END:auto-meeting -->
"""


class TestSlugify(unittest.TestCase):
    def test_basic_words(self):
        self.assertEqual(mn.slugify("Executive Staff Meeting"), "executive-staff-meeting")

    def test_colons_and_slashes(self):
        self.assertEqual(mn.slugify("1:1 EVM/Sul"), "1-1-evm-sul")

    def test_collapses_separators_and_strips_punct(self):
        self.assertEqual(mn.slugify("Darrin - Real Estate (Stockton)"), "darrin-real-estate-stockton")

    def test_preserves_internal_hyphen(self):
        self.assertEqual(mn.slugify("AI Priority Sync-Up"), "ai-priority-sync-up")

    def test_empty_falls_back(self):
        self.assertEqual(mn.slugify("   !!!   "), "meeting")


class TestFindNotePath(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.vault = Path(self.tmp)
        (self.vault / "Meetings").mkdir()

    def test_new_meeting_uses_base_slug(self):
        r = mn.find_note_path(self.vault, "2026-06-04", "Weekly Sync", time="1000", event_uid="uid-1")
        self.assertEqual(Path(r["path"]).name, "2026-06-04-weekly-sync.md")
        self.assertFalse(r["exists"])
        self.assertFalse(r["matches_uid"])

    def test_idempotent_by_event_uid_even_with_renamed_title(self):
        # An existing note for uid-1 lives under a DIFFERENT slug (title was renamed).
        existing = self.vault / "Meetings" / "2026-06-04-old-title.md"
        write(existing, make_note(date="2026-06-04", event_uid="uid-1"))
        r = mn.find_note_path(self.vault, "2026-06-04", "New Title", time="1000", event_uid="uid-1")
        self.assertEqual(Path(r["path"]), existing)  # returns the uid-matched file, not a new slug
        self.assertTrue(r["exists"])
        self.assertTrue(r["matches_uid"])

    def test_slug_clash_different_uid_gets_time_suffix(self):
        clashing = self.vault / "Meetings" / "2026-06-04-ai-sync.md"
        write(clashing, make_note(date="2026-06-04", event_uid="uid-OTHER"))
        r = mn.find_note_path(self.vault, "2026-06-04", "AI Sync", time="1430", event_uid="uid-NEW")
        self.assertEqual(Path(r["path"]).name, "2026-06-04-ai-sync-1430.md")
        self.assertFalse(r["exists"])


class TestCreateShells(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.vault = Path(self.tmp)
        (self.vault / "Meetings").mkdir()
        self.template = self.vault / "tmpl.md"
        self.template.write_text(FIXTURE_TEMPLATE)

    def _shell_meeting(self, **kw):
        m = dict(date="2026-06-04", title="GTreasury M&A Retro", time="1000",
                 start="2026-06-04T10:00:00-07:00", event_uid="uid-42",
                 calendar="work", attendees=["Jane Doe", "John Smith"])
        m.update(kw)
        return m

    def test_creates_dual_zone_shell(self):
        res = mn.create_shells(self.vault, [self._shell_meeting()], self.template)
        self.assertEqual(len(res["created"]), 1)
        path = Path(res["created"][0])
        self.assertEqual(path.name, "2026-06-04-gtreasury-m-a-retro.md")
        text = path.read_text()
        self.assertIn("status: shell", text)
        self.assertIn("event_uid: uid-42", text)
        self.assertIn("start: 2026-06-04T10:00:00-07:00", text)  # start time stored for otter-sync matching
        self.assertIn("# GTreasury M&A Retro", text)        # title substituted into body
        self.assertIn("## My Notes", text)
        self.assertIn("<!-- BEGIN:auto-meeting -->", text)
        self.assertIn("<!-- END:auto-meeting -->", text)
        self.assertIn("Jane Doe", text)                      # attendees recorded
        self.assertNotIn("{{date}}", text)                   # no unsubstituted placeholders
        self.assertNotIn("{{title}}", text)

    def test_uses_fallback_when_template_reverted_to_old_structure(self):
        # The vault is cloud-synced; sync could revert the template to a pre-v3
        # (no-markers) version. Shells must STILL be dual-zone regardless.
        old_tmpl = self.vault / "old-template.md"
        old_tmpl.write_text("---\ndate: {{date}}\ntype: meeting\n---\n\n# {{title}}\n\n## Summary\n-\n")
        res = mn.create_shells(self.vault, [self._shell_meeting(event_uid="uid-fb")], old_tmpl)
        text = Path(res["created"][0]).read_text()
        self.assertIn("## My Notes", text)
        self.assertIn("<!-- BEGIN:auto-meeting -->", text)
        self.assertIn("<!-- END:auto-meeting -->", text)
        self.assertIn("# GTreasury M&A Retro", text)   # title still substituted
        self.assertIn("status: shell", text)

    def test_uses_fallback_when_template_missing(self):
        res = mn.create_shells(self.vault, [self._shell_meeting(event_uid="uid-missing")],
                               self.vault / "does-not-exist.md")
        text = Path(res["created"][0]).read_text()
        self.assertIn("<!-- BEGIN:auto-meeting -->", text)
        self.assertIn("## My Notes", text)

    def test_idempotent_on_event_uid(self):
        mn.create_shells(self.vault, [self._shell_meeting()], self.template)
        before = (self.vault / "Meetings" / "2026-06-04-gtreasury-m-a-retro.md").read_text()
        res2 = mn.create_shells(self.vault, [self._shell_meeting(title="Renamed Retro")], self.template)
        self.assertEqual(len(res2["created"]), 0)            # not recreated
        self.assertEqual(len(res2["skipped"]), 1)
        after = (self.vault / "Meetings" / "2026-06-04-gtreasury-m-a-retro.md").read_text()
        self.assertEqual(before, after)                      # existing shell untouched


class TestMyNotesUntouched(unittest.TestCase):
    def test_only_comment_and_whitespace_is_untouched(self):
        self.assertTrue(mn.my_notes_is_untouched("<!-- anything -->\n\n   \n"))

    def test_real_content_is_touched(self):
        self.assertFalse(mn.my_notes_is_untouched("<!-- placeholder -->\n- prepped my agenda\n"))

    def test_blank_is_untouched(self):
        self.assertTrue(mn.my_notes_is_untouched("\n   \n"))


class TestPrune(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.vault = Path(self.tmp)
        (self.vault / "Meetings").mkdir()
        self.today = "2026-06-04"

    def _put(self, name, **kw):
        write(self.vault / "Meetings" / name, make_note(**kw))
        return self.vault / "Meetings" / name

    def test_deletes_empty_past_shell(self):
        p = self._put("2026-06-01-dead-shell.md", status="shell", date="2026-06-01", my_notes_body="")
        res = mn.prune(self.vault, self.today)
        self.assertIn(str(p), res["pruned"])
        self.assertFalse(p.exists())

    def test_keeps_shell_with_human_notes(self):
        p = self._put("2026-06-01-noted.md", status="shell", date="2026-06-01",
                      my_notes_body="- I prepped this one")
        res = mn.prune(self.vault, self.today)
        self.assertNotIn(str(p), res["pruned"])
        self.assertTrue(p.exists())

    def test_keeps_transcribed(self):
        p = self._put("2026-06-01-done.md", status="transcribed", date="2026-06-01", my_notes_body="")
        mn.prune(self.vault, self.today)
        self.assertTrue(p.exists())

    def test_keeps_today_and_future_shells(self):
        today = self._put("2026-06-04-today.md", status="shell", date="2026-06-04", my_notes_body="")
        future = self._put("2026-06-05-future.md", status="shell", date="2026-06-05", my_notes_body="")
        mn.prune(self.vault, self.today)
        self.assertTrue(today.exists())
        self.assertTrue(future.exists())

    def test_respects_lookback_window(self):
        old = self._put("2026-05-01-ancient.md", status="shell", date="2026-05-01", my_notes_body="")
        mn.prune(self.vault, self.today, lookback_days=7)   # 2026-05-01 is >7d before 2026-06-04
        self.assertTrue(old.exists())                        # outside window → not scanned/deleted

    def test_dry_run_reports_without_deleting(self):
        p = self._put("2026-06-02-dead.md", status="shell", date="2026-06-02", my_notes_body="")
        res = mn.prune(self.vault, self.today, dry_run=True)
        self.assertIn(str(p), res["pruned"])
        self.assertTrue(p.exists())                          # dry run: still there


if __name__ == "__main__":
    unittest.main()
