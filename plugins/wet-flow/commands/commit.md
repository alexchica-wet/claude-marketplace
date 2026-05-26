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
