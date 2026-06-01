# Update Check Guide

Reference for checking and applying upstream updates to external plugins in dev-forge.
Use this when running an update check, reviewing upstream changes, or applying a merge.

## Plugin Scanning

Scan every plugin directory to find which ones have upstream sources to check.

### Steps

1. List all plugins: `plugins/*/.claude-plugin/customizations.json`
2. For each file found, read and classify the plugin:

**Single-origin plugins** (`origin` key, singular) — e.g., forge-superpowers:
```json
{ "origin": { "type": "github", "repo": "obra/superpowers", "ref": "v5.0.6", ... } }
```

**Multi-origin plugins** (`origins` key, array) — e.g., forge-deep-review:
```json
{ "origins": [ { "repo": "anthropics/claude-code", "path": "plugins/pr-review-toolkit", "ref": "main" }, ... ] }
```

**Native plugins** (`origin.type: "native"`) — e.g., forge-proactive-qa:
```json
{ "origin": { "type": "native", "note": "..." } }
```

### Skip rules

- Skip `origin.type: "native"` — no upstream, nothing to check
- Skip plugins with no `customizations.json` — they are native dev-forge plugins
- If `origins` array contains an entry with `type: "native"`, skip only that entry

### Collected data per plugin

For each non-skipped plugin, record:
- Plugin name (directory name under `plugins/`)
- customizations.json path
- Origin(s): repo, path (may be empty string), current ref, fetched_at
- Customizations list: id, type, target, summary, reason
- Whether it's single-origin or multi-origin

---

## Upstream Check

Determine whether newer versions exist for each origin.

### Tag-style refs (e.g., v5.0.6)

A ref that starts with `v` followed by a version number is a tag-style ref.

**Primary method — GitHub releases API:**
```bash
gh api repos/{owner}/{repo}/releases/latest --jq '{tag: .tag_name, published: .published_at, body: .body}'
```
Example for forge-superpowers:
```bash
gh api repos/obra/superpowers/releases/latest --jq '{tag: .tag_name, published: .published_at, body: .body}'
```

**Fallback — git ls-remote:**
```bash
git ls-remote --tags https://github.com/{owner}/{repo}.git 'refs/tags/v*'
```
Parse the output, strip `refs/tags/` prefix, pick the highest semver tag.

**Determine if updates exist:** compare current `ref` against latest tag using semver ordering. If latest > current → `has_updates: true`.

### Branch refs (e.g., main)

A ref that matches a branch name (main, master, etc.) is a branch ref.

**Primary method — GitHub commits API:**
```bash
gh api repos/{owner}/{repo}/commits/{branch} --jq '{sha: .sha, date: .commit.committer.date, message: .commit.message}'
```
Example for forge-deep-review (checking `anthropics/claude-code`, branch `main`):
```bash
gh api repos/anthropics/claude-code/commits/main --jq '{sha: .sha, date: .commit.committer.date, message: .commit.message}'
```

**Fallback — git ls-remote:**
```bash
git ls-remote https://github.com/{owner}/{repo}.git refs/heads/{branch}
```
Returns the current commit SHA for the branch tip.

**Determine if updates exist:** compare current `commit` SHA against latest SHA. If different and `commit` field is non-empty → `has_updates: true`. If current `commit` is empty, record the latest SHA but treat as "unknown — needs baseline commit recorded".

### Subpath repos (forge-deep-review pattern)

When `path` is non-empty (e.g., `"path": "plugins/pr-review-toolkit"`), there is no per-subdirectory release. Check the repo-level latest commit and note the subpath:

```bash
gh api repos/anthropics/claude-code/commits/main --jq '{sha: .sha, date: .commit.committer.date}'
```

To find commits that touched the specific subpath (more precise):
```bash
gh api "repos/anthropics/claude-code/commits?path=plugins/pr-review-toolkit&sha=main&per_page=1" --jq '.[0] | {sha: .sha, date: .commit.committer.date, message: .commit.message}'
```

### Multi-origin plugins

