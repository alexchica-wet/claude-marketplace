---
description: Repair stale plugin cache references by symlinking missing version directories. Run when sessions show "Plugin directory does not exist" hook errors after a plugin version bump.
---

# Heal plugin cache

When Claude Code bumps a plugin version mid-session, any session pinned to the
old version starts failing on every tool call with:

> Failed to run: Plugin directory does not exist:
> `~/.claude/plugins/cache/<marketplace>/<plugin>/<old-version>`

This command scans every session transcript for historical plugin version
paths and creates symlinks from missing version dirs → the currently-installed
version, so orphaned sessions keep working without a restart.

## When to run

- You see repeated `PreToolUse:X hook error` / `PostToolUse:X hook error` lines across many tools in the same session
- The root cause message mentions "Plugin directory does not exist"
- Immediately after running `/forge-commit:release` if older sessions are still open
- As a maintenance sweep when plugin versions have drifted

## Step 1 — Scan (dry-run)

Run the scanner in dry-run mode (no flags = dry-run). Default scope is **all**
session files. For a quicker scan focused on recently-active sessions, pass
`--mtime 7` (last 7 days):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/heal-plugin-cache.sh" --mtime 30
```

Present the output verbatim. The script reports two lists:

- **Proposed symlinks** — `<marketplace>/<plugin>/<version> -> <target>` entries
- **Unfixable references** — versions whose plugin has no cache directory at all (e.g. removed plugins). These cannot be healed and should be noted but not acted on.

If the proposed list is empty, say "Nothing to heal" and stop.

## Step 2 — Review

For each proposed symlink, do a sanity check:

- **Same marketplace + plugin, only version differs** → safe to shim
- **Target version is significantly newer** (major version jump) → flag it: hook scripts or entry points may have changed in ways that break the orphaned session. The user should confirm before applying or restart the orphaned session instead.
- **Target is an odd value** like `unknown` or a commit SHA → note it, but usually still safe since it's the currently-installed directory

Ask the user: "Apply these shims? (y/n)"

## Step 3 — Apply

If confirmed, re-run with `--apply`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/heal-plugin-cache.sh" --mtime 30 --apply
```

Report the count of symlinks created. Tell the user their orphaned sessions
should stop erroring on the **next** tool call — no restart needed, Claude
Code re-resolves the plugin path on every invocation.

## Notes

- Only creates symlinks. Never deletes, moves, or overwrites existing directories.
- Targets the highest real version directory on disk per plugin (symlinks are skipped when computing the target).
- Creates **relative** symlinks so the cache stays portable if you move `~/.claude`.
- Idempotent — safe to re-run. Already-resolved references are skipped.
- Scope flags:
  - `--cache-dir DIR` — override `~/.claude/plugins/cache`
  - `--projects-dir DIR` — override `~/.claude/projects`
  - `--mtime DAYS` — only scan session files modified within N days (faster)
