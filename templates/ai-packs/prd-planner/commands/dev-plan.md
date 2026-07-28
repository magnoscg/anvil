---
description: Genera PRPs (planes por fases) a partir del PRD usando agentes paralelos
---

Lee el PRD y genera PRPs por fases de implementacion.

$ARGUMENTS

Parsea los argumentos:
- `--auto` → auto-aprueba el plan sin preguntar. Genera PRPs y continua directamente.
- Sin argumentos → modo interactivo, pide aprobacion antes de continuar.

## Antes de empezar

1. Busca el PRD activo. Comprueba en este orden:
   - Si hay subcarpetas en `plan/`, busca la que tenga un PRD con `status: approved` o `status: in-progress` en el frontmatter. Si hay varias, preguntame cual usar.
   - Si solo hay `plan/PRD.md` (estructura legacy), usalo directamente.
   - Si no hay PRD, dime que ejecute `/dev-prd` primero.
2. Lee el PRD completo. Extrae el `feature` slug del frontmatter.
3. Lee el `CLAUDE.md` del proyecto para entender stack y arquitectura.
4. Comprueba si ya existen PRPs en `plan/<feature>/prp-*.md` (o `plan/prp-*.md` si es legacy).
   - Si existen, preguntame: "Ya hay PRPs. Quieres regenerarlos (reemplaza) o ajustar los existentes?"
   - Si no existen, continua.

## Paso 1 — Cargar contexto

Lee estos ficheros (si existen):
- `.dev/arch-index.md` — indice de docs de arquitectura
- `.dev/skill-registry.md` — skills disponibles

Si no existen, genera `.dev/` automaticamente (sigue pasos de `/dev-init`).

## Paso 2 — Analisis (DEV-ARCHITECT)

Lanza el agente DEV-ARCHITECT que genera spec tecnica + diseno de componentes en un solo paso:

```
Agent(
  subagent_type: "DEV-ARCHITECT",
  prompt: "Genera spec tecnico y diseno de componentes para esta feature.
           PRD: <contenido del PRD>
           arch-index: <contenido de .dev/arch-index.md>
           skill-registry: <contenido de .dev/skill-registry.md>
           CWD: <directorio actual>"
)
```

Muestra un resumen al usuario: modelos, contratos, edge cases, arbol de componentes, skills aplicables.

## Paso 3 — Generar PRPs

Lanza el agente DEV-TASK-PLANNER con el output del ARCHITECT:

```
Agent(
  subagent_type: "DEV-TASK-PLANNER",
  prompt: "Genera PRPs con DAG de dependencias.
           PRD: <contenido del PRD>
           Spec tecnica + Design: <output de DEV-ARCHITECT>
           arch-index: <contenido de .dev/arch-index.md>
           skill-registry: <contenido de .dev/skill-registry.md>
           Feature path: plan/<feature>/
           CWD: <directorio actual>"
)
```

Recoge el result envelope con el DAG summary.

## Paso 4 — Aprobacion

Muestra un resumen con:
- Fases generadas con numero de tareas por fase
- DAG de dependencias (que fase depende de cual)
- Fases paralelizables y por que
- Skills recomendadas por fase

**Modo interactivo** (sin --auto): Preguntame si quiero ajustar algo antes de dar por bueno el plan.

**Modo --auto**: Auto-aprobar sin preguntar. Mostrar el resumen y continuar directamente al Paso 5.

No generes codigo. Solo los PRPs.

## Paso 5 — Indexar en RAG y actualizar estado

Tras la aprobacion:

1. **Actualizar PRD**: Cambia el `status` en el frontmatter del PRD de `approved` a `in-progress`.

2. **Ingestar PRPs en RAG**: Lee el contenido de cada PRP generado y usa `ingest_data` para cada uno con:
   - `content`: el contenido del PRP
   - `metadata.source`: `prp://<project>/<date>/<feature>/phase-<NN>` (usando los valores del frontmatter)
   - `metadata.format`: `markdown`
   - Confirma: "N PRPs indexados en RAG."

3. **Actualizar INDEX**: Actualiza la entrada de esta feature en `plan/INDEX.md` con el status `in-progress` y el numero de fases.

Si el RAG no esta disponible (el tool `ingest_data` no existe): WARNING una vez: "RAG no disponible — PRPs no ingestados." Sin diagnostico ni sugerencias de instalacion. Actualiza el INDEX igualmente.
