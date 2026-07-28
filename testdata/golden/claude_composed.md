# CLAUDE.md — Repository Guide for Claude

> Persistent context to maintain technical and style consistency in this iOS project.

## Project Summary

- **Platform**: iOS **18.0+** Swift 6
- **UI**: **SwiftUI** (Views only)
- **State / Observation**: **Observation** (`@Observable`)
- **Architecture**: **MVVM + Router + Clean Architecture** (Feature-based)
- **Persistence**: **SwiftData** (only in **Data** layer) using `ModelExecutor`
- **Testing**: **Swift Testing** (`import Testing`) mapped to `Tests/Features`, `Tests/Domain`, `Tests/Data`

## Build & Test

### Project Configuration

| Setting | Value |
|---------|-------|
| Project | `MyApp.xcodeproj` |
| Scheme | `MyApp-Dev` |
| Bundle ID | `com.testorg.MyApp` |

### Quick Commands

| Action | Command |
|--------|---------|
| **Build** | `xcodebuild build -scheme MyApp-Dev -destination "platform=iOS Simulator,name=iPhone 16 Pro"` |
| **Unit Tests** | `xcodebuild test -scheme MyApp-Dev -destination "platform=iOS Simulator,name=iPhone 16 Pro"` |
| **Launch app** | `xcrun simctl launch booted com.testorg.MyApp` |

## Non-negotiable Rules

### Layers (Clean)

- **Domain** layer is global: `Domain/<Feature>/` contains:
  - `Models/` — Domain models (e.g., `<Feature>Model.swift`)
  - `UseCases/` — Protocol + Implementation (e.g., `<Feature>UseCase.swift`, `<Feature>UseCaseImpl.swift`)
- **Data** layer is global: `Data/<Feature>/` contains:
  - `Repositories/` — Protocol + Implementation together
  - `DataSources/` — Remote and Local data sources
  - `DTO/` — Data Transfer Objects
  - `Mappers/` — DTO <-> Model transformations
- **Features** contain presentation only:
  - `DI/` — Factory
  - `UI/` — Views, State enum, Decorators, Components
  - `Presentation/ViewModels/` — ViewModels
  - `Presentation/Mappers/` — DecoratorMapper (Domain -> UI)
  - `Navigation/` — Router (with Route enum inside) and, only when needed, RouteResolver

### File Naming Convention

**IMPORTANT**: All files related to a feature must start with the feature name.

| Type | Pattern | Example |
|------|---------|---------|
| Domain Model | `<Feature>Model.swift` | `ArticleModel.swift` |
| UseCase Protocol | `<Feature>UseCase.swift` | `ArticleUseCase.swift` |
| UseCase Impl | `<Feature>UseCaseImpl.swift` | `ArticleUseCaseImpl.swift` |
| Repository Protocol | `<Feature>Repository.swift` | `ArticleRepository.swift` |
| Repository Impl | `<Feature>RepositoryImpl.swift` | `ArticleRepositoryImpl.swift` |
| Remote DataSource | `<Feature>RemoteDataSource.swift` | `ArticleRemoteDataSource.swift` |
| DTO | `<Feature>DTO.swift` | `ArticleDTO.swift` |
| DTOMapper | `<Feature>DTOMapper.swift` | `ArticleDTOMapper.swift` |
| View | `<Feature>View.swift` | `ArticleView.swift` |
| State | `<Feature>State.swift` | `ArticleState.swift` |
| Decorator | `<Feature>Decorator.swift` | `ArticleDecorator.swift` |
| ViewModel | `<Feature>ViewModel.swift` | `ArticleViewModel.swift` |
| DecoratorMapper | `<Feature>DecoratorMapper.swift` | `ArticleDecoratorMapper.swift` |
| Router | `<Feature>Router.swift` | `ArticleRouter.swift` |
| Optional RouteResolver | `<Feature>RouteResolver.swift` | `ArticleRouteResolver.swift` |
| Factory | `<Feature>Factory.swift` | `ArticleFactory.swift` |

### Struct vs Class

