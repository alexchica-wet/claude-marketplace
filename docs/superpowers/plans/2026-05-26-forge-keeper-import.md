# forge-keeper Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendorizar el plugin `forge-keeper` desde `dmedina-dev/dev-forge@v2.8.1` al marketplace `wet-tools` y dejar configurado el mecanismo de suscripción a upstream vía el comando `/forge-keeper:update-check` que el propio plugin trae.

**Architecture:** Vendor + customizations. Copia 1:1 del subdirectorio upstream `plugins/forge-keeper/` al árbol local `plugins/forge-keeper/`. Un fichero meta `customizations.json` declara el origen y registra nuestro único añadido (un README local). El plugin se registra en `.claude-plugin/marketplace.json` apuntando a nuestro repo. `.upstream/` queda gitignored para clones persistentes del comando `update-check` en ejecuciones futuras.

**Tech Stack:** Bash, git, `python3 -m json.tool` para validación de JSON. No requiere `gh`, `jq` ni dependencias adicionales (la suscripción usa fallback `git ls-remote` documentado por upstream).

**Spec de referencia:** `docs/superpowers/specs/2026-05-26-forge-keeper-import-design.md` (commit `c89f12e` en `feat/import-forge-keeper`).

---

## File Map

| Acción | Path | Responsabilidad |
|---|---|---|
| Modificar | `.gitignore` | +1 línea: `.upstream/` |
| Modificar | `.claude-plugin/marketplace.json` | Añadir entrada `forge-keeper` al array `plugins` |
| Crear (vendor, 17 blobs) | `plugins/forge-keeper/.claude-plugin/plugin.json`, `commands/*.md` (7), `hooks/{hooks.json,session-start-clear}`, `scripts/heal-plugin-cache.sh`, `skills/forge-keeper/SKILL.md`, `skills/forge-keeper/references/*.md` (5) | Copia exacta del upstream `v2.8.1` |
| Crear (nuevo) | `plugins/forge-keeper/.claude-plugin/customizations.json` | Meta: origen + estado upstream + customizations |
| Crear (nuevo, customization `added`) | `plugins/forge-keeper/README.md` | README local que identifica el plugin como mirror |

Total nuevos archivos: 19 (17 vendored + 2 propios). Modificaciones a archivos existentes: 2 (`.gitignore`, `marketplace.json`).

Estamos en la rama `feat/import-forge-keeper` (ya creada desde `main` sincronizado). Todos los pasos asumen `cwd = /Users/alejandrochicagutierrez/Desktop/WETACA/claude-marketplace`.

---

## Task 1: Gitignore `.upstream/`

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Leer el .gitignore actual**

Run: `cat .gitignore`

Expected output:
```
.DS_Store
node_modules/
*.log
.idea/
.vscode/
.claude/settings.local.json
```

- [ ] **Step 2: Añadir `.upstream/` al final**

Edita `.gitignore` para que quede así:

```
.DS_Store
node_modules/
*.log
.idea/
.vscode/
.claude/settings.local.json
.upstream/
```

- [ ] **Step 3: Verificar el cambio**

Run: `cat .gitignore | tail -1`
Expected: `.upstream/`

- [ ] **Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore .upstream/ for update-check clones

Reserva el directorio que /forge-keeper:update-check usará como cache
persistente de clones upstream cuando se ejecute.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Vendor copy from upstream `v2.8.1`

**Files:**
- Create (tree): `plugins/forge-keeper/` con los 17 blobs upstream listados en File Map.

- [ ] **Step 1: Clonar shallow el upstream a un directorio temporal**

```bash
rm -rf /tmp/dev-forge-v2.8.1
git clone --depth 1 --branch v2.8.1 https://github.com/dmedina-dev/dev-forge.git /tmp/dev-forge-v2.8.1
```

Expected: clon completo sin errores. Confirmar HEAD:

```bash
git -C /tmp/dev-forge-v2.8.1 rev-parse HEAD
```
Expected: `330000f7b6c38297b4604bb13ae475ea7126707a` (commit que v2.8.1 etiqueta; `10ea91b1` es el tag object SHA del tag anotado, no aparece por aquí).

- [ ] **Step 2: Copiar el subdirectorio preservando permisos**

