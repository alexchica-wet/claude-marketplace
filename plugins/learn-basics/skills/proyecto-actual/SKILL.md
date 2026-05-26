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
