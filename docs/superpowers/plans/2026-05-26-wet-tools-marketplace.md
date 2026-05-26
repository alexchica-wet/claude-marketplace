# wet-tools Marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `wet-tools` Claude Code marketplace skeleton plus two plugins: `learn-basics` (pedagogical, one example per component type) and `wet-flow` (functional git/commit/PR helper).

**Architecture:** Single git repository hosting a marketplace at root (`.claude-plugin/marketplace.json`) and per-plugin directories under `plugins/`. Each plugin self-contained with its own manifest, commands, skills, agents and hooks following Claude Code's official plugin spec.

**Tech Stack:** Markdown files with YAML frontmatter (commands, skills, agents), JSON manifests (marketplace and plugin), Bash for hook scripts, `jq` for JSON validation, `git` CLI.

**Working directory:** `/Users/alejandrochicagutierrez/Desktop/WETACA/claude-marketplace`

---

## Reference: Claude Code Plugin Format

Quick refresher so you don't have to look it up mid-task.

### `marketplace.json` (root, in `.claude-plugin/`)
```json
{
  "name": "wet-tools",
  "owner": { "name": "Alex Chica", "email": "alexchica@wetaca.com" },
  "metadata": { "description": "...", "version": "0.1.0" },
  "plugins": [
    {
      "name": "<plugin-name>",
      "description": "...",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/alexchica-wet/claude-marketplace.git",
        "path": "plugins/<plugin-name>"
      },
      "version": "0.1.0"
    }
  ]
}
```

### `plugin.json` (per plugin, in `<plugin>/.claude-plugin/`)
```json
{
  "name": "<plugin-name>",
  "description": "...",
  "version": "0.1.0",
  "author": { "name": "Alex Chica", "email": "alexchica@wetaca.com" },
  "repository": "https://github.com/alexchica-wet/claude-marketplace",
  "license": "MIT",
  "keywords": ["..."]
}
```

### Command (`commands/<name>.md`)
```markdown
---
description: Short description shown in /help
argument-hint: [optional positional args]
---

# Markdown body — this is the prompt Claude executes when the user runs the command.
# Use $ARGUMENTS to interpolate the user-typed arguments.
```

### Skill (`skills/<name>/SKILL.md`)
```markdown
---
name: <skill-name>
description: When this skill should activate — be specific so Claude picks it up.
---

# Markdown body — the skill content Claude reads when activated.
```

### Agent (`agents/<name>.md`)
```markdown
---
name: <agent-name>
description: When to invoke this agent.
tools: Read, Grep, Bash       # or "*" for all tools
---

# Markdown body — the system prompt for the subagent.
```

### Hooks (`hooks/hooks.json`)
```json
{
  "<EventName>": [
    {
      "matcher": "<tool-name-regex-or-empty>",
      "hooks": [
        { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh" }
      ]
    }
  ]
}
```
Hook scripts receive JSON on stdin describing the event. Exit code `2` blocks the action and shows stderr; exit `0` allows.

---

# Phase 1 — Marketplace Skeleton

## Task 1: Initialize marketplace.json

**Files:**
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create the directory**

```bash
mkdir -p .claude-plugin
```

- [ ] **Step 2: Write `marketplace.json` with empty plugins array**

```json
{
  "name": "wet-tools",
  "owner": {
    "name": "Alex Chica",
    "email": "alexchica@wetaca.com"
  },
  "metadata": {
    "description": "Marketplace personal de plugins para Claude Code",
    "version": "0.1.0"
  },
  "plugins": []
}
```

- [ ] **Step 3: Validate it parses as JSON**

Run: `jq . .claude-plugin/marketplace.json`
Expected: pretty-printed JSON matching what was written (no parse error).

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat: scaffold wet-tools marketplace.json"
```

---

## Task 2: Add LICENSE, .gitignore and update README

**Files:**
- Create: `LICENSE`
- Create: `.gitignore`
- Modify: `README.md`

- [ ] **Step 1: Write MIT LICENSE**

Create `LICENSE` with standard MIT text, copyright holder `Alex Chica`, year `2026`. Use the canonical template (e.g. https://opensource.org/license/mit), substituting only the year and name.

- [ ] **Step 2: Write `.gitignore`**

```gitignore
.DS_Store
node_modules/
*.log
.idea/
.vscode/
```

- [ ] **Step 3: Update `README.md`**

Replace the existing two-line README with:

```markdown
# wet-tools

