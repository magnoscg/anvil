# CLAUDE.md — Repository Guide for Claude

> Persistent context to maintain technical and style consistency in this iOS project.

## Project Summary

- **Platform**: iOS **18.0+** Swift 6.0
- **UI**: **SwiftUI** (Views only)
- **State / Observation**: **Observation** (`@Observable`)
- **Architecture**: **MVVM + Router + Clean Architecture-inspired layers** (Feature-based, single app target)
- **Concurrency**: `SWIFT_STRICT_CONCURRENCY = complete`, **no** default actor isolation (types are nonisolated unless annotated)
- **Dependency Injection**: manual constructor injection through `AppDependencies` + per-feature Factories (no DI container)
- **Persistence**: **none** — the SwiftData stack was not generated for this project
- **Testing**: **Swift Testing** (`import Testing`) in `MyAppTests/`, mirroring `Domain/`, `Data/` and `Features/`, plus shared `Mocks/`

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

### Layers (Clean Architecture-inspired)

- **App** (`App/`) — composition root and app-lifetime concerns:
  - `Application/AppMain.swift` — `@main`; creates `AppDependencies` and `AppRouterImpl`
  - `Config/` — `AppDependencies`, `AppEnvironment`, `EnvironmentConfiguration`, `Xcconfig/`
  - `Navigation/` — `AppRouter`, `AppRouterImpl`, `RootNavigationView`, `AppNavigationCoordinator`
- **Core** (`Core/`) — shared infrastructure, no feature knowledge:
  - `Networking/` — `APIClient` + `APIClientImpl`, endpoints, `APIError`, interceptors, retry
  - `Common/` — extensions, `Models/ErrorDecorator.swift`, `SwiftUI/{Builders,Components,Modifiers}/`
  - `DesignSystem/Tokens/` — colors, typography, spacing, icons
  - `Security/` — `KeychainHelper`
- **Domain** layer is global: `Domain/<Feature>/` contains:
  - `Models/` — Domain models (e.g., `<Feature>Model.swift`)
  - `UseCases/` — Protocol + Implementation in separate files (`<Feature>UseCase.swift`, `<Feature>UseCaseImpl.swift`)
  - `Domain/Common/` — `DomainError` and `DomainErrorMapping`
- **Data** layer is global: `Data/<Feature>/` contains:
  - `Repositories/` — Repository **protocol** and its Impl, in separate files (the protocol lives here, not in Domain — see Known Deviations)
  - `DataSources/` — Remote data source, plus optional Local (UserDefaults) and Keychain data sources (protocol + Impl in the same file)
  - `DTO/` — Data Transfer Objects
  - `Mappers/` — DTO -> Model transformations (protocol + Impl in the same file)
- **Features** contain presentation only:
  - `DI/` — Factory
  - `UI/` — Views, State enum, Decorators, Components
  - `Presentation/ViewModels/` — ViewModels
  - `Presentation/Mappers/` — DecoratorMapper (Domain -> UI, protocol + Impl in the same file)
  - `Navigation/` — Router (with Route enum inside) and, only when needed, RouteResolver
- Layers are **folders in one app target**, not modules: the compiler does not enforce the dependency direction, so review must.

### Known Deviations from Strict Clean Architecture

These are deliberate, project-wide choices. Follow them consistently; changing any of them is a project-wide refactor, never a per-feature decision.

- **Repository protocols live in `Data/<Feature>/Repositories/`**, so `<Feature>UseCaseImpl` (Domain) depends on a Data contract.
- **`DomainError.map(_:)` knows `APIError`** (`Domain/Common/DomainErrorMapping.swift`), so Domain is not transport-independent.
- **`ErrorDecorator` lives in `Core/Common/Models/`** even though it is a presentation type.

### Dependency Injection

- `AppDependencies` (`App/Config/AppDependencies.swift`) holds app-lifetime dependencies (the shared `APIClient`). It is created once in `@main`.
- Each feature has a `@MainActor enum <Feature>Factory` with `static func makeView(appRouter:dependencies:)`. Private `make*` helpers build DataSource -> Mapper -> Repository -> UseCase -> DecoratorMapper -> Router -> ViewModel -> View.
- Factories build a new graph per screen. Keep constructors cheap: no file I/O, decoding or network work in `init` (see Factory + @State below).

### File Naming Convention

**IMPORTANT**: All files related to a feature must start with the feature name. UseCase and Repository protocols and their `Impl` go in **separate files**. DataSources, DTOMappers, DecoratorMappers and the Router keep protocol and `Impl` in **one file**.

