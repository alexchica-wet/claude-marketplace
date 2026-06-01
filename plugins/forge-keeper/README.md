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