```bash
cp -R /tmp/dev-forge-v2.8.1/plugins/forge-keeper plugins/forge-keeper
```

- [ ] **Step 3: Verificar la lista de archivos importados**

```bash
find plugins/forge-keeper -type f | sort
```

Expected output (17 líneas):
```
plugins/forge-keeper/.claude-plugin/plugin.json
plugins/forge-keeper/commands/handoff.md
plugins/forge-keeper/commands/heal-plugin-cache.md
plugins/forge-keeper/commands/recall.md
plugins/forge-keeper/commands/segment-doc.md
plugins/forge-keeper/commands/status.md
plugins/forge-keeper/commands/sync.md
plugins/forge-keeper/commands/update-check.md
plugins/forge-keeper/hooks/hooks.json
plugins/forge-keeper/hooks/session-start-clear
plugins/forge-keeper/scripts/heal-plugin-cache.sh
plugins/forge-keeper/skills/forge-keeper/SKILL.md
plugins/forge-keeper/skills/forge-keeper/references/claudemd-guide.md
plugins/forge-keeper/skills/forge-keeper/references/exemplar-evaluation.md
plugins/forge-keeper/skills/forge-keeper/references/monorepo-patterns.md
plugins/forge-keeper/skills/forge-keeper/references/proposal-format.md
plugins/forge-keeper/skills/forge-keeper/references/update-check-guide.md
```

- [ ] **Step 4: Verificar el bit de ejecución de los dos scripts**

```bash
ls -l plugins/forge-keeper/hooks/session-start-clear plugins/forge-keeper/scripts/heal-plugin-cache.sh
```

Expected: ambos archivos con bits `-rwxr-xr-x` (o equivalente con `x` en user/group/other). Si no, restaurar con:

```bash
chmod +x plugins/forge-keeper/hooks/session-start-clear plugins/forge-keeper/scripts/heal-plugin-cache.sh
```

- [ ] **Step 5: Verificar fidelidad de contenido por hash contra upstream**

Para cada archivo importado, el `git hash-object` debe coincidir con el blob del upstream. El blob `plugin.json` upstream tiene SHA `(verificable con git -C /tmp/dev-forge-v2.8.1 ls-tree HEAD plugins/forge-keeper/.claude-plugin/plugin.json)`. Ejecuta este check global:

```bash
diff \
  <(cd /tmp/dev-forge-v2.8.1 && git ls-tree -r HEAD plugins/forge-keeper | awk '{print $3, substr($0, index($0,$4))}' | sort) \
  <(cd plugins/forge-keeper && find . -type f | while read f; do printf '%s plugins/forge-keeper/%s\n' "$(git hash-object "$f")" "${f#./}"; done | sort) \
&& echo "FIDELITY OK" || echo "MISMATCH — abortar y revisar"
```

Expected: `FIDELITY OK`

- [ ] **Step 6: Limpiar el clon temporal**

```bash
rm -rf /tmp/dev-forge-v2.8.1
```

- [ ] **Step 7: Commit (solo vendor, sin customizations todavía)**

```bash
git add plugins/forge-keeper
git status --short
```
Expected: 17 `A` lines bajo `plugins/forge-keeper/`.

