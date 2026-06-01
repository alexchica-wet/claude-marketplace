# setup-config

Instalador guiado one-shot del endurecimiento de seguridad de Claude Code. Invócalo con
`/setup-config`.

## Qué hace

1. **Scope:** eliges (multi-select) dónde aplicar — **User**, el **repo actual**, y/o **otros repos**
   (escaneando un directorio raíz).
2. **Audita** el estado actual de la config de los scopes elegidos.
3. **Pregunta medida a medida** (recomendación + trade-off): hook anti-destructivo global, `deny` de
   catastróficos + secretos, `ask` de `.env`/`git push`, limpieza de `allow` peligrosos, y para repos
   el modo de sandbox y la higiene de `.gitignore`.
4. **Aplica** en TU config (`~/.claude/` y los `settings.local.json` de los repos), validando el JSON.
   El plugin es un instalador: la protección persiste aunque lo desactives.
5. **Audita el resultado** con el subagente `security-auditor` y te ofrece corregir o asumir cada
   riesgo.

## Qué NO cubre (riesgo residual)

Bajo `--dangerously-skip-permissions` solo sobreviven `deny` + hooks. Sin capa `managed` (opt-in
avanzado), el agente puede reescribir sus propios límites en autopilot. La exfiltración vía
`curl`/`wget`/`nc` no está denegada por defecto.

## Artefactos que instala

- `~/.claude/hooks/check-destructive.py` (chmod 600) — hook anti-destructivo, registrado en tu
  `settings.json` de user.
- `~/.claude/agents/security-auditor.md` — para poder re-auditar cuando quieras.

Tras instalar/registrar el hook, abre `/hooks` o reinicia para que Claude Code lo recoja.
