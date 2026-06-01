---
description: Check plugins for upstream updates, show changes and conflicts with local customizations, and optionally apply updates.
---

Check all external plugins for upstream updates and optionally apply them.

**Step 1 — Scan plugins**
Scan all `plugins/*/.claude-plugin/customizations.json`. Classify each plugin:
- External: has `origin.type = "github"` → eligible for update check
- Native: `origin.type = "native"` or no `customizations.json` → skip

See `references/update-check-guide.md` § Plugin scanning.

**Step 2 — Check upstreams**
For each eligible plugin, check upstream for new versions using `gh api` (primary) or `git ls-remote` (fallback). Present a quick summary table:

```
Plugin                  Current     Latest      Status
────────────────────────────────────────────────────────────
forge-superpowers       v5.0.6      v5.1.0      ⚡ 2 releases ahead
forge-deep-review       v2.3.0      v2.3.0      ✓ up to date
forge-hookify           v1.0.0      v1.1.0      ⚡ 1 release ahead  ⚠ 1 conflict
```

See `references/update-check-guide.md` § Upstream check and § Quick summary format.

**Step 3 — Detail on request**
Ask: "Want details on any plugin? Enter name(s), 'all', or Enter to skip."

For each requested plugin, show releases/commits since current version and conflict analysis against `customizations[]` entries.

See `references/update-check-guide.md` § Detailed view per plugin.

**Step 4 — Apply on request**
Ask: "Apply updates? Enter plugin name(s), or Enter to skip."

For each plugin to update, offer three choices:
- **apply** — sync upstream clone in `.upstream/`, copy changes, preserve local customizations
- **reset** — copy fresh from `.upstream/`, clear customizations
- **skip** — leave as-is

Uses persistent full clones in `.upstream/` (gitignored). First apply clones, subsequent
applies fetch. One clone per upstream repo, shared across plugins from the same repo.

Execute the chosen action and show a post-update summary.

See `references/update-check-guide.md` § Apply update flow.