Marketplace personal de plugins para Claude Code.

## Instalación

En una sesión de Claude Code:

```
/plugin marketplace add alexchica-wet/claude-marketplace
/plugin install <nombre-plugin>@wet-tools
```

## Plugins disponibles

_Pendiente: se irán añadiendo aquí a medida que se publiquen._

## Estructura

- `.claude-plugin/marketplace.json` — catálogo del marketplace.
- `plugins/<nombre>/` — cada plugin, autocontenido.
- `docs/superpowers/specs/` — diseños aprobados.
- `docs/superpowers/plans/` — planes de implementación.

## Licencia

MIT.
```

- [ ] **Step 4: Commit**

```bash
git add LICENSE .gitignore README.md
git commit -m "chore: add LICENSE, .gitignore and expanded README"
```

---

# Phase 2 — Plugin `learn-basics`

Goal of this phase: one example of each component type (command, skill, agent, hook), each as trivial as possible, with READMEs that explain the structure.

## Task 3: Create plugin manifest

**Files:**
- Create: `plugins/learn-basics/.claude-plugin/plugin.json`

- [ ] **Step 1: Create directories**

```bash
mkdir -p plugins/learn-basics/.claude-plugin
mkdir -p plugins/learn-basics/commands
mkdir -p plugins/learn-basics/skills/proyecto-actual
mkdir -p plugins/learn-basics/agents
mkdir -p plugins/learn-basics/hooks
```

- [ ] **Step 2: Write `plugin.json`**

```json
{
  "name": "learn-basics",
  "description": "Plugin pedagógico — un ejemplo mínimo de cada tipo de componente (command, skill, agent, hook)",
  "version": "0.1.0",
  "author": { "name": "Alex Chica", "email": "alexchica@wetaca.com" },
  "repository": "https://github.com/alexchica-wet/claude-marketplace",
  "license": "MIT",
  "keywords": ["learning", "demo", "starter"]
}
```

- [ ] **Step 3: Validate**

Run: `jq . plugins/learn-basics/.claude-plugin/plugin.json`
Expected: pretty-printed JSON.

- [ ] **Step 4: Commit**

```bash
git add plugins/learn-basics/.claude-plugin/plugin.json
git commit -m "feat(learn-basics): add plugin manifest"
```

---

## Task 4: Add command `/saluda`

**Files:**
- Create: `plugins/learn-basics/commands/saluda.md`

- [ ] **Step 1: Write the command file**

```markdown
---
description: Saluda al nombre dado, o "mundo" si no se pasa argumento.
argument-hint: [nombre]
---

Eres un saludador entusiasta. El usuario te ha invocado con el argumento: `$ARGUMENTS`.

- Si `$ARGUMENTS` está vacío, saluda a "mundo".
- Si tiene contenido, salúdalo por su nombre.
- Responde en una sola línea, sin emojis, en español.

Ejemplo de respuesta esperada:
- `/saluda` → "¡Hola, mundo!"
- `/saluda Alex` → "¡Hola, Alex!"
```

- [ ] **Step 2: Verify frontmatter is valid YAML**

Run: `head -5 plugins/learn-basics/commands/saluda.md`
Expected: shows the three-dash frontmatter block with `description` and `argument-hint` keys.

- [ ] **Step 3: Commit**

```bash
git add plugins/learn-basics/commands/saluda.md
git commit -m "feat(learn-basics): add /saluda command"
```

---

## Task 5: Add skill `proyecto-actual`

**Files:**
- Create: `plugins/learn-basics/skills/proyecto-actual/SKILL.md`

- [ ] **Step 1: Write `SKILL.md`**

```markdown
---
name: proyecto-actual
description: Use when the user asks "what is this project", "qué hay en este repo", "en qué proyecto estoy", or otherwise wants a quick summary of the current working directory's project.
---

# Skill: proyecto-actual

Cuando el usuario pregunte qué proyecto es este o por su contenido:

