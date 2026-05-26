#!/usr/bin/env bash
# PreToolUse hook: bloquea `git push --force` (sin --force-with-lease) hacia main/master.
# Recibe en stdin un JSON con la invocación de la tool.
# Sale 0 si permite, 2 si bloquea (stderr se muestra al usuario).

set -euo pipefail

input=$(cat)

# Extraemos el comando bash que se va a ejecutar.
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# Si no es un git push, dejamos pasar.
if ! printf '%s' "$cmd" | grep -qE '(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)'; then
  exit 0
fi

# Si usa --force-with-lease, dejamos pasar (es razonablemente seguro).
if printf '%s' "$cmd" | grep -qE '(--force-with-lease|-f-with-lease)'; then
  exit 0
fi

# Detectamos --force / -f.
if ! printf '%s' "$cmd" | grep -qE '([[:space:]]--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$))'; then
  exit 0
fi

# Detectamos si apunta a main o master.
if printf '%s' "$cmd" | grep -qE '([[:space:]](main|master)([[:space:]]|$|:))'; then
  echo "[wet-flow] BLOQUEADO: 'git push --force' a main/master." >&2
  echo "         Usa '--force-with-lease' si necesitas force-push seguro." >&2
  echo "         Comando: $cmd" >&2
  exit 2
fi

exit 0
