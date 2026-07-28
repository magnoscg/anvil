---
description: Ejecuta fases del PRP via orquestador + sub-agentes especializados
---

## Modo de operacion

$ARGUMENTS

Parsea los argumentos:
- `--auto` → modo autonomo (todas las fases, sin intervencion humana, auto-commit, merge a develop)
- `--ui` → incluir UI tests (por defecto solo unit tests, UI tests son lentos)
- Numero de fase (ej: `3`) → ejecuta esa fase especifica (solo modo interactivo)
- Slug de feature (ej: `auth-system`) → usa esa feature (ambos modos)
- Sin argumentos → modo interactivo, siguiente fase pendiente, solo unit tests

Ejemplos: `/dev-build`, `/dev-build 3`, `/dev-build --auto`, `/dev-build --ui`, `/dev-build --auto --ui`

---

## Paso 0 — Branch gitflow

### Modo interactivo (sin --auto)

1. Ejecuta `git branch --show-current`.
2. **Si es `main` o `develop`**: proponer crear rama `feature/<slug>`. Esperar confirmacion.
3. **Si es `feature/*`, `hotfix/*`, `release/*`**: continuar.
4. **Otra rama**: avisar, preguntar si continuar.

### Modo --auto

1. **Actualizar develop**:
   ```bash
   git checkout develop
   git pull --ff-only
   ```
   Si falla: parar con mensaje de divergencia.

2. **Crear o actualizar feature branch**:
   - Si `feature/<slug>` NO existe: `git checkout -b feature/<slug>`
   - Si YA existe: `git checkout feature/<slug> && git rebase develop`
   - Si rebase tiene conflictos: `git rebase --abort` y parar.

**NUNCA** ejecutar implementacion ni commits en `main` o `develop` directamente.

## Paso 1 — Encontrar feature y fases

1. Si se indica slug, usa esa feature. Si no, busca feature `in-progress` en `plan/INDEX.md` (o `approved` si no hay `in-progress`).
2. Si no hay PRPs: "Ejecuta `/dev-plan` primero."
3. Lee TODOS los PRPs de `plan/<feature>/prp-*.md`. Parsea `depends_on`, `parallelizable_with` y `status`.
4. Construye el DAG de dependencias.

### Determinar que ejecutar

- **Modo interactivo**: Si se indica numero de fase, usa esa. Si no, la primera pendiente cuyas dependencias estan completadas.
- **Modo --auto**: todas las fases pendientes (loop hasta terminar o fallo).

### Paralelizacion

- **Interactivo**: Si multiples fases son ejecutables con `parallelizable_with` mutuo, preguntar: "Fases N y M son independientes. Ejecutar en paralelo?"
- **--auto**: paralelizar automaticamente sin preguntar.

## Paso 2 — Cargar contexto

1. Lee `.dev/arch-index.md`, `.dev/skill-registry.md` y `.dev/app-map.md` (si existen).
2. Lee el PRD de la feature activa.
3. Lee **SOLO** el PRP de la fase a ejecutar.
4. Verifica dependencias: si `depends_on` no estan `completed`, avisar y no continuar.
5. **Cargar retrospectiva previa** (si existe `prp-NN-nombre.retro.md` con status `partial`).
6. **Cargar contexto de fases previas**: solo `Open Issues` de retros de fases completadas. `Decisions Made` y `Lessons Learned` solo si la retro indica que hubo errores en esa fase.
7. **Snapshot del PRP original** (para detectar desviaciones).

## Paso 2.5 — Plan mode (solo interactivo)

Solo en modo interactivo (sin `--auto`):

1. Entra en plan mode (EnterPlanMode).
2. Explora el PRP, los ficheros existentes que se van a tocar, y el contexto de arquitectura.
3. Presenta al usuario un approach conciso: que ficheros se van a crear/modificar y por que.
4. Espera confirmacion o ajustes.
5. Sale de plan mode (ExitPlanMode).

El IMPLEMENTER recibe el PRP + el approach aprobado como contexto adicional.

En modo `--auto`: skip este paso (ejecucion directa).

## Paso 3 — Ejecucion (DEV-IMPLEMENTER)

NO codifiques directamente. Lanza agente(s):

