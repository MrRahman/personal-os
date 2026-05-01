#!/usr/bin/env python3
"""Refresh Slack xoxc/xoxd tokens via a dedicated Playwright browser profile.

Isolates the MCP's Slack session from the user's daily Slack desktop app, so
token extraction doesn't kick the laptop session and trigger an auth loop.

One-time setup:
    python3 -m venv ~/.local/venvs/slack-refresh
    ~/.local/venvs/slack-refresh/bin/pip install playwright
    ~/.local/venvs/slack-refresh/bin/playwright install chromium
    ~/.local/venvs/slack-refresh/bin/python mcp-servers/refresh-slack-tokens.py --login

Usage:
    refresh-slack-tokens.py                # headless refresh if current invalid
    refresh-slack-tokens.py --validate     # test current, exit 0 if valid
    refresh-slack-tokens.py --login        # force visible login (first-time or re-auth)
    refresh-slack-tokens.py --force        # refresh even if current still valid
    refresh-slack-tokens.py --dry-run      # extract but don't write .mcp.json
"""

import json
import re
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

MCP_JSON = Path(__file__).resolve().parent.parent / ".mcp.json"
SLACK_PROFILE_DIR = Path.home() / ".config/personal-os/slack-browser"
SLACK_AUTH_TEST = "https://slack.com/api/auth.test"
SLACK_CLIENT_URL = "https://app.slack.com/client/"

# How long to wait for an interactive login to complete before giving up.
LOGIN_TIMEOUT_SECONDS = 300

# How long to wait after navigating before reading localStorage. Slack hydrates
# `localConfig_v2` asynchronously after page load.
HYDRATION_WAIT_MS = 3000


JS_EXTRACT_XOXC = """
() => {
    try {
        const raw = localStorage.getItem('localConfig_v2');
        if (!raw) return null;
        const cfg = JSON.parse(raw);
        if (!cfg || !cfg.teams) return null;
        const teamIds = Object.keys(cfg.teams);
        if (!teamIds.length) return null;
        // Prefer a team whose token starts with xoxc; fall back to the first.
        for (const id of teamIds) {
            const t = cfg.teams[id] && cfg.teams[id].token;
            if (t && t.startsWith('xoxc-')) return t;
        }
        return (cfg.teams[teamIds[0]] || {}).token || null;
    } catch (e) {
        return null;
    }
}
"""


def notify(title: str, message: str) -> None:
    """Send a macOS notification (best effort)."""
    try:
        subprocess.run(
            [
                "osascript",
                "-e",
                f'display notification "{message}" with title "{title}"',
            ],
            capture_output=True,
            timeout=5,
        )
    except Exception:
        pass


def validate_tokens(xoxc: str | None, xoxd: str | None) -> bool:
    """Hit slack.com/api/auth.test with the given tokens. True on `ok: true`."""
    if not xoxc or not xoxd:
        return False
    data = urlencode({"token": xoxc}).encode()
    req = Request(SLACK_AUTH_TEST, data=data, method="POST")
    req.add_header("Cookie", f"d={xoxd}")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    try:
        with urlopen(req, timeout=10) as resp:
            body = json.loads(resp.read())
            return body.get("ok") is True
    except (HTTPError, URLError, json.JSONDecodeError):
        return False


def read_current_tokens() -> tuple[str | None, str | None]:
    """Parse the two Slack tokens out of .mcp.json."""
    if not MCP_JSON.exists():
        return None, None
    content = MCP_JSON.read_text()
    xoxc_match = re.search(r'"SLACK_MCP_XOXC_TOKEN"\s*:\s*"([^"]*)"', content)
    xoxd_match = re.search(r'"SLACK_MCP_XOXD_TOKEN"\s*:\s*"([^"]*)"', content)
    xoxc = xoxc_match.group(1) if xoxc_match else None
    xoxd = xoxd_match.group(1) if xoxd_match else None
    return (xoxc or None, xoxd or None)


