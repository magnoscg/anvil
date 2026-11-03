# ARCHITECTURE.md — Clean + MVVM + Router (iOS 18+)

## Overview

Layered architecture to keep code testable and decoupled:

```
+-------------------------------------------------------------+
|                      PRESENTATION                            |
|  +---------+    +-------------+    +------------------+      |
|  |  View   |--->|  ViewModel  |--->| NavigationRouter  |     |
|  +---------+    +-------------+    +------------------+      |
|         ^             |                                      |
|         |             v                                      |
|         |        @Observable (iOS 18+)                       |
+---------+--------------------------------------------+-------+
          | depends on
          v
+-------------------------------------------------------------+
|                          DOMAIN                              |
|  +-------------+  +----------------------+  +--------------+ |
|  |   UseCase   |  | Models (pure domain) |  | Repository   | |
|  +-------------+  +----------------------+  | (protocol)   | |
|         |                                   +--------------+ |
|         v                    DomainError                     |
|     Business Logic                                           |
+--------------------------------------------------------------+
                               ^ implements
                               |
+-------------------------------------------------------------+
|                           DATA                               |
|  +--------------+  +----------------+  +-----------------+   |
|  |  DataSources |  | SwiftData      |  | RepositoryImpl  |   |
|  |  DTOs        |  | (optional)     |  | DomainError     |   |
|  |              |  |                |  |  .catching      |   |
|  +--------------+  +----------------+  +-----------------+   |
|           \______________  MAPPERS  ________________/        |
+-------------------------------------------------------------+
```

Layers are folders inside one app target, not modules: the compiler does not enforce the dependency direction, so code review must. Data depends on Domain (it implements the Domain repository protocols); Domain depends on nothing.

## Responsibilities by Layer

### Presentation
- SwiftUI views: render + UI events.
- ViewModels: state + use case coordination.
- Router: feature navigation (push / pop through `AppRouter`). Deep links are parsed in the App layer (`AppNavigationCoordinator`).
- **Decorators**: transform Domain models to presentation models.
- **DecoratorMappers**: protocol + impl for Domain -> Decorator mapping.

**Not allowed**: URLSession, DTOs, SwiftData, JSON parsing.

### Domain
- **Models** (business models) — `Sendable`.
- **Use cases** (`UseCase` protocol + `UseCaseImpl`, separate files) — orchestrate repositories. They do not catch or map errors.
- **Repository protocols** (contracts) — owned by Domain, implemented in Data.
- **`DomainError`** (`Domain/Common/DomainError.swift`) — the single typed error every repository throws.

**Location**: Global `Domain/<Concept>/` folder with `Models/`, `UseCases/` and `Repositories/` subfolders, plus `Domain/Common/`. Organize by domain concept: `anvil feature` creates one folder per feature, and you merge folders when several screens share a concept.

**Not allowed**: SwiftUI, SwiftData, URLSession, UI framework dependencies, `APIError` or any other infrastructure type.

### Data
- **Repository implementations** (`<Feature>RepositoryImpl`) conforming to the Domain protocols. They wrap their work in `try await DomainError.catching { ... }`.
- **DataSources** (Remote, optional Local/Keychain) — encapsulate network/storage access. Protocol + Impl in one file.
- DTOs, decoding/serialization.
- SwiftData models and local storage operations (only when SwiftData is enabled).
- **Mappers** (DTOMapper protocol + Impl in one file) from DTO -> Domain.
- **`DomainErrorMapping`** (`Data/Common/DomainErrorMapping.swift`) — `DomainError.map(_:)` and `DomainError.catching { }`.
- Uses `APIClient`, `Endpoint`/`APIEndpoint` and `APIError` from `Core/Networking/` (dual-endpoint system; see `networking.md`).

**Location**: Global `Data/<Concept>/` folder with `Repositories/`, `DataSources/`, `DTO/`, `Mappers/` subfolders, plus `Data/Common/`.

> **Rule**: Network repositories delegate to DataSources and never call `APIClient` directly. SwiftData repositories receive their own `ModelExecutor` (see `swiftdata.md`) and never use the main `ModelContext`.

## Naming Conventions