```
Agent(
  subagent_type: "DEV-IMPLEMENTER",
  prompt: "Ejecuta las tareas del PRP.
           PRD path: plan/<feature>/PRD.md
           PRP path: plan/<feature>/prp-NN-nombre.md
           arch-index path: .dev/arch-index.md
           skill-registry path: .dev/skill-registry.md
           CWD: <directorio actual>

           CONTENIDO DEL PRD:
           <contenido del PRD>

           CONTENIDO DEL PRP:
           <contenido del PRP>

           CONTENIDO ARCH-INDEX:
           <contenido de .dev/arch-index.md o 'No disponible'>

           CONTENIDO SKILL-REGISTRY:
           <contenido de .dev/skill-registry.md o 'No disponible'>

           RETROSPECTIVA (sesion anterior, si existe):
           <contenido de prp-NN-nombre.retro.md o 'Sin retrospectiva previa'>

           CONTEXTO DE FASES PREVIAS:
           <Open Issues + Decisions Made + Lessons Learned de retros de fases completadas, o 'Sin fases previas'>"
)
```

Si fases en paralelo, lanzar multiples agentes en la MISMA llamada al Agent tool.

**Nota sobre delegacion UI:** El DEV-IMPLEMENTER puede delegar tareas UI al DEV-UI-ENGINEER segun su criterio.

## Paso 4 — Verificacion (paralelo)

Tras la ejecucion, lanza **simultaneamente**:

```
Agent(
  subagent_type: "DEV-VERIFIER",
  prompt: "Verifica los siguientes ficheros: <files_created + files_modified del envelope>
           arch-index: <contenido de .dev/arch-index.md>
           skill-registry: <contenido de .dev/skill-registry.md o 'No disponible'>
           CWD: <directorio actual>"
)

Agent(
  subagent_type: "DEV-TEST-RUNNER",
  prompt: "Ejecuta build y unit tests del proyecto. NO ejecutar UI tests (solo con --ui).
           CWD: <directorio actual>"
)
```

### UI tests (solo con --ui)

Si se paso `--ui`, lanzar un segundo TEST-RUNNER en paralelo o secuencialmente:
```
Agent(
  subagent_type: "DEV-TEST-RUNNER",
  prompt: "Ejecuta SOLO UI tests del proyecto (target UITests).
           CWD: <directorio actual>"
)
```
Si no se paso `--ui`: skip silencioso. El informe muestra "UI Tests: skipped (usa --ui para incluirlos)".

### Security scanner (condicional)

Si los ficheros tocan Auth, Login, Signup, Keychain, Security, CryptoKit, URLSession, APIClient, PrivacyInfo, tracking, IDFA → lanzar `axiom:security-privacy-scanner`. Si no aplica o no disponible, skip silencioso.

### Accessibility auditor (condicional)

Si los ficheros contienen `struct.*: View` → lanzar `axiom:accessibility-auditor`. Informativo, no bloquea. Si no aplica o no disponible, skip silencioso.

### Visual QA (condicional)

Si los ficheros contienen `struct.*: View` Y hay un simulador iOS booted → lanzar DEV-QA. Si AXe no instalado o simulador no booted, skip con WARNING.

## Paso 5 — Informe sintetizado

```
Fase NN — Nombre
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Implementacion:
  Tareas: N/M completadas (K bloqueadas)
  Ficheros creados: [lista]
  Ficheros modificados: [lista]

Verificacion arquitectonica:
  X criticos | Y warnings | Z info

Build & Tests:
  Build: OK/FAIL
  Unit Tests: N passed, N failed, N skipped

Security / Accessibility / Visual QA:
  [Resultados o "Skipped"]

Desviaciones del plan:
  N tareas anadidas | M modificadas | K eliminadas
```

## Paso 6 — Correccion

### Modo interactivo (gate humana)

- **Criticos del verifier**: mostrarmelos, preguntar que quiero hacer ANTES de sugerir commit.
  - Si aprueba fixes → lanzar DEV-IMPLEMENTER en modo fix. Tras fix, re-lanzar DEV-TEST-RUNNER.
- **Test failures**: mostrar, preguntar si quiero que intente arreglar.
- **Warnings sin criticos**: mostrar resumen, preguntar si quiero corregir alguno.
- **Limpio**: continuar.

### Modo --auto (correccion autonoma)

Decide autonomamente segun esta tabla:

| Tipo | Accion |
|------|--------|
| **CRITICO** (verifier) | Siempre corregir |
| **WARNING** (verifier) | Corregir salvo que requiera decision de diseno o sea ambiguo |
| **INFO** (verifier) | Solo reportar |
| **SECURITY critico** | Siempre corregir |
| **SECURITY warning** | Corregir si el fix es claro |
| **Test/Build failure** | Intentar corregir |
| **VISUAL QA critico** | Intentar corregir (crash, pantalla vacia) |
| **VISUAL QA functional FAIL** | Intentar corregir si fix claro |
| **VISUAL QA warning** | Solo reportar en retro |