- **Prefer `struct`** for UseCases, Repositories, and DataSources that are **stateless** (no internal mutable state).
- Use `class` only when you need shared mutable state (e.g., in-memory cache) or reference semantics.
- ViewModels remain `@Observable class` because they need identity and reactive state.

### Code Organization

- **Comments always in English**: All code comments, documentation, and MARK sections must be written in English.
- **MARK comments required**: Use `// MARK: - <Section>` to organize all code sections in all files (Properties, Init, Body, Methods, Extensions, etc.).
- **No inline code comments**: NEVER add comments explaining functions, variables, or code inside function bodies. Names must be self-explanatory. Only `///` doc comments on `struct`, `class`, `enum`, or `protocol` declarations are allowed (to explain the type's purpose). No comments inside method scope.
- **One View per file**: each SwiftUI View in its own `.swift` file.
- **Custom ViewModifiers**: **all** in `Core/Common/SwiftUI/Modifiers/`, never inline in Views.
- **@ViewBuilder helpers**: in `Core/Common/SwiftUI/Builders/`.
- **Private subviews** (< 15 lines): can be in the same file marked `private`.
- **Feature components**: in `Features/<Feature>/UI/Components/`.
- **IMPORTANT - Don't use `Protocol` suffix** in protocols — it's redundant, use base name.

### ViewModel State

- **State enum** in `UI/<Feature>State.swift` — only states (idle/loading/loaded/error).
- **Decorators** in `UI/<Feature>Decorator.swift` — UI models (section, item, error).
- **NO Action/Event enums** — actions are handled as direct methods in ViewModel.
- **DecoratorMapper** in `Presentation/Mappers/` — protocol + impl for Domain -> UI mapping.

### Concurrency

- ViewModels are **@MainActor** with `async` API for loading/updating.
- UseCases/Repos are **NOT** `@MainActor`; when they need SwiftData they must operate with their own isolated `ModelExecutor`/`ModelActor`, never with the main `ModelContext`.
- Each SwiftData repository creates or receives a dedicated `ModelExecutor` (e.g., `DefaultSerialModelExecutor`) configured when initializing the container; don't access the global `modelContext` in background.
- `Core/Persistence/ModelContainer+Shared.swift` exposes a `SwiftDataStack` that lives in `App/DI` and generates the `ModelExecutor` instances that factories inject into each repository.
- Propagate cancellation (don't swallow `CancellationError`).

### Errors

- Avoid `try?` / empty `catch {}` without justification.
- Prefer typed errors over loose `String` when useful.
- Map errors between layers: `APIError` -> `DomainError` -> `ErrorDecorator`.

### Memory (closures)

- Use `[weak self]` **only** in **escaping closures** that capture a **class** and can outlive the scope (callbacks, timers, notifications, Combine, stored `Task`, etc.).
- Don't use `weak self` by default in non-escaping closures.

### SwiftUI

- Keep `body` small: extract to subviews / helpers if it grows.
- No business logic in Views.
- Use `.task(id:)` to load data, not loose `Task { }`.

### Localization

- Strings go to **String Catalog** (no hardcoded literals in UI).
- Use `String(localized:)` for programmatic strings.
- If String Catalog does not exist, create it.

### Router (Type-erased Pattern)

- `AppRouter` protocol in `App/Navigation/AppRouter.swift`, implementation in `AppRouterImpl.swift`.
- `AppRouter.push<R: Hashable>(_ route: R)` accepts **any** route type — it does NOT know about specific feature routes.
- Each feature always has `Features/<Feature>/Navigation/<Feature>Router.swift`:
  - Route enum + protocol + impl in one file
- Add `Features/<Feature>/Navigation/<Feature>RouteResolver.swift` only when the feature owns subroutes that must be resolved into views from the app root or a `NavigationStack`.
- Features register their resolver in the app root only when that resolver exists.
- ViewModels depend only on their `FeatureRouter` protocol, NOT on AppRouter directly.
- If a feature only forwards to an already registered route, keep that logic inside `<Feature>Router.swift` and skip a resolver file.
- **Factory + @State pattern**: when a RouteResolver exists, it calls Factory to create ViewModel and the View uses `@State` to preserve it.
- **Why @State**: Without it, navigation back recreates View -> Factory creates NEW ViewModel -> state lost.

## Anti-patterns to Avoid

### Architecture
- **Don't create `Singleton`** for repos/use cases — use Dependency Injection.
- **Don't put `import SwiftData`** in Domain or Presentation.
- **Don't mix DTOs with Models** — always map between layers.
- **Don't access network/persistence** from ViewModels directly.
- **Don't put Repository protocol in Domain** — it goes in `Data/<Feature>/Repositories/`.
- **Don't use boolean app state** (`isLoggedIn`, `hasOnboarded`) — use enum state machine.
- **Don't put business logic in `@main`** — delegate to `AppStateController`.

### SwiftUI & State
- **Don't use `@Published`** — that's Combine, use `@Observable`.
- **Don't use `@StateObject` / `@ObservedObject`** — they're from the old paradigm.
- **Don't use loose `Task { }`** in Views — use `.task(id:)`.
- **Don't put ViewModifiers inline** — extract to `Core/Common/SwiftUI/Modifiers/`.
- **Don't put multiple public Views** in the same file.
- **Don't put State inside ViewModel** — separate into `UI/<Feature>State.swift`.
- **Don't create Action/Event enums** — actions are direct ViewModel methods.
- **Don't create custom Dark Mode toggle** — respect system preference.

### Concurrency (Swift 6)
- **Don't pass SwiftData models between actors** — pass IDs, fetch on target context.
- **Don't use `@Query` in ViewModels** — only in Views if needed, or use Repository.
- **Don't silence errors** with `try?` or empty `catch {}`.
- **Don't forget Sendable on protocols** — mappers, use cases, repos need `: Sendable`.

### Navigation
- **Don't create global route enum** — each feature defines its own routes inside Router.swift.
- **Don't add RouteResolver by default** — use Router.swift always, add RouteResolver.swift only when the feature resolves its own destinations.
- **Don't split simple navigation into extra files** — if a feature only pushes an existing route, Router.swift is enough.
- **Don't forget `Codable` on Route enums** — required for state preservation.

### Code Style
- **Don't omit MARK comments** — always organize with `// MARK: -`.
- **Don't use `Protocol` suffix** in protocols — it's redundant, use base name.
- **Don't omit `Impl` suffix** in protocol implementations.
- **Don't write comments in Spanish** — always in English.

## Reference Docs (read before implementing)

> Docs are in `.claude/docs/`. **Use Read tool** to read them before each task.

### Core Architecture

| Doc | When to read |
|-----|--------------|
| `.claude/docs/ARCHITECTURE.md` | Understand layers, mappers, and error flow |
| `.claude/docs/PROJECT-STRUCTURE.md` | Know where to create each file |
| `.claude/docs/new-feature.md` | Checklist when creating a new feature |

### UI & SwiftUI

| Doc | When to read |
|-----|--------------|
| `.claude/docs/swiftui-code-style.md` | Before creating/modifying Views or ViewModels |
| `.claude/docs/design-system.md` | HIG compliance, colors, typography, accessibility |

### Concurrency & Performance

| Doc | When to read |
|-----|--------------|
| `.claude/docs/swift-concurrency.md` | Swift 6 strict concurrency, Sendable, actors |
| `.claude/docs/performance.md` | Profiling, optimization, memory management |

### Data & Networking

| Doc | When to read |
|-----|--------------|
| `.claude/docs/swiftdata.md` | SwiftData persistence patterns |
| `.claude/docs/networking.md` | URLSession, async networking, error handling |

### Security & Diagnostics

| Doc | When to read |
|-----|--------------|
| `.claude/docs/security-privacy.md` | Privacy Manifests, Keychain, secure storage |
| `.claude/docs/diagnostics.md` | Crash analysis, build optimization, troubleshooting |

### Testing & QA

| Doc | When to read |
|-----|--------------|
| `.claude/docs/testing.md` | Before writing tests |
| `.claude/docs/create-tests.md` | Quick test templates |

## How to Work

> **MANDATORY**: Before implementing any task, you **MUST use the Read tool** to read the relevant doc from `.claude/docs/`. It's not enough to "know" it exists — read it in each session.

When implementing something:

1. **Read with Read tool** the relevant doc from the table above (they're in `.claude/docs/`).
2. **Read with Read tool** `PROJECT-STRUCTURE.md` to know where to create files.
3. **Explain** which files you'll touch/create and why (max 5-8 bullets).
4. **Implement** with minimal changes consistent with the architecture.
5. **Include** previews (if UI) and tests (if logic).

## Regla de oro
Si algo es ambiguo o hay mas de una forma razonable de implementarlo:
**para y preguntame antes de decidir.**

Pregunta especialmente cuando:
- Hay dos enfoques posibles
- Necesitas cambiar algo fuera del PRP actual
- Necesitas anadir una dependencia nueva
- Un fichero previsto no existe

## Workflow de desarrollo
Este proyecto usa PRD -> PRP para planificar features.
- Documentos en `/plan`
- Comandos: `/dev-prd`, `/dev-plan`, `/dev-build`, `/dev-design`, `/dev-status`, `/dev-verify`, `/dev-ff`, `/dev-build-yolo`, `/dev-qa`, `/dev-profile`, `/dev-retro`, `/dev-archive`, `/dev-registry`, `/dev-init`, `/dev-search`, `/dev-registry-refresh`
- No escribas codigo sin PRP aprobado
- Marca checkboxes (`- [x]`) conforme completes tareas
- Si una tarea queda bloqueada, marca `- [!]` con motivo
- Features completadas se archivan en `plan/_archive/`
- `.dev/` contiene indices generados (arch-index, skill-registry, ast-patterns)

### Comandos disponibles

| Comando | Proposito |
|---------|-----------|
| `/dev-prd <descripcion>` | Co-crear un PRD para una feature |
| `/dev-plan` | Generar PRPs (planes por fases) a partir del PRD |
| `/dev-build [N]` | Ejecutar la siguiente fase pendiente (o la fase N) |
| `/dev-design [desc]` | Crea disenos visuales en Paper MCP / Figma |
| `/dev-status` | Ver el estado actual de implementacion |
| `/dev-search <query>` | Buscar PRDs/PRPs anteriores en el RAG |
| `/dev-verify [N\|all]` | Verificar el codigo contra la arquitectura |
| `/dev-ff <descripcion>` | Fast-forward: PRD + plan + build en un paso (bugfixes) |
| `/dev-build-yolo` | Build YOLO — ejecuta /dev-build --auto para todas las features |
| `/dev-qa [target]` | QA visual y funcional completo con AXe |
| `/dev-profile [target]` | Perfilar la feature actual con xctrace |
| `/dev-retro [N]` | Genera retrospectiva para una fase completada |
| `/dev-archive [slug]` | Archiva una feature completada |
| `/dev-registry` | Ver el registro de skills disponibles |
| `/dev-registry-refresh` | Regenerar el registro de skills desde cero |
| `/dev-init` | Inicializar el workflow PRD en el proyecto |

### Flujo de trabajo

1. **Definir** -- `/dev-prd` para crear PRD en `plan/<feature>/PRD.md`
2. **Planificar** -- `/dev-plan` para generar PRPs en `plan/<feature>/prp-*.md`
3. **Disenar** -- `/dev-design` para crear mockups visuales (Paper MCP / Figma)
4. **Construir** -- `/dev-build` para ejecutar fase a fase
5. **Verificar** -- `/dev-status` para ver progreso
6. **Buscar** -- `/dev-search` para encontrar PRDs/PRPs de otros proyectos
7. **Auditar** -- `/dev-verify` para verificacion arquitectonica
8. **Fast-forward** -- `/dev-ff` para bugfixes rapidos (PRD+plan+build en un paso)
9. **QA Visual** -- `/dev-qa` para testing visual automatizado con AXe
10. **Perfilar** -- `/dev-profile` para analisis de rendimiento

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
