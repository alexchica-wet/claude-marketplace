# wet-tools — Diseño del marketplace inicial

**Fecha**: 2026-05-26
**Autor**: Alex Chica (`alexchica@wetaca.com`)
**Repo**: https://github.com/alexchica-wet/claude-marketplace
**Estado**: aprobado para implementación

---

## Objetivo

Crear un marketplace de plugins para Claude Code que sirva como punto de partida personal. Foco: **transversal / productividad general**. Prioridad inicial: **aprender la estructura** de cada componente del SDK de plugins (commands, skills, agents, hooks), y a continuación añadir un plugin con utilidad real en el día a día.

## Alcance

Tres entregables en este orden:
1. Esqueleto del marketplace (vacío, sin plugins listados).
2. Plugin `learn-basics` — pedagógico, un ejemplo trivial de cada tipo de componente.
3. Plugin `wet-flow` — funcional, foco en flujo git/commit/PR.

Fuera de alcance: publicación pública, registro en marketplaces de terceros, instalación cruzada con otros marketplaces, versionado avanzado.

---

## Sección 1 — Esqueleto del marketplace

### Estructura de directorios

```
claude-marketplace/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── learn-basics/           # añadido en Sección 2
│   └── wet-flow/               # añadido en Sección 3
├── docs/
│   └── superpowers/specs/      # este documento vive aquí
├── README.md
├── LICENSE                     # MIT
└── .gitignore
```

### `marketplace.json` inicial

```json
{
  "name": "wet-tools",
  "owner": { "name": "Alex Chica", "email": "alexchica@wetaca.com" },
  "metadata": {
    "description": "Marketplace personal de plugins para Claude Code",
    "version": "0.1.0"
  },
  "plugins": []
}
```

Cada plugin se añadirá al array `plugins` en su entrega correspondiente, con `source` de tipo `git-subdir` apuntando al repo público.

### Decisiones

- **Nombre**: `wet-tools`.
- **Licencia**: MIT (estándar para marketplaces compartibles).
- **Versionado**: SemVer; el marketplace empieza en `0.1.0` y se irá subiendo cada vez que se publique un plugin nuevo.
- **`.gitignore`**: cubre `.DS_Store`, `node_modules/`, `*.log`.
- **README**: introduce el marketplace y enumera los plugins disponibles con sus comandos.

---

## Sección 2 — Plugin `learn-basics` (pedagógico)

Plugin pensado **exclusivamente para aprender la estructura**. Cada componente es trivial; lo que importa es el formato, no el comportamiento.

### Estructura

```
plugins/learn-basics/
├── .claude-plugin/plugin.json
├── commands/saluda.md
├── skills/proyecto-actual/SKILL.md
├── agents/eco.md
├── hooks/hooks.json
└── README.md
```

### `plugin.json`

```json
{
  "name": "learn-basics",
  "description": "Plugin pedagógico — un ejemplo mínimo de cada tipo de componente",
  "version": "0.1.0",
  "author": { "name": "Alex Chica", "email": "alexchica@wetaca.com" },
  "repository": "https://github.com/alexchica-wet/claude-marketplace",
  "license": "MIT",
  "keywords": ["learning", "demo", "starter"]
}
```

### Componentes

| Tipo | Nombre | Comportamiento | Patrón que enseña |
|---|---|---|---|
| Command | `/saluda [nombre]` | Saluda al nombre dado (o "mundo"). | Argumentos posicionales en slash commands. |
| Skill | `proyecto-actual` | Lee `README.md` del cwd y resume el proyecto. | Auto-activación por descripción de skill. |
| Agent | `eco` | Recibe texto y devuelve resumen de 1 frase. | Subagente con system prompt mínimo. |
| Hook | `SessionStart` (script bash) | Imprime: rama, último commit, nº de cambios sin commitear. | Hook básico que ejecuta script en evento de sesión. |

### Documentación interna

El `README.md` del plugin explica cada archivo con comentarios línea a línea. **El valor de este plugin está en los READMEs**, no en su utilidad funcional.

### Entrada en `marketplace.json`

```json
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
```

---

## Sección 3 — Plugin `wet-flow` (funcional)

Plugin para uso diario en cualquier repo git. Mantiene la **paridad 1-de-cada-tipo** del Plugin A.

### Estructura

```
plugins/wet-flow/
├── .claude-plugin/plugin.json
├── commands/commit.md
├── skills/conventional-commits/SKILL.md
├── agents/diff-reviewer.md
├── hooks/hooks.json
└── README.md
```

### `plugin.json`

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

### Componentes

| Tipo | Nombre | Comportamiento |
|---|---|---|
| Command | `/commit` | Lee `git diff --staged`; propone mensaje en formato Conventional Commits; pide confirmación antes de commitear. Si no hay staged, avisa al usuario. |
| Skill | `conventional-commits` | Se activa al preparar un commit. Asegura formato `tipo(scope): descripción` con tipos válidos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. |
| Agent | `diff-reviewer` | Subagente que recibe el diff actual (staged o vs main) y devuelve: bugs potenciales, código sospechoso, sugerencias. No bloquea — solo informa. |
| Hook | `PreToolUse` en `Bash` | Detecta `git push --force` (sin `--force-with-lease`) hacia `main`/`master` y lo bloquea con un mensaje explicativo. |

### Interacción entre componentes

1. Editas archivos → puedes llamar al agente `diff-reviewer` para una revisión rápida.
2. Haces `git add` y vas a `/commit` → la skill `conventional-commits` ya está cargada y guía el formato.
3. Intentas `git push --force origin main` → el hook lo bloquea.

### Decisiones clave

- El hook bloquea solo `--force` sin `--force-with-lease`. `--force-with-lease` se considera suficientemente seguro y pasa sin avisos.
- El hook detecta `main` y `master` como ramas protegidas. Otras ramas no se tocan.
- `/commit` **siempre pide confirmación**; nunca commitea automáticamente.
- `diff-reviewer` es informativo, no bloqueante; nunca rechaza cambios.

### Entrada en `marketplace.json`

```json
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
```

---

## Plan de pruebas (alto nivel)

Tras cada plugin:

1. **Validación estructural**: `marketplace.json` y `plugin.json` parseables; estructura de directorios respetada.
2. **Instalación local**: `/plugin marketplace add` del repo local + `/plugin install <plugin>@wet-tools` en una sesión de prueba.
3. **Smoke test por componente**:
   - `learn-basics`: invocar `/saluda`, preguntar por el proyecto (skill), llamar agente `eco`, iniciar sesión y comprobar output del hook.
   - `wet-flow`: hacer un commit ficticio con `/commit`, llamar a `diff-reviewer` sobre cambios reales, probar el bloqueo del hook con `git push --force origin main` (sin pushear de verdad).
4. **Desinstalación**: `/plugin uninstall` deja la sesión limpia.

El plan detallado de implementación se elaborará por separado tras la aprobación de este spec.

---

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Cambios en la spec de Claude Code sobre `plugin.json` / `marketplace.json` | Versionar todo desde el inicio; revisar docs oficiales antes de cada publicación. |
| Hook con falsos positivos bloqueando trabajo legítimo | Empezar con regla muy estrecha (`--force` sin `--force-with-lease` a `main`/`master`). Probar antes de habilitarlo por defecto. |
| Agente `diff-reviewer` invoca otro modelo y consume tokens en exceso | El agente se invoca manualmente; no hay activación automática. |
| Skill `conventional-commits` colisiona con preferencias de otros proyectos | Skill solo orienta — no impone. El usuario decide. |
