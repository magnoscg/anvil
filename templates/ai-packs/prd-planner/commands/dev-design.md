---
description: Crea disenos visuales en Paper MCP o Figma Desktop (Vibma) — mockups, variaciones de estilo, y flujos completos con UX Pro Max + Axiom skills
---

Crear disenos visuales para: $ARGUMENTS

## Paso 0 — Parsear argumentos

Interpretar `$ARGUMENTS`:

- **Descripcion de pantalla**: "login screen", "pantalla de perfil", "dashboard de metricas"
- **Numero de variaciones**: buscar "N opciones", "N direcciones", "N variaciones" (default: 1)
- **Plataforma**: buscar "mobile", "tablet", "desktop", "iPad" (default: mobile 390x844)
- **Estilo especifico**: buscar "Liquid Glass", "minimal", "brutalist", etc.
- **Herramienta**: buscar "paper", "figma", "en figma", "en paper" (default: auto-detectar)
- **Referencia Figma**: buscar URL figma.com
- **Referencia codigo**: buscar path a fichero .swift existente

Ejemplos:
- `/dev-design login screen` → 1 direccion mobile, auto-detectar herramienta
- `/dev-design 3 opciones para pantalla de perfil` → 3 direcciones mobile
- `/dev-design dashboard tablet en figma` → 1 direccion tablet en Figma Desktop
- `/dev-design onboarding flow 2 variaciones Liquid Glass` → 2 direcciones mobile con estetica Liquid Glass
- `/dev-design en paper pantalla de settings` → forzar Paper como herramienta
- `/dev-design desde figma.com/design/abc...` → importar referencia Figma

## Paso 1 — Contexto del proyecto

Si hay un proyecto iOS en el directorio actual:
1. Leer CLAUDE.md para entender tipo de app, marca, stack
2. Si hay `.dev/` con arch-index o skill-registry, leerlos para entender la arquitectura
3. Si el usuario referencio un fichero .swift, leerlo para entender el diseno actual

Si no hay proyecto: el agente trabaja solo con la descripcion textual.

## Paso 2 — Lanzar DEV-DESIGNER

```
Agent(
  subagent_type: "DEV-DESIGNER",
  prompt: "Crea disenos visuales.

           HERRAMIENTA: <paper|figma|auto> (si el usuario especifico una, pasarla; si no, 'auto' para que DEV-DESIGNER detecte y pregunte si ambas estan disponibles)
           SOLICITUD: <descripcion parseada de $ARGUMENTS>
           VARIACIONES: <N>
           PLATAFORMA: <mobile|tablet|desktop> (<ancho>x<alto>)
           ESTILO: <estilo especifico si se indico, o 'libre'>

           CONTEXTO DEL PROYECTO:
           <contenido de CLAUDE.md si existe, o 'No hay proyecto asociado'>

           CODIGO EXISTENTE (si aplica):
           <contenido del fichero .swift referenciado, o 'No hay referencia de codigo'>

           REFERENCIA FIGMA (si aplica):
           <URL Figma, o 'No hay referencia Figma'>

           Sigue tu workflow completo: elegir herramienta → contexto → skills → brief → construir incremental → validar → presentar."
)
```

## Paso 3 — Presentar resultado

Mostrar el resultado del DEV-DESIGNER tal cual lo devuelve:

- Screenshots/exports de cada direccion
- Design briefs con paletas y tipografia
- Herramienta utilizada (Paper o Figma)
- Recomendaciones de uso por direccion (si multiples)

## Paso 4 — Acciones post-diseno

Preguntar al usuario:

- **Si multiples direcciones**: "Cual direccion quieres refinar? O quieres combinar elementos de varias?"
- **Refinamiento**: Si el usuario pide cambios, re-lanzar DEV-DESIGNER con feedback especifico
- **Implementar**: Si el usuario quiere pasar a codigo, sugerir: "Puedo lanzar DEV-UI-ENGINEER para traducir este diseno a SwiftUI. Quieres proceder?"
