# wet-tools

Marketplace personal de plugins para Claude Code.

## Instalación

En una sesión de Claude Code:

```
/plugin marketplace add alexchica-wet/claude-marketplace
/plugin install <nombre-plugin>@wet-tools
```

## Plugins disponibles

| Plugin | Descripción |
|---|---|
| [`learn-basics`](plugins/learn-basics/README.md) | Plugin pedagógico — un ejemplo mínimo de cada tipo de componente. |
| [`wet-flow`](plugins/wet-flow/README.md) | Flujo git/commit/PR — commit asistido, revisor de diff, hook anti-force-push. |

## Estructura

- `.claude-plugin/marketplace.json` — catálogo del marketplace.
- `plugins/<nombre>/` — cada plugin, autocontenido.
- `docs/superpowers/specs/` — diseños aprobados.
- `docs/superpowers/plans/` — planes de implementación.

## Licencia

MIT.
