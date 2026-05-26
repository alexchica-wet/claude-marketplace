---
description: Lightweight session handoff — writes a concise resumption note to docs/sessions/ without updating CLAUDE.md/rules/docs. Use when stopping now (or passing to another agent) without committing to a full /forge-keeper:sync. Takes an optional argument describing what the next session will focus on.
argument-hint: "[optional: what the next session will focus on]"
allowed-tools: Bash(git:*), Bash(date:*), Bash(mkdir:*), Read, Write, Glob
---

<!-- Curated from mattpocock/skills · skills/productivity/handoff · MIT. Adapted: writes to docs/sessions/ instead of $TMPDIR so /forge-keeper:recall can find handoffs later; includes branch + last commit SHA + working-tree status for receiver orientation; explicitly contrasts itself against /forge-keeper:sync as the heavyweight option. -->

## Context

- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Last commit: !`git log -1 --oneline 2>/dev/null || echo "(no commits)"`
- Working tree status (top 20 lines): !`git status --short 2>/dev/null | head -20 || echo "(not a git repo)"`
- Existing sessions directory: !`test -d docs/sessions && echo "docs/sessions/ exists" || echo "docs/sessions/ does NOT exist — will be created"`

## Your task

Write a handoff document at `docs/sessions/<filename>.md` where filename is `$(date +%Y-%m-%d-%H%M)-handoff-<slug>.md`. Slug is kebab-case of `$ARGUMENTS` (when provided) or `session` (when no argument).

Create `docs/sessions/` if it doesn't exist.

### What the handoff captures

1. **Goal of this session** — one paragraph: what was the user trying to accomplish.
2. **Current state** — what's done, what's in progress, what's blocked. **Do NOT re-summarize git log / CLAUDE.md / commit messages** — reference them by path or SHA. The handoff captures what's stateful in YOUR HEAD right now, not what already lives in the repo.
3. **Open threads** — unresolved decisions, pending questions, design tradeoffs not yet picked.
4. **Next steps** — concrete first 1-3 actions the next session should take. Specific files, branches, or commands when possible.
5. **Skills to invoke next** — list of relevant dev-forge skills or slash commands (`/forge-superpowers:writing-plans`, `/forge-deep-review:deep-review`, etc.).
6. **References** — paths to plans, PRDs, ADRs, commits, branches touched, files modified. **Reference, don't duplicate.**

### Rules

- **Don't duplicate** content from CLAUDE.md, `.claude/rules/`, `docs/`, recent commits, or open PRs. Reference them by path/SHA.
- **Keep it under ~200 lines.** If it grows past that, you're re-summarizing the repo — go back to references-only.
- **Tailor to the argument** when `$ARGUMENTS` is given. If the user said "continue the prototype implementation", focus on prototype state, not on unrelated branches.
- **No commit, no push.** This is a working note. The user decides if/when to commit it.

### Suggested structure

```markdown
# Handoff — <one-line goal>

**When:** YYYY-MM-DD HH:MM
**Branch:** <branch>
**Last commit:** <short SHA> <message>
**Next session focus:** <from $ARGUMENTS or "open">

## Goal of this session
<one paragraph>

## Current state
- Done: <bullets, with references>
- In progress: <bullets>
- Blocked: <bullets, if any>

## Open threads
- <unresolved decision 1>
- <pending question 2>

## Next steps
1. <concrete action — file/branch/command>
2. <…>
3. <…>

## Skills to invoke next
- `/forge-...` — <why>
- `<skill-name>` — <why>

## References
- Plan: `docs/plans/<file>.md`
- Spec: `docs/<…>.md`
- Commits: `<short SHA>..HEAD`
- Files touched this session: `<paths>`
```

### After writing

Print:

> Handoff saved to `docs/sessions/<filename>.md`.
>
> To do a full sync of CLAUDE.md / rules / docs (heavyweight), run `/forge-keeper:sync`.
> To find this or earlier handoffs later, run `/forge-keeper:recall <keyword>`.