| Type | Naming | Layer |
|------|--------|-------|
| API Response DTO | `ArticleDTO` / `ArticleResponseDTO` | Data |
| Domain Model | `ArticleModel` | Domain |
| SwiftData model (optional) | `ArticleSDModel` | Data |
| Remote DataSource | `ArticleRemoteDataSource` + Impl (one file) | Data |
| Local DataSource | `ArticleLocalDataSource` + Impl (one file) | Data |
| Repository protocol | `ArticleRepository` | Domain |
| Repository Impl | `ArticleRepositoryImpl` | Data |
| Section Decorator (UI) | `ArticleSectionDecorator` | Presentation |
| Item Decorator (UI) | `ArticleItemDecorator` | Presentation |
| DecoratorMapper | `ArticleDecoratorMapper` + Impl (one file) | Presentation |
| DTO Mapper | `ArticleDTOMapper` + Impl (one file) | Data |

## Data Flow and Mappers

```
API Response          Data Layer                     Domain            Presentation
---------------------------------------------------------------------
ArticleDTO -------> ArticleModel ---------> ArticleItemDecorator
  (JSON)          (DTOMapper)                  (DecoratorMapper)
     |                 |                            |
 DataSource        Repository --> UseCase --> ViewModel
 (Remote)
```

> **Note**: The project uses a single DTO type per API response (e.g., `ArticleDTO`).
> No separate "Codable" type — the DTO itself conforms to `Codable` and is decoded directly.

### Mapper Examples

```swift
// MARK: - ArticleDTOMapperImpl (Data/Article/Mappers/ArticleDTOMapper.swift)

struct ArticleDTOMapperImpl: ArticleDTOMapper {
    // MARK: - Public Methods

    func map(_ dto: ArticleDTO) -> ArticleModel {
        ArticleModel(
            id: dto.id,
            title: dto.title,
            body: dto.content,
            publishedAt: dto.publishedAt
        )
    }

    func map(_ dtos: [ArticleDTO]) -> [ArticleModel] {
        dtos.map { map($0) }
    }
}

// MARK: - ArticleDecoratorMapperImpl (Features/Article/Presentation/Mappers/ArticleDecoratorMapper.swift)

struct ArticleDecoratorMapperImpl: ArticleDecoratorMapper {
    // MARK: - Public Methods

    func map(_ model: ArticleModel) -> ArticleItemDecorator {
        ArticleItemDecorator(
            id: model.id,
            title: model.title,
            body: model.body,
            formattedDate: model.publishedAt.formatted(date: .abbreviated, time: .omitted)
        )
    }

    func mapToSections(_ models: [ArticleModel]) -> [ArticleSectionDecorator] {
        Dictionary(grouping: models, by: \.category)
            .map { category, items in
                ArticleSectionDecorator(
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
+---------------------------------------------------------------------+
|  CORE / DATA SOURCES                                                 |
|  APIError: .networkError | .httpError | .decodingError | .invalidURL |
|            | .unknown        (or the data source's own errors)       |
+------------------------------+--------------------------------------+
                               | RepositoryImpl: DomainError.catching { }
                               v
+---------------------------------------------------------------------+
|  DOMAIN (Repository protocol -> UseCase, no catch / no map)          |
|  DomainError: .network | .notFound | .unauthorized | .server         |
|               | .parsing | .unknown        (or CancellationError)    |
+------------------------------+--------------------------------------+
                               | ViewModel: ErrorDecorator.from(_:)
                               v
+---------------------------------------------------------------------+
|  PRESENTATION (ViewModel)                                            |
|  State: .error(ErrorDecorator) with localized message                |
+---------------------------------------------------------------------+
```

- `DomainError.catching` (in `Data/Common/DomainErrorMapping.swift`) rethrows `CancellationError` unchanged and converts everything else with `DomainError.map(_:)`.
- `DomainError.map` keeps an existing `DomainError`, maps `APIError` (401 -> `.unauthorized`, 404 -> `.notFound`, other HTTP -> `.server`, network / invalid URL -> `.network`, decoding -> `.parsing`), maps a raw `DecodingError` to `.parsing`, and anything else to `.unknown`.
- Repositories therefore throw only `DomainError` or `CancellationError`. UseCases let them through.

### ViewModel State with Decorator

