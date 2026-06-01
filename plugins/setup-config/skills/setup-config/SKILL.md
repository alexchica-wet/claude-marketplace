---
name: setup-config
description: Use when the user wants to set up or harden their Claude Code security configuration (permissions, sandbox, anti-destructive hook) at user level and/or for repos, or invokes /setup-config. Guides the decisions via questions, applies them, and runs a security audit at the end.
---

# Skill: setup-config

Instalador guiado one-shot del endurecimiento de seguridad de Claude Code. Audita → pregunta medida
a medida → aplica en la config del usuario → audita con `security-auditor` → ronda de corrección.

**Filosofía:** seguridad endurecida pero sin fricción; el usuario decide por scope y por medida;
nada se aplica sin confirmación; cada medida explica su por qué y su trade-off. Las medidas agresivas
van como opt-in con default No.

Detalle voluminoso en `references/`:
- `measure-catalog.md` — qué/nivel/por qué/trade-off de cada medida + descartadas.
- `settings-templates.md` — bloques JSON de `deny`/`ask`/`hook`/allow-cleanup/gitignore.
- `sandbox-modes.md` — los 3 modos + previews.
- `golden-rules.md` — invariantes al escribir settings (LEER antes de aplicar nada).

## Paso 0 — Selección de scope (SIEMPRE primero)

Presentar un `AskUserQuestion` **multi-select** con opciones construidas dinámicamente:
- **User** (siempre): `~/.claude/settings.json` + copia de assets a `~/.claude/`.
- **Repo actual: `<nombre>`** — incluir SOLO si `git rev-parse --show-toplevel` (en el cwd) tiene
  éxito; usa el basename del toplevel como `<nombre>`. Configura su `.claude/settings.local.json`.
- **Otros repos** (siempre): si se marca, preguntar por un directorio raíz, escanear repos debajo
  (`find <raíz> -maxdepth 3 -name .git -type d` → sus dirs padre), y ofrecer un segundo multi-select
  para elegir cuáles.

El conjunto elegido determina qué preguntas se hacen:
- Preguntas User (U1–U4) solo si "User" está en el scope.
- Preguntas Repo (R1–R4) solo si hay ≥1 repo en el scope.

## Paso 1 — Auditoría inicial (foto)

Para cada scope elegido, leer el settings actual (si existe) y resumir el estado: ¿hay hook
anti-destructivo?, ¿deny/ask?, ¿allow peligrosos?, ¿sandbox y en qué modo? Mostrar la foto antes de
preguntar. Esto alimenta U4 (allow a limpiar) y R3 (sandboxes a homogeneizar).

## Paso 2 — Preguntas medida a medida

Para CADA medida aplicable al scope, hacer un `AskUserQuestion` con la opción recomendada primero y
el trade-off explícito (textos en `measure-catalog.md`). Orden:

**User:** U1 hook anti-destructivo → U2 deny → U3 ask (+ sub-pregunta push solo vs push+commit) →
U4 limpiar allow peligrosos.

**Repo:** R1 alcance de lectura del sandbox → R2 modo de sandbox (usar previews de `sandbox-modes.md`)
→ R3 homogeneizar existentes (solo si la auditoría encontró otros modos) → R4 gitignore.

**Bloque avanzado (gate):** una pregunta "¿Ver opciones avanzadas de máximo blindaje? (normalmente
NO)". Si entra: `disableBypassPermissionsMode` y capa `managed`, ambas default No, con aviso de que
contradicen la "mano abierta con el flag".

NO preguntar la antigua "¿qué aplico primero?": el scope + la confirmación por medida ya lo cubren.

## Paso 3 — Aplicar

Seguir SIEMPRE `references/golden-rules.md`: read-before-write + merge, validar con `jq -e` tras cada
escritura, nivel correcto, `$HOME` dinámico, copia de assets idempotente con `chmod 600` en el hook.

Los assets se copian desde el propio plugin:
- `${CLAUDE_PLUGIN_ROOT}/assets/check-destructive.py` → `~/.claude/hooks/check-destructive.py`
- `${CLAUDE_PLUGIN_ROOT}/agents/security-auditor.md` → `~/.claude/agents/security-auditor.md`

## Paso 4 — Auditoría final + corrección (requisito clave)

1. Invocar el subagente `security-auditor` (vía Agent tool) sobre los ficheros YA escritos de todos
   los scopes configurados. Audita: precedencia de capas, allow over-broad, cobertura deny/ask,
   modos/skips peligrosos, robustez del hook, sandbox, MCP, permisos de fichero (600),
   additionalDirectories. (NO escanea secretos hardcodeados — fuera de scope.)
2. Reportar resumen ejecutivo + hallazgos por severidad (CRÍTICO→BAJO) con `file:line`, escenario de
   explotación y recomendación.
3. Por cada hallazgo accionable, `AskUserQuestion`: **corregir ahora** (aplicar la recomendación con
   el mismo merge+validación) / **aceptar conscientemente** (registrar como riesgo residual) /
   **ver detalle**.

## Paso 5 — Cierre

Resumen final: qué se aplicó por nivel, riesgos residuales aceptados (incl. los inherentes: bajo el
flag solo sobreviven `deny`+hooks; sin capa managed el agente puede reescribir sus límites; la
exfiltración vía `curl` no está denegada), y el aviso de recarga de hooks (`/hooks` o reinicio).
