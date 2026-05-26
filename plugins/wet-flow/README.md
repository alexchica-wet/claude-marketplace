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