```swift
// MARK: - ArticleViewModel

@MainActor
@Observable
final class ArticleViewModel {
    // MARK: - Properties

    private(set) var state: ArticleState = .idle

    private let useCase: ArticleUseCase
    private let decoratorMapper: ArticleDecoratorMapper
    private let router: ArticleRouter

    // MARK: - Init

    init(useCase: ArticleUseCase,
         decoratorMapper: ArticleDecoratorMapper,
         router: ArticleRouter) {
        self.useCase = useCase
        self.decoratorMapper = decoratorMapper
        self.router = router
    }

    // MARK: - Public Methods

    func loadArticles() async {
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

    func navigateToDetail(id: String) {
        router.navigateToDetail(articleId: id)
    }
}
```

**Note**: Actions are handled as direct methods in ViewModel (no Action/Event enums).

## Router and Navigation (Type-erased Pattern)

### Architecture

Each feature defines its own routes independently. The `AppRouter` is generic and accepts any `Hashable & Codable` route type.

```
+---------------------------------------------------------------------+
|  App/Navigation/                                                     |
|  - AppRouter.swift (protocol: push / pop / popToRoot)                |
|  - AppRouterImpl.swift (owns the NavigationPath `path`)              |
|  - RootNavigationView.swift (NavigationStack + resolvers)            |
|  - AppNavigationCoordinator.swift (deep links + persistence)         |
|  - Does NOT know about specific route types                          |
+---------------------------------------------------------------------+
                                    |
          +-------------------------+-------------------------+
          v                         v                         v
+------------------+    +------------------+    +------------------+
| ArticleRouter    |   |  SettingsRouter   |    |  ProfileRouter   |
| ArticleResolver? |   |  SettingsResolver?|    |  ProfileResolver?|
+------------------+    +------------------+    +------------------+
   (Feature-owned)         (Feature-owned)         (Feature-owned)
```

### Components

1. **AppRouter** (Protocol + Impl, in `App/Navigation/`)
   - `AppRouter.swift` — `@MainActor` protocol with only `push(_ route: some Hashable & Codable)`, `pop()` and `popToRoot()`
   - `AppRouterImpl.swift` — `@MainActor @Observable`, owns `path` (`NavigationPath`). Only the App layer touches `path`: `RootNavigationView` binds it and `AppNavigationCoordinator` restores, persists and replaces it

2. **FeatureRouter** (Always, in `Features/<Feature>/Navigation/<Feature>Router.swift`)
   - Route enum (`Hashable, Codable`) + `@MainActor` protocol + `struct` Impl that delegates to `AppRouter`, in one file

3. **FeatureRouteResolver** (Optional, in `Features/<Feature>/Navigation/<Feature>RouteResolver.swift`)
   - `ViewModifier` that resolves the feature's routes to views with `.navigationDestination(for: FeatureRoute.self)`
   - Only when the feature owns destinations; registered in `App/Navigation/RootNavigationView.swift`

### Implementation

```swift
// MARK: - AppRouter (App/Navigation/AppRouter.swift)

@MainActor
protocol AppRouter: Sendable {
    func push(_ route: some Hashable & Codable)
    func pop()
    func popToRoot()
}

// MARK: - AppRouterImpl (App/Navigation/AppRouterImpl.swift)

@MainActor
@Observable
final class AppRouterImpl: AppRouter {
    // MARK: - Properties

    var path = NavigationPath()

    // MARK: - Methods

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
// Features/Article/Navigation/ArticleRouter.swift
// Contains: Route enum + Protocol + Implementation

// MARK: - ArticleRoute

enum ArticleRoute: Hashable, Codable {
    case detail(articleId: String)
}

// MARK: - ArticleRouter

@MainActor
protocol ArticleRouter: Sendable {
    func navigateToDetail(articleId: String)
    func goBack()
}

// MARK: - ArticleRouterImpl

@MainActor
struct ArticleRouterImpl: ArticleRouter {
    // MARK: - Properties

    private let appRouter: AppRouter

    // MARK: - Init

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    // MARK: - Public Methods

    func navigateToDetail(articleId: String) {
        appRouter.push(ArticleRoute.detail(articleId: articleId))
    }

    func goBack() {
        appRouter.pop()
    }
}
```