Check each origin in the `origins` array independently, using the method appropriate to its `ref` type. Each origin has its own repo, path, and ref — treat them as separate checks.

---

## Quick Summary Format

After scanning all plugins and checking upstreams, produce a table:

```
Plugin Update Status — 2026-03-31
═══════════════════════════════════════════════════════════════════════
Plugin                  Upstream                     Current    Latest     Status
─────────────────────── ──────────────────────────── ────────── ────────── ──────
forge-superpowers       obra/superpowers             v5.0.6     v5.1.0     ⚡
forge-deep-review       anthropics/claude-code       main       main       ✓
forge-hookify           anthropics/claude-code       main       main       ✓
forge-security          anthropics/claude-code       main       main       ✓
forge-commit            anthropics/claude-code       main       main       ✓
forge-frontend-design   anthropics/claude-plugins-official  main  main     ✓
forge-telegram          —                            —          —          ⊘ (native)
forge-proactive-qa      —                            —          —          ⊘ (native)
forge-keeper            —                            —          —          ⊘ (native)
═══════════════════════════════════════════════════════════════════════
⚡ 1 plugin has updates   ✓ 5 up to date   ⊘ 3 skipped
```

**Status icons:**
- `⚡` — updates available
- `✓` — up to date
- `⊘` — skipped (native or no customizations.json)

After the table, list any plugins with updates and one-line summaries:
```
⚡ forge-superpowers: v5.0.6 → v5.1.0 — "Inline self-review + brainstorm server improvements"
   ⚠ 1 potential conflict (skills/brainstorming/SKILL.md — modified in custom-12)
```

---

## Detailed View Per Plugin

When the user asks for details on a specific plugin or on all plugins with updates, produce the detailed view.

### Format

```
forge-superpowers
  Origin:   obra/superpowers @ v5.0.6 (fetched 2026-03-29)
  Latest:   v5.1.0 (2026-04-15)
  Releases since current: 2

  v5.1.0 (2026-04-15): Inline self-review replacing subagent loops
    Files changed: skills/brainstorming/SKILL.md, hooks/hooks.json, hooks/session-start
    ⚠ skills/brainstorming/SKILL.md — conflicts with custom-12 (modified: reduced trigger sensitivity)
    ✓ hooks/hooks.json — conflicts with custom-13 (modified: removed Cursor platform detection)
    ✓ hooks/session-start — conflicts with custom-14 (modified: Claude Code only)

  v5.0.7 (2026-04-01): Bug fixes for session-start hook
    Files changed: hooks/session-start
    ⚠ hooks/session-start — conflicts with custom-14 (modified: Claude Code only)
```

### Conflict analysis rules

For each file changed upstream, cross-reference against local `customizations[]`:

