---
description: QA visual y funcional completo de la app con AXe — descubre pantallas, genera app map, testea interacciones y reporta hallazgos
---

QA visual y funcional para: $ARGUMENTS

## Paso 0 — Determinar scope

- Si `$ARGUMENTS` indica un path a fichero (ej: `/dev-qa Features/Auth/UI/LoginView.swift`): testear solo esa View.
- Si `$ARGUMENTS` indica un slug de feature (ej: `/dev-qa user-profile`): leer PRPs de `plan/<feature>/prp-*.md`, extraer Views creadas/modificadas.
- Si no se indica nada: QA completo de toda la app — todas las pantallas alcanzables.

## Paso 1 — App Map

### 1.1 Verificar si existe app map

Buscar `.dev/app-map.md`.

### 1.2 Si NO existe → generar

Lanzar DEV-EXPLORER para generar el app map:

```
Agent(
  subagent_type: "DEV-EXPLORER",
  prompt: "Genera un app map completo del proyecto.
           CWD: <directorio actual>

           Escanea el proyecto y genera `.dev/app-map.md` con este formato:

           # App Map — <nombre proyecto>
           Generated: <fecha> | Views: N | Last commit: <hash>

           ## Navegacion principal
           - Tab N: ViewName → [DestinationView, ...]
           - Modal: ViewName (condicion)
           - Onboarding: ViewName (first launch)

           ## Pantallas (N)

           ### <ViewName>
           - **Path**: ruta/al/fichero.swift
           - **Tipo**: Tab / Push / Modal / Root
           - **Navega a**: [lista de Views destino]
           - **Navegable desde**: [lista de Views origen]
           - **Requiere**: login / permisos de camara / etc (o 'nada')
           - **Datos**: que datos carga (SwiftData, API, etc) o 'estatico'
           - **Elementos interactivos**: N buttons, N text fields, N toggles, etc
           - **Test esperado**: descripcion de que deberia pasar al interactuar

           Para encontrar esta informacion:
           1. ast-grep -p 'struct $NAME: View { $$$ }' --lang swift para encontrar todas las Views
           2. Grep por NavigationLink, navigationDestination, .sheet, .fullScreenCover, TabView para detectar navegacion
           3. Grep por import CoreLocation, import Photos, import AVFoundation, import UserNotifications para detectar permisos
           4. Grep por @Query, @FetchRequest, URLSession, @Environment para detectar fuentes de datos
           5. Grep por SecureTextField, password, login, signIn para detectar auth gates
           6. Para cada View, contar elementos interactivos: Button, TextField, Toggle, Picker, NavigationLink

           Escribe el resultado en .dev/app-map.md"
)
```

### 1.3 Si EXISTE → verificar si esta actualizado

```bash
# Fecha del ultimo commit que toco Views
LAST_VIEW_CHANGE=$(git log -1 --format=%H -- '**/*View.swift' '**/*Screen.swift')
```

Comparar con el `Last commit: <hash>` del app map. Si difieren → re-lanzar DEV-EXPLORER para actualizar.

### 1.4 Ingestar en RAG

```
ingest_data con source: appmap://<project>/<date>
```

Si RAG no disponible: WARNING una vez (no bloquea).

## Paso 2 — Pre-flight

Verificar pre-requisitos (misma logica que DEV-QA Paso 0):

1. **AXe CLI**: `which axe` — si no instalado, parar con instrucciones de instalacion.
2. **Simulador**: Buscar booted, si no hay → bootear uno automaticamente.
3. **Bundle ID**: Buscar en CLAUDE.md, .pbxproj, o Info.plist.
4. **App instalada**: Si no → build e instalar automaticamente.

## Paso 3 — Lanzar DEV-QA

Determinar la lista de Views a testear segun el scope del Paso 0:

- **QA completo**: todas las Views del app map
- **Feature**: solo Views listadas en los PRPs de la feature
- **Fichero**: solo esa View

```
Agent(
  subagent_type: "DEV-QA",
  prompt: "Ejecuta QA visual y funcional completo.
           Ficheros UI: <lista de Views a testear>
           Bundle ID: <bundle ID>
           CWD: <directorio actual>

           APP MAP (contexto de navegacion):
           <contenido completo de .dev/app-map.md>

           MODO: standalone (no pipeline — testear todas las pantallas indicadas, no solo las recien implementadas)

           Para cada pantalla del app map:
           1. Navegar usando la ruta indicada en el map
           2. Verificar que los elementos interactivos listados existen
           3. Ejecutar functional tests (tap botones, rellenar campos, scroll)
           4. Comparar lo que ves con lo que dice el map — reportar discrepancias
           5. Capturar screenshot como evidencia"
)
```

## Paso 4 — Informe

Mostrar el informe del DEV-QA:

```
QA Report — <nombre proyecto>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scope: <completo | feature: X | fichero: Y>
Pantallas testeadas: N / M del app map
App Map: .dev/app-map.md (<fecha>)

Visual:
  CRITICAL: N | WARNING: N | INFO: N

Functional Tests:
  PASS: N | FAIL: N

  Detalle FAIL:
    [F01] <pantalla> — <elemento>: <accion> → <problema>

Console:
  CRITICAL: N | WARNING: N

Screenshots: N capturas en /tmp/devqa-*

Discrepancias app map vs realidad:
  [D01] <pantalla>: map dice X, simulador muestra Y
```

## Paso 5 — Acciones

- **Si hay CRITICAL o FAIL**: Preguntar al usuario: "Hay N problemas criticos. Quieres lanzar DEV-IMPLEMENTER para intentar corregir?"
  - Si acepta → lanzar DEV-IMPLEMENTER en modo fix con los hallazgos
  - Tras fix → re-lanzar DEV-QA solo en las pantallas afectadas para verificar
- **Si hay discrepancias app map**: Preguntar si quiere actualizar el app map (la realidad puede haber cambiado intencionalmente)
- **Si todo OK**: "QA passed. N pantallas testeadas sin problemas."

## Paso 6 — Ingestar resultado en RAG

```
ingest_data con source: qa-report://<project>/<date>
```

Esto permite que `/dev-search` encuentre historicos de QA para comparar regresiones entre versiones.
