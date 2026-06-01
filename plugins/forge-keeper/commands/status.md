---
description: Shows project context health — CLAUDE.md files, drift detection, rules coverage, adherence check, and AGENTS.md sync status.
---

Generate a context health report with 6 checks:

## 1. CLAUDE.md inventory

List all CLAUDE.md files with last modification date. Compare against recently
modified files (`git log --since="1 week"`) to identify zones with drift.

## 2. Rules coverage

List `.claude/rules/` files with their path scopes (globs from frontmatter).

## 3. Drift detection (convention adherence)

Sample 3-5 recently modified files (`git log --oneline -10`, pick varied zones).
For each, spot-check against CLAUDE.md instructions:
- Does the code follow the declared conventions?
- Are there patterns that contradict documented rules?
- Are there new conventions that should be documented?

Flag only clear violations, not style nitpicks.

## 4. AGENTS.md sync status

If AGENTS.md exists at project root, compare its content against CLAUDE.md.
Flag if CLAUDE.md has conventions/commands/architecture that AGENTS.md is missing.
If AGENTS.md doesn't exist, note: "No AGENTS.md — run /forge-init:init to generate one for cross-tool compatibility."

## 5. Session diary freshness

Show last session summary from `docs/sessions/` if one exists.
If the last entry is older than 3 days and there are recent commits, flag stale.

## 6. Line limit check

Count lines in each CLAUDE.md. Flag root > 200 or child > 100.

## Output format

```
Context health — [project name]

CLAUDE.md             Last updated       Lines    Status
──────────────────────────────────────────────────────────
./CLAUDE.md           2 days ago         142/200  [warn] 12 files changed since
apps/api/CLAUDE.md    1 week ago          87/100  [ok]
apps/web/CLAUDE.md    does not exist       —      [missing] 43 files without context

Rules                 Scope
──────────────────────────────────────────────────────────
testing.md            **/*.test.ts, **/*.spec.ts
security.md           domains/**, shared/auth/**

Adherence spot-check (sampled 4 files):
  ✓ src/api/routes.ts — follows kebab-case convention
  ⚠ src/utils/helpers.ts — uses default export (CLAUDE.md says named exports)
  ✓ tests/auth.test.ts — follows describe/it pattern

AGENTS.md             [ok] in sync | [warn] 3 conventions missing | [missing]

Last session: YYYY-MM-DD — "title" (2 days ago)
```
