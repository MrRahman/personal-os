# .claude/state/

Runtime state cache for Personal OS hooks + skills. **Gitignored** — this directory is local-only and ephemeral.

## Files

- `health.json` — output of `mcp-servers/healthcheck.sh`. Updated at every SessionStart by `.claude/hooks/sessionstart-health.sh`. Schema: `{timestamp, pass, fail, services: [{service, required, status, detail}]}`.
- `drift.json` — output of `mcp-servers/drift-check.sh`. Updated at every SessionStart by `.claude/hooks/sessionstart-drift.sh`. Schema: `{timestamp, releases, memory, goals, waiting_on}`.

Skills read these files rather than re-running detection on every invocation — keeps `/morning-plan`, `/reflect`, `/weekly-review` fast.

## Regenerating manually

If the cache is stale or you want a fresh check:

```bash
./mcp-servers/healthcheck.sh      # updates health.json
./mcp-servers/drift-check.sh      # updates drift.json
```

Both are idempotent and safe to run anytime.