```bash
git commit -m "feat(forge-keeper): vendor copy from dev-forge@v2.8.1

Copia 1:1 de plugins/forge-keeper/ del upstream dmedina-dev/dev-forge
en el tag v2.8.1 (commit 10ea91b1).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Add `customizations.json`

**Files:**
- Create: `plugins/forge-keeper/.claude-plugin/customizations.json`

- [ ] **Step 1: Escribir customizations.json**

Crea el archivo `plugins/forge-keeper/.claude-plugin/customizations.json` con este contenido exacto:

```json
{
  "origin": {
    "type": "github",
    "repo": "dmedina-dev/dev-forge",
    "path": "plugins/forge-keeper",
    "ref": "v2.8.1",
    "commit": "330000f7b6c38297b4604bb13ae475ea7126707a",
    "fetched_at": "2026-05-26",
    "check_url": "https://github.com/dmedina-dev/dev-forge/releases"
  },
  "upstream_status": {
    "last_checked": "2026-05-26",
    "latest_ref": "v2.8.1",
    "latest_commit": "330000f7b6c38297b4604bb13ae475ea7126707a",
    "has_updates": false,
    "summary": "",
    "changes": []
  },
  "customizations": [
    {
      "id": "custom-01",
      "type": "added",
      "target": "README.md",
      "summary": "Marketplace-local README explicando que es mirror de dev-forge",
      "reason": "Identificar el plugin como vendored en wet-tools, enlazar a upstream y documentar el flujo de actualización"
    }
  ]
}
```

- [ ] **Step 2: Validar JSON**

```bash
python3 -m json.tool plugins/forge-keeper/.claude-plugin/customizations.json > /dev/null && echo "JSON OK"
```
Expected: `JSON OK`

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-keeper/.claude-plugin/customizations.json
git commit -m "feat(forge-keeper): declare upstream origin in customizations.json

Pin a dmedina-dev/dev-forge@v2.8.1 con README.md como única customization
(tipo 'added'). Habilita /forge-keeper:update-check para detectar cambios
en upstream en ejecuciones futuras.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Write the local README

**Files:**
- Create: `plugins/forge-keeper/README.md`

- [ ] **Step 1: Escribir el README**

Crea el archivo `plugins/forge-keeper/README.md` con este contenido exacto:

```markdown
# forge-keeper (mirror)

Plugin que mantiene `CLAUDE.md`, reglas y documentación sincronizados con el estado real del proyecto. Provee comandos de sync, status, recall, segment-doc, handoff, heal-plugin-cache y update-check, además de un hook PreCompact que dispara el flujo de sync antes de comprimir contexto.

## Origen

