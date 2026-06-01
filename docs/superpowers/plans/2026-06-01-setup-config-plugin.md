# Plugin `setup-config` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir el plugin `setup-config` del marketplace `wet-tools`: un instalador guiado one-shot que endurece la config de seguridad de Claude Code (nivel user y/o repos) mediante preguntas y cierra con una auditoría del subagente `security-auditor`.

**Architecture:** Enfoque A (patrón `forge-keeper`): comando-entrada fino → skill orquestadora con `references/` para progressive disclosure. Dos artefactos empaquetados como assets (`check-destructive.py`, `security-auditor.md`) que el instalador copia a `~/.claude/`. Toda la protección vive en la config del usuario, no en el plugin (persiste sin él).

**Tech Stack:** Plugin de Claude Code (markdown + JSON), hook en Python 3, `jq` para validar JSON, `git`.

**Spec de referencia:** `docs/superpowers/specs/2026-06-01-setup-config-plugin-design.md`
**Brief de contexto:** `docs/setup-claude-config-brief.md`

**Nota sobre TDD en este plan:** el plugin es declarativo (markdown/JSON) + un asset Python. No hay suite de tests al uso; la "verificación" de cada tarea es un comando concreto con salida esperada (`jq -e` sobre JSON, `py_compile` + pipe-test del hook, checks de estructura/frontmatter). Se mantiene el ritmo crear → verificar → commit.

**Rutas base:**
- Raíz del repo: `/Users/alejandrochicagutierrez/Desktop/WETACA/alexchica-claude-marketplace`
- Raíz del plugin: `plugins/setup-config/`
- Branch de trabajo: `feat/setup-config-plugin` (ya creada y con el spec commiteado)

---

## Task 1: Manifest del plugin y registro en el marketplace

**Files:**
- Create: `plugins/setup-config/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (añadir entrada al array `plugins`)

- [ ] **Step 1: Crear `plugin.json`**

```json
{
  "name": "setup-config",
  "description": "Instalador guiado del endurecimiento de seguridad de Claude Code (user y/o repos), con auditoría final del security-auditor",
  "version": "0.1.0",
  "author": { "name": "Alex Chica", "email": "alexchica@wetaca.com" },
  "repository": "https://github.com/alexchica-wet/claude-marketplace",
  "license": "MIT",
  "keywords": ["security", "config", "setup", "permissions", "sandbox", "hooks"]
}
```

- [ ] **Step 2: Verificar que el JSON es válido**

Run: `jq -e . plugins/setup-config/.claude-plugin/plugin.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Añadir la entrada al array `plugins` de `marketplace.json`**

Insertar este objeto como último elemento del array `plugins` en `.claude-plugin/marketplace.json` (añadir la coma tras la entrada anterior `forge-keeper`):

```json
    {
      "name": "setup-config",
      "description": "Instalador guiado del endurecimiento de seguridad de Claude Code — preguntas + auditoría",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/alexchica-wet/claude-marketplace.git",
        "path": "plugins/setup-config"
      },
      "version": "0.1.0"
    }
```

- [ ] **Step 4: Verificar que `marketplace.json` sigue siendo válido y contiene la entrada**

Run: `jq -e '.plugins[] | select(.name=="setup-config")' .claude-plugin/marketplace.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add plugins/setup-config/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "feat(setup-config): manifest del plugin y registro en marketplace"
```

---

## Task 2: Empaquetar los assets (hook anti-destructivo + agente auditor)

**Files:**
- Create: `plugins/setup-config/assets/check-destructive.py` (copia verbatim de `~/.claude/hooks/check-destructive.py`)
- Create: `plugins/setup-config/agents/security-auditor.md` (copia verbatim de `~/.claude/agents/security-auditor.md`)

- [ ] **Step 1: Copiar el hook endurecido como asset**

```bash
mkdir -p plugins/setup-config/assets
cp ~/.claude/hooks/check-destructive.py plugins/setup-config/assets/check-destructive.py
```

- [ ] **Step 2: Verificar que el hook compila (sintaxis Python válida)**

Run: `python3 -m py_compile plugins/setup-config/assets/check-destructive.py && echo OK`
Expected: `OK`

