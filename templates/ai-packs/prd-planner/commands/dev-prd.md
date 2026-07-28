---
description: Co-crea un PRD para una nueva feature o tarea
---

Vamos a crear un PRD para: $ARGUMENTS

## Paso 0 — Verificar .dev/ y explorar codebase

1. Verifica que `.dev/arch-index.md` y `.dev/skill-registry.md` existen.
   - Si NO existen, genera la carpeta `.dev/` automaticamente:
     - Genera arch-index, skill-registry y ast-patterns (items 3-5 del Paso 3 de `/dev-init`).
     - Crea `.dev/` y anade a `.gitignore` si no esta.
   - Si existen, leelos.

2. Lanza `DEV-EXPLORER` para analizar el codebase:
   ```
   Agent(
     subagent_type: "DEV-EXPLORER",
     prompt: "Analiza el codebase para la feature: $ARGUMENTS
              CWD: <directorio actual>
              arch-index: <contenido de .dev/arch-index.md>
              skill-registry: <contenido de .dev/skill-registry.md>"
   )
   ```
   Guarda el result envelope del Explorer para usarlo como contexto.

3. Consulta el RAG con la descripcion proporcionada (`query_documents`, limit 5).
   - Si hay PRDs similares (score < 0.3), muestramelos: "Encontre PRDs relacionados: [feature] ([project]). Quieres que los tenga en cuenta?"
   - Si el usuario dice si, lee los chunks relevantes y usalos como contexto.
   - Si no hay nada relevante (score > 0.5 o sin resultados), continua sin mencionar.
   - Si el RAG no esta disponible (el tool `query_documents` no existe): WARNING una vez: "RAG no disponible. Ejecuta `npm install -g mcp-local-rag` y reinicia Claude Code para habilitar busqueda cross-proyecto." Continua sin RAG.

## Paso 1 — Preparar contexto

1. Lee `CLAUDE.md` del proyecto (si existe) para entender stack, convenciones y arquitectura.
2. Genera el slug de la feature en kebab-case a partir de la descripcion (ej: "sistema de autenticacion" → `auth-system`).
3. Comprueba si `plan/<feature-slug>/PRD.md` ya existe.
   - Si existe, preguntame: "Ya hay un PRD para esta feature. Quieres crear uno nuevo (reemplaza el actual) o editar el existente?"
   - Si no existe, continua.

## Paso 2 — Detectar scope

Analiza la descripcion proporcionada y el resultado del Explorer. Decide el tipo de PRD:

**PRD minimo** (bugfix, tarea pequena, cambio acotado):
- Problema
- Solucion propuesta
- Restricciones
- Criterios de aceptacion

**PRD completo** (feature mediana/grande):
- Resumen (2-3 frases)
- Problema que resuelve
- Fuentes de datos / API (si aplica): endpoints, auth, paginacion
- Que se construye: pantallas, componentes, interacciones
- Restricciones tecnicas (sacadas de CLAUDE.md + Explorer)
- Fuera de scope
- Decisiones de arquitectura
- Estructura de carpetas objetivo (informada por Explorer)
- Criterios de aceptacion
- Riesgos y preguntas abiertas

Si no tienes claro cual aplica, preguntame.

## Paso 3 — Entender la feature

Hazme preguntas para rellenar las secciones. **Agrupalas** en un solo bloque, no me hagas 15 preguntas de una en una.

Necesitas saber:
- Que hace exactamente
- Que problema resuelve y para quien
- Que restricciones tecnicas existen
- Que queda fuera del scope

Usa el contexto del Explorer para hacer preguntas mas informadas (ej: "Vi que ya tienes un AuthRepository — la feature se integra con eso?").

## Paso 4 — Generar el PRD

Con las respuestas, genera `plan/<feature-slug>/PRD.md` (crea las carpetas si no existen).

Al generar el fichero, incluye al inicio un frontmatter YAML:
```
---
project: <nombre de la carpeta raiz del proyecto (ultimo segmento del pwd)>
feature: <feature-slug en kebab-case>
date: <fecha actual YYYY-MM-DD>
type: prd
status: draft
summary: <resumen de 1 frase del PRD>
---
```

## Paso 5 — Pedir aprobacion

Muestrame un resumen del PRD y preguntame si quiero cambiar algo antes de cerrarlo. No avances hasta que yo confirme.

Tras la aprobacion, actualiza el `status` en el frontmatter de `draft` a `approved`.

IMPORTANTE: El PRD define el QUE, no el COMO. No incluyas pasos de implementacion.

## Paso 6 — Indexar en RAG y actualizar INDEX

Tras la aprobacion:

1. **Ingestar en RAG**: Lee el contenido de `plan/<feature-slug>/PRD.md` y usa `ingest_data` con:
   - `content`: el contenido del PRD
   - `metadata.source`: `prd://<project>/<date>/<feature>` (usando los valores del frontmatter)
   - `metadata.format`: `markdown`
   - Confirma: "PRD indexado en RAG."

2. **Actualizar INDEX**: Lee `plan/INDEX.md` (si existe) y anade o actualiza la entrada de esta feature. Si no existe, crealo con este formato:
   ```
   # Plan Index

   | Feature | Status | Date | Summary |
   |---------|--------|------|---------|
   | [<feature-slug>](<feature-slug>/PRD.md) | approved | YYYY-MM-DD | <summary> |
   ```

Si el RAG no esta disponible (el tool `ingest_data` no existe): WARNING una vez: "RAG no disponible — PRD no ingestado. Ejecuta `npm install -g mcp-local-rag` y reinicia Claude Code." Actualiza el INDEX igualmente.
