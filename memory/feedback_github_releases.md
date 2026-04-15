---
name: Use GitHub Releases not git tags
description: Always use `gh release create` for versioned releases — never `git tag` alone. User has corrected this repeatedly.
type: feedback
---

Always use `gh release create vX.Y --title "..." --notes "..."` to create releases. NEVER use `git tag -a` followed by `git push --tags` — that creates a tag without a Release page on GitHub.

**Why:** The user wants proper GitHub Releases with release notes visible on the repo's Releases page, not just lightweight tags in the git history. Tags alone don't show up as releases on GitHub.

**How to apply:** When the user asks to release/version/ship, use the `gh` CLI to create a release. Include a descriptive title and markdown release notes summarizing what changed.
