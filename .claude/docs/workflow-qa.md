# Workflow: Build → Test → Visual QA

> Complete workflow for building, testing, and quality assurance.
> Related docs: `performance.md`, `diagnostics.md`, `testing.md`

---

## Pre-PR Checklist con Axiom

> Run these checks before creating a pull request. Adjust based on what changed.

### 1. Build & Test (Always)

```bash
# Build
xcodebuild build -scheme <SCHEME> -destination "platform=iOS Simulator,id=<SIMULATOR_UDID>"

# Run tests
xcodebuild test -scheme <SCHEME> -destination "platform=iOS Simulator,id=<SIMULATOR_UDID>"
```

### 2. Code Quality Audits (Based on Changes)

| If You Changed... | Run This Audit |
|-------------------|----------------|
| **Async/await code** | `/axiom:audit concurrency` |
| **SwiftUI Views** | `/axiom:audit swiftui-performance` |
| **New UI elements** | `/axiom:audit accessibility` |
| **Networking code** | `/axiom:audit networking` |
| **Persistence/Data** | `/axiom:audit core-data` or swiftdata |
| **Memory-sensitive code** | `/axiom:audit memory` |
| **Energy-sensitive code** | `/axiom:audit energy` |

### 3. Visual QA (If UI Changed)

```bash
# Quick screenshot to verify
/axiom:screenshot

# Full visual test flow
/axiom:test-simulator
```

### 4. Pre-Release Audits (Before Major Releases)

| Audit | Command | Purpose |
|-------|---------|---------|
| **Security** | `/axiom:audit security` | Hardcoded secrets, privacy manifests |
| **Performance** | `/axiom:audit swift-performance` | Code-level optimizations |
| **SwiftUI** | `/axiom:audit swiftui-architecture` | Architecture patterns |
| **Testing** | `/axiom:audit testing` | Test quality, flaky tests |

### Quick Parallel Audit (All at Once)

For comprehensive pre-release verification, run audits in parallel:

```bash
# Run multiple audits simultaneously
/axiom:audit concurrency
/axiom:audit swiftui-performance
/axiom:audit accessibility
/axiom:audit security
```

---

## Opción Preferida: Axiom Skills

> **Usa Axiom skills primero** para testing visual. Son más inteligentes y contextuales que comandos raw.

| Acción | Skill |
|--------|-------|
| Screenshot rápido | `/axiom:screenshot` |
| Test visual completo | `/axiom:test-simulator` |
| Debugging iterativo | `axiom:simulator-tester` agent |

Los skills de Axiom automáticamente:
- Usan el UDID correcto del simulador
- Guardan screenshots en ubicaciones consistentes
- Proveen contexto para análisis visual

---

## Fallback: axe CLI

Si necesitas control granular o comandos específicos que Axiom no cubre, usa `axe` directamente.

## Configuración

| Setting | Value |
|---------|-------|
| Simulator UDID | `<SIMULATOR_UDID>` |
| Bundle ID | `<BUNDLE_ID>` |
| Scheme | `<SCHEME>` |

## 1. Build

```
xcodebuild build -scheme <SCHEME> -destination "platform=iOS Simulator,id=<SIMULATOR_UDID>"
```

## 2. Unit Tests

```
xcodebuild test -scheme <SCHEME> -destination "platform=iOS Simulator,id=<SIMULATOR_UDID>"
```

## 3. Visual QA con axe

> **Importante**: Todos los comandos `axe` requieren `--udid <UDID>`

### Variable para simplificar

```bash
UDID="<SIMULATOR_UDID>"
```

### Preparar simulador

```bash
# Listar simuladores disponibles
axe list-simulators

# Lanzar la app
xcrun simctl launch booted <BUNDLE_ID>
```

### Capturar y analizar

```bash
# Screenshot
axe screenshot --udid $UDID --output /tmp/screenshot.png

# Árbol de accesibilidad
axe describe-ui --udid $UDID

# Formato JSON
axe describe-ui --udid $UDID --format json
```

### Interactuar

```bash
# Tap por label de accesibilidad
axe tap --label "Clean Architecture" --udid $UDID

# Tap por coordenadas
axe tap -x 200 -y 300 --udid $UDID

# Scroll up
axe swipe --start-x 200 --start-y 600 --end-x 200 --end-y 200 --udid $UDID

# Scroll down
axe swipe --start-x 200 --start-y 200 --end-x 200 --end-y 600 --udid $UDID

# Escribir texto
axe type "texto" --udid $UDID

# Botones de hardware
axe button home --udid $UDID
```

## Flujo típico de QA

1. **Screenshot inicial**
   ```bash
   axe screenshot --udid <SIMULATOR_UDID> --output /tmp/screen.png
   ```
   Usar `Read tool` para ver `/tmp/screen.png`.

2. **Identificar elementos**
   ```bash
   axe describe-ui --udid <SIMULATOR_UDID>
   ```

3. **Navegar**
   ```bash
   axe tap --label "elemento" --udid <SIMULATOR_UDID>
   ```

4. **Verificar resultado** - Repetir screenshot y Read tool.

## Comandos útiles adicionales

```bash
# Grabar video
axe record-video --udid $UDID output.mp4

# Presionar tecla
axe key return --udid $UDID
```

---

## Troubleshooting

### Build Issues

| Problem | Solution |
|---------|----------|
| Build fails randomly | Run `axiom:build-fixer` agent |
| "No such module" | Clean SPM cache: `rm -rf ~/Library/Caches/org.swift.swiftpm` |
| Zombie processes | `killall xcodebuild` |

See `diagnostics.md` for detailed troubleshooting.

### Test Issues

| Problem | Solution |
|---------|----------|
| Tests fail without clear reason | Run `axiom:test-debugger` agent |
| Flaky tests in CI | Run `axiom:test-failure-analyzer` agent |
| Test timeouts | Check for missing `await`, deadlocks |

See `testing.md` for test patterns.

### Performance Issues

| Problem | Solution |
|---------|----------|
| App is slow | `/axiom:profile` |
| Janky scrolling | `/axiom:audit swiftui-performance` |
| Memory warnings | `/axiom:audit memory` |

See `performance.md` for optimization patterns.

---

## Quick Reference

| Task | Command/Skill |
|------|---------------|
| Screenshot | `/axiom:screenshot` |
| Full visual test | `/axiom:test-simulator` |
| Build check | `axiom:build-fixer` |
| Test debugging | `axiom:test-debugger` |
| Performance profile | `/axiom:profile` |
| Accessibility audit | `/axiom:audit accessibility` |
| Security audit | `/axiom:audit security` |