- [ ] **Step 3: Pipe-test — el hook BLOQUEA un comando destructivo**

Run:
```bash
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf build"}}' | python3 plugins/setup-config/assets/check-destructive.py; echo "exit=$?"
```
Expected: salida JSON/permiso que **niega o pide confirmación** (no permite en silencio). Anotar el `exit` y el cuerpo; debe indicar bloqueo. (El formato exacto lo define el script; basta confirmar que NO deja pasar el `rm -rf`.)

- [ ] **Step 4: Pipe-test — bypass legítimo con prefijo `DESTRUCTIVE_APPROVED=1`**

Run:
```bash
echo '{"tool_name":"Bash","tool_input":{"command":"DESTRUCTIVE_APPROVED=1 rm -rf build"}}' | python3 plugins/setup-config/assets/check-destructive.py; echo "exit=$?"
```
Expected: el hook **permite** (no bloquea) el comando con el prefijo aprobado.

- [ ] **Step 5: Pipe-test — comando benigno pasa**

Run:
```bash
echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | python3 plugins/setup-config/assets/check-destructive.py; echo "exit=$?"
```
Expected: el hook **permite** el comando benigno.

- [ ] **Step 6: Copiar el agente auditor**

```bash
mkdir -p plugins/setup-config/agents
cp ~/.claude/agents/security-auditor.md plugins/setup-config/agents/security-auditor.md
```

- [ ] **Step 7: Verificar el frontmatter del agente (name presente)**

Run: `head -2 plugins/setup-config/agents/security-auditor.md | grep -q '^name: security-auditor' && echo OK`
Expected: `OK`

- [ ] **Step 8: Commit**

```bash
git add plugins/setup-config/assets/check-destructive.py plugins/setup-config/agents/security-auditor.md
git commit -m "feat(setup-config): empaquetar hook anti-destructivo y agente auditor"
```

---

## Task 3: Reference `settings-templates.md` (bloques JSON)

**Files:**
- Create: `plugins/setup-config/skills/setup-config/references/settings-templates.md`

- [ ] **Step 1: Crear el fichero con los bloques JSON exactos**

```markdown
# Plantillas de settings

> Bloques JSON que el orquestador mergea (nunca reemplaza) en el settings destino.
> `<HOME>` se sustituye por el home real del usuario (`echo $HOME`), nunca hardcodear `/Users/<user>`.

## M2 — `deny` (catastróficos a nivel sistema + lectura de secretos)

```json
"deny": [
  "Bash(rm -rf /)", "Bash(rm -rf /*)", "Bash(rm -rf ~)", "Bash(rm -rf ~/)",
  "Bash(rm -rf ~/*)", "Bash(rm -rf $HOME)", "Bash(rm -rf $HOME/*)",
  "Bash(sudo rm *)", "Bash(mkfs *)", "Bash(dd if=* of=/dev/*)",
  "Read(<HOME>/.ssh/**)", "Read(<HOME>/.aws/**)",
  "Read(<HOME>/.config/gcloud/**)", "Read(<HOME>/.npmrc)",
  "Read(**/*.pem)", "Read(**/id_rsa)", "Read(**/id_ed25519)"
]
```

## M3 — `ask` (.env y git push)

```json
"ask": ["Read(**/.env)", "Read(**/.env.*)", "Bash(git push:*)"]
```

Si el usuario elige también pedir confirmación para commits (variante push **y** commit), añadir:

```json
"Bash(git commit:*)"
```

## M1 — registro del hook anti-destructivo (settings de user)

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash|Write|Edit|MultiEdit",
      "hooks": [
        { "type": "command", "command": "python3 \"$HOME/.claude/hooks/check-destructive.py\"" }
      ]
    }
  ]
}
```

## M4 — patrones `allow` peligrosos a detectar y proponer quitar

Comodines de ejecución arbitraria que NO deberían estar en `allow`:

```
Bash(node -e *)   Bash(python -c *)   Bash(eval *)   Bash(npx *)
Bash(curl *)      Bash(* | sh)        Bash(bash *)   Bash(*)
```

