# ARCHITECTURE.md — Clean + MVVM + Router (iOS 18+)

> Architecture reference for Clean Architecture + MVVM + Router pattern.
> Related skills: `axiom-swiftui-architecture`
> Axiom complementa: Generic MVVM/TCA patterns, refactoring workflows

## Overview

Layered architecture to keep code testable and decoupled. Layers are **folders in one app target** (`Example/Arquitectura/`), not modules, so the compiler does not enforce the dependency direction: review must.

```
┌─────────────────────────────────────────────────────────────┐
│  APP (composition root)          CORE (shared infrastructure)│
│  ArquitecturaApp, AppRootView,   Networking, ErrorDecorator, │
│  AppDependencies, Navigation     DesignSystem, Security      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                PRESENTATION (Features/<Screen>/)             │
│  ┌─────────┐    ┌─────────────┐    ┌──────────────────┐     │
│  │  View   │───▶│  ViewModel  │───▶│  <Feature>Router │     │
│  └─────────┘    └─────────────┘    └──────────────────┘     │
│                       │  @MainActor @Observable              │
└───────────────────────┼─────────────────────────────────────┘
                        │ depends on (protocols)
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   DOMAIN (Domain/<Concept>/)                 │
│  ┌─────────────┐  ┌──────────────────────┐  ┌────────────┐  │
│  │   UseCase   │  │ Models (pure domain) │  │ Repository │  │
│  │ (Proto+Impl)│  │                      │  │ (Protocol) │  │
│  └─────────────┘  └──────────────────────┘  └────────────┘  │
│  Domain/Common/DomainError.swift                             │
└──────────────────────────────────────────────────────────────┘
                               ▲ implements
                               │
┌─────────────────────────────────────────────────────────────┐
│                    DATA (Data/<Concept>/)                    │
│  ┌──────────────┐  ┌────────────────┐  ┌─────────────────┐  │
│  │  DataSources  │  │ DTOs           │  │ Repositories     │  │
│  │ (Remote,      │  │ DTOMappers     │  │ (Impl only)      │  │
│  │ Static, JSON) │  │                │  │                  │  │
│  └──────────────┘  └────────────────┘  └─────────────────┘  │
│  Data/Common/DomainError+Mapping.swift                       │
└─────────────────────────────────────────────────────────────┘
```

## Responsibilities by Layer

### App
- `ArquitecturaApp.swift` (`@main`): creates `AppDependencies` and the app-wide `AppLaunchState` (`.splash` / `.ready`). Nothing else.
- `App/Application/AppRootView.swift`: one per window. Owns that window's `AppRouterImpl` and `AppNavigationCoordinator`, shows the splash or `RootNavigationView`, and installs `.onOpenURL`.
- `App/Config/`: `AppDependencies` (today: the shared `APIClient`), `AppEnvironment`, `EnvironmentConfiguration`, `Xcconfig/`.
- `App/Navigation/`: `AppRouter`, `AppRouterImpl`, `RootNavigationView`, `AppNavigationCoordinator`.

### Core
- `Core/Networking/`: `APIClient` + `APIClientImpl`, endpoints, `APIError`, interceptors, retry, SSL pinning.
- `Core/Common/`: extensions, `Models/ErrorDecorator.swift`, `SwiftUI/{Builders,Components,Modifiers}/`.
- `Core/DesignSystem/Tokens/`, `Core/Security/KeychainHelper.swift`.
- No feature knowledge.

### Presentation
- Organized **per screen**: `Features/<Screen>/` with `DI/`, `UI/`, `Presentation/ViewModels/`, `Presentation/Mappers/`, `Navigation/`.
- SwiftUI views: render + UI events.
- ViewModels: state + use case coordination; convert `DomainError` with `ErrorDecorator.from(_:)`.
- Router: feature navigation through `AppRouter` (deep links are parsed in the App layer, see below).
- **Decorators**: transform Domain models to presentation models.
- **DecoratorMappers**: protocol + impl for Domain → Decorator mapping.

**Not allowed**: URLSession, DTOs, SwiftData, JSON parsing.

### Domain
- **Models** (business models), e.g. `PokemonSummaryModel`, `PokemonDetailModel`, `ArchitectureModel`.
- **Use cases** (`UseCase` protocol + `UseCaseImpl`, separate files) — orchestrate repositories. They do **not** catch or map errors.
- **Repository protocols** (contracts), owned by Domain and implemented in Data.
- **`DomainError`** (`Domain/Common/DomainError.swift`) — the single error type repositories expose: `.network`, `.notFound`, `.server`, `.parsing`, `.unknown`.

