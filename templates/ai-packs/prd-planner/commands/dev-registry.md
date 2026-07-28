---
description: Muestra el registro de skills disponibles
---

$ARGUMENTS

## Sin argumentos — Mostrar registry

1. Lee `.dev/skill-registry.md`.
   - Si no existe, generalo primero (sigue los pasos de generacion de `/dev-init`).
2. Muestra el contenido formateado.

## Con argumento "search <termino>" — Buscar skill

1. Lee `.dev/skill-registry.md`.
2. Busca el termino en triggers, nombres y descripciones.
3. Muestra las skills que coinciden.

> Para regenerar el registry usa `/dev-registry-refresh`.
