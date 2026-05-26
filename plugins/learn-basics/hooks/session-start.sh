#!/usr/bin/env bash
# Hook ejecutado al inicio de cada sesión.
# Imprime info básica del repo en el directorio actual.

set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[learn-basics] No estás dentro de un repositorio git."
  exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD)
last_commit=$(git log -1 --pretty=format:'%h %s' 2>/dev/null || echo "(sin commits)")
dirty=$(git status --porcelain | wc -l | tr -d ' ')

echo "[learn-basics] rama: $branch | último commit: $last_commit | cambios sin commitear: $dirty"
