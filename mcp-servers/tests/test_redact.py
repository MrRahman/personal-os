"""Unit tests for redact.py — secret scrubbing before logs.
Run: python3 -m unittest discover -s mcp-servers/tests
"""
import importlib.util
import unittest
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "redact", Path(__file__).resolve().parent.parent / "redact.py")
redact = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(redact)


class TestRedact(unittest.TestCase):
    def test_otter_cookie_env_assignment(self):
        out = redact.redact_text('OTTER_SESSION_COOKIE = "FAKEcookieNotARealSecret00000000"')
        self.assertEqual(out, 'OTTER_SESSION_COOKIE = "[REDACTED]"')

    def test_sessionid_header(self):
        out = redact.redact_text("req.add_header('Cookie', 'sessionid=abcdef0123456789abcdef')")
        self.assertIn("sessionid=[REDACTED]", out)
        self.assertNotIn("abcdef0123456789abcdef", out)

    def test_slack_tokens(self):
        _xoxc = "xoxc-" + "A" * 16   # constructed so no real-looking token literal lives in the file
        _xoxd = "xoxd-" + "Z" * 16
        self.assertNotIn("A" * 16, redact.redact_text(_xoxc))
        self.assertNotIn("Z" * 16, redact.redact_text(_xoxd))

    def test_notion_bearer_anthropic(self):
        self.assertNotIn("SECRETPART12345678", redact.redact_text("ntn_SECRETPART12345678"))
        self.assertNotIn("toktoktoktok123", redact.redact_text("Authorization: Bearer toktoktoktok123"))
        self.assertNotIn("keykeykeykey1234", redact.redact_text("sk-ant-keykeykeykey1234"))

    def test_leaves_normal_text_untouched(self):
        s = "otter-sync: filled=2 created=1 skipped=1 | cost 0.04 | turns 3"
        self.assertEqual(redact.redact_text(s), s)

    def test_preserves_identifying_prefix(self):
        self.assertTrue(redact.redact_text("sessionid=abcdef0123456789abcd").startswith("sessionid="))

    def test_empty_and_none_safe(self):
        self.assertEqual(redact.redact_text(""), "")
        self.assertEqual(redact.redact_text(None), None)

    def test_exact_match_secret_escaping_proof(self):
        # The real leak shape: a hard-coded cookie inside a JSON-escaped command
        # string, where the quote-anchored pattern alone could miss it.
        cookie = "FAKEcookieNotARealSecret00000000"
        escaped = '{"command": "OTTER_SESSION_COOKIE = \\"' + cookie + '\\""}'
        out = redact.redact_text(escaped, extra_secrets=[cookie])
        self.assertNotIn(cookie, out)
        self.assertIn("[REDACTED]", out)

    def test_extra_secret_too_short_ignored(self):
        self.assertEqual(redact.redact_text("hello world", extra_secrets=["abc"]), "hello world")

    def test_secrets_from_mcp(self):
        import json, tempfile, os
        cfg = {"mcpServers": {
            "otter": {"env": {"OTTER_SESSION_COOKIE": "FAKEcookieNotARealSecret00000000"}},
            "slack": {"env": {"SLACK_MCP_XOXC_TOKEN": "xoxc-abc123def456",
                              "SLACK_MCP_USER_AGENT": "Mozilla/5.0"}},
            "x": {"command": "foo"}}}
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
            json.dump(cfg, fh)
            p = fh.name
        try:
            secs = redact.secrets_from_mcp(p)
            self.assertIn("FAKEcookieNotARealSecret00000000", secs)
            self.assertIn("xoxc-abc123def456", secs)
            self.assertNotIn("Mozilla/5.0", secs)  # non-secret key not collected
        finally:
            os.unlink(p)

    def test_secrets_from_mcp_missing_file_safe(self):
        self.assertEqual(redact.secrets_from_mcp("/nonexistent/.mcp.json"), [])


if __name__ == "__main__":
    unittest.main()
