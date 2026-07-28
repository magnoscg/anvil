---
description: Build YOLO — ejecuta /dev-build --auto para todas las features pendientes del INDEX secuencialmente
---

Build YOLO: ejecutar todas las features pendientes.

Este comando ejecuta `/dev-build --auto` para cada feature pendiente del INDEX, una tras otra. Cada feature se ejecuta en su propia branch gitflow y se mergea a develop al completar.

**IMPORTANTE**: Este comando NO implementa directamente. Para cada feature:
1. Invoca `Skill(skill: "dev-plan", args: "--auto <slug>")` si no tiene PRPs
2. Invoca `Skill(skill: "dev-build", args: "--auto <slug>")` para ejecutar el workflow completo
NUNCA escribas codigo, lances DEV-IMPLEMENTER, ni hagas git merge directamente. Los comandos invocados via Skill se encargan de todo (branch, PRPs, implementacion, verificacion, tests, correccion, commit, retro, profiler, archivado, merge, RAG).

## Paso 1 — Leer INDEX

1. Lee `plan/INDEX.md`.
2. Parsea la tabla de features. Identifica las que tienen status `approved` o `in-progress`.
3. Ordena por fecha (mas antigua primero).
4. Si no hay features pendientes, para con mensaje: "No hay features pendientes en el INDEX."

Muestra las features que va a procesar:

```
Build YOLO — Features pendientes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. <feature-1> (approved, YYYY-MM-DD)
2. <feature-2> (in-progress, YYYY-MM-DD)

Ejecutando todas secuencialmente...
```

## Paso 2 — Loop por features

Para cada feature en orden:

1. Verificar que tiene PRPs en `plan/<feature-slug>/prp-*.md`. Si no tiene:
   - Invocar el comando via Skill tool:
     ```
     Skill(skill: "dev-plan", args: "--auto <slug>")
     ```
     Esto carga las instrucciones completas de `/dev-plan` que lanza DEV-ARCHITECT + DEV-TASK-PLANNER.
   - Si la generacion de PRPs falla, skip con mensaje: "Feature <slug>: fallo generando PRPs. Skipping."
2. Invocar el comando via Skill tool:
   ```
   Skill(skill: "dev-build", args: "--auto <slug>")
   ```
   Esto ejecuta el workflow completo: branch, fases, verificacion, tests, correccion, commit, retro, profiler, archivado, merge a develop, RAG.
   NO reimplementes estos pasos — el comando se encarga de todo.
3. Si la feature **completa exitosamente**: continuar con la siguiente.
4. Si la feature **falla irrecuperablemente**:
   - Parar todo el loop.
   - Reportar que features se completaron y cual fallo.
   - La branch parcial queda sin merge.
   - No continuar con mas features.

## Paso 3 — Resumen global

Al final (exito o fallo), mostrar:

```
Build YOLO — Resumen
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Feature | Status | Fases | Hallazgos | Profiler | Archivado |
|---------|--------|-------|-----------|----------|-----------|
| <feat-1> | archived | 3/3 | 5 corregidos | 0 criticos | plan/_archive/<feat-1>/ |
| <feat-2> | archived | 2/2 | 1 corregido | 1 critico (fixed) | plan/_archive/<feat-2>/ |
| <feat-3> | FAILED (fase 2) | 1/4 | 0 | — | — |

Features completadas: 2/3
Features fallidas: 1 (<feat-3>, fase 2: <motivo>)

Retros: plan/_archive/<feat-1>/feature.retro.md, plan/_archive/<feat-2>/feature.retro.md
```

## Notas importantes

- **Sin interaccion humana** durante toda la ejecucion.
- Cada feature es independiente — se ejecuta en su propia branch.
- El merge a develop entre features asegura que la siguiente feature trabaja sobre el codigo actualizado.
- Si hay conflicto de merge, se trata como fallo irrecuperable de esa feature.
- El usuario puede cancelar en cualquier momento (Ctrl+C). Los commits y merges ya hechos se preservan.