| Type | Pattern | Example |
|------|---------|---------|
| Domain Model | `<Feature>Model.swift` | `ArticleModel.swift` |
| UseCase Protocol | `<Feature>UseCase.swift` | `ArticleUseCase.swift` |
| UseCase Impl | `<Feature>UseCaseImpl.swift` | `ArticleUseCaseImpl.swift` |
| Repository Protocol | `<Feature>Repository.swift` | `ArticleRepository.swift` |
| Repository Impl | `<Feature>RepositoryImpl.swift` | `ArticleRepositoryImpl.swift` |
| DataSource (protocol + Impl) | `<Feature><Kind>DataSource.swift` (`Remote`, `Local`, `Keychain`) | `ArticleRemoteDataSource.swift` |
| DTO | `<Feature>DTO.swift` | `ArticleDTO.swift` |
| DTOMapper (protocol + Impl) | `<Feature>DTOMapper.swift` | `ArticleDTOMapper.swift` |
| View | `<Feature>View.swift` | `ArticleView.swift` |
| State | `<Feature>State.swift` | `ArticleState.swift` |
| Decorator | `<Feature>Decorator.swift` | `ArticleDecorator.swift` |
| ViewModel | `<Feature>ViewModel.swift` | `ArticleViewModel.swift` |
| DecoratorMapper (protocol + Impl) | `<Feature>DecoratorMapper.swift` | `ArticleDecoratorMapper.swift` |
| Router | `<Feature>Router.swift` | `ArticleRouter.swift` |
| Optional RouteResolver | `<Feature>RouteResolver.swift` | `ArticleRouteResolver.swift` |
| Factory | `<Feature>Factory.swift` | `ArticleFactory.swift` |
| Optional Accessibility IDs | `<Feature>AccessibilityID.swift` | `ArticleAccessibilityID.swift` |
| Test Mock | `Mocks/<Feature><Type>Mock.swift` (test target) | `ArticleRouterMock.swift` |

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

- The target builds with `SWIFT_STRICT_CONCURRENCY = complete` and **no** default actor isolation: types are nonisolated unless annotated. Don't add `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` without revisiting these rules.
- ViewModels, Routers, Factories, `AppRouter` and `AppNavigationCoordinator` are explicitly `@MainActor`.
- ViewModels are `@MainActor @Observable final class` with `private(set) var state` and an `async` API for loading/updating.
- UseCases, Repositories, DataSources and mappers are **NOT** `@MainActor`: they are `struct`s conforming to `Sendable` protocols.
- Propagate cancellation:
  - UseCases and Repositories rethrow `CancellationError` before handling any other error.
  - ViewModels restore the previous state on cancellation instead of showing an error.
  - A cancelled `URLSession` request surfaces as `URLError.cancelled`. Treat it as cancellation, not as a network error.

### Errors

- Avoid `try?` / empty `catch {}` without justification. Don't turn a load failure into an empty result: it later surfaces as "not found" instead of an error.
- Prefer typed errors over loose `String` when useful.
- Map errors between layers: `APIError` -> `DomainError` -> `ErrorDecorator`:
  - Data throws `APIError` (from `APIClient`).
  - `<Feature>UseCaseImpl` catches and converts with `DomainError.map(_:)`.
  - The ViewModel converts with `ErrorDecorator.from(_:)` and sets `state = .error(...)`.

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

- `AppRouter` protocol in `App/Navigation/AppRouter.swift`, implementation in `AppRouterImpl.swift` (`@MainActor @Observable`, owns a single `NavigationPath`).
- `AppRouter.push(_ route: some Hashable & Codable)` accepts **any** route type — it does NOT know about specific feature routes.
- Each feature always has `Features/<Feature>/Navigation/<Feature>Router.swift`:
  - Route enum (`Hashable, Codable`) + `@MainActor` protocol + `struct ...RouterImpl` that delegates to `AppRouter`, in one file
- Add `Features/<Feature>/Navigation/<Feature>RouteResolver.swift` only when the feature owns subroutes that must be resolved into views from the app root or a `NavigationStack`. It is a `ViewModifier` plus a `View.with<Feature>Routes(appRouter:dependencies:)` extension.
- Features register their resolver in `App/Navigation/RootNavigationView.swift`, only when that resolver exists.
- Deep links are parsed in `App/Navigation/AppNavigationCoordinator.swift`. It also persists the path to `@SceneStorage` with a debounce. A new deep-linkable route is added there.
- ViewModels depend only on their `FeatureRouter` protocol, NOT on AppRouter directly.
- If a feature only forwards to an already registered route, keep that logic inside `<Feature>Router.swift` and skip a resolver file.
- **Factory + @State pattern**: when a RouteResolver exists, it calls the Factory inside `navigationDestination`, and the View stores the ViewModel with `@State` (`State(initialValue:)` in `init`).
- **Why @State**: Without it, navigation back recreates View -> Factory creates NEW ViewModel -> state lost.
- **Cost of the pattern**: SwiftUI can call the destination closure, and therefore the Factory, many times. `@State` keeps only the first ViewModel and the rest are built and thrown away, so Factories and the `init`s they call must stay cheap (no I/O or decoding).

## Anti-patterns to Avoid

### Architecture
- **Don't create `Singleton`** for repos/use cases — use Dependency Injection.
- **Don't put `import SwiftData`** in Domain or Presentation.
- **Don't mix DTOs with Models** — always map between layers.
- **Don't access network/persistence** from ViewModels directly.
- **Don't move a single Repository protocol to Domain** — today they all live in `Data/<Feature>/Repositories/` (see Known Deviations). Moving them is a project-wide refactor.
- **Don't use boolean app state** (`isLoggedIn`, `hasOnboarded`) — use enum state machine.
- **Don't put business logic in `@main`** — it only composes `AppDependencies`, `AppRouterImpl` and the root view. Extract app-level state to an `@Observable` type in `App/`.
- **Don't do I/O or decoding in initializers reached from a Factory** — load lazily inside an `async` / `throws` method.

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
| `.claude/docs/swiftdata.md` | SwiftData persistence patterns (only if you add SwiftData — not generated for this project) |
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