```swift
// Features/Article/Navigation/ArticleRouteResolver.swift

// MARK: - ArticleRouteResolver

struct ArticleRouteResolver: ViewModifier {
    // MARK: - Properties

    let appRouter: AppRouter
    let dependencies: AppDependencies

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: ArticleRoute.self) { route in
                switch route {
                case let .detail(articleId):
                    ArticleDetailFactory.makeView(articleId: articleId,
                                                  appRouter: appRouter,
                                                  dependencies: dependencies)
                }
            }
    }
}

// MARK: - View Extension

extension View {
    func withArticleRoutes(appRouter: AppRouter, dependencies: AppDependencies) -> some View {
        modifier(ArticleRouteResolver(appRouter: appRouter, dependencies: dependencies))
    }
}
```

Features are per screen: the detail screen is its own feature (`Features/ArticleDetail/`) with its own Factory, and it can share `Domain/Article/` and `Data/Article/` with the list. The destination's ViewModel is created inside `navigationDestination` and kept by the View with `@State` (see `swiftui-code-style.md`).

### App Root Composition

`@main` (`App/Application/AppMain.swift`) only composes: it creates `AppRouterImpl` and `AppDependencies` (plus the `SwiftDataStack` when SwiftData is enabled) and shows `RootNavigationView`. `RootNavigationView` owns the `NavigationStack`, the `AppNavigationCoordinator`, `.onOpenURL`, the `@SceneStorage` restore and the debounced save. Feature resolvers are registered there:

```swift
// App/Navigation/RootNavigationView.swift

// MARK: - Body

var body: some View {
    NavigationStack(path: $appRouter.path) {
        ArticleFactory.makeView(appRouter: appRouter, dependencies: dependencies)
            .withArticleRoutes(appRouter: appRouter, dependencies: dependencies)
    }
    .onOpenURL { url in
        coordinator.handleDeepLink(url)
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

The generated root shows a placeholder `Text`; replace it with your first screen's Factory. The generated Info.plist disables multiple scenes, so there is one window, one `AppRouterImpl` and one coordinator.

### Key Benefits

- **Feature isolation**: Each feature defines its own routes without modifying global files
- **Type safety**: Each feature uses its own strongly-typed route enum
- **Scalability**: Adding a new feature only requires adding a new resolver modifier
- **Testability**: Mock the feature's Router protocol to test navigation

### Key Notes

- `NavigationPath` lives once at the root (`AppRouterImpl.path`); avoid nested `NavigationStack`s.
- ViewModels never import SwiftUI or know about `NavigationStack`; they only use their `FeatureRouter`.
- Features never read or replace the whole path: `AppRouter` has no `path`.
- Tests: mock the `FeatureRouter` (or its protocol) and verify the correct action was called.
- Deep links: see [Deep Linking](#deep-linking). A link replaces the stack; it is never pushed on top.

## App State Management

The generator does **not** create an app-state type: `@main` only composes `AppDependencies`, `AppRouterImpl` (and `SwiftDataStack` when enabled) and the root view. When the app needs authentication, onboarding or another app-level flow, model it as an enum state machine instead of scattered booleans (`isLoggedIn`, `hasOnboarded`), and keep it in an `@MainActor @Observable` type in `App/` that the root view switches on. Keep that logic out of `@main`.

```swift
// MARK: - AppState (App/State/AppState.swift)

enum AppState: Equatable {
    case loading
    case unauthenticated
    case onboarding(OnboardingStep)
    case authenticated
}

// MARK: - OnboardingStep

enum OnboardingStep: Equatable {
    case welcome
    case permissions
    case profile
}
```

**Key Benefits**:
- Transitions can be validated in one place
- No scattered booleans (`isLoggedIn`, `hasCompletedOnboarding`)
- Easy to debug and trace state changes

---

## Sendable Requirements (Swift 6)

Generated targets build with `SWIFT_STRICT_CONCURRENCY = complete` and **no** default actor isolation: every type is nonisolated unless annotated. Types that cross actor boundaries **must** conform to `Sendable`.

### Required Sendable Conformances

| Type | Isolation | Sendable? | Reason |
|------|-----------|-----------|--------|
| Domain Models | nonisolated | **Required** | Cross actor boundaries |
| DTOs | nonisolated | **Required** | Cross actor boundaries |
| UseCases (struct) | nonisolated | **Required** | Called from the main actor, run off it |
| Repositories (struct) | nonisolated | **Required** | Called from different actors |
| DataSources (struct) | nonisolated | **Required** | Called from different actors |
| Mappers (DTO + Decorator) | nonisolated | **Required** (protocol) | Used across actor boundaries |
| Decorators | nonisolated | **Recommended** | May be passed between actors |
| ViewModels | `@MainActor` | **NO** | Already main-actor isolated |
| Routers, Factories, `AppRouter`, `AppNavigationCoordinator` | `@MainActor` | Router protocols: `Sendable` | Drive navigation state |
| Views | SwiftUI (`@MainActor`) | **NO** | SwiftUI handles isolation |

### Implementation Examples

```swift
// Domain Model
struct ArticleModel: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let body: String
}