- **`modified` customization + same file changed upstream** → `⚠` potential conflict. Show: `⚠ {file} — conflicts with {id} ({summary})`
- **`removed` customization + same file or parent dir changed upstream** → `⚠` flag. Show: `⚠ {file} — you removed this (reason from customization)`
- **`excluded` customization + significant changes to excluded dir upstream** → `⚠` flag. Show: `⚠ {dir} — excluded (reason), but upstream changed it significantly`
- **`added` customization + file changed upstream** → no conflict (local-only additions don't conflict). Show: `✓ local addition — no upstream conflict`
- **No matching customization** → `✓` clean. Show: `✓ {file} — no conflicts`

"Significant change" for excluded dirs: if upstream release notes mention the excluded area explicitly, or if more than 3 files changed inside it.

### Fetching changed files for a release

To get the list of files changed in a specific release (tag-based):
```bash
gh api repos/{owner}/{repo}/compare/{old_tag}...{new_tag} --jq '.files[].filename'
```
Example:
```bash
gh api repos/obra/superpowers/compare/v5.0.6...v5.1.0 --jq '.files[].filename'
```

For branch-based, compare commit SHAs:
```bash
gh api repos/{owner}/{repo}/compare/{old_sha}...{new_sha} --jq '.files[].filename'
```

When the subpath is non-empty, filter files to only those under the subpath:
```bash
gh api "repos/anthropics/claude-code/compare/{old_sha}...{new_sha}" \
  --jq '.files[].filename | select(startswith("plugins/pr-review-toolkit/"))'
```

**Local alternative (when `.upstream/` exists):** If the upstream clone is already cached from
a previous apply, you can use git locally instead of the GitHub API — faster and no rate limits:
```bash
git -C .upstream/{slug}/ diff --name-only {old-ref}..{new-ref} -- {subpath}
```

---

## Apply Update Flow

When the user confirms they want to apply an update to a plugin, follow these 7 steps.

Upstream clones are stored persistently in `.upstream/` (gitignored). One full clone per
upstream repo, shared across all plugins from that repo. First run clones, subsequent runs
fetch. Full clones enable `git diff` between any two refs for precise change detection.

### Repo slug convention

Derive the clone directory from the repo name: replace `/` with `-`.
- `obra/superpowers` → `.upstream/obra-superpowers/`
- `anthropics/claude-code` → `.upstream/anthropics-claude-code/`
- `anthropics/claude-plugins-official` → `.upstream/anthropics-claude-plugins-official/`

### Step 1 — Ensure upstream clone

```bash
SLUG=$(echo "{repo}" | tr '/' '-')

# First time: full clone
if [ ! -d ".upstream/$SLUG" ]; then
  git clone "https://github.com/{repo}.git" ".upstream/$SLUG"
fi

# Subsequent: fetch latest
git -C ".upstream/$SLUG" fetch --all --tags

# Checkout target ref (tag or branch)
git -C ".upstream/$SLUG" checkout {target-ref}

# For branch refs, fast-forward to latest:
git -C ".upstream/$SLUG" pull 2>/dev/null || true
```

Source path: `.upstream/{slug}/{origin.path}/` (empty path = repo root).

Example for forge-superpowers:
```bash
git -C .upstream/obra-superpowers/ fetch --all --tags
git -C .upstream/obra-superpowers/ checkout v5.0.7
# Source: .upstream/obra-superpowers/.claude-plugin/
```

Example for forge-commit (subpath plugin):
```bash
git -C .upstream/anthropics-claude-code/ fetch --all --tags
git -C .upstream/anthropics-claude-code/ checkout main
# Source: .upstream/anthropics-claude-code/plugins/commit-commands/
```

### Step 2 — Identify upstream changes

Use git to get the precise list of files that changed upstream between the old and new refs.

**When `origin.commit` is populated (normal case):**
```bash
git -C .upstream/{slug}/ diff --name-only {old-ref}..{new-ref} -- {subpath}
```

**When `origin.commit` is empty (first sync):**
Skip diff — treat all upstream files as new. Copy everything from `.upstream/` (applying
customization filters in Step 3).

For each changed file, cross-reference against `customizations[]`:

| File matches... | Action |
|-----------------|--------|
| `excluded` target | Skip — still excluded |
| `removed` target | Skip — still removed |
| `modified` target | Flag as **conflict** — upstream changed a file you also modified |
| No customization | **Clean change** — apply directly |

To check if upstream changed a specific `modified` file:
```bash
git -C .upstream/{slug}/ diff --quiet {old-ref}..{new-ref} -- {subpath}/{file}
# Exit 0 = no change (safe, keep local), Exit 1 = changed (conflict)
```

### Step 3 — Apply clean changes

For each clean change (no matching customization):
- **Added/modified upstream** → copy from `.upstream/{slug}/{subpath}/{file}` to `plugins/{name}/{file}`
- **Deleted upstream** → delete from local (confirm with user before deleting)

**Never copy:**
- Files/dirs matching `excluded` customization targets
- Files/dirs matching `removed` customization targets
- `.claude-plugin/customizations.json` (always preserve local)
- `.claude-plugin/plugin.json` (always preserve local)

For first sync (no prior commit): copy all files from `.upstream/{slug}/{subpath}/` to
`plugins/{name}/`, filtering out excluded and removed targets.

### Step 4 — Handle conflicts

For each conflicting file (upstream changed + local `modified` customization), show the
upstream diff alongside the local version:

```
CONFLICT: skills/brainstorming/SKILL.md
  Customization: custom-12 — "Reduced trigger sensitivity to complex requirements only"
  Reason: "Original trigger was too aggressive, activating on simple requests"

  UPSTREAM DIFF ({old-ref}..{new-ref}):
  ─────────────────────────────────────
  [output of: git -C .upstream/{slug} diff {old}..{new} -- {path}]

  YOUR LOCAL VERSION:
  ─────────────────────────────────────
  [current local file content, relevant sections]

  Options:
    (k) keep local — preserve your customization as-is
    (u) use upstream — copy from .upstream/ (removes your customization)
    (m) manual merge — apply upstream, then re-apply your customization by hand
```

Ask the user for their choice for each conflict before proceeding.

### Step 5 — Reset option

If the user wants to discard all customizations and take upstream verbatim:
1. Delete everything in the local plugin directory (except `.claude-plugin/customizations.json` and `.claude-plugin/plugin.json`)
2. Copy all files from `.upstream/{slug}/{subpath}/` (respecting origin path)
3. Clear `customizations[]` to an empty array
4. Update `origin` tracking fields (see Step 6)
5. Warn the user: "All customizations discarded. Re-apply any needed changes manually."

Only do this if the user explicitly requests a reset.

### Step 6 — Update tracking

Get the exact commit SHA from the clone:
```bash
git -C .upstream/{slug}/ rev-parse {target-ref}
```

Update `customizations.json`:
```json
{
  "origin": {
    "ref": "{new-ref}",
    "commit": "{sha from rev-parse}",
    "fetched_at": "{today YYYY-MM-DD}"
  },
  "upstream_status": {
    "last_checked": "{today YYYY-MM-DD}",
    "latest_ref": "{new-ref}",
    "latest_commit": "{sha from rev-parse}",
    "has_updates": false,
    "summary": "",
    "changes": []
  }
}
```

For conflicts where the user chose "keep local": leave the customization entry unchanged.
For conflicts where the user chose "use upstream": remove that customization entry from `customizations[]`.

Validate the file after editing:
```bash
python3 -m json.tool plugins/{name}/.claude-plugin/customizations.json
```

### Step 7 — Commit

No temp directory cleanup needed — `.upstream/` persists for future updates.

Stage the changed plugin files and updated customizations.json, then commit:
```
feat({plugin-name}): update to {new-ref} from {old-ref}
```

---

## Multi-Origin Plugins

For plugins that use `origins` (array) instead of `origin` (singular), such as forge-deep-review:

### Checking

Check each origin independently using the method for its `ref` type. Present results grouped by plugin, with each origin on its own line:

```
forge-deep-review (2 origins)
  anthropics/claude-code @ plugins/pr-review-toolkit (main)
    Latest commit: abc1234 (2026-04-10) — "Add async tool support"
    ⚡ Updates available — 3 commits since fetch
    ⚠ agents/silent-failure-hunter.md — conflicts with custom-07 (modified: removed Anthropic-internal tooling refs)

  anthropics/claude-code @ plugins/code-review (main)
    Latest commit: abc1234 (2026-04-10) — "Add async tool support"
    ✓ Up to date
```

### Applying

All origins from the same repo share one `.upstream/` clone. Fetch once, apply per-origin.

For each origin in the `origins` array:
1. Ensure `.upstream/{slug}/` clone (Step 1 — shared, only fetch once per repo)
2. Identify changes for this origin's subpath (Step 2)
3. Apply clean changes from `.upstream/{slug}/{origin.path}/` (Step 3)
4. Handle conflicts for this origin's files (Step 4)

Then once for the whole plugin:
5. Handle reset if requested (Step 5)
6. Update tracking for all origins (Step 6)
7. Commit (Step 7)

Multi-origin customization entries have an `"origin"` field (e.g., `"origin": "pr-review-toolkit"`) that identifies which source they apply to. Only cross-reference a customization against changes from its named origin, not all origins.