1. Lee `README.md` del directorio actual si existe.
2. Si no existe, lista archivos top-level con `ls -la` y describe lo que ves.
3. Devuelve un resumen de **máximo 3 frases** en español:
   - Qué es el proyecto.
   - Lenguaje/stack principal (deducido por extensiones de archivo si no hay README).
   - Estado aparente (vacío, en desarrollo, abandonado por fecha de último commit si es repo git).

No inventes información. Si no hay README ni archivos representativos, dilo claramente.
```

- [ ] **Step 2: Verify the file is in the right place**

Run: `ls plugins/learn-basics/skills/proyecto-actual/`
Expected: `SKILL.md` listed.

- [ ] **Step 3: Commit**

```bash
git add plugins/learn-basics/skills/proyecto-actual/SKILL.md
git commit -m "feat(learn-basics): add proyecto-actual skill"
```

---

## Task 6: Add agent `eco`

**Files:**
- Create: `plugins/learn-basics/agents/eco.md`

- [ ] **Step 1: Write the agent file**

```markdown
---
name: eco
description: Resume cualquier texto que recibas en una sola frase. Úsalo cuando necesites comprimir un párrafo o una respuesta larga en un titular conciso.
tools: Read
---

Eres un agente "eco". Recibes un texto y devuelves **una única frase** en español que capture la idea central.

Reglas:
- Una sola frase. Sin viñetas, sin listas.
- Máximo 25 palabras.
- No añadas opinión ni interpretación: solo resume.
- Si el texto está vacío, responde literalmente: "(sin contenido)".
```

- [ ] **Step 2: Verify**

Run: `head -5 plugins/learn-basics/agents/eco.md`
Expected: frontmatter with `name: eco`, `description`, `tools: Read`.

- [ ] **Step 3: Commit**

```bash
git add plugins/learn-basics/agents/eco.md
git commit -m "feat(learn-basics): add eco agent"
```

---

## Task 7: Add SessionStart hook

**Files:**
- Create: `plugins/learn-basics/hooks/hooks.json`
- Create: `plugins/learn-basics/hooks/session-start.sh`

- [ ] **Step 1: Write the hook script**

Create `plugins/learn-basics/hooks/session-start.sh`:

```bash
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x plugins/learn-basics/hooks/session-start.sh
```

- [ ] **Step 3: Test the script manually in this repo**

Run: `plugins/learn-basics/hooks/session-start.sh`
Expected: a line like `[learn-basics] rama: main | último commit: <hash> <subject> | cambios sin commitear: <n>`.

- [ ] **Step 4: Write `hooks.json`**

Create `plugins/learn-basics/hooks/hooks.json`:

```json
{
  "SessionStart": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
        }
      ]
    }
  ]
}
```

- [ ] **Step 5: Validate JSON**

Run: `jq . plugins/learn-basics/hooks/hooks.json`
Expected: pretty-printed JSON.

- [ ] **Step 6: Commit**

```bash
git add plugins/learn-basics/hooks/hooks.json plugins/learn-basics/hooks/session-start.sh
git commit -m "feat(learn-basics): add SessionStart hook"
```

---

## Task 8: Write learn-basics README

**Files:**
- Create: `plugins/learn-basics/README.md`

- [ ] **Step 1: Write the README**

```markdown
# learn-basics

Plugin pedagógico del marketplace `wet-tools`. Contiene **un ejemplo mínimo de cada tipo de componente** que soporta un plugin de Claude Code. El objetivo no es ser útil — es enseñar la estructura.

## Componentes

### Comando: `/saluda [nombre]`
- **Archivo**: `commands/saluda.md`
- **Qué hace**: saluda al nombre dado, o a "mundo".
- **Qué enseña**: cómo se define un slash command y cómo se reciben argumentos vía `$ARGUMENTS`.

### Skill: `proyecto-actual`
- **Archivo**: `skills/proyecto-actual/SKILL.md`
- **Qué hace**: resume el proyecto actual leyendo README o listando archivos.
- **Qué enseña**: cómo se auto-activa una skill mediante su `description` en el frontmatter.

### Agent: `eco`
- **Archivo**: `agents/eco.md`
- **Qué hace**: resume cualquier texto en una sola frase.
- **Qué enseña**: cómo se define un subagente con su propio system prompt y lista de tools.

