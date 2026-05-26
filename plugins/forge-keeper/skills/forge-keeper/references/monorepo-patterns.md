# Monorepo Patterns for CLAUDE.md

Reference for managing Claude Code context in monorepo projects.

## Root vs Child Scope

In a monorepo, CLAUDE.md files form a hierarchy:

```
CLAUDE.md                    ← project-wide: stack, architecture, shared commands
apps/api/CLAUDE.md           ← API-specific: endpoints, middleware, DB patterns
apps/web/CLAUDE.md           ← web-specific: components, routing, state
domains/CLAUDE.md            ← domain layer: DDD patterns, aggregate rules
shared/CLAUDE.md             ← shared libs: versioning, cross-package impact
```

### Root CLAUDE.md responsibilities
- Project purpose and architecture overview
- Shared commands (build all, test all, lint all)
- Cross-cutting conventions (error handling, logging, naming)
- Monorepo-specific gotchas (dependency hoisting, build order)
- @imports to detailed docs

### Child CLAUDE.md responsibilities
- Directory-specific stack and tooling
- Commands that differ from root (e.g., different test runner)
- Patterns unique to this zone
- Local gotchas and workarounds

### The supplement rule

Children supplement the root, they never override it. If root says
"use Prettier for formatting", a child should not contradict this.
If a child needs an exception, document the WHY explicitly.

## Lazy Loading Behavior

Claude Code loads CLAUDE.md files lazily:
- Root CLAUDE.md is always loaded
- Child CLAUDE.md files load when Claude reads or edits files in that directory
- Deep children (e.g., `apps/api/src/modules/auth/CLAUDE.md`) only load when
  working in that specific path

Design your CLAUDE.md hierarchy knowing that Claude may not have loaded
a child's context. Don't rely on child instructions for cross-cutting behavior.

## Path-Scoped Rules (.claude/rules/)

For conventions that apply to specific file patterns across the entire project,
use `.claude/rules/` with glob patterns:

```yaml
# .claude/rules/testing.md
---
description: Testing conventions for all test files
globs: **/*.test.ts, **/*.spec.ts, **/*.test.tsx
---

- Use describe/it blocks, not standalone test()
- Mock external services, never the database
- Each test file mirrors its source file path
- Use factories for test data, not inline literals
```

```yaml
# .claude/rules/security.md
---
description: Security rules for domain and auth code
globs: domains/**, shared/auth/**
---

- Never log PII (email, phone, tokens)
- All auth checks go through the AuthGuard — no inline token parsing
- Domain errors must not leak internal state to API responses
```

### When to use rules vs CLAUDE.md

| Scenario | Use |
|----------|-----|
| Convention specific to one directory | That directory's CLAUDE.md |
| Convention for a file pattern across dirs | `.claude/rules/` with globs |
| Project-wide convention | Root CLAUDE.md |
| Exception to a root convention | Child CLAUDE.md with explanation |

## Zone Detection

When classifying changes by zone, use the first path segment:

```
apps/api/src/users.ts     → zone: apps/api
apps/web/src/App.tsx       → zone: apps/web
domains/auth/entities.ts   → zone: domains
shared/utils/helpers.ts    → zone: shared
scripts/deploy.sh          → zone: scripts
```

For flat projects (no monorepo), treat the root as a single zone and
classify by concern instead (e.g., "routing", "models", "tests").

## claudeMdExcludes

Some directories should never have or trigger CLAUDE.md loading:

```json
// .claude/settings.json
{
  "claudeMdExcludes": [
    "node_modules",
    "dist",
    "build",
    ".next",
    "coverage",
    "generated"
  ]
}
```

Add directories that contain generated code, build artifacts, or
dependencies. This prevents Claude from loading irrelevant context.

## Conflict Resolution

When root and child CLAUDE.md have conflicting instructions:

1. **Root wins by default** — it sets project-wide standards
2. **Child can override with explicit justification** — document WHY
3. **If the override is common**, consider updating root instead
4. **If it's a cross-cutting pattern**, move to `.claude/rules/`

Example of justified override:
```markdown
# apps/legacy-api/CLAUDE.md

## Conventions
# NOTE: This module uses callbacks instead of async/await (root convention)
# because it depends on a legacy library that doesn't support promises.
# Migration tracked in JIRA-1234.
- Use callback pattern for all async operations in this module
- New code that doesn't touch the legacy library CAN use async/await
```
