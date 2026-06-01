# Brief de contexto — plugin `setup-claude-config`

> **Propósito de este documento.** Capturar todo el contexto, decisiones y razones de la sesión en la que se endureció manualmente la configuración de seguridad de Claude Code (nivel user + repos). Sirve de **spec/contexto** para, en otra sesión, construir un plugin `setup-claude-config` (o nombre similar) que **guíe esta misma configuración mediante preguntas y la aplique/guarde automáticamente**.
>
> Generado el 2026-06-01. Usuario: alex (Wetaca). Plataforma: macOS, un solo usuario.
>
> **Alcance:** SOLO la parte de configuración de seguridad. Se omite deliberadamente la parte de git/commits/MR/marketplace de la sesión.

---

## 1. Qué debe hacer el plugin

Tras invocarse (p.ej. `/setup-claude-config`), el plugin debe:

1. **Auditar** el estado actual de la config de Claude Code en todos los niveles (managed, user, project, local) y de los repos bajo un directorio raíz dado.
2. **Guiar mediante preguntas** (estilo `AskUserQuestion`) las decisiones de endurecimiento, presentando trade-offs claros.
3. **Aplicar y guardar automáticamente** los cambios en el nivel correcto (user vs proyecto), validando el JSON tras cada edición.
4. Idealmente, **re-auditar** al final (incorporar el agente `security-auditor`, ver §7).

Filosofía rectora: **seguridad endurecida pero sin fricción innecesaria**; el usuario decide nivel por nivel; nada se aplica sin confirmación; toda medida explica su *por qué* y su *trade-off*.

---

## 2. Perfil y preferencias del usuario (claves para el diseño)

Estas preferencias condicionan qué debe ofrecer el plugin y con qué defaults:

- **Mano abierta con el flag.** Usa a veces `--dangerously-skip-permissions` y quiere que, con el flag, se le "abra la mano" en permisos. → **Rechaza** cualquier medida que mate el bypass de forma irrevocable (ver decisiones descartadas, §6).
- **Sandbox confina escritura, NO lectura.** Quiere poder leer para contexto; solo le importa no poder escribir fuera del proyecto sin su OK.
- **Hooks > instrucciones.** Para comportamientos automáticos ante eventos, prefiere hooks deterministas (los ejecuta el harness) sobre notas en `CLAUDE.md`/memoria (probabilísticas, las interpreta el LLM, consumen contexto, se pierden — de hecho un `/btw` no persistió).
- **`.env` es frecuente.** En Wetaca lee `.env` de servicios a menudo → no bloquear su lectura en duro; usar `ask`.
- **Confía en decisiones razonadas pero quiere control.** Va medida por medida, decide a qué nivel se aplica cada una. No quiere sobre-preguntas para cosas con default obvio, pero sí confirmar lo que tiene trade-off real o es difícil de revertir.

---

## 3. Catálogo de medidas aplicadas (las que SÍ se hicieron)

Organizado por nivel. Cada una: **qué**, **nivel**, **por qué**, **decisión concreta tomada**.

### 3.1 Nivel USER (`~/.claude/settings.json`) — protege TODOS los proyectos

#### M1. Hook anti-destructivo global (`check-destructive.py`)
- **Qué:** hook `PreToolUse` (matcher `Bash|Write|Edit|MultiEdit`) que **bloquea y exige confirmación** ante comandos destructivos, **incluso con `--dangerously-skip-permissions`** (los hooks PreToolUse son lo único que sobrevive al flag).
- **Por qué:** red de seguridad determinista contra borrados accidentales/inducidos; cubre los 11 proyectos y cualquiera nuevo desde un único sitio.
- **Ubicación:** `~/.claude/hooks/check-destructive.py`, referenciado en el settings como `python3 "$HOME/.claude/hooks/check-destructive.py"`.
- **Qué detecta (tras endurecerlo):** `rm/rmdir/unlink/shred` (incl. rutas absolutas tipo `/bin/rm`), `truncate`, `cp /dev/null`, `find -delete`, `find -exec rm`, `git rm`, `git clean -f`, `git reset --hard`, `git push --force/-f`, `dd if=`, e intérpretes inline destructivos (`node -e`/`python -c` con `rmSync`/`rmtree`/`unlink`).
- **Bypass legítimo:** prefijar el comando con `DESTRUCTIVE_APPROVED=1 ` (DEBE ser **prefijo**, no estar contenido en cualquier parte — si no, una injection `echo DESTRUCTIVE_APPROVED=1; rm -rf x` lo desarmaría).
- **También avisa (sin bloquear)** al escribir scripts `.sh/.bash/.zsh/.py` con contenido destructivo (incl. SQL `DROP/TRUNCATE/DELETE FROM`, `db.dropDatabase/dropCollection`).
- **Artefacto:** el script completo y endurecido vive hoy en `~/.claude/hooks/check-destructive.py` y duplicado en `wetaca.com/.claude/hooks/`. El plugin debería **empaquetar este script como asset** y declararlo vía `hooks/hooks.json`.

