---
description: Endurece la config de seguridad de Claude Code (user y/o repos) mediante preguntas guiadas, y la audita al final.
---

Vas a guiar al usuario para endurecer su configuración de seguridad de Claude Code.

Usa la skill `setup-config` y sigue su procedimiento al pie de la letra: empieza SIEMPRE por la
selección de scope (Paso 0), audita el estado actual, pregunta medida a medida, aplica respetando las
golden-rules, y cierra con la auditoría del subagente `security-auditor` y la ronda de corrección.

No apliques ninguna medida sin confirmación explícita del usuario.