// DTO
struct ArticleDTO: Sendable, Codable {
    let id: String
    let title: String
    let content: String
}

// UseCase Protocol
protocol ArticleUseCase: Sendable {
    func execute() async throws -> [ArticleModel]
}

// Repository Protocol (Domain/Article/Repositories/ArticleRepository.swift)
protocol ArticleRepository: Sendable {
    func fetchArticles() async throws -> [ArticleModel]
}

// Mapper Protocol
protocol ArticleDTOMapper: Sendable {
    func map(_ dto: ArticleDTO) -> ArticleModel
}

protocol ArticleDecoratorMapper: Sendable {
    func map(_ model: ArticleModel) -> ArticleItemDecorator
}

// Decorator
struct ArticleItemDecorator: Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let formattedDate: String
}
```

---

## Deep Linking

Deep links are handled by `AppNavigationCoordinator` (`App/Navigation/AppNavigationCoordinator.swift`), created by `RootNavigationView` as `AppNavigationCoordinator(appRouter: AppRouterImpl)`:

- `RootNavigationView` forwards `.onOpenURL` to `coordinator.handleDeepLink(_:)`.
- Links that arrive before `restoreNavigationState(from:)` has run (for example the URL that launched the app) are held and applied right after restoration. Restoration runs once, so a launch URL is never overwritten by the saved `@SceneStorage` path.
- `navigate(to:)` turns the URL into a `NavigationPath` and assigns it to `appRouter.path`, **replacing** the stack instead of pushing on top.
- The generated `navigate(to:)` only logs the host. Add each deep-linkable route there, and register your URL scheme (`CFBundleURLTypes`) in Info.plist; the generated Info.plist has none.

```swift
// App/Navigation/AppNavigationCoordinator.swift

// MARK: - Private Methods

private extension AppNavigationCoordinator {
    func navigate(to url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            Self.logger.warning("Deep link ignored: invalid URL components")
            return
        }

        var path = NavigationPath()
        switch host {
        case "article":
            guard let articleId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
                return
            }
            path.append(ArticleRoute.detail(articleId: articleId))
        default:
            Self.logger.debug("Deep link ignored: unknown host \(host, privacy: .public)")
            return
        }
        appRouter.path = path
    }
}
```

The route pushed by a deep link must be resolved by a registered `RouteResolver`, and every route must be `Codable` so the path can be persisted.

---

## Error Types Templates

### APIError (Data Layer)

```swift
// Core/Networking/APIError.swift
nonisolated enum APIError: Error, Sendable {
    case networkError(URLError)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(DecodingError)
    case invalidURL
    case unknown(SendableError)

    var isRetryable: Bool {
        switch self {
        case let .networkError(urlError):
            let retryableCodes: [URLError.Code] = [
                .timedOut, .networkConnectionLost, .notConnectedToInternet,
                .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed
            ]
            return retryableCodes.contains(urlError.code)
        case let .httpError(statusCode, _):
            return statusCode >= 500 || statusCode == 429
        case .decodingError, .invalidURL, .unknown:
            return false
        }
    }
}
```

### DomainError (Domain Layer)

```swift
// MARK: - DomainError (Domain/Common/DomainError.swift)

enum DomainError: Error, Sendable, Equatable {
    case network
    case notFound
    case unauthorized
    case server
    case parsing
    case unknown
}
```

`DomainError` knows nothing about `APIError`. The translation lives in Data:

```swift
// MARK: - DomainError + Error Mapping (Data/Common/DomainErrorMapping.swift)

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
}
```

`mapAPIError(_:)` is a private helper in the same file that applies the `APIError` rules listed in [Error Handling Between Layers](#error-handling-between-layers). Add feature-specific cases to `DomainError` (and to `ErrorDecorator.from(_:)`) only when the UI must react differently; don't create per-feature error enums that duplicate it.

### ErrorDecorator (Presentation, in Core)

```swift
// MARK: - ErrorDecorator (Core/Common/Models/ErrorDecorator.swift)