#### M2. `permissions.deny` (catastróficos + secretos de sistema)
- **Qué:** lista `deny` en el settings de user.
- **Por qué:** `deny` es la **única** semántica de permisos que se respeta incluso bajo `--dangerously-skip-permissions`. Es el suelo de último recurso.
- **Decisión sobre alcance:** `deny` duro SOLO para lo **catastrófico e irreversible a nivel sistema** (no para el `rm` cotidiano — eso lo gestiona el hook con confirmación, para no contradecir la "mano abierta").
- **Reglas aplicadas:**
  ```
  "deny": [
    "Bash(rm -rf /)", "Bash(rm -rf /*)", "Bash(rm -rf ~)", "Bash(rm -rf ~/)",
    "Bash(rm -rf ~/*)", "Bash(rm -rf $HOME)", "Bash(rm -rf $HOME/*)",
    "Bash(sudo rm *)", "Bash(mkfs *)", "Bash(dd if=* of=/dev/*)",
    "Read(/Users/<user>/.ssh/**)", "Read(/Users/<user>/.aws/**)",
    "Read(/Users/<user>/.config/gcloud/**)", "Read(/Users/<user>/.npmrc)",
    "Read(**/*.pem)", "Read(**/id_rsa)", "Read(**/id_ed25519)"
  ]
  ```
  > El plugin debe resolver la ruta del home del usuario dinámicamente (no hardcodear `/Users/<user>`).

#### M3. `permissions.ask` (`.env` y `git push`)
- **Qué:** `"ask": ["Read(**/.env)", "Read(**/.env.*)", "Bash(git push:*)"]`.
- **Por qué `.env` en `ask` y no `deny`:** el usuario lee `.env` a menudo; bloquearlo rompería su flujo. `ask` pregunta pero no bloquea.
- **Por qué `git push` en `ask`:** Claude NUNCA debe pushear por su cuenta; siempre preguntar. El usuario concede permiso de sesión vía "don't ask again this session" en el prompt. Solo push (NO `git commit` local — decisión explícita).
- **Aviso clave:** `ask` se **suprime** bajo `--dangerously-skip-permissions`. Es una protección de uso normal, no de autopilot.

#### M4. Quitar comodines de ejecución arbitraria del `allow`
- **Qué:** se eliminó `Bash(node -e ':*)` del `allow` (permitía ejecutar JS arbitrario sin prompt).
- **Regla general para el plugin:** detectar y advertir sobre `allow` peligrosos: `Bash(node -e *)`, `Bash(python -c *)`, `Bash(eval *)`, `Bash(npx *)`, `Bash(curl *)`, `Bash(* | sh)`, `Bash(bash *)`, `Bash(*)`.

#### M5. Hook `sync-env-example` (`PostToolUse`)
- **Qué:** hook `PostToolUse` (matcher `Write|Edit|MultiEdit`) que, al escribir/editar un `.env`, sincroniza los **nombres de variable** que falten al `.env.example` hermano.
- **Por qué un hook y no una instrucción:** determinismo. Una nota en CLAUDE.md es probabilística y se pierde; un hook lo ejecuta el harness siempre.
- **Reglas del comportamiento:** NUNCA copia valores (el `.env.example` se commitea → fuga de secretos); solo **añade** claves que falten (no borra ni reordena); crea el `.env.example` si no existe; es **idempotente** y **anti-bucle** (editar el propio `.env.example` no dispara nada).
- **Limitación honesta:** solo se dispara cuando es **Claude** quien edita el `.env`. Para ediciones manuales del humano, el complemento sería un **git pre-commit hook** (segunda capa opcional).
- **Artefacto:** `~/.claude/hooks/sync-env-example.py`. Ya se empaquetó en el plugin `tools@wetaca` del marketplace común como referencia de patrón (`hooks/hooks.json` + script con `${CLAUDE_PLUGIN_ROOT}`).

### 3.2 Nivel PROYECTO (por repo, en `.claude/settings.local.json`)

