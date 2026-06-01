# Modos de sandbox

El sandbox confina la **escritura** al directorio del proyecto; por defecto NO confina la lectura.
Los 3 modos se aplican al `.claude/settings.local.json` del repo. Recomendado: **Estricto**.

## Cómodo
El bash confinado no molesta; solo pregunta si necesita salir del sandbox.
```json
{ "sandbox": { "enabled": true, "autoAllowBashIfSandboxed": true, "allowUnsandboxedCommands": true } }
```

## Estricto (recomendado)
Pregunta por cada bash aunque esté confinado. Más control, más prompts.
```json
{ "sandbox": { "enabled": true, "autoAllowBashIfSandboxed": false } }
```

## Búnker
Ni con `--dangerously-skip-permissions` se sale del sandbox. Máxima contención; comandos que
necesiten red o escribir fuera fallan.
```json
{ "sandbox": { "enabled": true, "autoAllowBashIfSandboxed": true, "allowUnsandboxedCommands": false } }
```

## R1 — alcance de lectura
- **Solo escritura (recom.):** no añadir `denyRead`. Se puede leer para contexto.
- **También lectura:** añadir `denyRead` con las rutas a confinar (decisión avanzada).
- **Solo secretos:** `denyRead` limitado a rutas de secretos.

Usar estos bloques como **previews** en el `AskUserQuestion` del modo de sandbox (R2).
