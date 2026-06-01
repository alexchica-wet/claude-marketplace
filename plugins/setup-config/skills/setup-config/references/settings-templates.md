# Plantillas de settings

> Bloques JSON que el orquestador mergea (nunca reemplaza) en el settings destino.
> `<HOME>` se sustituye por el home real del usuario (`echo $HOME`), nunca hardcodear `/Users/<user>`.

## M2 — `deny` (catastróficos a nivel sistema + lectura de secretos)

```json
"deny": [
  "Bash(rm -rf /)", "Bash(rm -rf /*)", "Bash(rm -rf ~)", "Bash(rm -rf ~/)",
  "Bash(rm -rf ~/*)", "Bash(rm -rf $HOME)", "Bash(rm -rf $HOME/*)",
  "Bash(sudo rm *)", "Bash(mkfs *)", "Bash(dd if=* of=/dev/*)",
  "Read(<HOME>/.ssh/**)", "Read(<HOME>/.aws/**)",
  "Read(<HOME>/.config/gcloud/**)", "Read(<HOME>/.npmrc)",
  "Read(**/*.pem)", "Read(**/id_rsa)", "Read(**/id_ed25519)"
]
```

## M3 — `ask` (.env y git push)

```json
"ask": ["Read(**/.env)", "Read(**/.env.*)", "Bash(git push:*)"]
```

Si el usuario elige también pedir confirmación para commits (variante push **y** commit), añadir:

```json
"Bash(git commit:*)"
```

## M1 — registro del hook anti-destructivo (settings de user)

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash|Write|Edit|MultiEdit",
      "hooks": [
        { "type": "command", "command": "python3 \"$HOME/.claude/hooks/check-destructive.py\"" }
      ]
    }
  ]
}
```

## M4 — patrones `allow` peligrosos a detectar y proponer quitar

Comodines de ejecución arbitraria que NO deberían estar en `allow`:

```
Bash(node -e *)   Bash(python -c *)   Bash(eval *)   Bash(npx *)
Bash(curl *)      Bash(* | sh)        Bash(bash *)   Bash(*)
```

## R4 — línea de `.gitignore` (convención)

```
.claude/settings.local.json
```
