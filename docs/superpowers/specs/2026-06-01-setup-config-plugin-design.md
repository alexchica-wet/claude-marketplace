# Diseño — plugin `setup-config`

> Spec de diseño para el plugin `setup-config` del marketplace `wet-tools`. Guía mediante
> preguntas el endurecimiento de seguridad de Claude Code (nivel user y/o repos) y lo aplica,
> cerrando con una auditoría del subagente `security-auditor`.
>
> Fuente/contexto: `docs/setup-claude-config-brief.md` (decisiones y razones de la sesión manual
> del 2026-06-01). Brainstorm: 2026-06-01. Usuario: alex (Wetaca). Plataforma: macOS, un solo usuario.

---

## 1. Propósito y filosofía

El plugin es un **instalador guiado one-shot**: al invocarse, audita el estado actual, pregunta
medida a medida las decisiones de endurecimiento (presentando trade-offs), **escribe los cambios en
la config propia del usuario** (no en el plugin), y al final ejecuta un auditor que reporta riesgos
residuales y abre una ronda de corrección.

Objetivo de negocio: que un compañero de Wetaca pueda replicar fácilmente el endurecimiento que se
hizo a mano, decidiendo nivel por nivel, sin fricción innecesaria.

Filosofía rectora (heredada del brief): **seguridad endurecida pero sin fricción**; el usuario
decide por scope y por medida; nada se aplica sin confirmación; toda medida explica su *por qué* y
su *trade-off*; las decisiones "agresivas" del §6 del brief van como opt-in con default No.

Como instalador one-shot, **la protección vive en la config del usuario** (`~/.claude/` y los
`settings.local.json` de los repos), no en el plugin: persiste aunque el plugin se desactive o
desinstale.

**Alcance:** SOLO configuración de seguridad. Quedan fuera (decisiones explícitas de este brainstorm):
- El hook `sync-env-example.py` (higiene de `.env`, no es config).
- Detección de inversión de `.gitignore` (fue un bug puntual, no algo a auditar).
- Escaneo de secretos hardcodeados en `.mcp.json` (otro bug puntual, fuera del checklist del auditor).

---

## 2. Arquitectura (Enfoque A — comando fino + skill + assets)

Patrón calcado de `forge-keeper` (comando fino → skill con `references/` para progressive disclosure).

```
plugins/setup-config/
├── .claude-plugin/
│   └── plugin.json                      # name, description, version, author, keywords
├── commands/
│   └── setup-config.md                  # comando-entrada FINO → invoca la skill
├── skills/
│   └── setup-config/
│       ├── SKILL.md                     # orquestador: scope → audit → preguntas → aplicar → auditar → corregir
│       └── references/
│           ├── measure-catalog.md       # catálogo §3 del brief + descartadas §6 (con por qué/trade-off)
│           ├── settings-templates.md    # bloques JSON deny/ask/sandbox/hook (home dinámico)
│           ├── sandbox-modes.md         # los 3 modos §4 + previews JSON
│           └── golden-rules.md          # reglas de aplicación §9
├── agents/
│   └── security-auditor.md              # usado en la ronda final + copiado a ~/.claude/agents/
├── assets/
│   └── check-destructive.py             # copiado a ~/.claude/hooks/ por el instalador
└── README.md
```

**Responsabilidades por unidad:**

- `commands/setup-config.md` — entrada delgada (`/setup-config`). Solo invoca la skill.
- `skills/setup-config/SKILL.md` — orquestador. Mantiene el flujo de alto nivel y delega el detalle
  a `references/`.
- `references/*.md` — contenido voluminoso, cargado bajo demanda.
- `agents/security-auditor.md` — subagente auditor (opus, read-only `Read/Grep/Glob/Bash`). Se usa
  en la ronda final **y** el instalador lo copia a `~/.claude/agents/` para re-auditorías futuras.
- `assets/check-destructive.py` — versión endurecida del hook anti-destructivo; el instalador lo
  despliega a `~/.claude/hooks/`.

**Artefactos a empaquetar:** solo dos — `check-destructive.py` y `security-auditor.md`. (El origen
actual está en `~/.claude/hooks/check-destructive.py` y `~/.claude/agents/security-auditor.md`.)

---

## 3. Selección de scope al arrancar (requisito 1)

