#!/bin/bash
# Force cookie auth, unset email/password to prevent fallback
unset OTTER_EMAIL
unset OTTER_PASSWORD
# OTTER_SESSION_COOKIE is passed via .mcp.json env
exec otter-mcp
