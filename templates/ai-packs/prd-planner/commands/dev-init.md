---
description: Inicializa el workflow PRD en el proyecto (CLAUDE.md + .dev/ + plan/)
---

Inicializa el workflow PRD completo en el proyecto actual.

## Paso 0 — Validar entorno

Antes de cualquier otra accion, verifica que el ecosistema PRDPlanner esta instalado:

1. Verifica que existen los **9 agentes** DEV-*.md en `~/.claude/agents/`:
   - DEV-EXPLORER, DEV-ARCHITECT, DEV-TASK-PLANNER, DEV-IMPLEMENTER, DEV-UI-ENGINEER, DEV-TEST-RUNNER, DEV-VERIFIER, DEV-QA, DEV-PROFILER
2. Verifica que existen los **15 comandos** dev-*.md en `~/.claude/commands/`:
   - dev-init, dev-prd, dev-plan, dev-build, dev-build-yolo, dev-status, dev-verify, dev-search, dev-ff, dev-profile, dev-retro, dev-archive, dev-registry, dev-registry-refresh, dev-qa

Si falta algun fichero: **STOP** — muestra la lista de ficheros faltantes y sugiere reinstalar PRDPlanner.
Si todo esta presente: continua al Paso 1.

## Paso 1 — Inyectar workflow en CLAUDE.md

1. **Comprobar si existe `CLAUDE.md`** en la raiz del proyecto.
   - Si existe, leelo completo.
   - Si no existe, crealo vacio.

2. **Comprobar si ya tiene el workflow PRD**.
   - Busca la cadena `<!-- PRD-WORKFLOW -->` en el contenido.
   - Si ya existe, continua al Paso 2 (no re-inyectes).

3. **Inyectar el bloque** al final del `CLAUDE.md` (respetando el contenido existente). Anade exactamente este bloque:

```
<!-- PRD-WORKFLOW -->
## Workflow PRD

Este proyecto usa un workflow estructurado para planificar e implementar features.

### Comandos disponibles

| Comando | Proposito |
|---------|-----------|
| `/dev-prd <descripcion>` | Co-crear un PRD para una feature |
| `/dev-plan` | Generar PRPs (planes por fases) a partir del PRD |
| `/dev-build [N]` | Ejecutar la siguiente fase pendiente (o la fase N) |
| `/dev-status` | Ver el estado actual de implementacion |
| `/dev-search <query>` | Buscar PRDs/PRPs anteriores en el RAG |
| `/dev-verify [N\|all]` | Verificar el codigo contra la arquitectura |
| `/dev-ff <descripcion>` | Fast-forward: PRD + plan + build en un paso (bugfixes) |
| `/dev-registry` | Ver o regenerar el registro de skills disponibles |

### Flujo de trabajo

1. **Definir** — `/dev-prd` para crear PRD en `plan/<feature>/PRD.md`
2. **Planificar** — `/dev-plan` para generar PRPs en `plan/<feature>/prp-*.md`
3. **Construir** — `/dev-build` para ejecutar fase a fase
4. **Verificar** — `/dev-status` para ver progreso
5. **Buscar** — `/dev-search` para encontrar PRDs/PRPs de otros proyectos
6. **Auditar** — `/dev-verify` para verificacion arquitectonica
7. **Fast-forward** — `/dev-ff` para bugfixes rapidos (PRD+plan+build en un paso)

### Estructura de archivos

```
plan/
  INDEX.md                    # Indice de todas las features
  auth-system/                # Feature: sistema de autenticacion
    PRD.md                    # Requisitos del producto
    prp-01-models.md          # Plan fase 1
    prp-02-ui.md              # Plan fase 2
  _archive/                   # Features completadas
    onboarding/
      PRD.md
      prp-01-screens.md
```

### Carpeta .dev/ (generada)

```
.dev/
  arch-index.md               # Indice de docs de arquitectura
  skill-registry.md           # Skills auto-descubiertas
  ast-patterns.yml            # Patterns ast-grep para Swift
```

### Reglas

- El PRD define el QUE, los PRPs definen el COMO.
- Cada feature vive en su propia subcarpeta dentro de `plan/`.
- Cada fase se ejecuta en orden. No saltar fases.
- Los PRPs son el estado persistente. Al hacer `/clear`, se relee todo desde los ficheros.
- Los PRDs/PRPs se indexan automaticamente en el RAG para busqueda cross-project.
- Features completadas se archivan en `plan/_archive/`.
- Si algo es ambiguo, preguntar antes de actuar.
<!-- /PRD-WORKFLOW -->
```

## Paso 2 — Verificar dependencias

1. Comprobar que `ast-grep` esta instalado: ejecuta `which ast-grep`
   - Si esta instalado → anotar como disponible
   - Si no → anotar: "ast-grep no encontrado. Instala con: `brew install ast-grep`"
   - Continuar en ambos casos (no es bloqueante)