**Location**: Global `Domain/<Concept>/` folder, organized by **business concept, not by screen** (`Domain/Pokemon` serves both `Features/PokemonList` and `Features/PokemonDetail`), with `Models/`, `UseCases/` and `Repositories/` subfolders.

**Not allowed**: SwiftUI, SwiftData, URLSession, `APIError` or any other infrastructure type.

### Data
- **Repository implementations** (`<Feature>RepositoryImpl`) conforming to the Domain protocol. No protocols here.
- **DataSources** (protocol + Impl, separate files) — `Remote` (API), `Static` (in-code data) or `JSON` (bundled file). They throw `APIError` or their own errors (e.g. `DataSourceError`).
- DTOs, decoding/serialization.
- **Mappers** (DTOMapper protocol + impl) from DTO → Domain.
- **`Data/Common/DomainError+Mapping.swift`** — `DomainError.map(_:)` and `DomainError.catching { }`, which translate `APIError`, `DecodingError` and any other error into `DomainError`.

**Location**: Global `Data/<Concept>/` folder mirroring Domain, with `Repositories/`, `DataSources/`, `DTO/`, `Mappers/` subfolders.

`APIClient`, `APIError` and the dual-endpoint system (`Endpoint` struct for internal APIs, `APIEndpoint` protocol for external APIs) live in `Core/Networking/`. See `networking.md`.

> **Rule**: Repositories **always** delegate to DataSources, never access `APIClient` directly. `Example/` has no local database; if SwiftData is added (see `swiftdata.md`), the same rule applies to `ModelContext`.

## Naming Conventions

| Type | Naming | Layer |
|------|--------|-------|
| API Response DTO | `[Feature]DTO` / `[Feature]ResponseDTO` | Data |
| Domain Model | `[Feature]Model` (e.g. `PokemonSummaryModel`) | Domain |
| Remote DataSource | `[Feature]RemoteDataSource` + Impl | Data |
| Static / JSON DataSource | `[Feature]StaticDataSource`, `[Feature]JSONDataSource` + Impl | Data |
| Repository Protocol | `[Feature]Repository` | Domain |
| Repository Impl | `[Feature]RepositoryImpl` | Data |
| SwiftData model (only with the optional SwiftData stack, not in `Example/`) | `[Feature]SDModel` | Data |
| Section Decorator (UI) | `[Feature]SectionDecorator` | Presentation |
| Item Decorator (UI) | `[Feature]ItemDecorator` | Presentation |
| DecoratorMapper | `[Feature]DecoratorMapper` + Impl | Presentation |
| DTO Mapper | `[Feature]DTOMapper` + Impl | Data |

## Data Flow and Mappers

```
API Response          Data Layer                     Domain            Presentation
──────────────────────────────────────────────────────────────────────────────────────────

[Feature]DTO ──────▶ [Feature]Model ──────────▶ [Feature]ItemDecorator
  (JSON)            (DTOMapper)                   (DecoratorMapper)
     │                 │                            │
 DataSource        Repository ──▶ UseCase ──▶ ViewModel
 (Remote)
```

> **Note**: The project uses a single DTO type per API response (e.g., `[Feature]DTO`).
> No separate "Codable" type — the DTO itself conforms to `Codable` and is decoded directly.

### Mapper Examples

DTOMapper methods are `nonisolated` (protocol and Impl) so repositories can call them from any isolation, including task-group children (see `PokemonListDTOMapperImpl`).

```swift
// Data: DTO → Domain Model (in DTOMapperImpl)
extension FeatureDTOMapperImpl: FeatureDTOMapper {
    nonisolated func mapToDomain(_ dto: FeatureDTO) -> FeatureModel {
        FeatureModel(
            id: dto.id,
            title: dto.title,
            body: dto.content,
            publishedAt: dto.publishedAt
        )
    }
}

// Presentation: Domain → Decorator (in DecoratorMapperImpl)
extension FeatureDecoratorMapperImpl: FeatureDecoratorMapper {
    func map(_ model: FeatureModel) -> FeatureItemDecorator {
        FeatureItemDecorator(
            id: model.id,
            title: model.title,
            body: model.body,
            formattedDate: dateFormatter.string(from: model.publishedAt)
        )
    }

    func mapToSections(_ models: [FeatureModel]) -> [FeatureSectionDecorator] {
        Dictionary(grouping: models, by: \.category)
            .map { category, items in
                FeatureSectionDecorator(
                    title: category.rawValue,
                    items: items.map { map($0) }
                )
            }
            .sorted { $0.title < $1.title }
    }
}
```

