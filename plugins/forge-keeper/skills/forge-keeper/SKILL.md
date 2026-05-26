---
name: forge-keeper
description: >
  Keeps CLAUDE.md, rules, exemplars, and project documentation in sync.
  Activates explicitly with /forge-keeper:sync, or when the user says "update
  context", "sync docs", "session handoff", or "save progress". Also triggers
  automatically before /compact or /clear via hook, capturing context before
  it's lost.
---

# Forge Keeper

Keeps project context synchronized across Claude Code sessions.

## When to run

- When the human explicitly requests sync
- Automatically before `/compact` or `/clear` (via PreCompact hook)
- At the end of long sessions
- After significant architectural decisions

## Execution model

**Run sync as a subagent or teammate** to avoid polluting the user's working
context. The analysis happens in an isolated context. Only the structured
proposal returns to the main conversation for review.

- **Subagent** (default) — dispatch via Agent tool with the sync steps
- **Teammate** — if configured, dispatch as named teammate for parallel execution

The user sees only: brief announcement → structured proposal → confirmation.

## Sync process (6 steps)

For detailed criteria on each step, read the corresponding references.

1. **Analyze changes** — `git diff --name-only` to identify files, classify by zone
2. **Propose CLAUDE.md updates** — per zone, respecting limits.
   See `references/claudemd-guide.md`
3. **Propose .claude/rules/** — if new cross-cutting conventions emerged
4. **Evaluate code exemplars** — if `docs/exemplars.md` exists, check if
   exemplars are still the best reference. See `references/exemplar-evaluation.md`
5. **Check project docs** — `docs/`, `README.md`, `docs/adr/`
6. **Present structured proposal** — categorized by action type.
   See `references/proposal-format.md`

**DO NOT apply changes without explicit human confirmation.**

## Related commands

- `/forge-keeper:update-check` — check plugins for upstream updates and apply them

## References

- CLAUDE.md maintenance → `references/claudemd-guide.md`
- Monorepo patterns → `references/monorepo-patterns.md`
- Exemplar evaluation → `references/exemplar-evaluation.md`
- Proposal format → `references/proposal-format.md`