## Paso 3 — Generar .dev/

1. Crear carpeta `.dev/` si no existe.

2. Asegurar que `.dev/` esta en `.gitignore`:
   - Si `.gitignore` existe, buscar `.dev/` en el contenido. Si no esta, anadirlo.
   - Si `.gitignore` no existe, crearlo con `.dev/` como contenido.

3. **Generar `.dev/ast-patterns.yml`**:

```yaml
rules:
  # Anti-patterns (DEV-VERIFIER)
  - id: published-property
    language: swift
    pattern: "@Published var $PROP"
    message: "Usar @Observable en vez de @Published"
    severity: error

  - id: stateobject-usage
    language: swift
    pattern: "@StateObject var $PROP"
    message: "Usar @State con @Observable"
    severity: error

  - id: swiftui-in-domain
    language: swift
    pattern: "import SwiftUI"
    message: "Domain no debe importar SwiftUI (verificar path)"
    severity: warning

  - id: singleton-in-repo
    language: swift
    pattern: "static let shared"
    message: "Usar DI en vez de singleton (verificar contexto)"
    severity: warning

  # Exploracion (DEV-EXPLORER)
  - id: find-protocols
    language: swift
    pattern: "protocol $NAME { $$$ }"

  - id: find-observable-classes
    language: swift
    pattern: "@Observable class $NAME { $$$ }"

  - id: find-views
    language: swift
    pattern: "struct $NAME: View { $$$ }"
```

4. **Generar `.dev/arch-index.md`**:
   - Lee cada fichero en `~/.claude/dev-verify-docs/` (los 18 docs)
   - Para cada doc: extrae titulo, identifica cuando debe leerse (que dominios/ficheros activan su lectura), y extrae las 3-5 reglas mas criticas (busca MUST, NEVER, siempre, nunca, CRITICO, prohibido)
   - Escribe el indice con este formato:

```markdown
# Architecture Index
Generated: <fecha actual YYYY-MM-DD>

## <NOMBRE_DOC>.md
**Path**: ~/.claude/dev-verify-docs/<NOMBRE_DOC>.md
**Leer cuando**: <condicion concreta: que ficheros o dominios activan la lectura>
**Reglas criticas**:
1. <regla 1>
2. <regla 2>
3. <regla 3>
...

(repetir para cada uno de los 18 docs)
```

5. **Generar `.dev/skill-registry.md`**:
   Escanea estas fuentes y genera el registro:

   a) **Axiom Skills** — tabla hardcoded:
   ```markdown
   ## Axiom Skills (iOS)
   | Triggers | Skill | Tipo |
   |----------|-------|------|
   | View, Screen, SwiftUI, UI, Presentation | axiom:axiom-ios-ui | router |
   | Repository, DataSource, SwiftData, persistencia | axiom:axiom-ios-data | router |
   | API, Network, Remote, endpoint, HTTP | axiom:axiom-ios-networking | router |
   | async, Task, actor, Sendable, concurrencia | axiom:axiom-ios-concurrency | router |
   | Test, Swift Testing, mock, spec | axiom:axiom-ios-testing | router |
   | UI test, XCUITest, XCTest, UITests, accessibilityIdentifier, flaky test | axiom:axiom-ui-testing | skill |
   | XCUIElement, XCUIApplication, waitForExistence, test automation, Page Object | axiom:axiom-xctest-automation | skill |
   | Navigation, Router, Route, deep link | axiom:axiom-swiftui-nav | router |
   | Widget, Notification, Intent, Extension | axiom:axiom-ios-integration | router |
   | Performance, optimizar, lento, memoria | axiom:axiom-ios-performance | router |
   | Build, Xcode, compilar, error build | axiom:axiom-ios-build | router |
   | Vision, ARKit, RealityKit, visionOS | axiom:axiom-ios-vision | router |
   | AI, ML, CoreML, Foundation Models | axiom:axiom-ios-ai | router |
   | Security, Keychain, privacy, App Attest | axiom:axiom-ios-security | router |
   | iOS 26, SwiftUI 26, Liquid Glass | axiom:axiom-swiftui-26-ref | reference |
   | Design System, HIG, componentes UI | axiom:axiom-ios-design-system | reference |
   | App Store, submission, review | axiom:axiom-ios-app-store | router |
   ```

   b) **Skills locales** — escanea `~/.claude/skills/*/`:
   ```
   ls ~/.claude/skills/
   ```
   Para cada carpeta, busca SKILL.md o README.md para extraer nombre y descripcion.

   c) **Skills de proyecto** — escanea `.claude/skills/*/`:
   Si existe, lista las skills locales del proyecto.

   d) **Tutorials** — cuenta `~/.claude/tutorials/*/`:
   ```
   ls ~/.claude/tutorials/ | wc -l
   ```
   Solo reporta el conteo.

   Formato final:
   ```markdown
   # Skill Registry
   Generated: <fecha> | Project: <nombre proyecto>

   ## Axiom Skills (iOS)
   [tabla de arriba]

   ## Local Skills (N)
   | Nombre | Path | Descripcion |
   |--------|------|-------------|
   | ... |

   ## Project Skills
   | Nombre | Path | Descripcion |
   |--------|------|-------------|
   | ... |

   ## Tutorials: N disponibles en ~/.claude/tutorials/
   ```