## Error Handling Between Layers

### Propagation Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  DATA SOURCES (Data/<Concept>/DataSources)                           │
│  APIError: .networkError | .httpError | .decodingError | .invalidURL │
│            | .unknown   — or their own errors (DataSourceError, …)   │
│  APIClientImpl: URLError.cancelled → CancellationError if cancelled  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ RepositoryImpl wraps its work in
                               │ try await DomainError.catching { … }
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  DOMAIN (Repository protocol → UseCase)                              │
│  DomainError: .network | .notFound | .server | .parsing | .unknown   │
│  (or CancellationError). UseCases do NOT catch or map.               │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ ViewModel: ErrorDecorator.from(_:)
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PRESENTATION (ViewModel)                                            │
│  State: .error(ErrorDecorator) with localized message               │
└─────────────────────────────────────────────────────────────────────┘
```

Rules:
- Every `RepositoryImpl` that can fail wraps its body in `DomainError.catching`, so repositories throw only `DomainError` or `CancellationError`. A repository whose data source cannot throw (e.g. `ArchitectureRepositoryImpl` over a static data source) does not need it.
- `DomainError.catching` rethrows `CancellationError` unchanged. A repository that catches errors itself (e.g. the optional species request in `PokemonDetailRepositoryImpl`) rethrows `CancellationError` first.
- `DecodingError` (from `APIError.decodingError` or from a local decode) maps to `.parsing`; HTTP 404 maps to `.notFound`, any other HTTP status to `.server`.
- Don't turn a load failure into an empty result: it later surfaces as "not found" instead of an error.

### ViewModel State with Decorator

```swift
@MainActor
@Observable
final class FeatureViewModel {
    // MARK: - Properties

    private(set) var state: FeatureState = .idle

    private let useCase: FeatureUseCase
    private let router: FeatureRouter
    private let decoratorMapper: FeatureDecoratorMapper

    // MARK: - Init

    init(useCase: FeatureUseCase,
         router: FeatureRouter,
         decoratorMapper: FeatureDecoratorMapper) {
        self.useCase = useCase
        self.router = router
        self.decoratorMapper = decoratorMapper
    }

    // MARK: - Public Methods

    func loadFeatures() async {
        guard state != .loading else { return }

        let previousState = state
        state = .loading

        do {
            let models = try await useCase.execute()
            let sections = decoratorMapper.mapToSections(models)
            state = .loaded(sections)
        } catch is CancellationError {
            state = previousState
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }

    func navigateToDetail(featureId: String) {
        router.navigateToDetail(featureId: featureId)
    }
}
```

On cancellation the ViewModel restores the previous state instead of showing an error, so it never stays stuck in `.loading` (see `ArchitectureViewModel`, `PokemonDetailViewModel`).

**Note**: Actions are handled as direct methods in ViewModel (no Action/Event enums).

## Router and Navigation (Type-erased Pattern)

### Architecture

Each feature defines its own routes independently. The `AppRouter` is generic and accepts any `Hashable & Codable` route type.

```
┌─────────────────────────────────────────────────────────────────────┐
│  App/Navigation/                                                     │
│  - AppRouter.swift (protocol: push / pop / popToRoot only)           │
│  - AppRouterImpl.swift (owns the window's NavigationPath)            │
│  - RootNavigationView.swift (NavigationStack + resolver registration)│
│  - AppNavigationCoordinator.swift (deep links + state persistence)   │
│  - Does NOT know about specific route types                          │
└─────────────────────────────────────────────────────────────────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          ▼                         ▼                         ▼
┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│ ArchitectureRouter │  │ PokemonListRouter  │  │PokemonDetailRouter │
│ ArchitectureRoute- │  │ PokemonListRoute-  │  │  (no resolver)     │
│ Resolver           │  │ Resolver           │  │                    │
└────────────────────┘  └────────────────────┘  └────────────────────┘
   (Feature-owned)         (Feature-owned)         (Feature-owned)
```

### Components

1. **AppRouter** (Protocol + Impl, in `App/Navigation/`)
   - `AppRouter.swift` — `@MainActor` protocol with only `push(_ route: some Hashable & Codable)`, `pop()` and `popToRoot()`. Features never read or replace the whole path.
   - `AppRouterImpl.swift` — `@MainActor @Observable`, owns `path: NavigationPath`. Only the App layer uses `path` (`RootNavigationView` binds it, `AppNavigationCoordinator` restores and persists it).

2. **FeatureRouter** (Per-feature, always, in `Features/[Feature]/Navigation/`)
   - Contains Route enum + Protocol + Implementation in one file
   - Example: `[Feature]Router.swift` contains `[Feature]Route` enum + `[Feature]Router` protocol + `[Feature]RouterImpl`

3. **FeatureRouteResolver** (Optional, in `Features/[Feature]/Navigation/`)
   - Only when the feature owns routes that must be resolved into views (`ArchitectureRouteResolver`, `PokemonListRouteResolver`). `ArchitectureDetail` and `PokemonDetail` have none.
   - `ViewModifier` that resolves routes to views with `.navigationDestination(for: FeatureRoute.self)`, plus a `View.with<Feature>Routes(...)` extension.

### Implementation

```swift
// App/Navigation/AppRouter.swift
@MainActor
protocol AppRouter: Sendable {
    func push(_ route: some Hashable & Codable)
    func pop()
    func popToRoot()
}

// App/Navigation/AppRouterImpl.swift
@MainActor
@Observable
final class AppRouterImpl: AppRouter {
    // MARK: - Properties

    var path = NavigationPath()

    // MARK: - Public Methods

    func push(_ route: some Hashable & Codable) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        guard !path.isEmpty else { return }
        path = NavigationPath()
    }
}
```

```swift
// Features/[Feature]/Navigation/FeatureRouter.swift
// Contains: Route enum + Protocol + Implementation

// MARK: - FeatureRoute

enum FeatureRoute: Hashable, Codable {
    case detail(featureId: String)
}

// MARK: - FeatureRouter

@MainActor
protocol FeatureRouter: Sendable {
    func navigateToDetail(featureId: String)
    func goBack()
}

// MARK: - FeatureRouterImpl

@MainActor
struct FeatureRouterImpl: FeatureRouter {
    // MARK: - Properties