## R4 — línea de `.gitignore` (convención)

```
.claude/settings.local.json
```
```

- [ ] **Step 2: Verificar que contiene los bloques clave**

Run:
```bash
grep -q 'Read(<HOME>/.ssh/\*\*)' plugins/setup-config/skills/setup-config/references/settings-templates.md \
&& grep -q 'check-destructive.py' plugins/setup-config/skills/setup-config/references/settings-templates.md \
&& echo OK
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add plugins/setup-config/skills/setup-config/references/settings-templates.md
git commit -m "feat(setup-config): reference settings-templates"
```

---

## Task 4: Reference `sandbox-modes.md` (3 modos + previews)

**Files:**
- Create: `plugins/setup-config/skills/setup-config/references/sandbox-modes.md`

- [ ] **Step 1: Crear el fichero**

```markdown
# Modos de sandbox

El sandbox confina la **escritura** al directorio del proyecto; por defecto NO confina la lectura.
Los 3 modos se aplican al `.claude/settings.local.json` del repo. Recomendado: **Estricto**.

## Cómodo
El bash confinado no molesta; solo pregunta si necesita salir del sandbox.
```json
{ "sandbox": { "enabled": true, "autoAllowBashIfSandboxed": true, "allowUnsandboxedCommands": true } }
```

## Estricto (recomendado)
Pregunta por cada bash aunque esté confinado. Más control, más prompts.
```json
{ "sandbox": { "enabled": true, "autoAllowBashIfSandboxed": false } }
```

## Búnker
Ni con `--dangerously-skip-permissions` se sale del sandbox. Máxima contención; comandos que
necesiten red o escribir fuera fallan.
```json
{ "sandbox": { "enabled": true, "autoAllowBashIfSandboxed": true, "allowUnsandboxedCommands": false } }
```

## R1 — alcance de lectura
- **Solo escritura (recom.):** no añadir `denyRead`. Se puede leer para contexto.
- **También lectura:** añadir `denyRead` con las rutas a confinar (decisión avanzada).
- **Solo secretos:** `denyRead` limitado a rutas de secretos.

Usar estos bloques como **previews** en el `AskUserQuestion` del modo de sandbox (R2).
```

- [ ] **Step 2: Verificar que están los 3 modos**

Run:
```bash
grep -c 'autoAllowBashIfSandboxed' plugins/setup-config/skills/setup-config/references/sandbox-modes.md
```
Expected: `3`

- [ ] **Step 3: Commit**

```bash
git add plugins/setup-config/skills/setup-config/references/sandbox-modes.md
git commit -m "feat(setup-config): reference sandbox-modes"
```

---

## Task 5: Reference `measure-catalog.md` (catálogo + descartadas)

**Files:**
- Create: `plugins/setup-config/skills/setup-config/references/measure-catalog.md`

- [ ] **Step 1: Crear el fichero**

```markdown
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
```

- [ ] **Step 2: Verificar contenido clave**

Run:
```bash
grep -q 'disableBypassPermissionsMode' plugins/setup-config/skills/setup-config/references/measure-catalog.md \
&& grep -q 'DESTRUCTIVE_APPROVED=1' plugins/setup-config/skills/setup-config/references/measure-catalog.md \
&& echo OK
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add plugins/setup-config/skills/setup-config/references/measure-catalog.md
git commit -m "feat(setup-config): reference measure-catalog"
```

---

## Task 6: Reference `golden-rules.md` (reglas de aplicación)

**Files:**
- Create: `plugins/setup-config/skills/setup-config/references/golden-rules.md`

- [ ] **Step 1: Crear el fichero**

```markdown
# Reglas de oro de aplicación

El orquestador SIEMPRE sigue estas invariantes al escribir cualquier settings:

1. **Read-before-write + merge, nunca reemplazar.** Leer el settings destino; mergear dentro de los
   arrays `allow`/`deny`/`ask` sin pisar lo existente; deduplicar entradas. Nunca sobrescribir el
   array entero.
2. **Validar con `jq -e` tras cada escritura.** Un JSON roto desactiva en silencio TODA la config de
   ese fichero. Si la validación falla: restaurar el contenido previo y avisar; no continuar.