#### P1. Sandbox estricto
- **Qué:** `{"sandbox": {"enabled": true, "autoAllowBashIfSandboxed": false}}` en cada repo.
- **Por qué:** confina la **escritura** al directorio del proyecto (lo que el usuario pidió). Modo "estricto" elegido = cada bash pide confirmación aunque esté confinado.
- **Matiz crítico que el plugin DEBE explicar:** el sandbox por defecto confina la escritura pero **NO la lectura**. Para confinar lectura hay que añadir `denyRead` explícito → el usuario lo **rechazó** (quiere leer para contexto).
- **`allowUnsandboxedCommands`:** dejar el default (true) → Claude puede pedir salir del sandbox (con tu OK, o con el flag). Ponerlo `false` = "búnker" (ni con flag se sale) → NO elegido.

#### P2. Convención `.gitignore` para configs de Claude
- **Regla:** `settings.json` → **commiteable** (config de equipo); `settings.local.json` → **gitignoreado** (config personal). Es la convención correcta (la del repo de referencia `wetaca.com`).
- **Anti-patrón detectado y corregido:** un repo gitignoreaba `settings.json` (al revés) — síntoma de tener config personal en el archivo de equipo. El plugin debería detectar y avisar de esta inversión.
- **Nota:** el usuario tiene un gitignore **global** (`~/.config/git/ignore`) con `**/.claude/settings.local.json`, así que para él ya está cubierto en todos los repos; para el **equipo** conviene la línea en cada `.gitignore` de repo.

---

## 4. Modos de sandbox (las 3 variantes ofrecidas)

El plugin debe ofrecer estos 3 modos (el usuario eligió **Estricto**):

| Modo | Config | Comportamiento |
|---|---|---|
| **Cómodo** | `enabled:true, autoAllowBashIfSandboxed:true, allowUnsandboxedCommands:true` | El bash confinado no molesta; pregunta solo si necesita salir del sandbox |
| **Estricto** (elegido) | `enabled:true, autoAllowBashIfSandboxed:false` | Pregunta por cada bash aunque esté confinado. Más control, más prompts |
| **Búnker** | `enabled:true, autoAllowBashIfSandboxed:true, allowUnsandboxedCommands:false` | Ni con el flag se puede salir del sandbox. Máxima contención; comandos que necesiten red/escribir fuera fallan |

---

## 5. Flujo de preguntas (replicar en el plugin)

Las preguntas reales que se hicieron, en orden lógico. El plugin debería estructurar su interrogatorio así:

1. **Punto de partida / qué aplicar primero** (multi-opción): hook anti-destructivo global · sandbox donde falta · deny global · "revisar catálogo primero".
2. **Alcance de lectura del sandbox:** confinar también lectura (`denyRead`) · solo escritura *(elegido)* · solo secretos.
3. **Modo de sandbox:** Cómodo · Estricto *(elegido)* · Búnker.
4. **Homogeneizar sandboxes existentes** al modo elegido: sí *(elegido)* · solo los nuevos.
5. **`git push`/commit:** solo push *(elegido)* · también commit.
6. **(Avanzado, normalmente NO)** capa `managed` irrevocable / `disableBypassPermissionsMode` — ver §6.
7. **Higiene gitignore:** aplicar convención `settings.json` commiteable / `settings.local.json` ignorado.

Patrón de cada pregunta: opción **recomendada primero**, descripción con el **trade-off** explícito, y para temas con artefacto visual usar previews (modos de sandbox).

---

## 6. Decisiones DESCARTADAS (y por qué) — el plugin debe marcarlas como opt-in avanzado, no default

| Medida | Qué era | Por qué se descartó |
|---|---|---|
| **`disableBypassPermissionsMode: true`** (a nivel user o managed) | Mata `--dangerously-skip-permissions` por completo | Contradice la "mano abierta con el flag" que el usuario quiere |
| **Capa `managed` irrevocable** (`/Library/Application Support/ClaudeCode/managed-settings.json`, root-owned) | Suelo de seguridad que ni el agente ni una injection pueden reescribir; sobrevive al flag | El usuario priorizó autonomía sin fricción; requiere `sudo`; acepta el riesgo de que el agente pueda auto-editar sus límites en autopilot |
| **`denyRead` en sandbox** | Confinar también la lectura entre proyectos/secretos | Quiere poder leer para contexto; solo confina escritura |
| **`deny` de exfiltración** (`curl`/`wget`/`nc`) | Bloquear salida de datos | Demasiada fricción con curl legítimo; omitido (riesgo residual aceptado) |
| **`.env` → `deny`** | Bloqueo duro de lectura de `.env` | Se quedó en `ask`; lee `.env` a menudo |
| **Fijar/forkear marketplaces de terceros** | Pinning de `dev-forge`/`nemonemo` a commit | Omitido por ahora (riesgo de supply-chain aceptado) |