### Hook: `SessionStart`
- **Archivos**: `hooks/hooks.json` + `hooks/session-start.sh`
- **Qué hace**: al iniciar sesión muestra rama, último commit y nº de cambios sin commitear.
- **Qué enseña**: cómo conectar un evento del SDK a un script bash via `${CLAUDE_PLUGIN_ROOT}`.

## Instalación

```
/plugin marketplace add alexchica-wet/claude-marketplace
/plugin install learn-basics@wet-tools
```
```

- [ ] **Step 2: Commit**

```bash
git add plugins/learn-basics/README.md
git commit -m "docs(learn-basics): add plugin README"
```

---

## Task 9: Register learn-basics in marketplace.json

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Update the `plugins` array**

Replace the empty array with one entry. Final file:

```json
{
  "name": "wet-tools",
  "owner": {
    "name": "Alex Chica",
    "email": "alexchica@wetaca.com"
  },
  "metadata": {
    "description": "Marketplace personal de plugins para Claude Code",
    "version": "0.1.0"
  },
  "plugins": [
    {
      "name": "learn-basics",
      "description": "Plugin pedagógico — un ejemplo mínimo de cada tipo de componente",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/alexchica-wet/claude-marketplace.git",
        "path": "plugins/learn-basics"
      },
      "version": "0.1.0"
    }
  ]
}
```

- [ ] **Step 2: Validate**

Run: `jq '.plugins | length' .claude-plugin/marketplace.json`
Expected: `1`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat: register learn-basics in marketplace catalog"
```

---

## Task 10: Smoke test learn-basics

**Files:** none — manual verification.

This is a manual checkpoint. The user runs these steps interactively in a Claude Code session inside this repo.

- [ ] **Step 1: Push to remote so `git-subdir` source resolves**

```bash
git push origin main
```

- [ ] **Step 2: Add the marketplace and install the plugin**

In a Claude Code session inside any test directory:

```
/plugin marketplace add alexchica-wet/claude-marketplace
/plugin install learn-basics@wet-tools
```

- [ ] **Step 3: Verify each component**

- Command: type `/saluda Alex` → expect "¡Hola, Alex!".
- Skill: ask "¿qué hay en este repo?" → expect a 1-3 frase summary using `proyecto-actual`.
- Agent: invoke the `eco` subagent with a paragraph → expect a 1-frase summary.
- Hook: start a new session in a git repo → expect the `[learn-basics]` info line.

- [ ] **Step 4: Uninstall and confirm clean state**

```
/plugin uninstall learn-basics@wet-tools
```

If any check fails, fix and commit before moving to Phase 3.

---

# Phase 3 — Plugin `wet-flow`

Goal: a functional plugin for daily git/commit/PR workflow.

## Task 11: Create plugin manifest

**Files:**
- Create: `plugins/wet-flow/.claude-plugin/plugin.json`

- [ ] **Step 1: Create directories**

```bash
mkdir -p plugins/wet-flow/.claude-plugin
mkdir -p plugins/wet-flow/commands
mkdir -p plugins/wet-flow/skills/conventional-commits
mkdir -p plugins/wet-flow/agents
mkdir -p plugins/wet-flow/hooks
```

- [ ] **Step 2: Write `plugin.json`**

```json
{
  "name": "wet-flow",
  "description": "Flujo git/commit/PR — commit asistido, revisor de diff, hook anti-force-push",
  "version": "0.1.0",
  "author": { "name": "Alex Chica", "email": "alexchica@wetaca.com" },
  "repository": "https://github.com/alexchica-wet/claude-marketplace",
  "license": "MIT",
  "keywords": ["git", "commit", "pr", "workflow"]
}
```

- [ ] **Step 3: Validate**

Run: `jq . plugins/wet-flow/.claude-plugin/plugin.json`
Expected: pretty-printed JSON.

- [ ] **Step 4: Commit**

```bash
git add plugins/wet-flow/.claude-plugin/plugin.json
git commit -m "feat(wet-flow): add plugin manifest"
```

---

## Task 12: Add command `/commit`

**Files:**
- Create: `plugins/wet-flow/commands/commit.md`

- [ ] **Step 1: Write the command file**

