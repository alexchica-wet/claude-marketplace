---
description: Analyze a monolithic .md file and propose segmenting it into smaller, focused documents for better context loading. Use when a doc is too large (>200 lines) to be effective as a single @import.
---

Analyze a markdown document and propose a better structure.

## When to use

- During forge-init when a discovered .md is too large for a single @import
- When the user has a monolithic doc (architecture guide, development checklist,
  reference) that they want to break up for Claude Code
- When a CLAUDE.md or reference file has grown beyond its line limits

## Process

### Step 1: Analyze the document

Read the file. Identify:
- Total line count
- Natural sections (## headings, --- separators, topic shifts)
- Which sections are zone-specific vs cross-cutting vs project-wide
- Which sections contain rules (conventions, patterns to follow)
  vs reference (architecture, explanations, context)

### Step 2: Propose segmentation

Present a plan showing where each section would go:

```
## Segmentation Proposal for [filename]

Current: [N] lines in one file

### Proposed structure:

Section "Domain entity patterns" (lines 12-85)
  → domains/CLAUDE.md as @import to domains/entity-patterns.md
  Reason: zone-specific, only relevant when working in domains/

Section "API error handling" (lines 86-140)
  → .claude/rules/api-errors.md (globs: apps/api/**)
  Reason: cross-cutting convention, applies to all API files

Section "Testing conventions" (lines 141-200)
  → .claude/rules/testing.md (globs: **/*.test.ts, **/*.spec.ts)
  Reason: cross-cutting, applies to specific file pattern

Section "Architecture overview" (lines 201-280)
  → root CLAUDE.md as @import to docs/architecture.md
  Reason: project-wide context, relevant everywhere

### Original file:
  → keep as-is OR replace with index pointing to new locations
```

### Step 3: Ask the user

- Which segments to accept
- Whether to keep the original file, replace it with an index, or delete it
- Any sections they want to handle differently

### Step 4: Execute

Only after user confirmation:
1. Create the segmented files
2. Add @imports to corresponding CLAUDE.md files
3. Create .claude/rules/ with globs where appropriate
4. Handle the original file as the user decided
5. Verify no broken references

## Guidelines

- Prefer fewer, larger segments over many tiny files
- Each segment should be self-contained — readable without the others
- Cross-cutting conventions → .claude/rules/ with globs (loaded only for matching files)
- Zone-specific content → @import in that zone's CLAUDE.md
- Project-wide context → @import in root CLAUDE.md
- Don't lose information — if unsure where something goes, keep it in a reference @import
