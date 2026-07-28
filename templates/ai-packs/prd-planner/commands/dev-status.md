---
description: Muestra el estado actual de implementacion con soporte DAG y archive
allowed-tools: Read, Glob, Grep, Bash
---

Lee el INDEX.md y genera un resumen del estado con formato visual compacto.

## Fuente de verdad

**INDEX.md es la fuente de verdad unica para status de features y fases.** No leer frontmatters de PRPs para determinar status — solo usar la tabla del INDEX.

Los checkboxes de los PRPs (`- [x]`, `- [ ]`, `- [!]`) se usan solo para el detalle de progreso por tarea (barra de progreso).

## Buscar datos

1. Lee `plan/INDEX.md` — tabla de features y tabla de fases por feature
2. Para features activas: lee PRPs para contar checkboxes (progreso por tarea)
3. Busca features archivadas en: `plan/_archive/*/PRD.md`
4. Busca retrospectivas: `plan/*/prp-*.retro.md`

## Datos a recopilar

Para cada feature en el INDEX:
- Nombre de la feature (del INDEX)
- Status de la feature (del INDEX: planned, approved, in-progress, completed, archived)
- Para cada fase (de la tabla de fases del INDEX):
  - Status (del INDEX: pending, completed, partial)
  - Dependencias (del INDEX `Depends on`)
  - Si status es pending/partial: leer el PRP para contar checkboxes y mostrar progreso

## Formato de salida

### Cabecera global (SIEMPRE primero)

```
┌─ <proyecto> ─────────────────────────────────────────────┐
│ Progreso: ▓▓▓▓░░░░░░░░░░░░░░░░ 11/197 (5%)              │
│ Siguiente: <feature> → PRP-NN (+ PRP-MM en paralelo)     │
└──────────────────────────────────────────────────────────┘
```

- Barra de progreso: 20 chars, `▓` = completado, `░` = pendiente
- "Siguiente" = la accion recomendada ahora mismo (fase ejecutable de mayor prioridad)
- Si hay tareas bloqueadas: anadir linea `│ ⚠ N tareas bloqueadas │`

### Features activas

Para cada feature, formato compacto:

```
▸ <feature-slug>                                   done/total

  NN <nombre-fase>       <estado> <barra> done/total  <dag>
```

**Iconos de estado:**
- `○` = ejecutable ahora (sin dependencias bloqueantes)
- `·` = bloqueada (depende de fases no completadas)
- `⟳` = en progreso (tiene algun [x] pero no todos)
- `✓` = completada (todas [x])

**Barra de progreso por fase:**
- 5 chars: `░░░░░` (0%), `▓░░░░` (20%), `▓▓▓░░` (60%), `▓▓▓▓▓` (100%)

**DAG inline** a la derecha (solo para fases con dependencias):
- Mostrar dependencias compactas: `01,02→03`, `03→04`, etc.
- Si una fase es paralelizable, agrupar con `┐` y `┘`

### Ejemplo completo

```
┌─ MiProyecto ─────────────────────────────────────────────┐
│ Progreso: ▓▓▓▓▓▓▓▓░░░░░░░░░░░░ 11/28 (39%)              │
│ Siguiente: auth-system → PRP-03 Components                │
└──────────────────────────────────────────────────────────┘

▸ auth-system                                      11/28
  01 Domain              ✓ ▓▓▓▓▓ 6/6
  02 Data                ⟳ ▓▓▓░░ 5/7  (1 bloq)    01→02
  03 Components          ○ ░░░░░ 0/6               01→03  ┐ paralelo
  04 UI                  · ░░░░░ 0/5               02,03→04
  05 Tests               · ░░░░░ 0/4               04→05  ┘

  Bloqueadas:
    02.6: "Esperando definicion de API v2"

  Retros: 01 ✓ (2 errores, 0 open) │ 02 parcial (1 open)
  Open: "NetworkClient retry needs exponential backoff"

▸ onboarding                                       0/15
  01 Screens             ○ ░░░░░ 0/5
  02 Logic               · ░░░░░ 0/5               01→02
  03 Tests               · ░░░░░ 0/5               02→03

Archivadas: core-data ✓ │ settings ✓
.dev/: ✓ (2026-03-20)
Git: 1 fichero modificado
```

### Criterios pendientes

Para cada PRP con todas las tareas `[x]` (completada):
- Lee la seccion "Criterios de hecho" o "Criterios de aceptacion" del PRP
- Si hay criterios `[ ]` sin marcar, muestra alerta:

```
  ⚠ Criterios pendientes:
    02 Data: 2 sin marcar → Tests integracion, Docs API
```

Si no hay criterios pendientes, omite.

### Sugerencias

Detecta y muestra al final:

```
  Sugerencias:
    → /dev-archive auth-system (completada, sin archivar)
    → /dev-retro 03 (completada, sin retro)
```

- Features completadas sin archivar → sugiere `/dev-archive <slug>`
- Fases completadas sin retro → sugiere `/dev-retro <NN>`
- Si no hay sugerencias, omite la seccion

### Git diff

Si es repo git, una linea al final:
- `Git: limpio` o `Git: N ficheros modificados`

### Estado de .dev/

Una linea compacta:
- `.dev/: ✓ (YYYY-MM-DD)` o `.dev/: ✗ no generado → /dev-init`

## Reglas

- Si no hay PRPs en `plan/`, indica que no hay plan y sugiere `/dev-prd` y `/dev-plan`.
- **Compacto siempre.** Sin lineas vacias innecesarias, sin explicaciones.
- La cabecera con "Siguiente" es lo MAS importante — va primero.
- Alinear columnas para legibilidad.
- Retrospectivas y open issues: inline con la feature, no en seccion separada.
