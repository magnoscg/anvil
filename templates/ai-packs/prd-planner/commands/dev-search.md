---
description: Busca PRDs y PRPs anteriores en el RAG
---

Busca en el RAG: $ARGUMENTS

## Pasos

1. Usa `query_documents` con el query del usuario.
   - Limit: 10 (balance entre precision y cobertura)
   - Si los resultados tienen score > 0.5, intenta query expansion: manten el termino original y anade 2-4 variantes (sinonimos, abreviaturas, terminos relacionados).

2. Presenta los resultados agrupados por documento (usa fileTitle):
   - Proyecto y feature (del frontmatter si disponible)
   - Score (relevancia)
   - Fragmento relevante (chunk)
   - Tipo: PRD o PRP (del frontmatter si disponible)

3. Si no hay resultados, sugiere terminos alternativos basados en la query original.

4. Si el RAG no esta disponible (el tool `query_documents` no existe), informa al usuario: "El RAG no esta configurado en este proyecto. Anade mcp-local-rag con /mcp."

## Interpretacion de scores

| Score | Significado |
|-------|-------------|
| < 0.3 | Muy relevante, usar directamente |
| 0.3-0.5 | Relevante si menciona el mismo concepto |
| > 0.5 | Poco relevante, omitir salvo que no haya mejores |

## Ejemplos de uso
- `/dev-search autenticacion OAuth` — buscar PRDs que trataron auth
- `/dev-search pantalla de onboarding` — buscar disenos previos de onboarding
- `/dev-search API paginacion` — buscar como se resolvio paginacion antes
- `/dev-search project:CholloGas` — buscar todo de un proyecto especifico
- `/dev-search retro build error SwiftData` — buscar sesiones que tuvieron errores de build con SwiftData
- `/dev-search retro test failure async` — buscar sesiones con fallos en tests async
- `/dev-search retro desviacion plan` — buscar sesiones donde el plan cambio durante ejecucion