```markdown
---
description: Genera un mensaje de commit (Conventional Commits) desde el diff staged y pide confirmación.
argument-hint: [opcional: pista/tipo]
---

Vas a ayudar al usuario a crear un commit en formato Conventional Commits.

## Pasos

1. Ejecuta `git diff --staged --stat` y `git diff --staged` (cabeza, ~200 líneas).
2. Si **no hay cambios staged**, responde literalmente: `No hay cambios staged. Haz git add primero.` y termina.
3. Analiza los cambios y propón **un único mensaje** con formato:
   `tipo(scope): descripción imperativa en minúsculas`
   - Tipos válidos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`, `build`, `ci`.
   - `scope` opcional (entre paréntesis). Si no aplica, omítelo.
   - Descripción ≤ 72 caracteres.
4. Si el usuario pasó `$ARGUMENTS` y parece ser un tipo o pista, úsalo como sesgo.
5. Muestra el mensaje propuesto al usuario y **pregunta**: "¿Commiteo con este mensaje? (sí/no/edita)".
6. Si responde "sí" → ejecuta `git commit -m "<mensaje>"` y muestra el output.
7. Si responde "no" → no commitees nada.
8. Si responde "edita" o propone otro mensaje → usa el que indique.

**Nunca** commitees sin confirmación explícita.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/wet-flow/commands/commit.md
git commit -m "feat(wet-flow): add /commit command"
```

---

## Task 13: Add skill `conventional-commits`

**Files:**
- Create: `plugins/wet-flow/skills/conventional-commits/SKILL.md`

- [ ] **Step 1: Write `SKILL.md`**

```markdown
---
name: conventional-commits
description: Use when the user is about to create a git commit, asks how to write a commit message, drafts a commit, or invokes any /commit-related command. Guides the user toward the Conventional Commits format.
---

# Skill: conventional-commits

Cuando el usuario esté preparando un commit, asegúrate de que el mensaje siga el formato:

```
<tipo>(<scope opcional>): <descripción imperativa en minúsculas>

<cuerpo opcional, explicando el porqué — no el qué>

<footers opcionales: BREAKING CHANGE, Refs, Co-Authored-By>
```

## Tipos válidos

| Tipo | Cuándo |
|---|---|
| `feat` | Nueva funcionalidad para el usuario. |
| `fix` | Corrección de un bug. |
| `docs` | Solo cambios en documentación. |
| `refactor` | Cambio interno sin alterar comportamiento. |
| `test` | Añadir o corregir tests. |
| `chore` | Mantenimiento (deps, config, build) sin código de producto. |
| `perf` | Mejora de rendimiento. |
| `style` | Formato, espacios, comas — no afecta a la lógica. |
| `build` | Cambios en sistema de build o dependencias externas. |
| `ci` | Cambios en CI/CD. |

## Reglas

- Descripción ≤ 72 caracteres, imperativo presente ("añade", no "añadido").
- Sin punto final.
- Scope entre paréntesis si aplica (p. ej. módulo o área).
- Si introduce breaking change → añade `!` después del scope (ej. `feat(api)!: ...`) **y** una línea `BREAKING CHANGE: ...` en el footer.

## Ejemplos

- `feat(auth): añade login con google`
- `fix(api)!: cambia formato de respuesta /users` + footer `BREAKING CHANGE: ...`
- `docs: corrige typo en README`
- `chore(deps): actualiza tailwind a 3.4`
```

- [ ] **Step 2: Commit**

```bash
git add plugins/wet-flow/skills/conventional-commits/SKILL.md
git commit -m "feat(wet-flow): add conventional-commits skill"
```

---

## Task 14: Add agent `diff-reviewer`

**Files:**
- Create: `plugins/wet-flow/agents/diff-reviewer.md`

- [ ] **Step 1: Write the agent file**

```markdown
---
name: diff-reviewer
description: Revisa el diff actual del repositorio (staged o vs main) buscando bugs potenciales, código sospechoso y oportunidades de mejora. No bloquea — solo informa. Úsalo antes de commitear o de abrir un PR.
tools: Read, Grep, Bash
---

Eres un revisor de diffs. Tu único trabajo es analizar el diff actual y dar feedback útil y conciso.