    private let appRouter: AppRouter

    // MARK: - Init

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    // MARK: - FeatureRouter

    func navigateToDetail(featureId: String) {
        appRouter.push(FeatureRoute.detail(featureId: featureId))
    }

    func goBack() {
        appRouter.pop()
    }
}
```

```swift
// Features/[Feature]/Navigation/FeatureRouteResolver.swift
import SwiftUI

// MARK: - FeatureRouteResolver

struct FeatureRouteResolver: ViewModifier {
    // MARK: - Properties

    let appRouter: AppRouter

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: FeatureRoute.self) { route in
                destination(for: route)
            }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func destination(for route: FeatureRoute) -> some View {
        switch route {
        case let .detail(featureId):
            FeatureDetailFactory.makeView(featureId: featureId, appRouter: appRouter)
        }
    }
}

// MARK: - View Extension

extension View {
    func withFeatureRoutes(appRouter: AppRouter) -> some View {
        modifier(FeatureRouteResolver(appRouter: appRouter))
    }
}
```

A resolver that builds networked screens also receives `AppDependencies` (see `PokemonListRouteResolver` and `.withPokemonListRoutes(appRouter:dependencies:)`). A router can push another feature's route when that route is already registered (`ArchitectureDetailRouterImpl` pushes `PokemonListRoute.list`); in that case no resolver file is needed.

### App Root Composition

Three App-layer types compose navigation (code trimmed to the composition):

```swift
// ArquitecturaApp.swift
@main
struct ArquitecturaApp: App {
    // MARK: - Properties

    @State
    private var launchState: AppLaunchState = .splash

    private let dependencies: AppDependencies

    // MARK: - Init

    init() {
        dependencies = AppDependencies()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRootView(launchState: $launchState,
                        dependencies: dependencies)
        }
    }
}
```

```swift
// App/Application/AppRootView.swift — one per window
struct AppRootView: View {
    // MARK: - Properties

    @Binding
    var launchState: AppLaunchState
    let dependencies: AppDependencies

    @State
    private var appRouter: AppRouterImpl

    @State
    private var coordinator: AppNavigationCoordinator

    // MARK: - Init

