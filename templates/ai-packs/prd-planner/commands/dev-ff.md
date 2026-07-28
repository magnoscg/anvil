---
description: Fast-forward para bugfixes — PRD minimo + PRPs + build en un solo comando
---

Fast-forward para: $ARGUMENTS

Este comando acelera bugfixes y tareas pequenas: genera PRD minimo, PRPs, y ejecuta build en un solo flujo con una sola aprobacion.

## Paso 1 — Cargar contexto

1. Lee `.dev/arch-index.md` y `.dev/skill-registry.md`.
   - Si no existen, genera `.dev/` automaticamente (sigue pasos de `/dev-init`).
2. Lee `CLAUDE.md` del proyecto.

### Branch check (gitflow)
1. Ejecuta `git branch --show-current`.
2. Si es `main` o `develop`:
   - Proponer: `git checkout -b hotfix/<slug>` (para bugfixes) o `feature/<slug>`.
   - Esperar confirmacion antes de continuar.
3. Si ya estamos en `feature/*` o `hotfix/*`: continuar.

## Paso 2 — Explorar codebase

Lanza DEV-EXPLORER:

```
Agent(
  subagent_type: "DEV-EXPLORER",
  prompt: "Analiza el codebase para: $ARGUMENTS
           CWD: <directorio actual>
           arch-index: <contenido de .dev/arch-index.md>
           skill-registry: <contenido de .dev/skill-registry.md>"
)
```

## Paso 3 — Generar PRD minimo (sin preguntas)

Genera automaticamente un PRD minimo con 4 secciones:
- **Problema**: extraido de la descripcion + contexto del Explorer
- **Solucion propuesta**: basada en el analisis del codebase
- **Restricciones**: del CLAUDE.md y arch-index
- **Criterios de aceptacion**: derivados del problema

Genera el slug en kebab-case. Crea `plan/<slug>/PRD.md` con frontmatter.

## Paso 4 — Generar PRPs (1-2 fases)

Sin lanzar agentes paralelos (es un bugfix, max 2 fases):
- Genera 1-2 PRPs directamente con tareas concretas
- Escribe `plan/<slug>/prp-01-fix.md` (y prp-02 si necesario)

## Paso 5 — Gate de aprobacion unica

Muestra TODO en un solo bloque:

```
Fast-forward: <descripcion>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRD:
  Problema: ...
  Solucion: ...
  Restricciones: ...
  Criterios: ...

Plan:
  Fase 1 — <nombre>
    - [ ] tarea 1
    - [ ] tarea 2
  [Fase 2 — <nombre> (si aplica)]

Aprobar y ejecutar? (S/n)
```

Espera mi aprobacion. Si apruebo, continua. Si no, pregunta que ajustar.

## Paso 6 — Ejecutar

Tras aprobacion:
1. Actualiza PRD status a `approved` → `in-progress`
2. Para cada fase, invoca via Skill tool:
   ```
   Skill(skill: "dev-build", args: "<slug>")
   ```
   Esto ejecuta el workflow completo por fase (implementacion, verificacion, tests, correccion, commit).
3. NO implementes directamente ni lances agentes sin pasar por `/dev-build`.

## Paso 7 — Indexar

1. Ingestar PRD y PRPs en RAG. Si RAG no disponible: WARNING una vez: "RAG no disponible — PRD/PRPs no ingestados. Ejecuta `npm install -g mcp-local-rag` y reinicia Claude Code."
2. Actualizar `plan/INDEX.md`
3. Si todo completado, archivar en `plan/_archive/`
4. Sugerir commit
