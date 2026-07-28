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
|  +-------------+    +----------------------+                 |
|  |   UseCase   |    | Models (pure domain) |                 |
|  +-------------+    +----------------------+                 |
|         |                                                    |
|         v                                                    |
|     Business Logic                                           |
+--------------------------------------------------------------+
                               | uses
                               v
+-------------------------------------------------------------+
|                           DATA                               |
|  +--------------+  +----------------+  +-----------------+   |
|  |  API Client  |  | SwiftData      |  | Repositories    |   |
|  |  DTOs        |  | Models         |  | (Proto + Impl)  |   |
|  +--------------+  +----------------+  +-----------------+   |
|           \______________  MAPPERS  ________________/        |
+-------------------------------------------------------------+
```

## Responsibilities by Layer

### Presentation
- SwiftUI views: render + UI events.
- ViewModels: state + use case coordination.
- Router: navigation, deep links, sheet presentation.
- **Decorators**: transform Domain models to presentation models.
- **DecoratorMappers**: protocol + impl for Domain -> Decorator mapping.

**Not allowed**: URLSession, DTOs, SwiftData, JSON parsing.

### Domain
- **Models** (business models) — ideally `Sendable`.
- **Use cases** (`UseCase` protocol + `UseCaseImpl`) — orchestrate repositories.
- **Domain errors** — typed errors that the UseCase exposes.

**Location**: Global `Domain/<Feature>/` folder with `Models/` and `UseCases/` subfolders.

**Not allowed**: SwiftUI, SwiftData, URLSession, UI framework dependencies, Repository protocols.

### Data
- **Repository protocols** (contracts) + implementations.
- **DataSources** (Remote and Local) — encapsulate network/persistence access.
- API clients, DTOs, decoding/serialization.
- SwiftData models and local storage operations.
- **Mappers** (DTOMapper protocol + impl) between DTO <-> Domain.
- **APIError** — network layer errors.
- **Dual-endpoint system**: `Endpoint` struct for internal APIs (baseURL from environment), `APIEndpoint` protocol for external APIs (baseURL embedded in endpoint). See `networking.md` for details.

**Location**: Global `Data/<Feature>/` folder with `Repositories/`, `DataSources/`, `DTO/`, `Mappers/` subfolders.

> **Rule**: Repositories **always** delegate to DataSources (Remote/Local), never access APIClient or ModelContext directly.

## Naming Conventions

| Type | Naming | Layer |
|------|--------|-------|
| API Response DTO | `ArticleDTO` / `ArticleResponseDTO` | Data |
| Domain Model | `ArticleModel` | Domain |
| SwiftData model | `ArticleSDModel` | Data |
| Remote DataSource | `ArticleRemoteDataSource` + Impl | Data |
| Local DataSource | `ArticleLocalDataSource` + Impl | Data |
| Repository | `ArticleRepository` + Impl | Data |
| Section Decorator (UI) | `ArticleSectionDecorator` | Presentation |
| Item Decorator (UI) | `ArticleItemDecorator` | Presentation |
| DecoratorMapper | `ArticleDecoratorMapper` + Impl | Presentation |
| DTO Mapper | `ArticleDTOMapper` + Impl | Data |

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
// Data: DTO -> Domain Model (in DTOMapperImpl)
extension ArticleDTOMapperImpl: ArticleDTOMapper {
    func mapToDomain(_ dto: ArticleDTO) -> ArticleModel {
        ArticleModel(
            id: dto.id,
            title: dto.title,
            body: dto.content,
            publishedAt: dto.publishedAt
        )
    }
}

// Presentation: Domain -> Decorator (in DecoratorMapperImpl)
extension ArticleDecoratorMapperImpl: ArticleDecoratorMapper {
    func map(_ model: ArticleModel) -> ArticleItemDecorator {
        ArticleItemDecorator(
            id: model.id,
            title: model.title,
            body: model.body,
            formattedDate: dateFormatter.string(from: model.publishedAt)
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
|  DATA (API)                                                          |
|  APIError: .networkError | .httpError | .decodingError | .invalidURL |
+------------------------------+--------------------------------------+
                               | Repository maps to domain error
                               v
+---------------------------------------------------------------------+
|  DOMAIN (UseCase)                                                    |
|  ArticleError: .notFound | .serverError | .networkUnavailable        |
+------------------------------+--------------------------------------+
                               | ViewModel maps to state
                               v
+---------------------------------------------------------------------+
|  PRESENTATION (ViewModel)                                            |
|  State: .error(ErrorDecorator) with localized message                |
+---------------------------------------------------------------------+
```

### ViewModel State with Decorator

