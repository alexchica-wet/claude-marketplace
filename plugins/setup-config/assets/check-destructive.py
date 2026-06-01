#!/usr/bin/env python3
"""PreToolUse hook: forces user confirmation for destructive bash commands
and warns on dangerous script writes.

Bash: denies the first attempt so Claude must ask the user. If the user
approves, Claude re-runs prefixed with DESTRUCTIVE_APPROVED=1 to bypass.

File writes (.sh/.bash/.zsh/.py with destructive content): injects a
warning message so Claude informs the user, but does not block the write.
"""

import json
import os
import re
import sys

# --- Bash: direct destructive commands ---
BASH_DESTRUCTIVE_PATTERN = re.compile(
    r'(^|[\s;&|`$(])(\S*/)?(rm|rmdir|unlink|shred)(\s|$)'   # rm etc, incl. absolute paths like /bin/rm
    r'|(^|[\s;&|`$(])(\S*/)?truncate(\s|$)'                  # truncate -s 0 file
    r'|cp\s+(-\S+\s+)*/dev/null\s'                           # cp /dev/null file (destructive overwrite)
    r'|find\s+[^|;&]*-delete'
    r'|find\s+[^|;&]*-exec\s+rm'
    r'|git\s+rm(\s|$)'
    r'|git\s+clean\s+[^;|&]*-[a-z]*f'
    r'|git\s+reset\s+--hard'
    r'|git\s+push\b[^;|&]*\s(--force-with-lease|--force|-f)(\s|$)'  # force push rewrites remote history
    r'|(node\s+-e|python3?\s+-c)[^\n]*'                      # inline interpreter with destructive call
    r'(rmSync|rmdirSync|unlinkSync|rmtree|shutil\.rmtree|os\.remove|os\.unlink)'
    r'|(^|[\s;&|`$(])dd\s+if=',
    re.IGNORECASE,
)

# Bypass marker: user already confirmed
BYPASS_MARKER = "DESTRUCTIVE_APPROVED=1"

# --- File: script extensions ---
SCRIPT_EXT_PATTERN = re.compile(r'\.(sh|bash|zsh|py)$', re.IGNORECASE)

# --- File: destructive commands inside scripts ---
SCRIPT_DESTRUCTIVE_PATTERN = re.compile(
    r'(^|\n|;|&&|\|\|)\s*(sudo\s+)?(rm|rmdir|unlink|shred|dd\s+if=|mkfs|chown|chmod\s+777)\b'
    r'|find\s+[^\n]*-delete'
    r'|find\s+[^\n]*-exec\s+rm'
    r'|\bDROP\s+(TABLE|DATABASE|COLLECTION|INDEX)\b'
    r'|\bTRUNCATE\s+TABLE\b'
    r'|\bDELETE\s+FROM\b'
    r'|\bdb\.(dropDatabase|dropCollection)\b',
    re.IGNORECASE,
)

# Self-exclusion: do not trigger on edits to this hook script itself
SELF_PATH = os.path.normpath(os.path.abspath(__file__))

BASH_DENY_MSG = (
    "\U0001f6d1 **Destructive command detected - user confirmation required**\n\n"
    "A file deletion or destructive command was detected. "
    "This hook requires explicit user confirmation before proceeding "
    "(even with `--dangerously-skip-permissions`).\n\n"
    "**Detected command types:**\n"
    "- `rm`, `rm -rf`, `rmdir`, `unlink`, `shred` (incl. absolute paths like `/bin/rm`)\n"
    "- `truncate`, `cp /dev/null ...` (destructive overwrite)\n"
    "- `find ... -delete`, `find ... -exec rm`\n"
    "- `git rm`, `git clean -fd`, `git reset --hard`, `git push --force`\n"
    "- `node -e` / `python -c` with `rmSync`/`rmtree`/`unlink`\n"
    "- `dd if=...`\n\n"
    "**Action required:**\n"
    "1. Show the user the exact command you want to run.\n"
    "2. Explain why it is necessary and whether it is reversible.\n"
    "3. Wait for explicit user approval.\n"
    "4. Once approved, re-run the command prefixed with "
    "`DESTRUCTIVE_APPROVED=1 ` to bypass this check.\n\n"
    "Example: `DESTRUCTIVE_APPROVED=1 git reset --hard HEAD~1`"
)

SCRIPT_WARN_MSG = (
    "\u26a0\ufe0f **Script with potentially destructive commands**\n\n"
    "You are creating/editing a script (`.sh/.bash/.zsh/.py`) that contains "
    "destructive operations.\n\n"
    "**Detected patterns (check which one applies):**\n"
    "- File deletion: `rm/rmdir/unlink/shred`, `find -delete`\n"
    "- Filesystem: `dd if=`, `mkfs`\n"
    "- Dangerous permissions: `chmod 777`, `chown`, `sudo`\n"
    "- Database: `DROP`, `TRUNCATE`, `DELETE FROM`, `db.dropDatabase/dropCollection`\n\n"
    "**You MUST inform the user** before proceeding:\n"
    "1. What the script does.\n"
    "2. Which destructive command it contains and why it is needed.\n"
    "3. What data/files could be affected if run by mistake."
)


def deny(message):
    """Return a deny response that blocks the tool execution."""
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
        },
        "systemMessage": message,
    }


def warn(message):
    """Return a warning that does not block execution."""
    return {"systemMessage": message}


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print("{}")
        return

    tool = data.get("tool_name", "")
    inp = data.get("tool_input", {})

    # Check bash commands
    if tool == "Bash":
        command = inp.get("command", "")
        # Allow if user explicitly approved via bypass marker.
        # Must be a PREFIX of the command (not merely contained anywhere) so an
        # injected `echo DESTRUCTIVE_APPROVED=1; rm -rf x` cannot disarm the check.
        if command.lstrip().startswith(BYPASS_MARKER):
            print("{}")
            return
        if BASH_DESTRUCTIVE_PATTERN.search(command):
            print(json.dumps(deny(BASH_DENY_MSG)))
            return

    # Check file writes for destructive script content (warn only, no block)
    if tool in ("Write", "Edit", "MultiEdit"):
        file_path = inp.get("file_path", "")

        # Skip self: edits to this hook script should not trigger
        if file_path and os.path.normpath(os.path.abspath(file_path)) == SELF_PATH:
            print("{}")
            return

        if SCRIPT_EXT_PATTERN.search(file_path):
            content = ""
            if tool == "Write":
                content = inp.get("content", "")
            elif tool == "Edit":
                content = inp.get("new_string", "")
            elif tool == "MultiEdit":
                edits = inp.get("edits", [])
                content = " ".join(e.get("new_string", "") for e in edits)

            if content and SCRIPT_DESTRUCTIVE_PATTERN.search(content):
                print(json.dumps(warn(SCRIPT_WARN_MSG)))
                return

    # No match - allow
    print("{}")


if __name__ == "__main__":
    main()