## Pasos

1. Determina el diff a revisar:
   - Si el usuario te pasa un rango (ej. `main..HEAD`), úsalo.
   - Si no, intenta `git diff --staged`; si está vacío, usa `git diff HEAD`.
2. Lee el diff completo (`git diff <rango>`).
3. Analiza y reporta en **tres secciones, en este orden**:

### Bugs potenciales
Cosas que probablemente fallarán en producción: null/undefined no comprobados, condiciones invertidas, fugas de recursos, queries N+1 obvias, secrets en el código.

### Código sospechoso
Cosas que **podrían** estar mal pero no son seguras: nombres confusos, complejidad excesiva, duplicación, magic numbers, falta de manejo de errores en bordes del sistema.

### Sugerencias
Mejoras opcionales: extracción de funciones, comentarios donde el porqué no es obvio, simplificaciones.

## Reglas

- Sé concreto: cita líneas y archivos.
- No inventes problemas. Si no encuentras nada en una categoría, pon "Nada que reportar."
- No reescribas el código — solo describe el problema.
- Máximo 10 puntos en total entre las tres secciones. Prioriza.
- No bloquees nada. Eres informativo.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/wet-flow/agents/diff-reviewer.md
git commit -m "feat(wet-flow): add diff-reviewer agent"
```

---

## Task 15: Add anti-force-push hook

**Files:**
- Create: `plugins/wet-flow/hooks/hooks.json`
- Create: `plugins/wet-flow/hooks/check-force-push.sh`

- [ ] **Step 1: Write the hook script**

Create `plugins/wet-flow/hooks/check-force-push.sh`:

```bash
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x plugins/wet-flow/hooks/check-force-push.sh
```

- [ ] **Step 3: Manual unit tests for the script**

Test that it allows safe commands and blocks dangerous ones. Run each in turn:

```bash
# Allow: not a git push
echo '{"tool_input":{"command":"ls"}}' | plugins/wet-flow/hooks/check-force-push.sh ; echo "exit=$?"
# Expected: exit=0

# Allow: git push without force
echo '{"tool_input":{"command":"git push origin main"}}' | plugins/wet-flow/hooks/check-force-push.sh ; echo "exit=$?"
# Expected: exit=0

# Allow: --force to a feature branch
echo '{"tool_input":{"command":"git push --force origin feature/foo"}}' | plugins/wet-flow/hooks/check-force-push.sh ; echo "exit=$?"
# Expected: exit=0

# Allow: --force-with-lease to main
echo '{"tool_input":{"command":"git push --force-with-lease origin main"}}' | plugins/wet-flow/hooks/check-force-push.sh ; echo "exit=$?"
# Expected: exit=0

# Block: --force to main
echo '{"tool_input":{"command":"git push --force origin main"}}' | plugins/wet-flow/hooks/check-force-push.sh 2>&1 ; echo "exit=$?"
# Expected: BLOQUEADO message on stderr + exit=2

# Block: -f to master
echo '{"tool_input":{"command":"git push -f origin master"}}' | plugins/wet-flow/hooks/check-force-push.sh 2>&1 ; echo "exit=$?"
# Expected: BLOQUEADO message + exit=2
```

If any case behaves differently, fix the script before continuing.

- [ ] **Step 4: Write `hooks.json`**

Create `plugins/wet-flow/hooks/hooks.json`:

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/hooks/check-force-push.sh"
        }
      ]
    }
  ]
}
```

- [ ] **Step 5: Validate JSON**

Run: `jq . plugins/wet-flow/hooks/hooks.json`
Expected: pretty-printed JSON.

- [ ] **Step 6: Commit**

```bash
git add plugins/wet-flow/hooks/hooks.json plugins/wet-flow/hooks/check-force-push.sh
git commit -m "feat(wet-flow): add anti-force-push PreToolUse hook"
```

---

## Task 16: Write wet-flow README

**Files:**
- Create: `plugins/wet-flow/README.md`

- [ ] **Step 1: Write the README**