    init(launchState: Binding<AppLaunchState>, dependencies: AppDependencies) {
        let appRouter = AppRouterImpl()
        self._launchState = launchState
        self.dependencies = dependencies
        self._appRouter = State(initialValue: appRouter)
        self._coordinator = State(initialValue: AppNavigationCoordinator(appRouter: appRouter))
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch launchState {
            case .splash:
                SplashScreenFactory.makeView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        launchState = .ready
                    }
                }
            case .ready:
                RootNavigationView(appRouter: appRouter,
                                   coordinator: coordinator,
                                   dependencies: dependencies)
            }
        }
        .onOpenURL { url in
            coordinator.handleDeepLink(url)
        }
    }
}
```

```swift
// App/Navigation/RootNavigationView.swift — resolvers are registered here
var body: some View {
    NavigationStack(path: $appRouter.path) {
        ArchitectureFactory.makeView(appRouter: appRouter)
            .withArchitectureRoutes(appRouter: appRouter)
            .withPokemonListRoutes(appRouter: appRouter, dependencies: dependencies)
    }
    .task(id: "restore") {
        coordinator.restoreNavigationState(from: navigationData)
    }
    .onChange(of: appRouter.path) { _, _ in
        coordinator.saveNavigationStateDebounced { data in
            navigationData = data
        }
    }
}
```

`RootNavigationView` holds `@Bindable var appRouter: AppRouterImpl` (the concrete type, because `@Bindable` needs the `@Observable` class) and `@SceneStorage("app.navigation.path") private var navigationData: Data?`.

### Key Benefits

- **Feature isolation**: Each feature defines its own routes without modifying global files
- **Type safety**: Each feature uses its own strongly-typed route enum
- **Scalability**: Adding a new feature with its own destinations only requires adding a resolver modifier in `RootNavigationView`
- **Testability**: Mock the `FeatureRouter` protocol to test navigation from ViewModels

### Key Notes

- Navigation is **per window**: each `AppRootView` owns its own `AppRouterImpl` and `AppNavigationCoordinator`, so iPad windows navigate and restore independently. Never share one `AppRouterImpl` across windows.
- One `NavigationStack` per window, in `RootNavigationView`; avoid nested stacks.
- ViewModels never import SwiftUI or know about `NavigationStack`; they only use their `FeatureRouter`.
- Tests: mock the `FeatureRouter` (or its protocol) and verify the correct action was called.
- Deep links are parsed in `AppNavigationCoordinator` and **replace** the stack; features never handle URLs (see Deep Linking below).

### Factory + `@State` Pattern

The resolver calls the Factory inside `navigationDestination`, and the View stores the ViewModel with `@State` (`State(initialValue:)` in `init`), so navigating back does not create a new ViewModel. SwiftUI can evaluate the destination closure, and therefore the Factory, many times: `@State` keeps only the first ViewModel and the rest are built and thrown away. Factories and every `init` they reach must stay cheap — no file I/O, decoding or network work. `ArchitectureDetailJSONDataSourceImpl` only resolves the file URL in `init` and reads/decodes it inside its `async throws` load method.

## App State Management

Use an explicit enum state machine for app-level state instead of scattered booleans (`isLoggedIn`, `hasOnboarded`).

### AppLaunchState

`Example/` has one app-level state, declared in `ArquitecturaApp.swift`:

```swift
// MARK: - AppLaunchState

/// App launch state machine
enum AppLaunchState: Equatable {
    case splash
    case ready
}
```

- `ArquitecturaApp` owns it as `@State` and passes a `Binding` to every window's `AppRootView`.
- `AppRootView` switches on it: `.splash` shows `SplashScreenFactory.makeView { ... }`, whose completion sets `.ready`; `.ready` shows `RootNavigationView`.
- `.onOpenURL` is installed on `AppRootView`, above the splash, so a deep link that launches the app is captured before `RootNavigationView` exists.

**Growing it**: if the app needs more states (authentication, onboarding), add cases to the enum and, once transitions need logic, move them into an `@Observable` type in `App/`. Don't put that logic in `@main`, which only composes `AppDependencies`, the launch state and `AppRootView`.

---

## Sendable Requirements (Swift 6)

For Swift 6 strict concurrency compliance, types that cross actor boundaries **must** conform to `Sendable`.

### Required Sendable Conformances

| Type | Sendable? | Reason |
|------|-----------|--------|
| Domain Models | ✅ **Required** | Cross actor boundaries |
| DTOs | ✅ **Required** | Cross actor boundaries |
| UseCases (struct) | ✅ **Required** | Called from different actors |
| Repositories (struct) | ✅ **Required** | Called from different actors |
| DataSources (struct) | ✅ **Required** | Called from different actors |
| Mappers (protocol) | ✅ **Required** | Used across actor boundaries |
| Decorators | ✅ **Recommended** | May be passed between actors |
| ViewModels | ❌ **NO** | Already @MainActor isolated |
| Views | ❌ **NO** | SwiftUI handles isolation |

> **In `Example/`**: every UseCase, Repository, DataSource, Mapper and Router **protocol** declares `: Sendable` explicitly. Internal value types (Domain models, most DTOs, Decorators) rely on implicit `Sendable` inference and don't spell it out. DTOs decoded off the main actor (`ArchitectureDetailDTO` and friends) are declared `nonisolated` and `Sendable` explicitly. Both styles below are valid.

### Implementation Examples

```swift
// Domain Model — Sendable (immutable struct)
struct FeatureModel: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let body: String
}