> **Riesgo residual asumido** (documentar en el plugin como "lo que NO cubre esta config"): bajo `--dangerously-skip-permissions` solo sobreviven `deny` + hooks; sin capa managed el agente puede reescribir sus propios límites; la exfiltración vía `curl` no está denegada.

---

## 7. Agente `security-auditor` (incorporar al plugin)

Se creó un subagente auditor (`~/.claude/agents/security-auditor.md`, modelo opus, color red, tools read-only `Read/Grep/Glob/Bash`) que audita críticamente la config y los repos buscando agujeros, pensando como atacante, con foco en uso autónomo/autopilot. El plugin debería **ejecutarlo al final** del setup para validar y reportar riesgos residuales.

**Qué audita (checklist reutilizable):** capas de settings y precedencia (`managed > local > project > user`, `deny > ask > allow`); `allow` over-broad; cobertura de `deny`/`ask`; modos/skips peligrosos; robustez de los hooks (¿el regex es evadible? ¿el script es escribible/poisonable?); sandbox (allowUnsandboxed, autoAllow, denyRead, allowedDomains); MCP (`enableAllProjectMcpServers`, tokens embebidos); plugins/marketplaces de terceros; **secretos hardcodeados / `.env` o `.mcp.json` trackeados**; permisos de fichero (600 en settings/hooks); `additionalDirectories`.

**Salida:** resumen ejecutivo + hallazgos por severidad (CRÍTICO→BAJO) con ubicación `file:line`, escenario de explotación concreto, y recomendación con el nivel donde aplicarla.

**Hallazgos reales de esta sesión (ejemplos de lo que el auditor detecta):**
- **CRÍTICO:** credencial hardcodeada en un `.mcp.json` trackeado → mover a `${VAR}` + `.env`. (El plugin debería escanear `.mcp.json`/configs en busca de secretos.)
- **CRÍTICO:** regex del hook anti-destructivo evadible (rutas absolutas, intérpretes, redirección) y bypass por substring → de ahí salió el endurecimiento de M1.
- **MEDIO:** `allowUnsandboxedCommands:true` anulando un sandbox estricto.
- **MEDIO:** matcher de hook incompleto (faltaba `MultiEdit`).
- **BAJO:** hooks en `644` (auto-modificables por el propio agente).

---

## 8. Artefactos a empaquetar en el plugin

1. **`check-destructive.py`** (versión endurecida) — copia actual en `~/.claude/hooks/check-destructive.py`.
2. **`sync-env-example.py`** — copia actual en `~/.claude/hooks/sync-env-example.py` (y ya en `tools@wetaca`).
3. **`security-auditor.md`** — definición del subagente, en `~/.claude/agents/security-auditor.md`.
4. **Plantillas de settings** — bloques JSON de `deny`/`ask`/`hooks`/`sandbox` (ver §3), con el home resuelto dinámicamente.

Patrón de empaquetado (según convenciones del marketplace Wetaca): hooks en `hooks/hooks.json` + script, referenciados con `${CLAUDE_PLUGIN_ROOT}`; el estado/persistencia (si lo hubiera) en `~/.config/wetaca/<plugin>/`.

---

## 9. Reglas de oro para la implementación del plugin

- **Siempre leer antes de escribir** un settings.json y **mergear** (nunca reemplazar arrays como `allow`/`deny`).
- **Validar el JSON con `jq -e`** tras cada edición; un settings.json roto desactiva en silencio TODA la config de ese archivo.
- **Probar los hooks** tras escribirlos (pipe-test con un payload sintético) y avisar de que se activan al abrir `/hooks` o reiniciar (el watcher solo recoge cambios en caliente si el dir ya se vigilaba).
- **Nivel correcto:** medidas personales → user / `settings.local.json`; medidas de equipo → `settings.json` (commiteable).
- **No aplicar nada sin confirmación**; presentar trade-off; respetar las decisiones descartadas de §6 como defaults "no".
- El hook ejecuta el `.py` desde disco en cada llamada → editar el script surte efecto inmediato; registrar/de-registrar el hook en settings sí requiere recarga (`/hooks` o reinicio).
