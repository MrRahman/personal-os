---
name: Cognition application — May 2026
description: Active job application to Cognition AI Business Operations role; resume positioned as "operator who builds"
type: project
---

Applied to Cognition AI (makers of Devin + Windsurf) Business Operations role on 2026-05-28. JD URL: https://jobs.ashbyhq.com/cognition/170ec744-c6b9-4d75-bdb1-f1eaf5e24d79

**Resume positioning locked:** "Operator who builds." Selected Builds section above Experience surfaces 4 AI projects (Personal OS, AI Transformation @ Ripple, Competitive Intel Agency, Breezy at breezy.xyz). Summary leads with builder identity, addresses 19yrs→3-5yrs seniority gap with "consolidate operator and builder into one seat."

**Why:** Cognition values dogfooding agents (they make Devin). AI builds are the differentiator vs. other VPs applying. Persona debate (recruiter / hiring manager / exec coach) consensus.

**Files (FINAL, as of 2026-05-29):**
- **Submit this:** `~/Downloads/Sulaiman Rahman Resume.pdf` — v2, one page, HTML/CSS → headless-Chrome PDF. Clean metadata. Visually verified.
- **ATS fallback:** `~/Downloads/Sulaiman Rahman Resume.docx` — same v2 copy, clean core props (author=Sulaiman Rahman). Build script: `/tmp/resume-build/build_resume_v2.py`.
- Source HTML: `/tmp/resume-build/resume.html` (Newsreader + IBM Plex Sans; near-monochrome ink; hairline rules).
- Superseded: `~/Downloads/Sulaiman Rahman Resume - May 28 2026.docx` (old copy + python-docx design).
- Handoff context: `~/Downloads/Cognition Resume — Context Handoff.md`

**Key truths corrected (2026-05-29, Sul):** (1) URL is **breezy-app.xyz** (not breezy.xyz). (2) Breezy shipped in **a few weeks**, not 2 months. (3) He **did NOT hand-write code** — he architected/directed Claude Code; the agent wrote it. Resume now says so explicitly ("built by directing Claude Code," "the agent wrote the code," "Claude built it") — a strength at Cognition (Devin makers), not a hedge. Never reintroduce "I wrote in Python." (4) Positioning is NOT "rather build than manage" — it's **wants the earlier seat at a smaller company: build a function from the ground up instead of inheriting one, and grow into leading it** (the role offers a path to functional lead). He's seen companies scale; now wants to build from zero.

**v2 work (2026-05-29):** Re-ran 3 personas as line-editors + dedicated de-AI pass. Killed em-dash monotony, the "trust/speed/low-ego" values-echo close, rule-of-three triads, buzzwords. Rewrote builds in builder voice ("I wrote/coded/shipped"). Added links line + Build/Operate skills split; named the down-level as deliberate. Design rebuilt as polished 1-pager. User-confirmed: keep "tracks ROI by function"; Operate line = quarterly planning & goal-setting + OKRs; keep "Nineteen years."

**Render gotchas (macOS):** headless Chrome can't read `~/Downloads` (TCC) — build in `/tmp`. Bash sandbox grants Downloads access but disabling it loses that; Chrome never has it. Use `--no-pdf-header-footer`, fresh `--user-data-dir`, `--disable-cache`, unique render filename (Chrome caches file:// by path). pypdf in docx-tools venv sets clean metadata.

**Still open before submit:** GitHub housekeeping done enough (personal-os IS pinned, profile fine per Sul). 

**v3 structure (2026-05-29, latest):** (a) Removed ALL em-dashes (—); en-dashes in date ranges kept (standard). (b) Experience reformatted to match his Jan-21 original: company listed once, roles nested beneath, each role opens with an impact sentence then detail bullets. (c) All links clickable (PDF link annotations + real docx w:hyperlink relationships): email, linkedin, github, breezy-app.xyz, personal-os repo. (d) Four summary-closer variants built + scored by 3 agents (recruiter, hiring manager, AI-ATS):
- vA Arc (35/31/32), vB Bold (44/39/32 — humans' #1, "dogfooding is just my Tuesday"), vC Concrete (36/37/44 — ATS #1, keyword-rich + lowest AI-text risk), **vD Hybrid (all 3 agents independently converged on this; ~43-45 every axis)** = C's concrete receipts spine + B's Tuesday line, em-dash-free, soft tells cut.
- Render gotcha learned: macOS `date +%N` is literal (BSD) → profile-dir collisions hang Chrome; use `$RANDOM-$$` for unique `--user-data-dir`, render one at a time. Chrome also hangs AFTER writing print-to-pdf; the PDF is written, just pkill it and finalize separately.

**FINAL (2026-05-29, submit these):** `~/Downloads/Sulaiman Rahman Resume.pdf` + `.docx` (variant files cleared). Build: `/tmp/resume-build/resume_base.html` (PDF source) + `/tmp/resume-build/build_final.py` (docx). 2 pages, zero em-dashes, 6 clickable links, clean metadata.
- **Summary = V6 (hybrid)**: all 3 scoring agents ranked V5 "Operator who builds" thesis #1 of five, and all 3 independently proposed the same hybrid. Final = V5 spine + V4's "the gap between an idea and a working system has gone from quarters to days" + de-tell'd antithesis + Credit Karma as co-anchor (build-from-zero through-line) + "data and analytics / corporate strategy" keywords. 
- Sul's last refinements applied: subhead drops breezy-app (kept LinkedIn+GitHub); removed the repeated "clause: list" colon construction (AI tell) leaving exactly ONE grammatically-clean colon; Selected Builds header → (2026); Personal OS → "(3 custom)"; Breezy commits line removed.
- Voice: FIRST person (his established voice), no second-person address ("your engineers" was cover-letter voice that had leaked in — removed). Honest AI-direction framing throughout ("I set the architecture and the requirements, and the agent writes the code").
