# Exemplar Evaluation

Reference for forge-keeper step 4. Use this when evaluating whether code
exemplars are still the best reference after session changes.

## When to evaluate

Only if the project has `docs/exemplars.md` (created by forge-init).
Skip this step entirely if no exemplars file exists.

## Evaluation criteria

For each exemplar listed in `docs/exemplars.md`, check:

### Exemplar file was modified

Was the change an improvement or a regression?
- Still exemplary → no action
- Degraded (added workarounds, broke pattern) → flag for replacement

### Better example emerged

Did this session produce a file that's now cleaner than the current exemplar
for its category?
- Compare the new file against the current exemplar
- If clearly better, propose replacement with explanation
- "Better" means: cleaner structure, follows newer conventions, better
  error handling, more readable

### New category needed

Did the session introduce a new pattern type that deserves its own exemplar?
- Only if the pattern will recur across the project
- Don't create exemplars for one-off implementations

### Exemplar outdated

Does the exemplar use patterns the project has moved away from?
- If the team adopted a new convention and the exemplar still uses the old one
- Propose replacement or removal

## Include in proposal

Add exemplar changes to the structured proposal under their own section:

```
### Exemplars (code reference updates)
- Replace [category] exemplar: `old-file.ts` superseded by `new-file.ts`
  (uses new [pattern] convention)
- New category: "[name]" → `file.ts` (demonstrates [pattern])
- Remove: `file.ts` no longer exemplary (adopted [old pattern])
```
