# Structured Proposal Format

Reference for forge-keeper step 6. Use this format to present sync results
to the user for approval.

## Format

Group all proposed changes by action type. For each change, explain WHAT
will change and WHY.

```
## Context Sync Proposal

### Update (refresh stale content)
- `CLAUDE.md` — [what changed and why]
- `apps/api/CLAUDE.md` — [what changed and why]

### Create (new knowledge worth capturing)
- `docs/adr/NNNN-title.md` — [decision and rationale]
- `.claude/rules/name.md` — [convention and scope]

### Archive (remove outdated content)
- `CLAUDE.md` line N-M — [what's outdated and why]

### Exemplars (code reference updates)
- Replace [category]: `old.ts` → `new.ts` — [why new is better]
- New category: "[name]" → `file.ts` — [what pattern it shows]

### Session log
- `docs/sessions/YYYY-MM-DD-title.md` — [preview of session entry]

### No changes needed
- `shared/CLAUDE.md` — still accurate
- `.claude/rules/testing.md` — still accurate
```

## Rules

- Every change must have a WHY — don't propose changes without explanation
- Group by action type, not by file — easier to review intent
- "No changes needed" section builds trust — shows you checked, not just skipped
- Include content previews for Create actions — user should see what will be written
- Keep the proposal concise — this is a summary, not a full diff
- Session log captures the user's personal bitácora — what was done and why,
  searchable later via `/forge-keeper:recall`

## User response handling

After presenting the proposal:
- **Approve all** → execute all changes
- **Approve selectively** → "apply 1, 2, and 4 but skip 3" → execute only approved
- **Request modifications** → adjust proposal, re-present
- **Reject** → no changes applied

## Post-approval

After applying approved changes:
- Brief confirmation: "Applied N changes."