6. **Generar `.dev/app-map.md`** (solo si el proyecto tiene Views SwiftUI):

   Verificar si existen ficheros con `struct.*: View`:
   ```bash
   grep -rl "struct.*: View" --include="*.swift" . | head -1
   ```
   Si no hay Views SwiftUI (no es un proyecto iOS con UI): skip silencioso.

   Si hay Views: lanzar DEV-EXPLORER para generar el app map:
   ```
   Agent(
     subagent_type: "DEV-EXPLORER",
     prompt: "Genera .dev/app-map.md con inventario de pantallas del proyecto.
              Escanea: struct.*: View, NavigationLink, .sheet, TabView, Router, permisos, datos.
              Formato: # App Map — <proyecto> con secciones Navegacion principal y Pantallas.
              CWD: <directorio actual>"
   )
   ```

## Paso 4 — Configurar RAG (opcional)

1. **Verificar mcp-local-rag**:
   - Ejecuta: `which mcp-local-rag` o `npx -y mcp-local-rag --version`
   - Si NO esta disponible: INFO "RAG no instalado. `/dev-search` no disponible. Instala con: `npm install -g mcp-local-rag` si lo necesitas."
     - **NO intentar instalar automaticamente.**
     - Continuar sin RAG (no es bloqueante). Skip pasos 2-4.
   - Si esta disponible: anotar como OK, continuar.

2. **Crear directorio RAG global** (si no existe):
   ```bash
   mkdir -p ~/.claude/rag-data
   ```

3. **Configurar .mcp.json del proyecto**:

   El JSON exacto que debe tener la entrada `local-rag`:
   ```json
   {
     "mcpServers": {
       "local-rag": {
         "command": "npx",
         "args": ["-y", "mcp-local-rag"],
         "env": {
           "BASE_DIR": "/Users/<usuario>/.claude/rag-data"
         }
       }
     }
   }
   ```
   Nota: Sustituir `/Users/<usuario>` por el home real (`echo $HOME`).

   - Si `.mcp.json` **no existe**: crear el fichero con el JSON de arriba.
   - Si `.mcp.json` **existe**:
     a. Leerlo con `cat .mcp.json`
     b. Parsear como JSON. Si tiene `mcpServers.local-rag` → ya configurado, no tocar.
     c. Si NO tiene `local-rag`: añadir la key `local-rag` dentro de `mcpServers` preservando las demas keys existentes. Escribir el JSON resultante.
     d. Si el fichero no es JSON valido: WARNING "`.mcp.json` tiene formato invalido. Corrigelo manualmente." No sobreescribir.

4. **Validar que el RAG responde**:
   - Tras configurar `.mcp.json`, verificar que el tool `query_documents` o `ingest_data` esta disponible en la sesion.
   - Si NO esta disponible: WARNING "mcp-local-rag configurado en .mcp.json pero no disponible en esta sesion. Reinicia Claude Code para activar el servidor RAG."
   - Si esta disponible: hacer un test con `query_documents` query "test" para confirmar que responde.
   - Anotar resultado (OK / requiere reinicio / no instalado).

## Paso 5 — Crear plan/

1. Crear `plan/` si no existe.
2. Crear `plan/INDEX.md` si no existe, con cabecera:
   ```markdown
   # Plan Index

   | Feature | Status | Date | Summary |
   |---------|--------|------|---------|
   ```

## Paso 6 — Confirmar

Muestra un resumen:

```
Proyecto configurado:
  CLAUDE.md              ✓ (workflow inyectado)
  mcp-local-rag          ✓|✗ (instalado / no encontrado — instala con: npm install -g mcp-local-rag)
  ~/.claude/rag-data     ✓ (directorio RAG global)
  .mcp.json              ✓ (local-rag configurado con BASE_DIR ~/.claude/rag-data)
  RAG activo             ✓|⚠ (respondiendo / requiere reiniciar Claude Code)
  .dev/arch-index.md     ✓ (N docs indexados)
  .dev/skill-registry.md ✓ (N skills encontradas)
  .dev/app-map.md        ✓|— (N pantallas mapeadas / no es proyecto iOS con UI)
  .dev/ast-patterns.yml  ✓ (N patterns Swift)
  ast-grep               ✓|✗ (instalado / no encontrado — instala con: brew install ast-grep)
  plan/INDEX.md          ✓
  .gitignore             ✓ (.dev/ excluido)
```
