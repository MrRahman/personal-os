"""Unit tests for mcp_json_io.py — atomic/validated/0600 .mcp.json writes.
Run: python3 -m unittest discover -s mcp-servers/tests
"""
import importlib.util
import json
import os
import shutil
import stat
import tempfile
import unittest
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "mcp_json_io", Path(__file__).resolve().parent.parent / "mcp_json_io.py")
mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mod)


class TestAtomicWrite(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.p = Path(self.d) / ".mcp.json"
        self.p.write_text('{"mcpServers": {"a": {"env": {"K": "old"}}}}')

    def tearDown(self):
        shutil.rmtree(self.d, ignore_errors=True)

    def test_writes_valid_json_and_sets_0600(self):
        new = '{"mcpServers": {"a": {"env": {"K": "new"}}}}'
        mod.write_mcp_json_atomic(self.p, new)
        self.assertEqual(json.loads(self.p.read_text())["mcpServers"]["a"]["env"]["K"], "new")
        self.assertEqual(stat.S_IMODE(os.stat(self.p).st_mode), 0o600)

    def test_invalid_json_raises_and_leaves_original_intact(self):
        with self.assertRaises(ValueError):
            mod.write_mcp_json_atomic(self.p, '{"mcpServers": {oops not json')
        self.assertEqual(json.loads(self.p.read_text())["mcpServers"]["a"]["env"]["K"], "old")

    def test_no_temp_files_left_behind(self):
        mod.write_mcp_json_atomic(self.p, '{"x": 1}')
        leftovers = [f for f in os.listdir(self.d) if f.startswith(".mcp-")]
        self.assertEqual(leftovers, [])


if __name__ == "__main__":
    unittest.main()