struct ErrorDecorator: Sendable {
    // MARK: - Properties

    let title: String
    let message: String
    let retryAction: (@Sendable () -> Void)?

    // MARK: - Static Factories

    static let generic = ErrorDecorator(title: String(localized: "error.title.generic"),
                                        message: String(localized: "error.message.generic"),
                                        retryAction: nil)
}

// MARK: - DomainError Mapping

extension ErrorDecorator {
    static func from(_ error: DomainError) -> ErrorDecorator {
        switch error {
        case .network: .network
        case .notFound: .notFound
        case .server: .server
        case .parsing, .unknown, .unauthorized: .generic
        }
    }
}
```

The generated file also defines `.notFound`, `.network` and `.server`. `ErrorView` shows a retry button when `retryAction` is set.

---

## Concurrency (Playbook)

- ViewModels, Routers, Factories, `AppRouter`, `AppNavigationCoordinator`: explicitly `@MainActor` (there is no default actor isolation).
- UseCases/Repos/DataSources/mappers: nonisolated `Sendable` structs with `async` APIs, never `@MainActor`.
- Don't ignore cancellations:
  - If you catch errors, re-throw `CancellationError` (`DomainError.catching` already does).
  - In the ViewModel, restore the previous state on `CancellationError` instead of showing an error.

Recommended patterns:
- In View: `.task(id:) { await viewModel.load() }` (auto-cancels).
- In VM if you need manual control:
  - `private var loadTask: Task<Void, Never>?`
  - `loadTask?.cancel()` before creating a new one.

## Dependency Injection

- Manual constructor injection, no DI container.
- `AppDependencies` (`App/Config/AppDependencies.swift`) holds app-lifetime dependencies: the shared `APIClient` and, when SwiftData is enabled, the `SwiftDataStack`. It is created once in `@main`.
- One `@MainActor enum <Feature>Factory` per feature with `static func makeView(appRouter:dependencies:)`. Private `make*` helpers build DataSource -> Mapper -> Repository -> UseCase -> DecoratorMapper -> Router -> ViewModel -> View.
- Factories build a new graph per screen; keep them and the `init`s they call cheap (no I/O or decoding).

### Factory Example

```swift
// MARK: - ArticleFactory (Features/Article/DI/ArticleFactory.swift)

@MainActor
enum ArticleFactory {
    // MARK: - Public Methods

    static func makeView(appRouter: AppRouter, dependencies: AppDependencies) -> some View {
        let viewModel = makeViewModel(appRouter: appRouter, apiClient: dependencies.apiClient)
        return ArticleView(viewModel: viewModel)
    }
}

// MARK: - Private Factory Methods

private extension ArticleFactory {
    // MARK: - DataSources

    static func makeRemoteDataSource(apiClient: APIClient) -> ArticleRemoteDataSource {
        ArticleRemoteDataSourceImpl(apiClient: apiClient)
    }

    // MARK: - Mappers

    static func makeDTOMapper() -> ArticleDTOMapper {
        ArticleDTOMapperImpl()
    }

    // MARK: - Repositories

    static func makeRepository(apiClient: APIClient) -> ArticleRepository {
        ArticleRepositoryImpl(remoteDataSource: makeRemoteDataSource(apiClient: apiClient),
                              mapper: makeDTOMapper())
    }

    // MARK: - UseCases

    static func makeUseCase(apiClient: APIClient) -> ArticleUseCase {
        ArticleUseCaseImpl(repository: makeRepository(apiClient: apiClient))
    }

    // MARK: - Decorator Mappers

    static func makeDecoratorMapper() -> ArticleDecoratorMapper {
        ArticleDecoratorMapperImpl()
    }

    // MARK: - Navigation

    static func makeRouter(appRouter: AppRouter) -> ArticleRouter {
        ArticleRouterImpl(appRouter: appRouter)
    }

    // MARK: - ViewModels

    static func makeViewModel(appRouter: AppRouter, apiClient: APIClient) -> ArticleViewModel {
        ArticleViewModel(useCase: makeUseCase(apiClient: apiClient),
                         decoratorMapper: makeDecoratorMapper(),
                         router: makeRouter(appRouter: appRouter))
    }
}
```
