---
description: Archiva una feature completada
allowed-tools: Read, Glob, Grep, Write, Bash
---

Archiva una feature completada moviendo su directorio a `plan/_archive/`.

## Parametros

- `$ARGUMENTS` — Slug de la feature (ej: `auth-system`). Si no se proporciona, auto-detecta la feature con todas las fases completadas.

## Paso 1 — Identificar feature

1. Busca features en `plan/*/PRD.md` (excluyendo `_archive`)
2. Si se proporciono slug: verifica que `plan/<slug>/` existe
3. Si NO se proporciono: busca features donde TODOS los PRPs tengan todas las tareas `[x]`
4. Si no hay feature completada: informa y sugiere `/dev-status`
5. Si hay multiples candidatas: lista y pide al usuario que elija

## Paso 2 — Verificar completitud

Para la feature seleccionada:

1. Lee todos los `prp-*.md` (excluyendo `.retro.md`) en `plan/<feature>/`
2. Verifica que cada PRP tiene TODAS las tareas como `[x]` (completadas)
3. Si hay tareas `[ ]` (pendientes) o `[!]` (bloqueadas): STOP con lista de tareas incompletas
4. Muestra resumen:
   ```
   Feature: <slug>
   PRPs: N fases, todas completadas
   Retros: M/N fases documentadas
   ```
5. Si hay fases sin retro, sugiere `/dev-retro <NN>` antes de archivar (pero no bloquea)

## Paso 3 — Archivar

1. Actualiza el `status` del PRD (frontmatter) a `completed` si no lo esta
2. Crea `plan/_archive/` si no existe
3. Mueve `plan/<feature>/` → `plan/_archive/<feature>/` (usa `mv`)
4. Actualiza `plan/INDEX.md`:
   - Cambia el status de la feature a `archived`
   - Actualiza el link del PRD a `_archive/<feature>/PRD.md`

## Paso 4 — Re-ingestar en RAG

Lee el PRD archivado y usa `ingest_data` con:
- `source`: `prd://<project>/<feature>` (actualiza el existente)
- Si RAG no disponible: WARNING una vez: "RAG no disponible — PRD archivado no ingestado. Ejecuta `npm install -g mcp-local-rag` y reinicia Claude Code."

## Paso 5 — Resumen

Muestra:
```
Feature "<slug>" archivada en plan/_archive/<slug>/
  PRPs: N fases
  Retros: M documentadas
  INDEX.md: actualizado
```