3. **Nivel correcto.** Medidas personales → `~/.claude/settings.json` (user) o
   `.claude/settings.local.json` (repo). Nunca escribir config personal en el `settings.json` de
   equipo (commiteable).
4. **`$HOME` dinámico.** Resolver el home real (`echo $HOME`); nunca hardcodear `/Users/<user>`.
5. **Copia de assets idempotente.**
   - `check-destructive.py` → `~/.claude/hooks/check-destructive.py`, luego `chmod 600`.
   - `security-auditor.md` → `~/.claude/agents/security-auditor.md`.
   - Si el destino ya existe y difiere, avisar antes de sobrescribir.
6. **Aviso de recarga de hooks.** Registrar/des-registrar un hook en settings requiere `/hooks` o
   reiniciar; el script en disco surte efecto inmediato. Avisar al terminar.
7. **Nada sin confirmación.** Cada medida se confirma con `AskUserQuestion`. Las descartadas del
   catálogo mantienen default No.
```

- [ ] **Step 2: Verificar contenido clave**

Run: `grep -q 'jq -e' plugins/setup-config/skills/setup-config/references/golden-rules.md && grep -q 'chmod 600' plugins/setup-config/skills/setup-config/references/golden-rules.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add plugins/setup-config/skills/setup-config/references/golden-rules.md
git commit -m "feat(setup-config): reference golden-rules"
```

---

## Task 7: Orquestador `SKILL.md`

**Files:**
- Create: `plugins/setup-config/skills/setup-config/SKILL.md`

- [ ] **Step 1: Crear el `SKILL.md`**

````markdown
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
````

- [ ] **Step 2: Verificar frontmatter y pasos clave**

Run:
```bash
head -3 plugins/setup-config/skills/setup-config/SKILL.md | grep -q '^name: setup-config' \
&& grep -q 'security-auditor' plugins/setup-config/skills/setup-config/SKILL.md \
&& grep -q 'CLAUDE_PLUGIN_ROOT' plugins/setup-config/skills/setup-config/SKILL.md \
&& echo OK
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add plugins/setup-config/skills/setup-config/SKILL.md
git commit -m "feat(setup-config): orquestador SKILL.md"
```

---

## Task 8: Comando-entrada fino `setup-config.md`

**Files:**
- Create: `plugins/setup-config/commands/setup-config.md`

- [ ] **Step 1: Crear el comando**

```markdown
---
description: Endurece la config de seguridad de Claude Code (user y/o repos) mediante preguntas guiadas, y la audita al final.
---

Vas a guiar al usuario para endurecer su configuración de seguridad de Claude Code.

Usa la skill `setup-config` y sigue su procedimiento al pie de la letra: empieza SIEMPRE por la
selección de scope (Paso 0), audita el estado actual, pregunta medida a medida, aplica respetando las
golden-rules, y cierra con la auditoría del subagente `security-auditor` y la ronda de corrección.

No apliques ninguna medida sin confirmación explícita del usuario.
```

- [ ] **Step 2: Verificar frontmatter**

Run: `head -3 plugins/setup-config/commands/setup-config.md | grep -q '^description:' && grep -q 'setup-config' plugins/setup-config/commands/setup-config.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add plugins/setup-config/commands/setup-config.md
git commit -m "feat(setup-config): comando-entrada /setup-config"
```

---

## Task 9: README del plugin

**Files:**
- Create: `plugins/setup-config/README.md`

- [ ] **Step 1: Crear el README**

```markdown
# setup-config

Instalador guiado one-shot del endurecimiento de seguridad de Claude Code. Invócalo con
`/setup-config`.

## Qué hace

1. **Scope:** eliges (multi-select) dónde aplicar — **User**, el **repo actual**, y/o **otros repos**
   (escaneando un directorio raíz).
2. **Audita** el estado actual de la config de los scopes elegidos.
3. **Pregunta medida a medida** (recomendación + trade-off): hook anti-destructivo global, `deny` de
   catastróficos + secretos, `ask` de `.env`/`git push`, limpieza de `allow` peligrosos, y para repos
   el modo de sandbox y la higiene de `.gitignore`.
