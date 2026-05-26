# learn-basics

Plugin pedagógico del marketplace `wet-tools`. Contiene **un ejemplo mínimo de cada tipo de componente** que soporta un plugin de Claude Code. El objetivo no es ser útil — es enseñar la estructura.

## Componentes

### Comando: `/saluda [nombre]`
- **Archivo**: `commands/saluda.md`
- **Qué hace**: saluda al nombre dado, o a "mundo".
- **Qué enseña**: cómo se define un slash command y cómo se reciben argumentos vía `$ARGUMENTS`.

### Skill: `proyecto-actual`
- **Archivo**: `skills/proyecto-actual/SKILL.md`
- **Qué hace**: resume el proyecto actual leyendo README o listando archivos.
- **Qué enseña**: cómo se auto-activa una skill mediante su `description` en el frontmatter.

### Agent: `eco`
- **Archivo**: `agents/eco.md`
- **Qué hace**: resume cualquier texto en una sola frase.
- **Qué enseña**: cómo se define un subagente con su propio system prompt y lista de tools.

### Hook: `SessionStart`
- **Archivos**: `hooks/hooks.json` + `hooks/session-start.sh`
- **Qué hace**: al iniciar sesión muestra rama, último commit y nº de cambios sin commitear.
- **Qué enseña**: cómo conectar un evento del SDK a un script bash via `${CLAUDE_PLUGIN_ROOT}`.

## Instalación

```
/plugin marketplace add alexchica-wet/claude-marketplace
/plugin install learn-basics@wet-tools
```
