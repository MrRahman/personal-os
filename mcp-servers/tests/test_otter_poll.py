"""Unit tests for otter-poll.py — the cheap non-LLM cost gate.

Pure logic + filesystem only; no live network. The poll decides whether
otter-sync should spend on a Haiku run at all.
Run: python3 -m unittest discover -s mcp-servers/tests
"""
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

# otter-poll.py isn't a valid module name (hyphen) — load it by path.
_SPEC = importlib.util.spec_from_file_location(
    "otter_poll", str(Path(__file__).resolve().parent.parent / "otter-poll.py"))
op = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(op)  # raises if the file is missing → RED


def speech(otid, title="Real Meeting", duration=1200, finished=True,
           start=1780504236, end=1780505494):
    return {"otid": otid, "title": title, "duration": duration,
            "process_finished": finished, "start_time": start, "end_time": end}


class TestFilterNew(unittest.TestCase):
    def test_keeps_ready_new_substantial_and_normalizes(self):
        out = op.filter_new([speech("OT1")], exclude_otids=set(), min_duration_s=300)
        self.assertEqual(len(out), 1)
        self.assertEqual(out[0]["otid"], "OT1")
        self.assertEqual(out[0]["title"], "Real Meeting")
        self.assertIn("start_time", out[0])
        self.assertIn("duration", out[0])

    def test_excludes_already_captured_in_notes_or_state(self):
        out = op.filter_new([speech("OT1"), speech("OT2")],
                            exclude_otids={"OT1"}, min_duration_s=300)
        self.assertEqual([s["otid"] for s in out], ["OT2"])

    def test_excludes_too_short(self):
        out = op.filter_new([speech("OT1", duration=120)], exclude_otids=set(), min_duration_s=300)
        self.assertEqual(out, [])

    def test_excludes_unfinished_processing(self):
        out = op.filter_new([speech("OT1", finished=False)], exclude_otids=set(), min_duration_s=300)
        self.assertEqual(out, [])

    def test_derives_la_date_and_iso_start_so_actor_needs_no_conversion(self):
        # 1780504236 == 2026-06-03 09:30 America/Los_Angeles (verified live via Otter)
        out = op.filter_new([speech("OT1", start=1780504236)], exclude_otids=set(), min_duration_s=300)
        self.assertEqual(out[0]["date"], "2026-06-03")
        self.assertTrue(out[0]["start"].startswith("2026-06-03T09:"))


class TestScanNoteOtids(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.vault = Path(self.tmp)
        (self.vault / "Meetings").mkdir()

    def _note(self, name, otter_id):
        (self.vault / "Meetings" / name).write_text(
            f"---\ndate: 2026-06-01\ntype: meeting\nstatus: transcribed\notter_id: {otter_id}\n---\n\n# X\n")

    def test_collects_otter_ids_from_frontmatter(self):
        self._note("a.md", "OT_A")
        self._note("b.md", "OT_B")
        (self.vault / "Meetings" / "shell.md").write_text(
            "---\ndate: 2026-06-01\nstatus: shell\notter_id:\n---\n\n# Y\n")  # empty → ignored
        got = op.scan_note_otids(self.vault)
        self.assertEqual(got, {"OT_A", "OT_B"})


class TestProcessedState(unittest.TestCase):
    def test_missing_state_file_is_empty_set(self):
        self.assertEqual(op.load_processed(Path(tempfile.mkdtemp()) / "nope.json"), set())

    def test_roundtrip(self):
        p = Path(tempfile.mkdtemp()) / "otter-sync.json"
        op.save_processed(p, {"OT1", "OT2"})
        self.assertEqual(op.load_processed(p), {"OT1", "OT2"})


if __name__ == "__main__":
    unittest.main()
