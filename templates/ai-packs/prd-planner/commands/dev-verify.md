---
description: Verifica el codigo contra las reglas de arquitectura (lanza agente DEV-VERIFIER)
---

Lanza el agente `DEV-VERIFIER` para verificar el codigo.

## Determinar scope

$ARGUMENTS

- Sin argumentos: todos los `.swift` en Domain/, Data/, Features/ del proyecto.
- Numero (ej: `/dev-verify 2`): lee `plan/<feature>/prp-02-*.md` (o `plan/prp-02-*.md` legacy) y extrae ficheros mencionados.
- `all`: todos los `.swift` del proyecto incluyendo Core/ y App/.

## Cargar arch-index

Lee `.dev/arch-index.md` si existe. Incluirlo en el prompt del agente.

## Lanzar agente

Usa Glob para obtener la lista de ficheros del scope.
Luego lanza el agente `DEV-VERIFIER` usando el tool Agent con:
- `subagent_type: "DEV-VERIFIER"`
- `prompt`: "Verifica los siguientes ficheros: [LISTA]. Directorio de trabajo: [CWD]. arch-index: [contenido de .dev/arch-index.md si existe]"

## Mostrar resultado

Muestra el informe completo del agente al usuario.

**NUNCA corrijas hallazgos automaticamente.** El informe es informativo — toda correccion requiere aprobacion explicita del usuario.

- Criticos: "Hay N violaciones criticas. Quieres que corrija alguna? Dimme cuales."
- Solo warnings: "Hay N warnings. Quieres corregir alguno o continuar?"
- Limpio/info: "Codigo alineado con la arquitectura."

Si el usuario aprueba correcciones, lanza DEV-IMPLEMENTER en modo fix:
```
Agent(
  subagent_type: "DEV-IMPLEMENTER",
  prompt: "MODO FIX — Aplica estos fixes aprobados: <lista de hallazgos>
           arch-index path: .dev/arch-index.md
           CWD: <directorio actual>"
)
```
