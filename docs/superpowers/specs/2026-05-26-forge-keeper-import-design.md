# Importación de forge-keeper a wet-tools — Diseño

**Fecha**: 2026-05-26
**Autor**: Alex Chica (`alexchica@wetaca.com`)
**Repo**: https://github.com/alexchica-wet/claude-marketplace
**Rama**: `feat/import-forge-keeper`
**Estado**: aprobado para implementación
**Upstream**: `dmedina-dev/dev-forge` @ `v2.8.1` (commit `10ea91b112e52dd2ffcfe807beec7c7baffc72a9`)

---

## Objetivo

Incorporar el plugin `forge-keeper` del marketplace de terceros `dmedina-dev/dev-forge` al marketplace `wet-tools`, **vendorizado** (copia local en `plugins/forge-keeper/`) y con **suscripción a actualizaciones** del upstream usando el propio mecanismo `/forge-keeper:update-check` que ese plugin trae incorporado.

## Por qué este enfoque

- **Vendoring** (copia local) en lugar de instalación remota directa: permite versionar, customizar y desacoplar nuestro release cycle del de upstream.
- **El propio plugin trae el mecanismo de subscripción**: `forge-keeper` incluye un comando `/update-check` que escanea `plugins/*/.claude-plugin/customizations.json`, consulta upstream vía `gh api` (con fallback a `git ls-remote`) y propone aplicar diffs preservando customizations locales. Al copiarlo, nos suscribimos por bootstrap.
- **Patrón dogfooding**: es exactamente el patrón que `dev-forge` aplica a los plugins que incorpora desde otros repos (ej. `forge-superpowers` ← `obra/superpowers`).

## Alcance

1. Crear `plugins/forge-keeper/` con copia 1:1 del subdirectorio upstream `plugins/forge-keeper/` a `v2.8.1`.
2. Añadir `plugins/forge-keeper/.claude-plugin/customizations.json` registrando origen y customizations.
3. Añadir `plugins/forge-keeper/README.md` (única customization en esta primera importación, tipo `added`).
4. Registrar el plugin en `.claude-plugin/marketplace.json`.
5. Añadir `.upstream/` al `.gitignore` raíz (directorio que el comando `/update-check` usará para clones persistentes en ejecuciones futuras).

**Fuera de alcance**: customizar el comportamiento del plugin, instalar plugins hermanos del upstream (`forge-superpowers`, `forge-deep-review`, etc.), publicar otros plugins externos.

---

## Sección 1 — Estructura final del plugin

```
plugins/forge-keeper/
├── .claude-plugin/
│   ├── plugin.json                      (upstream as-is)
│   └── customizations.json              ← NUEVO (meta, no existe en upstream)
├── commands/
│   ├── handoff.md                       (upstream as-is)
│   ├── heal-plugin-cache.md             (upstream as-is)
│   ├── recall.md                        (upstream as-is)
│   ├── segment-doc.md                   (upstream as-is)
│   ├── status.md                        (upstream as-is)
│   ├── sync.md                          (upstream as-is)
│   └── update-check.md                  (upstream as-is) ← motor de la suscripción
├── hooks/
│   ├── hooks.json                       (upstream as-is)
│   └── session-start-clear              (upstream as-is)
├── scripts/
│   └── heal-plugin-cache.sh             (upstream as-is)
├── skills/forge-keeper/
│   ├── SKILL.md                         (upstream as-is)
│   └── references/
│       ├── claudemd-guide.md            (upstream as-is)
│       ├── exemplar-evaluation.md       (upstream as-is)
│       ├── monorepo-patterns.md         (upstream as-is)
│       ├── proposal-format.md           (upstream as-is)
│       └── update-check-guide.md        (upstream as-is)
└── README.md                            ← NUEVO (customization tipo "added")
```

Fuente de la copia: árbol `plugins/forge-keeper/` del tag `v2.8.1` del upstream. Forma de obtención (cualquier de las dos sirve, elegir la más limpia en el plan de implementación):

- `git archive` desde el upstream a un directorio temporal y copiado al destino.
- Clon poco profundo a `/tmp` y `cp -R`.

## Sección 2 — `customizations.json`