def write_tokens(xoxc: str, xoxd: str) -> bool:
    """Replace both tokens in .mcp.json. Returns True if anything changed."""
    content = MCP_JSON.read_text()

    if not re.search(r'"SLACK_MCP_XOXC_TOKEN"\s*:\s*"', content):
        raise RuntimeError(
            f"SLACK_MCP_XOXC_TOKEN not found in {MCP_JSON}. "
            "Is the `slack` MCP block configured?"
        )
    if not re.search(r'"SLACK_MCP_XOXD_TOKEN"\s*:\s*"', content):
        raise RuntimeError(
            f"SLACK_MCP_XOXD_TOKEN not found in {MCP_JSON}. "
            "Is the `slack` MCP block configured?"
        )

    new = re.sub(
        r'("SLACK_MCP_XOXC_TOKEN"\s*:\s*")[^"]*(")',
        lambda m: m.group(1) + xoxc + m.group(2),
        content,
    )
    new = re.sub(
        r'("SLACK_MCP_XOXD_TOKEN"\s*:\s*")[^"]*(")',
        lambda m: m.group(1) + xoxd + m.group(2),
        new,
    )
    if new == content:
        return False
    MCP_JSON.write_text(new)
    return True


def _import_playwright():
    """Late-import Playwright with a helpful error if missing."""
    try:
        from playwright.sync_api import sync_playwright  # noqa: F401
        return sync_playwright
    except ImportError:
        print(
            "ERROR: Playwright not installed. One-time setup:\n"
            "  python3 -m venv ~/.local/venvs/slack-refresh\n"
            "  ~/.local/venvs/slack-refresh/bin/pip install playwright\n"
            "  ~/.local/venvs/slack-refresh/bin/playwright install chromium\n"
            "Then invoke via the venv's python:\n"
            "  ~/.local/venvs/slack-refresh/bin/python "
            f"{Path(__file__).name} --login",
            file=sys.stderr,
        )
        sys.exit(2)


def extract_tokens(headless: bool) -> tuple[str | None, str | None]:
    """Launch Chromium against the persistent profile, try to extract both tokens.

    When `headless=True`, returns (None, None) if the profile has no active
    session — caller decides whether to fall back to interactive login.
    """
    sync_playwright = _import_playwright()
    SLACK_PROFILE_DIR.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        ctx = p.chromium.launch_persistent_context(
            user_data_dir=str(SLACK_PROFILE_DIR),
            headless=headless,
            args=["--disable-blink-features=AutomationControlled"],
        )
        page = ctx.new_page()
        try:
            try:
                page.goto(
                    SLACK_CLIENT_URL,
                    wait_until="domcontentloaded",
                    timeout=30000,
                )
            except Exception as e:
                print(f"Navigation error: {e}", file=sys.stderr)
                return None, None

            page.wait_for_timeout(HYDRATION_WAIT_MS)
            xoxc = page.evaluate(JS_EXTRACT_XOXC)
            cookies = ctx.cookies("https://app.slack.com")
            xoxd = next((c["value"] for c in cookies if c["name"] == "d"), None)
            return xoxc, xoxd
        finally:
            ctx.close()


def interactive_login() -> tuple[str | None, str | None]:
    """Open visible Chromium, poll for login completion, extract both tokens."""
    sync_playwright = _import_playwright()
    SLACK_PROFILE_DIR.mkdir(parents=True, exist_ok=True)

    notify(
        "Slack Login Needed",
        "Log into Ripple Slack in the browser window that just opened.",
    )
    print(
        "Opening Chromium. Log into Ripple Slack in the window — the script "
        "will extract tokens automatically once you reach the workspace.",
        flush=True,
    )

    with sync_playwright() as p:
        ctx = p.chromium.launch_persistent_context(
            user_data_dir=str(SLACK_PROFILE_DIR),
            headless=False,
            args=["--disable-blink-features=AutomationControlled"],
        )
        page = ctx.new_page()
        try:
            try:
                page.goto(
                    SLACK_CLIENT_URL,
                    wait_until="domcontentloaded",
                    timeout=30000,
                )
            except Exception:
                # First-time login often redirects through signin.slack.com;
                # that's fine, just keep polling.
                pass

            deadline = time.time() + LOGIN_TIMEOUT_SECONDS
            xoxc = None
            while time.time() < deadline:
                try:
                    xoxc = page.evaluate(JS_EXTRACT_XOXC)
                except Exception:
                    xoxc = None
                if xoxc:
                    break
                time.sleep(2)

            cookies = ctx.cookies("https://app.slack.com")
            xoxd = next((c["value"] for c in cookies if c["name"] == "d"), None)
            return xoxc, xoxd
        finally:
            ctx.close()


