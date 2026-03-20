#!/bin/bash
# Force cookie auth, unset email/password to prevent fallback
unset OTTER_EMAIL
unset OTTER_PASSWORD
export OTTER_SESSION_COOKIE="n3mbbdnematgodviij4fvux7rf4eywq9"
exec /Users/sulaimanrahman/.local/bin/otter-mcp