Nada más invocar `/setup-config`, **antes de cualquier otra acción**, se presenta un
`AskUserQuestion` **multi-select** con opciones construidas dinámicamente:

- **User** *(siempre presente)* — configura `~/.claude/settings.json` y copia los assets a
  `~/.claude/hooks/` y `~/.claude/agents/`.
- **Repo actual: `<nombre>`** *(solo si el cwd está dentro de un repo git)* — detección por
  `git rev-parse --show-toplevel`; configura su `.claude/settings.local.json`.
- **Otros repos** *(siempre presente)* — si se marca, pregunta por un **directorio raíz**, escanea
  repos debajo (busca `.git/`) y ofrece un segundo multi-select para elegir cuáles.

Se pueden marcar varias. El conjunto elegido determina qué preguntas se hacen después:
- Las preguntas de nivel-user (U1–U4) solo si "User" está en el scope.
- Las de nivel-repo (R1–R4) solo si hay al menos un repo en el scope.

**Orden:** primero auditar el estado actual de **todos** los scopes elegidos (foto inicial), luego
arrancar la ronda de preguntas.

---

## 4. Flujo de preguntas de runtime

Tras la auditoría inicial, se pregunta **medida a medida** (opción recomendada primero + trade-off
explícito; nada se aplica sin confirmar). Se omite la antigua pregunta §5-Q1 "¿qué aplico primero?":
con el scope ya elegido y la confirmación por medida, esa priorización sobra.

### Nivel User (si "User" en scope)

- **U1 · Hook anti-destructivo global (M1).** Instalar `check-destructive.py` en `~/.claude/hooks/`
  + registrarlo (`PreToolUse`, matcher `Bash|Write|Edit|MultiEdit`). *Recom. Sí.* Red de seguridad
  determinista que sobrevive a `--dangerously-skip-permissions`; bypass legítimo con **prefijo**
  `DESTRUCTIVE_APPROVED=1 `.
- **U2 · `deny` catastróficos + secretos (M2).** Solo lo irreversible a nivel sistema
  (`rm -rf /`, `mkfs`, `dd ... of=/dev/*`, etc.) + lectura de secretos (`.ssh`, `.aws`, gcloud,
  `*.pem`, `id_rsa`, `id_ed25519`, `.npmrc`). `$HOME` resuelto dinámicamente. *Recom. Sí.* No incluye
  el `rm` cotidiano (de eso se encarga el hook con confirmación).
- **U3 · `ask` de `.env` y `git push` (M3).** `Read(**/.env)`, `Read(**/.env.*)`, `Bash(git push:*)`.
  Sub-pregunta (§5-Q5): `git push` solo *(recom.)* vs. push **y** commit. *Recom. Sí.* Aviso: `ask`
  se suprime bajo el flag.
- **U4 · Limpiar `allow` peligrosos (M4).** Detectar comodines de ejecución arbitraria en el `allow`
  (`Bash(node -e *)`, `Bash(python -c *)`, `Bash(eval *)`, `Bash(npx *)`, `Bash(curl *)`,
  `Bash(* | sh)`, `Bash(bash *)`, `Bash(*)`) y proponer quitarlos. *Recom. Sí, los detectados.*

### Nivel Repo (si ≥1 repo en scope)

- **R1 · Alcance de lectura del sandbox (§5-Q2).** Solo escritura *(recom.)* / también lectura
  (`denyRead`) / solo secretos. El sandbox por defecto confina escritura pero **no** lectura.
- **R2 · Modo de sandbox (§5-Q3).** Cómodo / **Estricto** *(recom.)* / Búnker, **con previews** del
  bloque JSON de cada modo (ver tabla §4 del brief).
- **R3 · Homogeneizar sandboxes existentes (§5-Q4).** Solo si la auditoría encontró repos ya con
  sandbox en otro modo: aplicar el modo elegido a todos *(recom.)* / solo a los que no tienen.
- **R4 · `.gitignore` (§5-Q7).** Crear el `.gitignore` si no existe y **añadir** la línea de la
  convención (`.claude/settings.local.json` ignorado). *Recom. aplicar.* **Sin** detección de
  inversión.

### Bloque avanzado (gate "normalmente NO")

