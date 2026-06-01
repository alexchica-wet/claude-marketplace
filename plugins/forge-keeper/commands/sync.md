---
description: Syncs CLAUDE.md, rules, docs and memories with the current session's changes. Analyzes git diff, classifies by zone, proposes updates for human review.
---

Run the forge-keeper skill to synchronize project context.

Steps:
1. Analyze session changes via git diff
2. Classify changes by monorepo zone
3. Propose updates to affected CLAUDE.md files
4. Propose .claude/rules/ additions if new conventions emerged
5. Generate session summary
6. Present everything for human approval

DO NOT apply changes without explicit human confirmation.