// DTO — Sendable
struct FeatureDTO: Sendable, Codable {
    let id: String
    let title: String
    let content: String
}

// UseCase Protocol — Sendable
protocol FeatureUseCase: Sendable {
    func execute() async throws -> [FeatureModel]
}

// Repository Protocol — Sendable
protocol FeatureRepository: Sendable {
    func fetchFeatures() async throws -> [FeatureModel]
}

// Mapper Protocol — Sendable (IMPORTANT!)
protocol FeatureDTOMapper: Sendable {
    func map(_ dto: FeatureDTO) -> FeatureModel
}

protocol FeatureDecoratorMapper: Sendable {
    func map(_ model: FeatureModel) -> FeatureItemDecorator
}

// Decorator — Sendable recommended
struct FeatureItemDecorator: Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let formattedDate: String
}
```

### @unchecked Sendable

Use sparingly when you have thread-safe code that the compiler can't verify:

```swift
// Core/Networking/Security/SSLPinningDelegate.swift (excerpt)
final class SSLPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    // MARK: - Properties

    private let pinnedPublicKeyHashes: Set<String>
    private let pinnedHosts: Set<String>
    private let isEnabled: Bool

    // MARK: - Init

    init(publicKeyHashes: [String], pinnedHosts: Set<String>, isEnabled: Bool = true) {
        self.pinnedPublicKeyHashes = Set(publicKeyHashes)
        self.pinnedHosts = Set(pinnedHosts.map { $0.lowercased() })
        self.isEnabled = isEnabled
        super.init()
    }
}
```

It is safe because every stored property is an immutable `let`. Don't add `var` properties without re-analyzing thread safety (`APIClientImpl` follows the same rule).

---

## Deep Linking

### URL Scheme Registration

`Example/Arquitectura/Info.plist` registers the `arquitectura` scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>arquitectura</string>
        </array>
    </dict>
</array>
```

### AppNavigationCoordinator

Deep links are parsed in `App/Navigation/AppNavigationCoordinator.swift` (one instance per window, created by `AppRootView` with `AppNavigationCoordinator(appRouter: AppRouterImpl)`). A new deep-linkable route is added there.

| URL | Resulting stack |
|-----|-----------------|
| `arquitectura://feature?id=<id>` | `[ArchitectureRoute.detail(featureId:)]` (id must be non-empty, ≤ 256 chars) |
| `arquitectura://pokemon?id=<n>` | `[PokemonListRoute.list, PokemonListRoute.detail(pokemonId:)]` (n > 0) |
| `arquitectura://pokedex` | `[PokemonListRoute.list]` |

Behavior:
- A valid link builds a fresh `NavigationPath` and **replaces** the stack (`appRouter.path = newPath`); it never pushes on top. Invalid links are logged and ignored.
- Links received before `restoreNavigationState(from:)` has run (for example, the URL that launched the app) are held in `pendingDeepLink`; a newer link replaces a held one. Right after restoring, the held link is applied, so the result does not depend on whether `.onOpenURL` or the restoration `.task` runs first.
- `.onOpenURL` lives on `AppRootView` (above the splash) and calls `coordinator.handleDeepLink(url)`.

```swift
// App/Navigation/AppNavigationCoordinator.swift (excerpt)
func handleDeepLink(_ url: URL) {
    guard hasRestoredState else {
        pendingDeepLink = url
        return
    }
    navigate(to: url)
}
```

### Testing Deep Links

```bash
# From Terminal
xcrun simctl openurl booted "arquitectura://pokemon?id=25"
```

Unit tests: `ArquitecturaTests/App/Navigation/AppNavigationCoordinatorTests.swift`.

> **Axiom skill**: Use `axiom:axiom-deep-link-debugging` for diagnosing deep link issues.

---

## State Preservation

Preserve navigation state across app terminations using `@SceneStorage`.

### Route Codable Requirement

All route enums must conform to `Codable` for state preservation:

```swift
// Features/[Feature]/Navigation/FeatureRouter.swift
enum FeatureRoute: Hashable, Codable {
    case list
    case detail(featureId: String)
}
```

