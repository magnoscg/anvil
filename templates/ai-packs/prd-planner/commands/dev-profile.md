---
description: Perfila la feature actual o ficheros especificos con xctrace
---

## Determinar scope

$ARGUMENTS

- Si se indica un target o paths (ej: `/dev-profile MiApp`), usa esos directamente.
- Si no se indica nada, busca la feature activa en `plan/INDEX.md` (status `in-progress` o `completed` no archivada).
  - Del PRD, extrae el nombre de la feature.
  - De los PRPs, extrae los ficheros creados/modificados (busca `files_created` y `files_modified` en los envelopes, o lee las tareas `[x]`).
- Si no hay feature activa ni argumentos, pregunta que quiere perfilar.

## Preparar contexto

1. Lee `.dev/skill-registry.md` (si existe).
2. Recopila los paths de ficheros Swift de la feature.
3. Detecta simuladores/dispositivos disponibles:
   ```
   xcrun simctl list devices booted
   xctrace list devices
   ```
4. Si no hay dispositivo/simulador corriendo, pregunta al usuario que lance la app.

## Lanzar DEV-PROFILER

```
Agent(
  subagent_type: "DEV-PROFILER",
  prompt: "Perfila la feature.
           PRD path: plan/<feature>/PRD.md
           Ficheros de la feature: <lista de paths>
           skill-registry path: .dev/skill-registry.md
           Target/App: <nombre app o PID>
           Dispositivo: <simulador o device detectado>
           CWD: <directorio actual>

           CONTENIDO DEL PRD:
           <contenido del PRD>

           CONTENIDO SKILL-REGISTRY:
           <contenido de .dev/skill-registry.md>"
)
```

## Presentar resultados

Muestra el informe del profiler tal cual lo devuelve.

- **Si hay criticos**: pregunta si quiere optimizar (volveria a un ciclo build).
- **Si hay warnings**: muestra y pregunta si quiere actuar o aceptar.
- **Si skip**: muestra la justificacion.
- **Si error** (xctrace fallo, app no corriendo): muestra el error con instrucciones para resolverlo.
