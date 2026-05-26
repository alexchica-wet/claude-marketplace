# CLAUDE.md Maintenance Guide

Reference for forge-keeper's sync process. Use this when updating CLAUDE.md
files after development sessions.

## When to Update CLAUDE.md

Update when the session introduced:
- **New conventions** — a pattern was established that future sessions should follow
- **Changed commands** — build/test/deploy commands were modified
- **Architectural shifts** — new modules, changed boundaries, restructured directories
- **Gotchas discovered** — bugs found, workarounds needed, non-obvious behavior
- **Dependencies changed** — new libraries that affect code patterns

Do NOT update for:
- Routine code changes within existing patterns
- Bug fixes that don't reveal new gotchas
- File additions that follow existing conventions
- Dependency version bumps without pattern changes

## Incremental Update Process

### 1. Read the current CLAUDE.md

Before proposing changes, read the existing file completely. Understand
what's already documented and what's missing.

### 2. Identify what the session adds

Compare session changes against existing content:
- Is this genuinely new information?
- Does it modify something already documented?
- Does it make existing content obsolete?

### 3. Propose minimal changes

- **Add** new instructions only if they're non-obvious and recurring
- **Update** existing instructions if they've become stale
- **Remove** instructions that are no longer accurate
- **Never** just append — integrate into the right section

### 4. Respect line limits

After your changes, count lines:
- Root CLAUDE.md: ~200 lines max
- Child CLAUDE.md: ~100 lines max

If over limit, prune in this order:
1. Remove what Claude already knows from training
2. Remove what's duplicated from config files
3. Merge similar or overlapping instructions
4. Move detailed guidance to @imports
5. Remove the oldest or most well-established conventions

### 5. Detect unconnected .md documentation

If the session created or modified .md files with development context
(guides, checklists, architecture docs, READMEs — any name, any location),
check that they're wired into the context system:

- Zone-specific .md → @import in that zone's CLAUDE.md
- Project-wide .md → @import in root CLAUDE.md
- .md with cross-cutting rules → extract to `.claude/rules/` with globs

If a .md exists but isn't connected via @import, propose adding it. If it's
monolithic (>200 lines), note it and suggest the user run `/forge-keeper:segment-doc`
to break it into focused pieces.

## What Makes a Good Update

Good CLAUDE.md updates share these qualities:

**Specific and verifiable:**
```
# Good: "API routes use kebab-case: /user-profiles, /auth-tokens"
# Bad: "Follow REST naming conventions"
```

**Actionable:**
```
# Good: "Run `pnpm db:migrate` before `pnpm dev` after pulling"
# Bad: "Make sure the database is up to date"
```

**Non-obvious:**
```
# Good: "The payments module uses a saga pattern — don't call
#        services directly, dispatch events through the saga"
# Bad: "Use dependency injection for services"
```

## Handling Conflicts

When a session's findings conflict with existing CLAUDE.md content:

1. **Verify the conflict is real** — read the code to confirm
2. **Update, don't append** — remove the old instruction, add the new one
3. **Add context** — explain why it changed if non-obvious
4. **Check children** — if root changed, verify children are still consistent

## Session Summary Format

Every sync should produce a session summary in `docs/sessions/`:

```
## Session: YYYY-MM-DD — [descriptive title]

### Changes made
- [Concrete list of what changed]

### Decisions taken
- [Decision]: [rationale]

### Current status
- Completed: [finished items]
- In progress: [partial items]
- Pending: [identified but not started]

### Context for next session
- [What a fresh Claude session needs to know to continue]
```

The "Context for next session" section is the most valuable. Write it
as if briefing a colleague who knows the codebase but wasn't in the room.

## Rules for .claude/rules/ Updates

Only propose new rules when:
- A convention applies to multiple directories (cross-cutting)
- The convention needs path scoping (different rules for different files)
- It's not already in a CLAUDE.md file

Rule frontmatter format:
```yaml
---
description: What this rule enforces
globs: **/*.test.ts, **/*.spec.ts
---
```

Prefer CLAUDE.md for directory-specific conventions. Use `.claude/rules/`
for cross-cutting patterns that span the project.