Una sola pregunta-compuerta: *"¿Ver opciones avanzadas de máximo blindaje? (normalmente NO)"*. Si
entra: `disableBypassPermissionsMode` y capa `managed` irrevocable — ambas con **default No** y aviso
de que contradicen la "mano abierta con el flag". Las demás descartadas del §6 (deny de exfiltración,
`.env`→deny, pinning de marketplaces) se documentan en `measure-catalog.md` como "no por defecto"
pero no se preguntan; `denyRead` ya sale en R1.

---

## 5. Lógica de aplicación y reglas de oro (§9)

Invariantes que sigue el orquestador (detalladas en `references/golden-rules.md`):

1. **Read-before-write + merge, nunca reemplazar.** Leer el settings destino; mergear dentro de
   arrays (`allow`/`deny`/`ask`) sin pisar lo existente; deduplicar.
2. **Validar con `jq -e` tras cada escritura.** JSON roto → desactiva en silencio toda la config de
   ese fichero. Si falla la validación: restaurar y avisar.
3. **Nivel correcto.** Personal → `~/.claude/settings.json` o `settings.local.json` del repo; nunca
   config personal en el `settings.json` de equipo.
4. **`$HOME` dinámico.** Resolver el home real; nunca hardcodear `/Users/<user>`.
5. **Copia de assets idempotente.** `check-destructive.py` → `~/.claude/hooks/` (chmod `600`);
   `security-auditor.md` → `~/.claude/agents/`. No sobrescribir sin avisar si ya existe y difiere.
6. **Aviso de recarga de hooks.** Registrar/des-registrar un hook en settings requiere `/hooks` o
   reinicio; el script en disco surte efecto inmediato.
7. **Nada sin confirmación**; las descartadas del §6 mantienen default No.

---

## 6. Ronda del auditor (requisito 2)

Tras aplicar todas las medidas confirmadas y validar el JSON:

1. **Invocar `security-auditor`** sobre los ficheros **ya escritos en disco** de todos los scopes
   configurados. Checklist (§7 del brief, sin escaneo de secretos): precedencia de capas
   (`managed > local > project > user`, `deny > ask > allow`); `allow` over-broad; cobertura
   `deny`/`ask`; modos/skips peligrosos; robustez del hook (¿regex evadible?, ¿script
   poisonable/escribible?); sandbox (allowUnsandboxed, autoAllow, denyRead, allowedDomains); MCP
   (`enableAllProjectMcpServers`, tokens embebidos); permisos de fichero (`600`);
   `additionalDirectories`.
2. **Reportar** resumen ejecutivo + hallazgos por severidad (CRÍTICO→BAJO) con ubicación `file:line`,
   escenario de explotación concreto y recomendación con el nivel donde aplicarla.
3. **Ronda de corrección.** Por cada hallazgo accionable, `AskUserQuestion`: **corregir ahora**
   (aplica la recomendación con el mismo merge+validación) / **aceptar conscientemente** (lo registra
   como riesgo residual) / **ver detalle**.
4. **Cierre.** Resumen final: qué se aplicó por nivel, qué riesgos residuales se aceptaron, y el aviso
   de recarga de hooks.

---

## 7. Riesgo residual (documentar en el cierre y en el README)

Lo que esta config **NO** cubre (heredado del §6 del brief): bajo `--dangerously-skip-permissions`
solo sobreviven `deny` + hooks; sin capa managed, el agente puede reescribir sus propios límites en
autopilot; la exfiltración vía `curl`/`wget`/`nc` no está denegada.

---

## 8. Decisiones del brainstorm (registro)

| Tema | Decisión |
|---|---|
| Nombre del plugin | `setup-config` (sin "claude", redundante) |
| Arquitectura | Enfoque A: comando fino + skill + `references/` + assets (patrón `forge-keeper`) |
| Alcance "repo-local" | Multi-select al arrancar: **User** + **Repo actual** (si aplica) + **Otros repos** (escanea raíz) |
| Orden aplicar/auditar | Aplicar → auditar (sobre ficheros reales) → ronda de corrección |
| Dónde viven los hooks | Copiar a `~/.claude/` (instalador one-shot); persisten sin el plugin |
| `sync-env-example.py` | **Omitido** (no es config de seguridad) |
| Inversión de `.gitignore` | **Omitida** (bug puntual, no a auditar) |
| Secretos hardcodeados | **Omitido** del checklist del auditor (bug puntual, no config) |
| Artefactos empaquetados | Solo `check-destructive.py` + `security-auditor.md` |
