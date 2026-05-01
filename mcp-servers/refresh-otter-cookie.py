#!/usr/bin/env python3
"""Refresh Otter.ai session cookie from Chrome's cookie store.

Reads the encrypted 'sessionid' cookie for .otter.ai from Chrome's
SQLite DB, decrypts it using the macOS Keychain, and updates
the project's .mcp.json OTTER_SESSION_COOKIE env value.

Usage:
    python3 refresh-otter-cookie.py                        # extract + update .mcp.json
    python3 refresh-otter-cookie.py --list                 # show all otter.ai cookies
    python3 refresh-otter-cookie.py --dry-run              # extract but don't write
    python3 refresh-otter-cookie.py --validate             # test if current cookie works
    python3 refresh-otter-cookie.py --profile "Profile 2"  # force a Chrome profile
"""

import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

CHROME_DIR = Path.home() / "Library/Application Support/Google/Chrome"
WRAPPER_SCRIPT = Path(__file__).parent / "otter-wrapper.sh"
MCP_JSON = Path(__file__).resolve().parent.parent / ".mcp.json"
OTTER_DOMAIN = "otter.ai"
COOKIE_NAME = "sessionid"
OTTER_USER_URL = "https://otter.ai/forward/api/v1/user"


def get_chrome_safe_storage_key() -> bytes:
    """Get Chrome's Safe Storage encryption key from macOS Keychain."""
    result = subprocess.run(
        [
            "security",
            "find-generic-password",
            "-w",
            "-s",
            "Chrome Safe Storage",
            "-a",
            "Chrome",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            "Failed to get Chrome Safe Storage key from Keychain. "
            "Is Chrome installed?"
        )
    return result.stdout.strip().encode()


def derive_key(safe_storage_key: bytes) -> bytes:
    """Derive AES key using PBKDF2 (Chrome's macOS parameters)."""
    return hashlib.pbkdf2_hmac(
        "sha1", safe_storage_key, b"saltysalt", 1003, dklen=16
    )


def decrypt_cookie(encrypted_value: bytes, key: bytes) -> str:
    """Decrypt a Chrome cookie value (v10 format on macOS)."""
    if encrypted_value[:3] != b"v10":
        # Unencrypted or unknown format
        return encrypted_value.decode("utf-8", errors="replace")

    encrypted_value = encrypted_value[3:]
    iv = b" " * 16
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    decryptor = cipher.decryptor()
    decrypted = decryptor.update(encrypted_value) + decryptor.finalize()

    # Remove PKCS7 padding
    padding_len = decrypted[-1]
    decrypted = decrypted[:-padding_len]

    # Chrome prepends a 32-byte integrity hash before the cookie value.
    # Try full decode first; if it fails, skip the 32-byte prefix.
    try:
        return decrypted.decode("utf-8")
    except UnicodeDecodeError:
        if len(decrypted) > 32:
            return decrypted[32:].decode("utf-8")
        raise


def find_chrome_profile(profile_name: str | None = None) -> Path:
    """Find the Chrome profile that has the otter.ai session cookie."""
    if not CHROME_DIR.exists():
        raise FileNotFoundError("Chrome not found at expected path.")

    if profile_name:
        cookies_path = CHROME_DIR / profile_name / "Cookies"
        if not cookies_path.exists():
            raise FileNotFoundError(f"No Cookies DB at {cookies_path}")
        return cookies_path

    # Search all profiles, prefer the one whose cookie matches the
    # currently configured value in the wrapper script.
    current_cookie = None
    if WRAPPER_SCRIPT.exists():
        m = re.search(
            r'OTTER_SESSION_COOKIE="([^"]+)"', WRAPPER_SCRIPT.read_text()
        )
        if m:
            current_cookie = m.group(1)

    candidates = ["Default", "Profile 1", "Profile 2", "Profile 3"]
    matches = []
    for name in candidates:
        cookies_path = CHROME_DIR / name / "Cookies"
        if not cookies_path.exists():
            continue
        tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
        tmp.close()
        shutil.copy2(cookies_path, tmp.name)
        for ext in ("-wal", "-shm"):
            wal = Path(str(cookies_path) + ext)
            if wal.exists():
                shutil.copy2(wal, tmp.name + ext)
        try:
            conn = sqlite3.connect(tmp.name)
            count = conn.execute(
                "SELECT COUNT(*) FROM cookies "
                "WHERE host_key LIKE ? AND name = ?",
                (f"%{OTTER_DOMAIN}%", COOKIE_NAME),
            ).fetchone()[0]
            conn.close()
        finally:
            os.unlink(tmp.name)
        if count > 0:
            matches.append((name, cookies_path))

    if not matches:
        raise FileNotFoundError(
            f"No Chrome profile has a '{COOKIE_NAME}' cookie for "
            f"{OTTER_DOMAIN}. Log into otter.ai in Chrome."
        )

    # If we know the current cookie, find the matching profile
    if current_cookie and len(matches) > 1:
        safe_key = get_chrome_safe_storage_key()
        key = derive_key(safe_key)
        for name, cookies_path in matches:
            db_path = copy_cookies_db(cookies_path)
            try:
                for cname, enc_value in get_otter_cookies(db_path):
                    if cname == COOKIE_NAME:
                        val = decrypt_cookie(enc_value, key)
                        if val == current_cookie:
                            return cookies_path
            except Exception:
                pass
            finally:
                os.unlink(db_path)

    # Fall back to last match (higher-numbered profiles are usually newer)
    return matches[-1][1]


def copy_cookies_db(cookies_path: Path) -> str:
    """Copy Chrome's cookies DB to a temp file (Chrome locks the original)."""
    tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    tmp.close()
    shutil.copy2(cookies_path, tmp.name)
    for ext in ("-wal", "-shm"):
        wal = Path(str(cookies_path) + ext)
        if wal.exists():
            shutil.copy2(wal, tmp.name + ext)
    return tmp.name


def get_otter_cookies(db_path: str) -> list[tuple[str, bytes]]:
    """Query all cookies for .otter.ai from the copied DB."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute(
        "SELECT name, encrypted_value FROM cookies "
        "WHERE host_key LIKE ? ORDER BY name",
        (f"%{OTTER_DOMAIN}%",),
    )
    rows = cursor.fetchall()
    conn.close()
    return rows


def list_cookies(profile: str | None = None):
    """Print all otter.ai cookies (for debugging)."""
    cookies_path = find_chrome_profile(profile)
    print(f"Using profile: {cookies_path.parent.name}")
    db_path = copy_cookies_db(cookies_path)
    try:
        rows = get_otter_cookies(db_path)
        if not rows:
            print(f"No cookies found for {OTTER_DOMAIN}")
            return

        safe_key = get_chrome_safe_storage_key()
        key = derive_key(safe_key)

        print(f"Cookies for {OTTER_DOMAIN}:\n")
        for name, enc_value in rows:
            try:
                value = decrypt_cookie(enc_value, key)
                preview = value[:20] + "..." if len(value) > 20 else value
            except Exception as e:
                preview = f"<decrypt error: {e}>"
            marker = " <--" if name == COOKIE_NAME else ""
            print(f"  {name}: {preview}{marker}")
    finally:
        os.unlink(db_path)


def extract_cookie(profile: str | None = None) -> str:
    """Extract and decrypt the Otter session cookie."""
    cookies_path = find_chrome_profile(profile)
    print(f"Using profile: {cookies_path.parent.name}")
    db_path = copy_cookies_db(cookies_path)
    try:
        rows = get_otter_cookies(db_path)
        if not rows:
            raise RuntimeError(
                f"No cookies found for {OTTER_DOMAIN}. "
                "Make sure you're logged into otter.ai in Chrome."
            )

        safe_key = get_chrome_safe_storage_key()
        key = derive_key(safe_key)

        for name, enc_value in rows:
            if name == COOKIE_NAME:
                return decrypt_cookie(enc_value, key)

        available = [name for name, _ in rows]
        raise RuntimeError(
            f"Cookie '{COOKIE_NAME}' not found for {OTTER_DOMAIN}. "
            f"Available: {available}"
        )
    finally:
        os.unlink(db_path)


def update_wrapper(cookie: str) -> bool:
    """Replace the session cookie in .mcp.json. Returns True if changed.

    Historically lived in otter-wrapper.sh; migrated to .mcp.json env. Falls
    back to the wrapper if .mcp.json has no OTTER_SESSION_COOKIE entry (for
    backwards compat).
    """
    if MCP_JSON.exists():
        content = MCP_JSON.read_text()
        if re.search(r'"OTTER_SESSION_COOKIE"\s*:\s*"[^"]*"', content):
            new_content = re.sub(
                r'"OTTER_SESSION_COOKIE"\s*:\s*"[^"]*"',
                f'"OTTER_SESSION_COOKIE": "{cookie}"',
                content,
            )
            if new_content == content:
                return False
            MCP_JSON.write_text(new_content)
            return True

    content = WRAPPER_SCRIPT.read_text()
    if not re.search(r'OTTER_SESSION_COOKIE="[^"]*"', content):
        raise RuntimeError(
            f"Could not find OTTER_SESSION_COOKIE in {MCP_JSON} or {WRAPPER_SCRIPT}"
        )
    new_content = re.sub(
        r'export OTTER_SESSION_COOKIE="[^"]*"',
        f'export OTTER_SESSION_COOKIE="{cookie}"',
        content,
    )
    if new_content == content:
        return False
    WRAPPER_SCRIPT.write_text(new_content)
    return True


def validate_cookie(cookie: str) -> bool:
    """Test if a cookie is valid by hitting the Otter API."""
    req = Request(OTTER_USER_URL)
    req.add_header("Cookie", f"sessionid={cookie}")
    try:
        with urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            return data.get("status") == "OK"
    except (HTTPError, URLError, json.JSONDecodeError):
        return False


def notify(title: str, message: str):
    """Send a macOS notification."""
    subprocess.run(
        [
            "osascript",
            "-e",
            f'display notification "{message}" with title "{title}"',
        ],
        capture_output=True,
    )


def get_current_cookie() -> str | None:
    """Read the current cookie from .mcp.json, falling back to the wrapper."""
    if MCP_JSON.exists():
        m = re.search(
            r'"OTTER_SESSION_COOKIE"\s*:\s*"([^"]+)"', MCP_JSON.read_text()
        )
        if m:
            return m.group(1)
    if not WRAPPER_SCRIPT.exists():
        return None
    m = re.search(
        r'OTTER_SESSION_COOKIE="([^"]+)"', WRAPPER_SCRIPT.read_text()
    )
    return m.group(1) if m else None


def parse_profile_arg() -> str | None:
    """Extract --profile value from argv."""
    for i, arg in enumerate(sys.argv):
        if arg == "--profile" and i + 1 < len(sys.argv):
            return sys.argv[i + 1]
        if arg.startswith("--profile="):
            return arg.split("=", 1)[1]
    return None


def main():
    profile = parse_profile_arg()

    if "--list" in sys.argv:
        list_cookies(profile)
        return

    if "--validate" in sys.argv:
        cookie = get_current_cookie()
        if not cookie:
            print("No cookie configured in wrapper script.")
            sys.exit(1)
        print(f"Testing cookie {cookie[:8]}...{cookie[-4:]}")
        if validate_cookie(cookie):
            print("Valid.")
        else:
            print("Expired or invalid.")
            notify("Otter Cookie Expired", "Run refresh-otter-cookie.py or log into otter.ai in Chrome.")
            sys.exit(1)
        return

    dry_run = "--dry-run" in sys.argv

    # Check if current cookie still works — skip refresh if so
    current = get_current_cookie()
    if current and not dry_run:
        if validate_cookie(current):
            print(f"Current cookie still valid ({current[:8]}...{current[-4:]}). Skipping refresh.")
            return

    print("Extracting Otter session cookie from Chrome...")
    try:
        cookie = extract_cookie(profile)
    except (FileNotFoundError, RuntimeError) as e:
        print(f"Extraction failed: {e}", file=sys.stderr)
        notify("Otter Cookie Refresh Failed", str(e))
        sys.exit(1)

    print(f"Found: {cookie[:8]}...{cookie[-4:]}")

    # Validate the extracted cookie before writing
    if validate_cookie(cookie):
        print("Cookie validated against Otter API.")
    else:
        print("WARNING: Extracted cookie failed validation.", file=sys.stderr)
        print("Chrome session may have expired. Log into otter.ai in Chrome.", file=sys.stderr)
        notify("Otter Cookie Invalid", "Log into otter.ai in Chrome to refresh your session.")
        sys.exit(1)

    if dry_run:
        print("Dry run — not updating wrapper script.")
        return

    if update_wrapper(cookie):
        print(f"Updated {WRAPPER_SCRIPT.name}")
        notify("Otter Cookie Refreshed", "Session cookie updated successfully.")
    else:
        print("Cookie unchanged — already up to date.")


if __name__ == "__main__":
    main()