Vivirá en `plugins/forge-keeper/.claude-plugin/customizations.json`. Schema: el mismo que documenta `dev-forge` en `docs/customizations-pattern.md`. Contenido inicial:

```json
{
  "origin": {
    "type": "github",
    "repo": "dmedina-dev/dev-forge",
    "path": "plugins/forge-keeper",
    "ref": "v2.8.1",
    "commit": "10ea91b112e52dd2ffcfe807beec7c7baffc72a9",
    "fetched_at": "2026-05-26",
    "check_url": "https://github.com/dmedina-dev/dev-forge/releases"
  },
  "upstream_status": {
    "last_checked": "2026-05-26",
    "latest_ref": "v2.8.1",
    "latest_commit": "10ea91b112e52dd2ffcfe807beec7c7baffc72a9",
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

### Por qué `ref = v2.8.1` y no `v1.4.1`

El campo `version` interno del `plugin.json` de upstream dice `1.4.1` — es la versión semántica **del plugin**. Pero los tags `v*.*.*` del repo `dev-forge` son del **marketplace entero**; el último es `v2.8.1`. `/update-check` consulta `gh api repos/owner/repo/releases/latest`, así que tiene que comparar contra el tag del repo, no contra el `version` interno. Pin = `v2.8.1`.

Para detectar cambios reales en el subdirectorio `plugins/forge-keeper/` (y no falsos positivos cuando upstream tagee por cambios en otros plugins), `/update-check` cuenta con el modo subpath-aware documentado en `references/update-check-guide.md § Subpath repos`:

```bash
gh api "repos/dmedina-dev/dev-forge/commits?path=plugins/forge-keeper&sha=v2.9.0&per_page=1"
```

## Sección 3 — Entrada en `marketplace.json`

Se añade un tercer objeto al array `plugins`:

```json
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
```

### Decisiones de versionado

- `version` en `marketplace.json` = `1.4.1` (espeja la version interna del `plugin.json` upstream). Si más adelante upstream sube a `1.5.0` y aplicamos el update, ambos campos suben a `1.5.0`.
- `source.url` apunta a **nuestro** repo. El consumidor del marketplace `wet-tools` instala desde nuestro fork vendorizado, no directamente desde dev-forge.
- No tocamos la `metadata.version` del marketplace en este PR (cambio de contenido pero no de schema). La subiremos cuando el spec lo cubra.

## Sección 4 — README local

`plugins/forge-keeper/README.md` es la única customization añadida en esta importación. Contenido mínimo a redactar en la fase de plan:

- Identifica el plugin como **mirror vendorizado** del upstream.
- Enlaza al repo upstream y al tag al que estamos anclados (`v2.8.1`).
- Apunta a `.claude-plugin/customizations.json` como fuente de verdad del estado de sync.
- Resume cómo actualizarlo: ejecutar `/forge-keeper:update-check` desde la raíz de este repo.
- No duplica documentación funcional del plugin (los comandos `/sync`, `/status`, etc. están documentados en su propio SKILL.md). Si necesitamos profundizar, enlazamos al upstream.

## Sección 5 — Flujo de suscripción

```
┌──────────────────────────────────────────────────────────────────┐
│ Maintainer abre sesión de Claude Code en claude-marketplace/     │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                              ▼
              /forge-keeper:update-check
                              │
                              ▼
   ┌────────────────────────────────────────────────────────┐
   │ Escanea plugins/*/.claude-plugin/customizations.json   │
   │ Encuentra forge-keeper → origin = dev-forge @ v2.8.1   │
   └─────────────────────────────┬──────────────────────────┘
                                 │
                                 ▼
        ┌──────────────────────────────────────────┐
        │ gh api releases/latest (o git ls-remote) │
        │ → último tag conocido                    │
        └─────────────────────────────┬────────────┘
                                      │
                          ┌───────────┴────────────┐
                          ▼                        ▼
              latest == v2.8.1            latest > v2.8.1
              "up to date"                  │
                                            ▼
                   ┌────────────────────────────────────────┐
                   │ Drill subpath: ¿plugins/forge-keeper   │
                   │ cambió desde v2.8.1?                   │
                   └─────────────┬──────────────────────────┘
                                 │
                          ┌──────┴────────┐
                          ▼               ▼
                       no              sí
                  "ningún cambio       Mostrar diff + conflictos
                   en este plugin"     con customizations[]
                                            │
                                            ▼
                                  Maintainer aprueba
                                            │
                                            ▼
                                  Clonar a .upstream/ (gitignored),
                                  copiar archivos, preservar README,
                                  actualizar customizations.json,
                                  bumpear version en marketplace.json,
                                  commit + push
                                            │
                                            ▼
                                  Consumidores reciben /plugin update
```

Notas:

- `.upstream/` queda ignorado en `.gitignore` desde este mismo PR; el primer `update-check` lo creará y reutilizará en sucesivas ejecuciones.
- El propio README local (`custom-01`) está marcado como `added` ⇒ no entra en conflicto con cambios upstream (solo lo haría si upstream añadiera su propio `README.md` con el mismo path).

---

## Riesgos y notas operativas

| Riesgo | Mitigación |
|---|---|
| `gh` CLI no instalado en local (verificado: no está disponible en este Mac) | `update-check` documenta fallback `git ls-remote`. Se degrada solo. |
| Upstream renombra o reestructura forge-keeper | Antes de aplicar cualquier update, leer `CHANGELOG.md` del upstream. Si hay renames, abortar y replantear el spec. |
| Conflictos entre nuestro README y futuros archivos upstream con mismo path | `custom-01` lo registra como `added`. El comando lo señalará como conflicto y el maintainer decide. |
| Drift silencioso (alguien edita archivos del plugin sin pasar por update-check) | Convención: nunca editar a mano `plugins/forge-keeper/` salvo el README. Si hace falta customizar, añadir entrada nueva a `customizations[]`. |
| Upstream introduce dependencias a otros plugins suyos (ej. `forge-superpowers`) | Probar `/forge-keeper:status` después de la importación. Si requiere plugins ausentes, decidir caso por caso: importarlos o stubbearlos. |
| Tag `v2.8.1` queda obsoleto antes incluso del primer release de wet-tools | Aceptable: el flujo de subscripción está pensado precisamente para esto. Primera ejecución de `/update-check` post-merge ya lo detectará. |

---

## Plan de pruebas

Cada hito a verificar antes de mergear:

1. **Lint estructural**
   - `cat .claude-plugin/marketplace.json | python3 -m json.tool` parsea.
   - `cat plugins/forge-keeper/.claude-plugin/plugin.json | python3 -m json.tool` parsea.
   - `cat plugins/forge-keeper/.claude-plugin/customizations.json | python3 -m json.tool` parsea.
   - Estructura del directorio coincide con la Sección 1 (verificable con `find plugins/forge-keeper`).

2. **Hashes de fidelidad**
   - Comparar SHA256 de cada archivo no nuevo contra el blob upstream en `v2.8.1` (script de un solo uso). Solo el README y el customizations.json son nuevos.

3. **Instalación local**
   - `/plugin marketplace add ./` desde el repo.
   - `/plugin install forge-keeper@wet-tools` en una sesión de prueba en otro directorio.
   - Sin errores de carga al iniciar la sesión.

4. **Comandos clave del plugin importado**
   - `/forge-keeper:status` corre y produce un reporte sin trazas de error.
   - `/forge-keeper:update-check` corre, encuentra `forge-keeper` en el escaneo, consulta upstream y reporta `up to date` (porque acabamos de fijar `v2.8.1` y aún es el último). Si upstream ya hubiera publicado `v2.9.0+` entre el spec y el merge, el output describiría el delta — esperado.

5. **No regresión sobre los plugins existentes**
   - `/plugin install learn-basics@wet-tools` y `/plugin install wet-flow@wet-tools` siguen funcionando.
   - `marketplace.json` lista los tres plugins.

---

## Trabajo posterior (no en este PR)

- Documentar en `README.md` raíz del marketplace que `forge-keeper` es un mirror.
- Decidir si publicar otros plugins de dev-forge (`forge-superpowers`, `forge-deep-review`) — caso por caso, cada uno con su propio spec.
- Considerar añadir un `.github/workflows/upstream-check.yml` que ejecute `git ls-remote` semanalmente y abra issue si detecta cambios. Fuera de alcance ahora.