A route with no cases still needs `Codable`; `PokemonDetailRoute` implements `init(from:)` and `encode(to:)` by hand for that reason.

### NavigationPath Persistence

`RootNavigationView` owns the `@SceneStorage("app.navigation.path")` value and delegates the work to `AppNavigationCoordinator` (see the `RootNavigationView` body above):

- **Restore**: `.task(id: "restore")` calls `coordinator.restoreNavigationState(from: navigationData)`. It runs **once per window** (`hasRestoredState` guard), decodes `NavigationPath.CodableRepresentation` into `appRouter.path`, logs a decode failure without clearing storage, and then applies any held deep link.
- **Save**: `.onChange(of: appRouter.path)` calls `coordinator.saveNavigationStateDebounced { data in navigationData = data }`. Saves are debounced by 300 ms; a newer change cancels the pending save.
- **Never persists nil**: the `persist` closure receives non-optional `Data`. When `path.codable` is nil or encoding fails, nothing is written and the last good state is kept.

```swift
// App/Navigation/AppNavigationCoordinator.swift (excerpt)
func saveNavigationStateDebounced(persist: @escaping @MainActor (Data) -> Void) {
    saveTask?.cancel()
    saveTask = Task { [weak self] in
        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }
        guard !Task.isCancelled, let data = self?.encodeNavigationState() else { return }
        persist(data)
    }
}
```

---

## Error Types Templates

### APIError (Core/Networking, thrown by DataSources)

```swift
// Core/Networking/APIError.swift
nonisolated enum APIError: Error {
    case networkError(URLError)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(DecodingError)
    case invalidURL
    case unknown(SendableError)
}

// MARK: - APIError + Retryable

extension APIError {
    var isRetryable: Bool {
        switch self {
        case let .networkError(urlError):
            let retryableCodes: [URLError.Code] = [
                .timedOut, .networkConnectionLost,
                .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed
            ]
            return retryableCodes.contains(urlError.code)
        case let .httpError(statusCode, _):
            return statusCode >= 500 || statusCode == 429
        case .decodingError, .invalidURL, .unknown:
            return false
        }
    }

    var serverError: APIErrorResponse? {
        guard case let .httpError(_, data) = self else { return nil }
        return APIErrorResponse.decode(from: data)
    }
}
```

### DomainError (Domain Layer, shared by all features)

There is one `DomainError` for the whole app; features don't define their own error enums. It knows nothing about `APIError`.

```swift
// Domain/Common/DomainError.swift
enum DomainError: Error {
    case network
    case notFound
    case server
    case parsing
    case unknown
}
```

### DomainError Mapping (Data Layer)

```swift
// Data/Common/DomainError+Mapping.swift
extension DomainError {
    static func catching<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw map(error)
        }
    }

    static func map(_ error: Error) -> DomainError {
        if let domainError = error as? DomainError {
            return domainError
        }

        if let apiError = error as? APIError {
            return mapAPIError(apiError)
        }

        if error is DecodingError {
            return .parsing
        }

        return .unknown
    }

    // MARK: - Private

    private static func mapAPIError(_ error: APIError) -> DomainError {
        switch error {
        case .networkError:
            .network
        case let .httpError(statusCode, _):
            statusCode == 404 ? .notFound : .server
        case .decodingError:
            .parsing
        case .invalidURL:
            .network
        case .unknown:
            .unknown
        }
    }
}
```

Usage in a repository (from `PokemonListRepositoryImpl`):

```swift
func getPokemonList(limit: Int, offset: Int) async throws -> PokemonListRepositoryResult {
    try await DomainError.catching {
        let listResponse = try await remoteDataSource.fetchPokemonList(limit: limit, offset: offset)
        let pokemon = try await fetchDetailsInParallel(for: listResponse.results)
        let hasMore = listResponse.next != nil

        return PokemonListRepositoryResult(pokemon: pokemon,
                                           totalCount: listResponse.count,
                                           hasMore: hasMore)
    }
}
```

UseCases never call `DomainError.map` or `DomainError.catching`: they let the repository's `DomainError` through.

### ErrorDecorator (Presentation type in Core)

`ErrorDecorator` lives in `Core/Common/Models/ErrorDecorator.swift` (a deliberate deviation: it is a presentation type, but every feature shares it). Localized keys are in `Resources/Strings/Localizable.xcstrings`.