Lanzar DEV-IMPLEMENTER en modo fix si hay hallazgos a corregir. Si un fix no tiene sentido, marcar `[!]` en el PRP y registrar en retro.

Re-verificacion solo si hubo CRITICOS. Si sigue fallando tras **2 intentos** → fallo irrecuperable.

## Paso 7 — Commit

### Modo interactivo

Proponer mensaje descriptivo (sin referencias a PRP/PRD/fase). NO ejecutar sin confirmacion.

### Modo --auto

Auto-commit:
1. `git add` de ficheros creados/modificados.
2. `git commit -m "<mensaje descriptivo>"` — mensaje describe lo que se hizo.

## Paso 8 — Post-ejecucion (por fase)

1. **Actualizar status en INDEX.md**: Cambiar el status de la fase en la tabla del INDEX a `completed` (o `partial` si hay `[!]`). El INDEX es la fuente de verdad unica para status. NO modificar el frontmatter del PRP.

2. **Generar retrospectiva** (`plan/<feature>/prp-NN-nombre.retro.md`):
   - Errores de envelopes (IMPLEMENTER, VERIFIER, TEST-RUNNER).
   - Decisiones tomadas (gate humana o autonomas).
   - Desviaciones del plan (comparar snapshot).
   - Open issues.
   - Formato: frontmatter yaml + secciones `## Errors Encountered`, `## Plan Deviations`, `## Decisions Made`, `## Open Issues`, `## Fix Loop Summary`.
   - Si no hubo incidencias, retro minima.
   - **Interactivo**: sugerir `/dev-retro NN` para reflexiones humanas.

3. **Re-ingestar PRP y retro en RAG** (si disponible, WARNING si no).

## Paso 9 — Loop (solo --auto)

Si quedan fases pendientes, volver a Paso 2 con la siguiente fase ejecutable del DAG. Si fallo irrecuperable:
1. Parar loop.
2. Reportar fases completadas vs fallida.
3. No hacer merge a develop.
4. Generar retro parcial.

## Paso 10 — Feature completa

Si TODAS las fases tienen status `completed`:

### 10a. Retro consolidada (solo si hubo errores)

Si alguna fase tuvo errores (build failures, test failures, verification criticals, o tareas `[!]`):
- Generar `plan/<feature>/feature.retro.md` mergeando retros con errores.
- **Interactivo**: preguntar al usuario: "Que fue bien?", "Que no fue bien?", "Decisiones clave?", "Lecciones aprendidas?"
- **--auto**: generar automaticamente sin preguntas humanas. Nota: el usuario puede enriquecer con `/dev-retro`.
- Ingestar en RAG si disponible.

Si todas las fases completaron sin errores: skip retro consolidada. Mensaje: "Feature completada sin incidencias."

### 10b. Profiler

Lanzar DEV-PROFILER automaticamente.
- **Interactivo**: si reporta criticos, preguntar si optimizar.
- **--auto**: si reporta criticos, intentar optimizar autonomamente (lanzar DEV-IMPLEMENTER modo fix). Si no hay criticos, solo registrar en retro.

### 10c. Archivado

Actualizar PRD a `completed`, mover `plan/<feature>/` a `plan/_archive/<feature>/`, actualizar INDEX.
- **Interactivo**: confirmar antes de archivar.
- **--auto**: archivar automaticamente.

### 10d. Merge a develop (solo --auto)

1. `git checkout develop && git pull --ff-only`
   Si falla: intentar `git pull --rebase`. Si sigue: parar con mensaje.
2. `git merge --no-ff feature/<slug> -m "Merge <slug>"`
   Si conflictos: `git merge --abort` y parar con mensaje.
3. Verificar merge exitoso con `git log --oneline -1`.
4. Actualizar INDEX: status → `archived`.

### 10e. Informe final

**Interactivo**:
- Que se hizo, ficheros, problemas, tareas bloqueadas.
- Siguiente fase (si quedan).

**--auto**:
```
Build --auto — <feature-slug>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fases completadas: N/N
Commits: N (merged a develop)

Por fase:
  Fase 01 — <nombre>: M tareas, K hallazgos corregidos
  ...

Hallazgos totales:
  Corregidos autonomamente: X
  Descartados: Y
  Tareas [!]: Z

Retro: plan/<feature>/feature.retro.md
```

### 10f. RAG

Ingestar PRPs y retros finales. WARNING si RAG no disponible.

## Notas

- **Interactivo**: si la conversacion es larga, usa `/clear` antes de la siguiente fase. PRPs y retros son el estado persistente.
- **--auto**: sin interaccion humana. Cada decision queda en la retro. Cancelacion con Ctrl+C preserva commits.
