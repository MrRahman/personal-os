#!/bin/bash
# Personal OS v3.0 — cost monitor (Phase 5). Read-only.
#
# Sums `total_cost_usd` from the background-job run-logs (.claude/logs/*.jsonl:
# daily-brief, otter-sync, cadence-*) over a window, grouped by job, with a rough
# monthly projection. The user accepted background cost but wanted to watch it; this
# is the cheap awareness tool. No network, no writes. Usage: cost-report.sh [days]
set -uo pipefail
REPO="/Users/sulaimanrahman/projects/personal-os"
DAYS="${1:-30}"

/usr/bin/python3 - "$REPO/.claude/logs" "$DAYS" <<'PY'
import sys, json, glob, os, datetime
logdir, days = sys.argv[1], int(sys.argv[2])
cutoff = (datetime.date.today() - datetime.timedelta(days=days)).isoformat()
by_job, total, runs = {}, 0.0, 0
for f in sorted(glob.glob(os.path.join(logdir, "*.jsonl"))):
    if os.path.basename(f)[:10] < cutoff:   # filenames start YYYY-MM-DD
        continue
    for line in open(f, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
        except Exception:
            continue
        c = d.get("cost_usd")
        if isinstance(c, (int, float)):
            job = d.get("job", "?")
            by_job[job] = by_job.get(job, 0.0) + c
            total += c
            runs += 1
print(f"Background-job cost — last {days} days ({runs} runs with recorded cost):")
for job in sorted(by_job, key=lambda j: -by_job[j]):
    print(f"  {job:26s} ${by_job[job]:7.2f}")
print(f"  {'-'*26} {'-'*8}")
print(f"  {'TOTAL':26s} ${total:7.2f}")
if days > 0 and total > 0:
    print(f"  {'~monthly projection':26s} ${total / days * 30:7.2f}")
PY
