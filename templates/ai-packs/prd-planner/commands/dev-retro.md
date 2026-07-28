---
description: Genera retrospectiva para una fase completada con reflexion humana
allowed-tools: Read, Glob, Grep, Bash, Write
---

Genera una retrospectiva enriquecida para una fase completada del plan.

## Parametros

- `$ARGUMENTS` — Numero de fase (ej: `1`, `02`). Si no se proporciona, auto-detecta la fase completada mas reciente sin retro.

## Paso 1 — Identificar fase

1. Busca PRPs en `plan/*/prp-*.md`
2. Si se proporciono numero de fase, busca `prp-{NN}-*.md` (con zero-padding flexible)
3. Si NO se proporciono: busca la fase completada mas reciente (todas las tareas `[x]`) que NO tenga `.retro.md`
4. Si no hay fase completada sin retro: informa y sugiere `/dev-status`

## Paso 2 — Recopilar contexto

1. Lee el PRP de la fase
2. Ejecuta `git log --oneline` para encontrar el commit asociado a la fase (busca por nombre de feature/fase en mensajes)
3. Si encuentra commit: `git diff <commit>^..<commit> --stat` para listar ficheros cambiados
4. Lee retro existente si la hay (`.retro.md`) — sera enriquecida, no sobreescrita

## Paso 3 — Reflexion humana

Pregunta al usuario (una pregunta a la vez):

1. **Que fue bien?** — Que decisiones o enfoques funcionaron
2. **Que no fue bien?** — Que causo fricciones, errores inesperados, o tiempo perdido
3. **Decisiones clave** — Alguna decision arquitectonica o de diseno que quieras documentar?
4. **Lecciones aprendidas** — Que harias diferente la proxima vez?

Si el usuario responde "skip" o "nada" a cualquier pregunta, continua con la siguiente.

## Paso 4 — Generar retro

Escribe `plan/<feature>/prp-NN-nombre.retro.md` con este formato:

```yaml
---
project: <nombre-proyecto>
feature: <feature-slug>
date: <YYYY-MM-DD>
type: retro
phase: "NN"
prp: prp-NN-nombre.md
session_count: 1
status: completed
source: human
---
```

### Secciones

- `## Summary` — Resumen de 2-3 lineas de la fase
- `## Files Changed` — Lista de ficheros del git diff (si disponible)
- `## What Went Well` — Respuestas del humano
- `## What Didn't Go Well` — Respuestas del humano
- `## Key Decisions` — Decisiones documentadas
- `## Lessons Learned` — Lecciones para futuras fases/features
- `## Errors Encountered` — Del PRP si hay (Build Errors, Test Failures, Verification Findings)
- `## Open Issues` — Issues pendientes identificados

Si ya existia una retro auto-generada por `/dev-build`:
- Preserva las secciones existentes (Errors Encountered, Fix Loop Summary, etc.)
- Anade las secciones humanas (What Went Well, Lessons Learned, etc.)
- Incrementa `session_count`
- Cambia `source` a `human+auto`

## Paso 5 — Ingestar en RAG

Lee el contenido de la retro generada y usa `ingest_data` con:
- `source`: `retro://<project>/<date>/<feature>/phase-<NN>`
- Si RAG no disponible: WARNING una vez: "RAG no disponible — retro no ingestada. Ejecuta `npm install -g mcp-local-rag` y reinicia Claude Code."

## Paso 6 — Resumen

Muestra:
- Path del fichero generado
- Numero de secciones con contenido
- Si hay open issues pendientes