```markdown
# wet-flow

Plugin funcional del marketplace `wet-tools` para el flujo diario git/commit/PR. Mantiene paridad 1-de-cada-tipo con `learn-basics`.

## Componentes

### Comando: `/commit [pista]`
Lee `git diff --staged`, propone un mensaje en formato Conventional Commits, **pide confirmación** antes de commitear.

### Skill: `conventional-commits`
Se auto-activa al preparar un commit. Asegura el formato `tipo(scope): descripción` con tipos válidos (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`, `build`, `ci`).

### Agent: `diff-reviewer`
Subagente que revisa el diff actual y reporta bugs potenciales, código sospechoso y sugerencias. Solo informa — no bloquea.

### Hook: `PreToolUse` anti-force-push
Bloquea `git push --force` (sin `--force-with-lease`) hacia `main` o `master`. Otros force-push pasan sin avisos.

## Instalación

```
/plugin marketplace add alexchica-wet/claude-marketplace
/plugin install wet-flow@wet-tools
```

## Diseño

Ver `docs/superpowers/specs/2026-05-26-wet-tools-marketplace-design.md` en la raíz del marketplace.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/wet-flow/README.md
git commit -m "docs(wet-flow): add plugin README"
```

---

## Task 17: Register wet-flow in marketplace.json + update root README

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

- [ ] **Step 1: Update `marketplace.json` to include `wet-flow`**

Final `plugins` array (replace the existing one):

```json
"plugins": [
  {
    "name": "learn-basics",
    "description": "Plugin pedagógico — un ejemplo mínimo de cada tipo de componente",
    "source": {
      "source": "git-subdir",
      "url": "https://github.com/alexchica-wet/claude-marketplace.git",
      "path": "plugins/learn-basics"
    },
    "version": "0.1.0"
  },
  {
    "name": "wet-flow",
    "description": "Flujo git/commit/PR — commit asistido, revisor de diff, hook anti-force-push",
    "source": {
      "source": "git-subdir",
      "url": "https://github.com/alexchica-wet/claude-marketplace.git",
      "path": "plugins/wet-flow"
    },
    "version": "0.1.0"
  }
]
```

- [ ] **Step 2: Validate**

Run: `jq '.plugins | length' .claude-plugin/marketplace.json`
Expected: `2`

- [ ] **Step 3: Update root `README.md` `Plugins disponibles` section**

Replace the placeholder paragraph with:

```markdown
## Plugins disponibles

| Plugin | Descripción |
|---|---|
| [`learn-basics`](plugins/learn-basics/README.md) | Plugin pedagógico — un ejemplo mínimo de cada tipo de componente. |
| [`wet-flow`](plugins/wet-flow/README.md) | Flujo git/commit/PR — commit asistido, revisor de diff, hook anti-force-push. |
```

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/marketplace.json README.md
git commit -m "feat: register wet-flow in marketplace catalog"
```

---

## Task 18: Smoke test wet-flow

**Files:** none — manual verification.

- [ ] **Step 1: Push to remote**

```bash
git push origin main
```

- [ ] **Step 2: Update marketplace and install wet-flow**

```
/plugin marketplace update wet-tools
/plugin install wet-flow@wet-tools
```

- [ ] **Step 3: Verify each component**

- Command `/commit`:
  - In an empty staging area, `/commit` should respond "No hay cambios staged. Haz git add primero."
  - Stage a small change, run `/commit`, expect a Conventional Commits proposal + confirmation prompt.
- Skill: ask Claude "ayúdame a redactar un commit message para estos cambios" → expect the skill to guide format.
- Agent `diff-reviewer`: invoke on the current staged diff → expect a structured report with the three sections.
- Hook: try (carefully — use a throwaway remote or `--dry-run` if uncertain) `git push --force origin main`. Expected: blocked with the `[wet-flow]` message.

- [ ] **Step 4: Final commit (if any docs changed during testing)**

If smoke tests surfaced fixes, commit them before closing out.

---

## Acceptance criteria

The plan is complete when:

1. `jq . .claude-plugin/marketplace.json` shows both plugins listed.
2. `git log --oneline` shows a clean linear history with conventional commit messages.
3. Both plugins install cleanly via `/plugin install <name>@wet-tools`.
4. Each component (4 + 4 = 8) has been smoke-tested manually.
5. The root README links to both plugin READMEs.
6. No file in either plugin contains TODO / TBD / placeholder content.
