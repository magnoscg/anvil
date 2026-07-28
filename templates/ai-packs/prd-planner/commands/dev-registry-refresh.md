---
description: Regenera el registro de skills disponibles
---

1. Re-escanea todas las fuentes de skills:
   - Axiom Skills (tabla hardcoded de 17 skills en `/dev-init`)
   - Skills locales (`~/.claude/skills/*/`)
   - Skills de proyecto (`.claude/skills/*/`)
   - Tutorials (`~/.claude/tutorials/*/` — solo conteo)
2. Reescribe `.dev/skill-registry.md` con la fecha actual.
3. Muestra el nuevo registry.