```swift
@MainActor
@Observable
final class ArticleViewModel {

    private(set) var state: ArticleState = .idle

    private let useCase: ArticleUseCase
    private let decoratorMapper: ArticleDecoratorMapper

    func loadArticles() async {
        guard state != .loading else { return }
        state = .loading

        do {
            let models = try await useCase.execute()
            let sections = decoratorMapper.mapToSections(models)
            state = .loaded(sections)
        } catch is CancellationError {
            return
        } catch let error as ArticleError {
            state = .error(error.toDecorator())
        } catch {
            state = .error(ErrorDecorator.generic)
        }
    }

    func navigateToDetail(id: String) {
        router.navigateToDetail(id: id)
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
|  - AppRouter.swift (protocol only)                                   |
|  - AppRouterImpl.swift (implementation)                              |
|  - Generic push(_ route: some Hashable & Codable)                   |
|  - Owns NavigationPath                                               |
|  - Does NOT know about specific route types                          |
+---------------------------------------------------------------------+
                                    |
          +-------------------------+-------------------------+
          v                         v                         v
+------------------+    +------------------+    +------------------+
| ArticleRouter    |   |  SettingsRouter   |    |  ProfileRouter   |
| ArticleResolver  |   |  SettingsResolver |    |  ProfileResolver |
+------------------+    +------------------+    +------------------+
   (Feature-owned)         (Feature-owned)         (Feature-owned)
```

### Components (2 Files per Feature)

1. **AppRouter** (Protocol + Impl, in `App/Navigation/`)
   - `AppRouter.swift` — Protocol with `push(_ route: some Hashable & Codable)`
   - `AppRouterImpl.swift` — Owns `NavigationPath`, implements protocol

2. **FeatureRouter** (Per-feature, in `Features/<Feature>/Navigation/`)
   - Contains Route enum + Protocol + Implementation in one file

3. **FeatureRouteResolver** (Per-feature, in `Features/<Feature>/Navigation/`)
   - `ViewModifier` that resolves routes to views
   - Uses `.navigationDestination(for: FeatureRoute.self)`

### Implementation

```swift
// App/Navigation/AppRouter.swift (protocol only)
@MainActor
protocol AppRouter {
    var path: NavigationPath { get set }
    func push(_ route: some Hashable & Codable)
    func pop()
    func popToRoot()
}

// App/Navigation/AppRouterImpl.swift
@MainActor
@Observable
final class AppRouterImpl: AppRouter {
    var path = NavigationPath()

    func push(_ route: some Hashable & Codable) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
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
protocol ArticleRouter {
    func navigateToDetail(articleId: String)
    func goBack()
}

// MARK: - ArticleRouterImpl

@MainActor
struct ArticleRouterImpl: ArticleRouter {
    private let appRouter: AppRouter

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

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
struct ArticleRouteResolver: ViewModifier {
    let appRouter: AppRouter

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: ArticleRoute.self) { route in
                switch route {
                case .detail(let articleId):
                    ArticleFactory.makeDetailView(articleId: articleId, appRouter: appRouter)
                }
            }
    }
}

extension View {
    func withArticleRoutes(appRouter: AppRouter) -> some View {
        modifier(ArticleRouteResolver(appRouter: appRouter))
    }
}
```

### App Root Composition

```swift
@main
struct MyApp: App {
    @State private var appRouter = AppRouterImpl()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appRouter.path) {
                ArticleFactory.makeView(appRouter: appRouter)
                    .withArticleRoutes(appRouter: appRouter)
                    // Add more resolvers as features are added:
                    // .withSettingsRoutes(appRouter: appRouter)
                    // .withProfileRoutes(appRouter: appRouter)
            }
        }
    }
}
```

### Key Benefits

- **Feature isolation**: Each feature defines its own routes without modifying global files
- **Type safety**: Each feature uses its own strongly-typed route enum
- **Scalability**: Adding a new feature only requires adding a new resolver modifier
- **Testability**: Mock the `AppRouter` protocol to test navigation

### Key Notes

- `NavigationPath` lives once at the root; avoid multiple `NavigationStack`.
- ViewModels never import SwiftUI or know about `NavigationStack`; they only use their `FeatureRouter`.
- Tests: mock the `FeatureRouter` (or its protocol) and verify the correct action was called.
- Deep links / Scenes: resolve URL -> specific route and call `appRouter.push(FeatureRoute.someCase)`.

## App State Management

For apps with authentication, onboarding, or complex app-level states, use an explicit state machine instead of scattered booleans.

### AppStateController Pattern

```swift
// App/State/AppState.swift
enum AppState: Equatable {
    case loading
    case unauthenticated
    case onboarding(OnboardingStep)
    case authenticated(User)
    case error(AppError)
}

enum OnboardingStep: Equatable {
    case welcome
    case permissions
    case profile
}

// App/State/AppStateController.swift
@Observable
@MainActor
final class AppStateController {
    private(set) var state: AppState = .loading

    func transition(to newState: AppState) {
        guard isValidTransition(from: state, to: newState) else {
            assertionFailure("Invalid transition from \(state) to \(newState)")
            return
        }
        state = newState
    }

    private func isValidTransition(from: AppState, to: AppState) -> Bool {
        switch (from, to) {
        case (.loading, _): return true
        case (.unauthenticated, .authenticated): return true
        case (.unauthenticated, .onboarding): return true
        case (.onboarding, .authenticated): return true
        case (.authenticated, .unauthenticated): return true
        case (.error, .loading): return true
        default: return false
        }
    }
}
```

