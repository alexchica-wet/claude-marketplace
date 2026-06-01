# Reglas de oro de aplicación

El orquestador SIEMPRE sigue estas invariantes al escribir cualquier settings:

1. **Read-before-write + merge, nunca reemplazar.** Leer el settings destino; mergear dentro de los
   arrays `allow`/`deny`/`ask` sin pisar lo existente; deduplicar entradas. Nunca sobrescribir el
   array entero.
2. **Validar con `jq -e` tras cada escritura.** Un JSON roto desactiva en silencio TODA la config de
   ese fichero. Si la validación falla: restaurar el contenido previo y avisar; no continuar.
3. **Nivel correcto.** Medidas personales → `~/.claude/settings.json` (user) o
   `.claude/settings.local.json` (repo). Nunca escribir config personal en el `settings.json` de
   equipo (commiteable).
4. **`$HOME` dinámico.** Resolver el home real (`echo $HOME`); nunca hardcodear `/Users/<user>`.
5. **Copia de assets idempotente.**
   - `check-destructive.py` → `~/.claude/hooks/check-destructive.py`, luego `chmod 600`.
   - `security-auditor.md` → `~/.claude/agents/security-auditor.md`.
   - Si el destino ya existe y difiere, avisar antes de sobrescribir.
6. **Aviso de recarga de hooks.** Registrar/des-registrar un hook en settings requiere `/hooks` o
   reiniciar; el script en disco surte efecto inmediato. Avisar al terminar.
7. **Nada sin confirmación.** Cada medida se confirma con `AskUserQuestion`. Las descartadas del
   catálogo mantienen default No.
