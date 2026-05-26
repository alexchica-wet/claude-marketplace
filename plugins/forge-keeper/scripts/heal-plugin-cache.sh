#!/usr/bin/env bash
# heal-plugin-cache.sh
#
# Repair stale plugin version references by creating symlinks from orphaned
# version paths (referenced by old sessions) to the current installed version
# on disk.
#
# When Claude Code bumps a plugin version mid-session, any session pinned to
# the old version fails with:
#   Failed to run: Plugin directory does not exist:
#     ~/.claude/plugins/cache/<marketplace>/<plugin>/<old-version>
#
# This scans session transcripts once, extracts every referenced
# <marketplace>/<plugin>/<version> triple, and creates a relative symlink for
# each missing version path, pointing at the highest real version directory
# on disk for that plugin.
#
# Usage:
#   heal-plugin-cache.sh                       # dry-run (default)
#   heal-plugin-cache.sh --apply               # create the symlinks
#   heal-plugin-cache.sh --cache-dir DIR       # override cache dir
#   heal-plugin-cache.sh --projects-dir DIR    # override projects dir
#   heal-plugin-cache.sh --mtime DAYS          # only scan sessions modified
#                                              # within DAYS (default: all)
#
# Safe to re-run: only creates symlinks, never deletes or overwrites.

set -u

APPLY=0
CACHE_DIR="${HOME}/.claude/plugins/cache"
PROJECTS_DIR="${HOME}/.claude/projects"
MTIME=""

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --cache-dir) shift; CACHE_DIR="$1" ;;
    --projects-dir) shift; PROJECTS_DIR="$1" ;;
    --mtime) shift; MTIME="$1" ;;
    -h|--help)
      sed -n '4,26p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if [ ! -d "$CACHE_DIR" ]; then
  echo "No plugin cache directory: $CACHE_DIR" >&2
  exit 1
fi

# Build find args for session files, optionally limited by mtime.
find_args=("$PROJECTS_DIR" -name "*.jsonl")
if [ -n "$MTIME" ]; then
  find_args+=(-mtime "-$MTIME")
fi

# Single grep pass: extract every <marketplace>/<plugin>/<version> triple
# referenced in any session transcript. This is the expensive step.
if [ -d "$PROJECTS_DIR" ]; then
  refs="$(
    find "${find_args[@]}" -print0 2>/dev/null \
      | xargs -0 grep -hoE 'cache/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[0-9][0-9A-Za-z.+-]*' 2>/dev/null \
      | sed 's|^cache/||' \
      | sort -u
  )"
else
  refs=""
fi

# Cache of targets per plugin so we don't recompute repeatedly.
# (Keys are "<marketplace>/<plugin>" strings.)
targets_keys=""
targets_vals=""

get_target() {
  local key="$1"
  local plugin_path="$CACHE_DIR/$key"
  local saved

  # Linear lookup — plugin count stays small.
  saved="$(
    printf '%s\n' "$targets_keys" | awk -v k="$key" -v vals="$targets_vals" '
      BEGIN { n = split(vals, v, "\n") }
      $0 == k { print v[NR]; exit }
    '
  )"
  if [ -n "$saved" ]; then
    printf '%s\n' "$saved"
    return
  fi

  local target=""
  if [ -d "$plugin_path" ]; then
    target="$(
      find "$plugin_path" -mindepth 1 -maxdepth 1 -type d -not -name '.*' \
        -exec basename {} \; 2>/dev/null | sort -V | tail -1
    )"
  fi

  targets_keys="${targets_keys}${key}"$'\n'
  targets_vals="${targets_vals}${target}"$'\n'
  printf '%s\n' "$target"
}

plans=()
unfixable=()
created=0
failed=0

while IFS= read -r ref; do
  [ -z "$ref" ] && continue

  # ref looks like: <marketplace>/<plugin>/<version>
  version="${ref##*/}"
  key="${ref%/*}"  # <marketplace>/<plugin>

  # Skip if the referenced path already exists (dir or symlink).
  if [ -e "$CACHE_DIR/$ref" ]; then
    continue
  fi

  target="$(get_target "$key")"
  if [ -z "$target" ]; then
    unfixable+=("$ref (no cache directory)")
    continue
  fi

  if [ "$version" = "$target" ]; then
    continue
  fi

  plans+=("$ref -> $target")

  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$CACHE_DIR/$key" 2>/dev/null || true
    if ln -s "$target" "$CACHE_DIR/$ref" 2>/dev/null; then
      created=$((created + 1))
    else
      failed=$((failed + 1))
      echo "  ! failed to create $CACHE_DIR/$ref" >&2
    fi
  fi
done <<EOF
$refs
EOF

# Report.
if [ ${#plans[@]} -eq 0 ] && [ ${#unfixable[@]} -eq 0 ]; then
  echo "No stale plugin version references found."
  exit 0
fi

if [ ${#plans[@]} -gt 0 ]; then
  if [ "$APPLY" -eq 1 ]; then
    echo "Created $created symlink(s)${failed:+, failed $failed}:"
  else
    echo "Would create ${#plans[@]} symlink(s) (dry-run; pass --apply to create):"
  fi
  for p in "${plans[@]}"; do
    echo "  $p"
  done
fi

if [ ${#unfixable[@]} -gt 0 ]; then
  echo
  echo "Cannot fix ${#unfixable[@]} reference(s) — no current version on disk:"
  for u in "${unfixable[@]}"; do
    echo "  $u"
  done
fi
