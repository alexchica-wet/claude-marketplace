# Catálogo de medidas

Cada medida: qué · nivel · por qué · trade-off. El orquestador la presenta con recomendación primero.

## Nivel User

### U1 — Hook anti-destructivo global (M1)
- **Qué:** instalar `check-destructive.py` en `~/.claude/hooks/` + registrarlo (`PreToolUse`, matcher `Bash|Write|Edit|MultiEdit`).
- **Por qué:** red de seguridad determinista que sobrevive a `--dangerously-skip-permissions` (los PreToolUse son lo único que sobrevive al flag).
- **Trade-off:** algún prompt extra ante comandos destructivos. Bypass legítimo: prefijo `DESTRUCTIVE_APPROVED=1 ` (debe ser PREFIJO).
- **Recom.:** Sí.

### U2 — `deny` catastróficos + secretos (M2)
- **Qué:** lista `deny` solo con lo irreversible a nivel sistema + lectura de secretos. Ver `settings-templates.md`.
- **Por qué:** `deny` es la única semántica que se respeta bajo el flag; suelo de último recurso.
- **Trade-off:** ninguno relevante (no incluye el `rm` cotidiano, que gestiona el hook).
- **Recom.:** Sí.

### U3 — `ask` de `.env` y `git push` (M3)
- **Qué:** `Read(**/.env)`, `Read(**/.env.*)`, `Bash(git push:*)`. Opción: añadir `Bash(git commit:*)`.
- **Por qué:** `.env` se lee a menudo (bloquearlo rompería el flujo → `ask`, no `deny`); Claude nunca debe pushear solo.
- **Trade-off:** `ask` se SUPRIME bajo el flag (protección de uso normal, no de autopilot).
- **Recom.:** Sí (git push solo).

### U4 — Limpiar `allow` peligrosos (M4)
- **Qué:** detectar y proponer quitar comodines de ejecución arbitraria del `allow`. Ver lista en `settings-templates.md`.
- **Por qué:** un `allow` over-broad permite ejecutar código arbitrario sin prompt.
- **Recom.:** Sí, los detectados.

## Nivel Repo

### R1 — Alcance de lectura del sandbox
Ver `sandbox-modes.md`. Recom.: solo escritura.

### R2 — Modo de sandbox
Ver `sandbox-modes.md`. Recom.: Estricto.

### R3 — Homogeneizar sandboxes existentes
Solo si la auditoría inicial detectó repos con sandbox en otro modo. Recom.: aplicar el modo elegido a todos.

### R4 — `.gitignore`
Crear si no existe y añadir `.claude/settings.local.json`. Sin detección de inversión. Recom.: aplicar.

## Descartadas (opt-in avanzado, default NO)

| Medida | Por qué NO por defecto |
|---|---|
| `disableBypassPermissionsMode: true` | Mata el flag por completo; contradice la "mano abierta con el flag" |
| Capa `managed` irrevocable | Requiere sudo; el usuario priorizó autonomía sin fricción |
| `denyRead` general | Quiere poder leer para contexto (ya ofrecido en R1) |
| `deny` de exfiltración (`curl`/`wget`/`nc`) | Demasiada fricción con curl legítimo |
| `.env` → `deny` | Se queda en `ask`; lo lee a menudo |
| Pinning de marketplaces de terceros | Riesgo de supply-chain aceptado por ahora |