**Key Benefits**:
- All state transitions are validated
- No scattered booleans (`isLoggedIn`, `hasCompletedOnboarding`)
- Easy to debug and trace state changes
- Scene lifecycle handled centrally

---

## Sendable Requirements (Swift 6)

For Swift 6 strict concurrency compliance, types that cross actor boundaries **must** conform to `Sendable`.

### Required Sendable Conformances

| Type | Sendable? | Reason |
|------|-----------|--------|
| Domain Models | **Required** | Cross actor boundaries |
| DTOs | **Required** | Cross actor boundaries |
| UseCases (struct) | **Required** | Called from different actors |
| Repositories (struct) | **Required** | Called from different actors |
| DataSources (struct) | **Required** | Called from different actors |
| Mappers (protocol) | **Required** | Used across actor boundaries |
| Decorators | **Recommended** | May be passed between actors |
| ViewModels | **NO** | Already @MainActor isolated |
| Views | **NO** | SwiftUI handles isolation |

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

// Repository Protocol
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

### Deep Link Handler

```swift
// App/Navigation/DeepLinkHandler.swift
struct DeepLinkHandler {

    func handle(_ url: URL, router: AppRouter) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              url.scheme == "myapp" else {
            return
        }

        switch url.host {
        case "article":
            if let articleId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                router.push(ArticleRoute.detail(articleId: articleId))
            }
        case "settings":
            router.push(SettingsRoute.main)
        default:
            break
        }
    }
}
```

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

### Domain Error (Domain Layer)

```swift
// Domain/<Feature>/Errors/<Feature>Error.swift
enum ArticleError: Error, Equatable {
    case notFound
    case serverError(String?)
    case networkUnavailable
    case unknown

    init(from apiError: APIError) {
        switch apiError {
        case .networkError:
            self = .networkUnavailable
        case let .httpError(statusCode, _) where statusCode == 404:
            self = .notFound
        case .httpError:
            self = .serverError(apiError.serverError?.message)
        case .decodingError, .invalidURL, .unknown:
            self = .unknown
        }
    }
}
```

### ErrorDecorator (Presentation Layer)

```swift
// Core/Common/Models/ErrorDecorator.swift
struct ErrorDecorator: Equatable {
    let title: String
    let message: String
    let isRetryable: Bool

    static let generic = ErrorDecorator(
        title: String(localized: "error.generic.title"),
        message: String(localized: "error.generic.message"),
        isRetryable: true
    )

    static let network = ErrorDecorator(
        title: String(localized: "error.network.title"),
        message: String(localized: "error.network.message"),
        isRetryable: true
    )
}
```

---

## Concurrency (Playbook)

- ViewModels: `@MainActor` + `@Observable`.
- UseCases/Repos: `async` without `@MainActor`.
- Don't ignore cancellations:
  - If you catch errors, re-throw `CancellationError`.
  - Avoid updating state if the task was cancelled.

Recommended patterns:
- In View: `.task(id:) { await viewModel.load() }` (auto-cancels).
- In VM if you need manual control:
  - `private var loadTask: Task<Void, Never>?`
  - `loadTask?.cancel()` before creating a new one.

## Dependency Injection

- Factories per feature to build (View <-> VM <-> UseCase <-> Repo).
- Inject protocols (Domain) and concretes (Data) only at the "composition root".

### Factory Example

```swift
// Features/Article/DI/ArticleFactory.swift
@MainActor
enum ArticleFactory {

    static func makeView(appRouter: AppRouter) -> ArticleView {
        let repository = makeRepository()
        let useCase = makeUseCase(repository: repository)
        let router = makeRouter(appRouter: appRouter)
        let decoratorMapper = ArticleDecoratorMapperImpl()
        let viewModel = makeViewModel(useCase: useCase, router: router, decoratorMapper: decoratorMapper)

        return ArticleView(viewModel: viewModel)
    }

    static func makeDetailView(articleId: String, appRouter: AppRouter) -> ArticleDetailView {
        ArticleDetailView(articleId: articleId)
    }
}

private extension ArticleFactory {

    static func makeRepository() -> ArticleRepository {
        ArticleRepositoryImpl()
    }

    static func makeUseCase(repository: ArticleRepository) -> ArticleUseCase {
        ArticleUseCaseImpl(repository: repository)
    }

    static func makeRouter(appRouter: AppRouter) -> ArticleRouter {
        ArticleRouterImpl(appRouter: appRouter)
    }

    static func makeViewModel(
        useCase: ArticleUseCase,
        router: ArticleRouter,
        decoratorMapper: ArticleDecoratorMapper
    ) -> ArticleViewModel {
        ArticleViewModel(
            useCase: useCase,
            router: router,
            decoratorMapper: decoratorMapper
        )
    }
}
```
