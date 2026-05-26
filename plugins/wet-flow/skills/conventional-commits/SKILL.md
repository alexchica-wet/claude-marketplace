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