4. **Aplica** en TU config (`~/.claude/` y los `settings.local.json` de los repos), validando el JSON.
   El plugin es un instalador: la protección persiste aunque lo desactives.
5. **Audita el resultado** con el subagente `security-auditor` y te ofrece corregir o asumir cada
   riesgo.

## Qué NO cubre (riesgo residual)

Bajo `--dangerously-skip-permissions` solo sobreviven `deny` + hooks. Sin capa `managed` (opt-in
avanzado), el agente puede reescribir sus propios límites en autopilot. La exfiltración vía
`curl`/`wget`/`nc` no está denegada por defecto.

## Artefactos que instala

- `~/.claude/hooks/check-destructive.py` (chmod 600) — hook anti-destructivo, registrado en tu
  `settings.json` de user.
- `~/.claude/agents/security-auditor.md` — para poder re-auditar cuando quieras.

Tras instalar/registrar el hook, abre `/hooks` o reinicia para que Claude Code lo recoja.
```

- [ ] **Step 2: Verificar**

Run: `test -f plugins/setup-config/README.md && grep -q 'riesgo residual' plugins/setup-config/README.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add plugins/setup-config/README.md
git commit -m "docs(setup-config): README del plugin"
```

---

## Task 10: Validación estructural end-to-end

**Files:** ninguno nuevo (solo verificación; corregir inline si algo falla).

- [ ] **Step 1: Verificar que existen todos los ficheros esperados**

Run:
```bash
cd plugins/setup-config && for f in \
  .claude-plugin/plugin.json \
  commands/setup-config.md \
  skills/setup-config/SKILL.md \
  skills/setup-config/references/measure-catalog.md \
  skills/setup-config/references/settings-templates.md \
  skills/setup-config/references/sandbox-modes.md \
  skills/setup-config/references/golden-rules.md \
  agents/security-auditor.md \
  assets/check-destructive.py \
  README.md; do
  test -f "$f" && echo "OK  $f" || echo "FALTA $f"
done; cd -
```
Expected: `OK` en las 10 líneas, ningún `FALTA`.

- [ ] **Step 2: Validar todos los JSON del plugin + marketplace**

Run:
```bash
jq -e . plugins/setup-config/.claude-plugin/plugin.json > /dev/null \
&& jq -e . .claude-plugin/marketplace.json > /dev/null \
&& echo "JSON OK"
```
Expected: `JSON OK`

- [ ] **Step 3: Recompilar el hook (sanity final)**

Run: `python3 -m py_compile plugins/setup-config/assets/check-destructive.py && echo OK`
Expected: `OK`

- [ ] **Step 4: Verificar frontmatter de skill, agente y comando**

Run:
```bash
grep -q '^name: setup-config' plugins/setup-config/skills/setup-config/SKILL.md \
&& grep -q '^name: security-auditor' plugins/setup-config/agents/security-auditor.md \
&& grep -q '^description:' plugins/setup-config/commands/setup-config.md \
&& echo OK
```
Expected: `OK`

- [ ] **Step 5: Commit final (si hubo correcciones) o anotar que la validación pasó**

```bash
git add -A plugins/setup-config
git commit -m "chore(setup-config): validación estructural end-to-end" || echo "nada que commitear, validación limpia"
```

---

## Verificación final del plan (manual, tras ejecutar todas las tareas)

1. **Cobertura del spec:** Paso 0 scope (req 1) ✓ Task 7; aplicar→auditar→corregir (req 2) ✓ Task 7 Pasos 3-4; instalador one-shot a `~/.claude/` ✓ golden-rules + SKILL Paso 3; artefactos = 2 ✓ Task 2; omisiones (sync-env, inversión gitignore, secretos) respetadas ✓.
2. **Carga del plugin:** en una sesión nueva, `/setup-config` debe aparecer y la skill `setup-config` estar disponible. (Verificación manual fuera del alcance de los comandos shell.)
3. **Smoke real opcional:** ejecutar `/setup-config` eligiendo solo "User", confirmar que audita, pregunta y NO aplica nada sin confirmación.