Este directorio es un **mirror vendorizado** de [`dmedina-dev/dev-forge`](https://github.com/dmedina-dev/dev-forge) en su tag [`v2.8.1`](https://github.com/dmedina-dev/dev-forge/releases/tag/v2.8.1) (commit `330000f7b6c38297b4604bb13ae475ea7126707a`).

No editamos los archivos importados a mano. El estado de sincronización con upstream vive en [`.claude-plugin/customizations.json`](./.claude-plugin/customizations.json).

## Actualizar

Desde la raíz del marketplace, en sesión de Claude Code:

```
/forge-keeper:update-check
```

El comando lee `customizations.json`, consulta los releases del upstream y propone aplicar deltas preservando customizaciones locales (este README es la única customization registrada en `v2.8.1`).

## Documentación funcional

Cada comando se documenta a sí mismo en `commands/*.md`. La skill principal vive en `skills/forge-keeper/SKILL.md` con referencias detalladas en `skills/forge-keeper/references/`.
```

- [ ] **Step 2: Verificar que el archivo existe**

```bash
test -f plugins/forge-keeper/README.md && wc -l plugins/forge-keeper/README.md
```
Expected: un número > 10 líneas.

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-keeper/README.md
git commit -m "docs(forge-keeper): add marketplace-local README

Implementa custom-01 declarado en customizations.json: README propio
identificando el plugin como mirror vendorizado y describiendo el flujo
de actualización vía /forge-keeper:update-check.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Register in `marketplace.json`

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Leer el estado actual**

```bash
cat .claude-plugin/marketplace.json
```

Confirmar: el array `plugins` contiene `learn-basics` y `wet-flow`.

- [ ] **Step 2: Añadir la tercera entrada**

Reemplaza el contenido completo del archivo `.claude-plugin/marketplace.json` por:

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
    },
    {
      "name": "forge-keeper",
      "description": "Mantiene CLAUDE.md y docs sincronizados — vendored desde dmedina-dev/dev-forge",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/alexchica-wet/claude-marketplace.git",
        "path": "plugins/forge-keeper"
      },
      "version": "1.4.1"
    }
  ]
}
```

- [ ] **Step 3: Validar JSON**

```bash
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo "MARKETPLACE JSON OK"
```
Expected: `MARKETPLACE JSON OK`

- [ ] **Step 4: Confirmar que las tres entradas están presentes**

```bash
python3 -c "
import json
with open('.claude-plugin/marketplace.json') as f:
    data = json.load(f)
names = [p['name'] for p in data['plugins']]
print('plugins:', names)
assert names == ['learn-basics', 'wet-flow', 'forge-keeper'], f'orden inesperado: {names}'
print('OK')
"
```
Expected: `plugins: ['learn-basics', 'wet-flow', 'forge-keeper']` y `OK`.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat: register forge-keeper in marketplace catalog

Añade el plugin como tercera entrada del marketplace wet-tools. version
1.4.1 espeja la version interna del plugin.json upstream; el ref de
sincronización (tag v2.8.1 del repo) vive en customizations.json.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: End-to-end validation

**Files:** ninguno (solo verificaciones).

- [ ] **Step 1: Estructura final del plugin**

```bash
find plugins/forge-keeper -type f | sort
```

Expected (19 líneas):
```
plugins/forge-keeper/.claude-plugin/customizations.json
plugins/forge-keeper/.claude-plugin/plugin.json
plugins/forge-keeper/README.md
plugins/forge-keeper/commands/handoff.md
plugins/forge-keeper/commands/heal-plugin-cache.md
plugins/forge-keeper/commands/recall.md
plugins/forge-keeper/commands/segment-doc.md
plugins/forge-keeper/commands/status.md
plugins/forge-keeper/commands/sync.md
plugins/forge-keeper/commands/update-check.md
plugins/forge-keeper/hooks/hooks.json
plugins/forge-keeper/hooks/session-start-clear
plugins/forge-keeper/scripts/heal-plugin-cache.sh
plugins/forge-keeper/skills/forge-keeper/SKILL.md
plugins/forge-keeper/skills/forge-keeper/references/claudemd-guide.md
plugins/forge-keeper/skills/forge-keeper/references/exemplar-evaluation.md
plugins/forge-keeper/skills/forge-keeper/references/monorepo-patterns.md
plugins/forge-keeper/skills/forge-keeper/references/proposal-format.md
plugins/forge-keeper/skills/forge-keeper/references/update-check-guide.md
```

- [ ] **Step 2: JSON parseables**

```bash
for f in .claude-plugin/marketplace.json plugins/forge-keeper/.claude-plugin/plugin.json plugins/forge-keeper/.claude-plugin/customizations.json plugins/forge-keeper/hooks/hooks.json; do
  python3 -m json.tool "$f" > /dev/null && echo "OK $f" || echo "FAIL $f"
done
```
Expected: cuatro líneas `OK`, ninguna `FAIL`.

- [ ] **Step 3: Bits de ejecución preservados**

```bash
test -x plugins/forge-keeper/hooks/session-start-clear && test -x plugins/forge-keeper/scripts/heal-plugin-cache.sh && echo "EXEC BITS OK"
```
Expected: `EXEC BITS OK`. Si falla, ejecutar `chmod +x` y volver a verificar; si hace falta amendar el commit del vendor, hacerlo en un commit nuevo en lugar de amendar.

- [ ] **Step 4: Resumen de commits**

```bash
git log --oneline main..HEAD
```

Expected (orden cronológico inverso, 5 commits nuevos sobre el spec):
```
<sha> feat: register forge-keeper in marketplace catalog
<sha> docs(forge-keeper): add marketplace-local README
<sha> feat(forge-keeper): declare upstream origin in customizations.json
<sha> feat(forge-keeper): vendor copy from dev-forge@v2.8.1
<sha> chore: gitignore .upstream/ for update-check clones
<sha> docs(forge-keeper): add import design spec
```

(El commit del spec ya está hecho en una iteración anterior; los cinco siguientes son los de este plan.)

- [ ] **Step 5: Git status limpio**

```bash
git status
```
Expected: `nada para hacer commit, el árbol de trabajo está limpio`.

---

## Smoke tests manuales (usuario)

No están automatizados; los ejecuta el maintainer en una sesión interactiva de Claude Code después del merge a `main`:

1. `/plugin marketplace add ./` desde el repo → marketplace `wet-tools` aparece listado con tres plugins.
2. `/plugin install forge-keeper@wet-tools` → instalación sin errores.
3. `/forge-keeper:status` → reporte sin trazas de error.
4. `/forge-keeper:update-check` → escanea, encuentra `forge-keeper`, reporta `up to date` (o describe el delta si upstream ya publicó `v2.9.0+` entre el plan y la ejecución).
5. `/plugin install learn-basics@wet-tools` y `/plugin install wet-flow@wet-tools` siguen funcionando (no regresión).

Si cualquiera de estos pasos falla post-merge, abrir issue con el output y revisar el spec antes de tocar el código.