```swift
// Core/Common/Models/ErrorDecorator.swift
struct ErrorDecorator: Equatable {
    // MARK: - Properties

    let title: String
    let message: String
    let isRetryable: Bool

    // MARK: - Static Factories

    static let generic = ErrorDecorator(title: String(localized: "error.title.generic"),
                                        message: String(localized: "error.message.generic"),
                                        isRetryable: true)

    static let notFound = ErrorDecorator(title: String(localized: "error.title.notFound"),
                                         message: String(localized: "error.message.notFound"),
                                         isRetryable: false)

    static let network = ErrorDecorator(title: String(localized: "error.title.network"),
                                        message: String(localized: "error.message.network"),
                                        isRetryable: true)

    static let server = ErrorDecorator(title: String(localized: "error.title.server"),
                                       message: String(localized: "error.message.server"),
                                       isRetryable: true)
}

// MARK: - DomainError Mapping

extension ErrorDecorator {
    static func from(_ error: DomainError) -> ErrorDecorator {
        switch error {
        case .network:
            .network
        case .notFound:
            .notFound
        case .server:
            .server
        case .parsing:
            .generic
        case .unknown:
            .generic
        }
    }
}
```

---

## Concurrency (Playbook)

- `Example/` builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`: every declaration without explicit isolation is `@MainActor`, **including UseCases, Repositories and DataSources**. Being in `Domain/` or `Data/` does not move work off the main actor.
- ViewModels: `@MainActor` + `@Observable`.
- `nonisolated` for DTOs (`init(from:)`), DTOMapper methods, `APIError` and the networking types in `Core/Networking/`.
- `@concurrent` for work that must leave the main actor (heavy decoding, disk I/O), e.g. `ArchitectureDetailJSONDataSourceImpl.decodeFeatures(at:)`. See `swift-concurrency.md`.
- Don't ignore cancellations:
  - If you catch errors, re-throw `CancellationError`.
  - On cancellation, ViewModels restore the previous state instead of showing an error.

Recommended patterns:
- In View: `.task(id:) { await viewModel.load() }` (auto-cancels).
- In VM if you need manual control:
  - `private var loadTask: Task<Void, Never>?`
  - `loadTask?.cancel()` before creating a new one.

## Dependency Injection

- Manual constructor injection, no DI container.
- `AppDependencies` (`App/Config/AppDependencies.swift`) holds app-lifetime dependencies (today: the shared `APIClient`). It is created once in `@main` and passed to `AppRootView` → `RootNavigationView` → resolvers → Factories.
- One `@MainActor enum <Feature>Factory` per feature with `static func makeView(...)`. It receives `AppRouter` and, when it needs networking, `AppDependencies` (`PokemonListFactory.makeView(appRouter:dependencies:)`). Private `make*` helpers build DataSource → Mapper → Repository → UseCase → DecoratorMapper → Router → ViewModel → View.
- Inject protocols (Domain) and concretes (Data) only in the Factory.
- Factories build a new graph per screen and can run many times (Factory + `@State` pattern above): keep constructors cheap, no I/O in `init`.

### Factory Example

```swift
// Features/[Feature]/DI/FeatureFactory.swift

// MARK: - FeatureFactory

@MainActor
enum FeatureFactory {
    // MARK: - Public Methods

    static func makeView(appRouter: AppRouter, dependencies: AppDependencies) -> FeatureView {
        let repository = makeRepository(apiClient: dependencies.apiClient)
        let useCase = makeUseCase(repository: repository)
        let router = makeRouter(appRouter: appRouter)
        let decoratorMapper = FeatureDecoratorMapperImpl()
        let viewModel = makeViewModel(useCase: useCase, router: router, decoratorMapper: decoratorMapper)

        return FeatureView(viewModel: viewModel)
    }
}

// MARK: - Private Factory Methods

private extension FeatureFactory {
    static func makeRepository(apiClient: APIClient) -> FeatureRepository {
        FeatureRepositoryImpl(remoteDataSource: FeatureRemoteDataSourceImpl(apiClient: apiClient),
                              dtoMapper: FeatureDTOMapperImpl())
    }

    static func makeUseCase(repository: FeatureRepository) -> FeatureUseCase {
        FeatureUseCaseImpl(repository: repository)
    }

    static func makeRouter(appRouter: AppRouter) -> FeatureRouter {
        FeatureRouterImpl(appRouter: appRouter)
    }

    static func makeViewModel(
        useCase: FeatureUseCase,
        router: FeatureRouter,
        decoratorMapper: FeatureDecoratorMapper
    ) -> FeatureViewModel {
        FeatureViewModel(
            useCase: useCase,
            router: router,
            decoratorMapper: decoratorMapper
        )
    }
}
```