def main() -> None:
    args = sys.argv[1:]

    if "--validate" in args:
        xoxc, xoxd = read_current_tokens()
        if not xoxc or not xoxd:
            print("No tokens configured in .mcp.json.", file=sys.stderr)
            sys.exit(1)
        print(f"Testing xoxc {xoxc[:12]}... xoxd {xoxd[:8]}...")
        if validate_tokens(xoxc, xoxd):
            print("Valid.")
            sys.exit(0)
        print("Expired or invalid.")
        notify(
            "Slack Tokens Expired",
            "Run: python3 mcp-servers/refresh-slack-tokens.py",
        )
        sys.exit(1)

    dry_run = "--dry-run" in args
    force = "--force" in args

    # --login: force interactive, skip the headless attempt entirely.
    if "--login" in args:
        xoxc, xoxd = interactive_login()
        if not (xoxc and xoxd):
            print(
                "Login window closed without producing tokens.",
                file=sys.stderr,
            )
            notify(
                "Slack Login Failed",
                "No tokens extracted. Try again: --login",
            )
            sys.exit(1)
        if not validate_tokens(xoxc, xoxd):
            print(
                "WARNING: extracted tokens failed auth.test.",
                file=sys.stderr,
            )
            notify(
                "Slack Tokens Invalid",
                "Extraction worked but Slack rejected the tokens.",
            )
            sys.exit(1)
        print(f"Found: xoxc {xoxc[:12]}... xoxd {xoxd[:8]}...")
        if dry_run:
            print("Dry run — not updating .mcp.json.")
            return
        if write_tokens(xoxc, xoxd):
            print(f"Updated {MCP_JSON}")
            notify(
                "Slack Tokens Refreshed",
                "Session updated. Restart Claude Code.",
            )
        else:
            print("Tokens unchanged — already up to date.")
        return

    # Default: skip if current tokens still validate (unless --force).
    current_xoxc, current_xoxd = read_current_tokens()
    if not force and current_xoxc and current_xoxd:
        if validate_tokens(current_xoxc, current_xoxd):
            print(
                f"Current tokens still valid (xoxc {current_xoxc[:12]}...). "
                "Skipping refresh."
            )
            return

    # Headless first — cheap and silent when the profile has a live session.
    print("Extracting Slack tokens from dedicated browser profile (headless)...")
    try:
        xoxc, xoxd = extract_tokens(headless=True)
    except Exception as e:
        print(f"Headless extraction errored: {e}", file=sys.stderr)
        xoxc, xoxd = None, None

    # If headless didn't yield a valid pair, the persistent profile needs a
    # fresh login. Don't pop a browser unprompted from a background (launchd)
    # context — notify the user and exit non-zero so they re-run with --login.
    if not (xoxc and xoxd) or not validate_tokens(xoxc, xoxd):
        print(
            "Persistent profile has no valid Slack session. "
            "Run this script with --login to authenticate:\n"
            f"  python3 {Path(__file__).name} --login",
            file=sys.stderr,
        )
        notify(
            "Slack Tokens Need Login",
            "Run: python3 mcp-servers/refresh-slack-tokens.py --login",
        )
        sys.exit(1)

    print(f"Found: xoxc {xoxc[:12]}... xoxd {xoxd[:8]}...")

    if dry_run:
        print("Dry run — not updating .mcp.json.")
        return

    if write_tokens(xoxc, xoxd):
        print(f"Updated {MCP_JSON}")
        notify(
            "Slack Tokens Refreshed",
            "Session updated. Restart Claude Code to pick up new tokens.",
        )
    else:
        print("Tokens unchanged — already up to date.")


if __name__ == "__main__":
    main()
