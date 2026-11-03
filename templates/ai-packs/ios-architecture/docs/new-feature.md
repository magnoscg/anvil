# new-feature.md — Create a Feature (Checklist)

## 0) Quick Decisions (Before Coding)
- Feature name: `[Feature]` (one feature = one screen)
- Domain concept: reuse an existing `Domain/<Concept>/` folder if another screen already models it
- Required routes (push/sheet/deeplink) and whether the feature owns destinations (RouteResolver)
- ViewModel states (idle/loading/loaded/error)
- `DomainError` cases the UI must tell apart (reuse `DomainError`; add a case only when needed)
- Data sources needed: Remote (API) / Local (UserDefaults) / Keychain / SwiftData

> **Scaffold first**: `anvil feature [Feature]` generates every file below, plus tests and mocks. It asks whether to include a Local (UserDefaults) data source, Keychain storage, a RouteResolver and UI tests. Then adapt the generated code.

## 1) Folder Structure

Create files in **three separate locations**:

### Domain Layer (Global)
```
Domain/[Feature]/
  Models/
    [Feature]Model.swift              # Domain model
  UseCases/
    [Feature]UseCase.swift            # Protocol
    [Feature]UseCaseImpl.swift        # Implementation
  Repositories/
    [Feature]Repository.swift         # Protocol (owned by Domain)
```

### Data Layer (Global)
```
Data/[Feature]/
  Repositories/
    [Feature]RepositoryImpl.swift     # Implementation only
  DataSources/
    [Feature]RemoteDataSource.swift   # Protocol + Impl (only if API calls)
    [Feature]LocalDataSource.swift    # Protocol + Impl (optional, UserDefaults)
    [Feature]KeychainDataSource.swift # Protocol + Impl (optional)
  DTO/
    [Feature]DTO.swift                # (only if API calls)
  Mappers/
    [Feature]DTOMapper.swift          # Protocol + Impl (only if API calls)
```

### Features (Presentation Only)
```
Features/[Feature]/
  DI/
    [Feature]Factory.swift

  UI/
    [Feature]View.swift               # Main view
    [Feature]State.swift              # State enum only
    [Feature]Decorator.swift          # Decorators (section, item)
    [Feature]AccessibilityID.swift    # Optional (UI tests)
    Components/                       # Feature-specific subviews (add when needed)
      [Feature]Row.swift

  Presentation/
    ViewModels/
      [Feature]ViewModel.swift
    Mappers/
      [Feature]DecoratorMapper.swift  # Protocol + Impl

  Navigation/
    [Feature]Router.swift             # Route enum + Protocol + Impl (always)
    [Feature]RouteResolver.swift      # Optional: only if the feature owns destinations
```

## 2) Domain

- **Model**: `Sendable` (crosses actor boundaries).
- **Errors**: use the shared `DomainError` (`Domain/Common/DomainError.swift`); no per-feature error enum.
- **Repository Protocol**: `Sendable` contract in `Domain/[Feature]/Repositories/`.
- **UseCase Protocol + Impl**: business logic orchestration. The Impl does not catch or map errors.

```swift
// Domain/Article/Models/ArticleModel.swift
struct ArticleModel: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let body: String
    let category: Category
    let publishedAt: Date

    enum Category: String, Sendable, CaseIterable {
        case news = "News"
        case tutorial = "Tutorial"
    }
}

// Domain/Article/Repositories/ArticleRepository.swift

// MARK: - ArticleRepository

/// Repository contract owned by Domain; the Impl throws only `DomainError` or `CancellationError`.
protocol ArticleRepository: Sendable {
    func fetchArticles() async throws -> [ArticleModel]
}

// Domain/Article/UseCases/ArticleUseCase.swift

// MARK: - ArticleUseCase

protocol ArticleUseCase: Sendable {
    func execute() async throws -> [ArticleModel]
}

// Domain/Article/UseCases/ArticleUseCaseImpl.swift

// MARK: - ArticleUseCaseImpl

struct ArticleUseCaseImpl: ArticleUseCase {
    // MARK: - Properties

    private let repository: ArticleRepository

    // MARK: - Init

    init(repository: ArticleRepository) {
        self.repository = repository
    }

    // MARK: - Public Methods

    func execute() async throws -> [ArticleModel] {
        try await repository.fetchArticles()
    }
}
```

## 3) Data

- **Repository Impl**: implements the Domain protocol and wraps its work in `try await DomainError.catching { ... }`.
- **DataSources**: Remote (API), optional Local (UserDefaults) and Keychain. Protocol + Impl in one file.
- **DTO**: Data Transfer Object (only for API responses).
- **DTOMapper Protocol + Impl** (one file): transformations DTO -> Domain Model.
- **Error mapping**: `APIError` -> `DomainError` happens only in `DomainError.catching` / `DomainError.map` (`Data/Common/DomainErrorMapping.swift`).

### DataSource Rules

| DataSource | When to use | Returns |
|------------|-------------|---------|
| RemoteDataSource | Feature makes API calls (`APIClient`) | `[FeatureDTO]` |
| LocalDataSource (optional) | Small local cache in `UserDefaults` | `[FeatureDTO]` |
| KeychainDataSource (optional) | Secrets / tokens through `KeychainHelper` | `String?` |
| SwiftData | Persistent models (only when SwiftData is enabled) | see `swiftdata.md` |

### Repository with DTOMapper

```swift
// Data/Article/Repositories/ArticleRepositoryImpl.swift

// MARK: - ArticleRepositoryImpl

struct ArticleRepositoryImpl: ArticleRepository {
    // MARK: - Properties

    private let remoteDataSource: ArticleRemoteDataSource
    private let mapper: ArticleDTOMapper

    // MARK: - Init

    init(remoteDataSource: ArticleRemoteDataSource,
         mapper: ArticleDTOMapper) {
        self.remoteDataSource = remoteDataSource
        self.mapper = mapper
    }

    // MARK: - Public Methods

    func fetchArticles() async throws -> [ArticleModel] {
        try await DomainError.catching {
            let dtos = try await remoteDataSource.fetchArticles()
            return mapper.map(dtos)
        }
    }
}
```

### RemoteDataSource (returns DTO)

```swift
// Data/Article/DataSources/ArticleRemoteDataSource.swift

// MARK: - ArticleRemoteDataSource

protocol ArticleRemoteDataSource: Sendable {
    func fetchArticles() async throws -> [ArticleDTO]
}

// MARK: - ArticleRemoteDataSourceImpl

struct ArticleRemoteDataSourceImpl: ArticleRemoteDataSource {
    // MARK: - Properties

    private let apiClient: APIClient

    // MARK: - Init

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods

    func fetchArticles() async throws -> [ArticleDTO] {
        try await apiClient.request(Endpoint.get(path: "/articles"))
    }
}
```

The generated `fetch()` is a `fatalError("TODO: ...")` placeholder: replace it with a real `Endpoint` / `APIEndpoint` call before running the screen.

### DTOMapper

```swift
// Data/Article/Mappers/ArticleDTOMapper.swift

// MARK: - ArticleDTOMapper

protocol ArticleDTOMapper: Sendable {
    func map(_ dto: ArticleDTO) -> ArticleModel
    func map(_ dtos: [ArticleDTO]) -> [ArticleModel]
}

// MARK: - ArticleDTOMapperImpl

struct ArticleDTOMapperImpl: ArticleDTOMapper {
    // MARK: - Public Methods

    func map(_ dtos: [ArticleDTO]) -> [ArticleModel] {
        dtos.map { map($0) }
    }

    func map(_ dto: ArticleDTO) -> ArticleModel {
        ArticleModel(
            id: dto.id,
            title: dto.title,
            body: dto.content,
            category: ArticleModel.Category(rawValue: dto.category) ?? .news,
            publishedAt: Date(timeIntervalSince1970: dto.timestamp)
        )
    }
}
```

## 4) Presentation

### State (in UI folder)

```swift
// Features/Article/UI/ArticleState.swift
enum ArticleState: Equatable {
    case idle
    case loading
    case loaded([ArticleSectionDecorator])
    case error(ErrorDecorator)
}
```

### Decorators (in UI folder)

```swift
// Features/Article/UI/ArticleDecorator.swift

// MARK: - ArticleSectionDecorator

struct ArticleSectionDecorator: Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let items: [ArticleItemDecorator]
}

// MARK: - ArticleItemDecorator

struct ArticleItemDecorator: Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let formattedDate: String
}
```

### DecoratorMapper (in Presentation/Mappers)

Protocol + Impl in one file. Like the other mappers it is a nonisolated `Sendable` struct, not `@MainActor`.

```swift
// Features/Article/Presentation/Mappers/ArticleDecoratorMapper.swift

// MARK: - ArticleDecoratorMapper

protocol ArticleDecoratorMapper: Sendable {
    func map(_ model: ArticleModel) -> ArticleItemDecorator
    func mapToSections(_ models: [ArticleModel]) -> [ArticleSectionDecorator]
}

// MARK: - ArticleDecoratorMapperImpl

struct ArticleDecoratorMapperImpl: ArticleDecoratorMapper {
    // MARK: - Public Methods

    func map(_ model: ArticleModel) -> ArticleItemDecorator {
        ArticleItemDecorator(
            id: model.id,
            title: model.title,
            formattedDate: model.publishedAt.formatted(date: .abbreviated, time: .omitted)
        )
    }

    func mapToSections(_ models: [ArticleModel]) -> [ArticleSectionDecorator] {
        Dictionary(grouping: models, by: \.category)
            .map { category, items in
                ArticleSectionDecorator(
                    id: category.rawValue,
                    title: category.rawValue,
                    items: items.map { map($0) }
                )
            }
            .sorted { $0.title < $1.title }
    }
}
```

### ViewModel (in Presentation/ViewModels)

**Note**: No Action/Event enums. Actions are direct methods. **No default values** — everything is injected.

```swift
// Features/Article/Presentation/ViewModels/ArticleViewModel.swift

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

    func navigateToDetail(articleId: String) {
        router.navigateToDetail(articleId: articleId)
    }
}
```

### View (in UI folder)

The View keeps the ViewModel in `@State`, set once with `State(initialValue:)` in `init`. Retry toggles a trigger that restarts `.task(id:)` instead of creating a loose `Task`.

```swift
// Features/Article/UI/ArticleView.swift

// MARK: - ArticleView

struct ArticleView: View {
    // MARK: - Properties

    @State
    private var viewModel: ArticleViewModel

    @State
    private var retryTrigger = false

    // MARK: - Init

    init(viewModel: ArticleViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        content
            .task(id: retryTrigger) {
                await viewModel.loadArticles()
            }
    }
}

// MARK: - Private Views

private extension ArticleView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            LoadingStateView()
        case let .loaded(sections):
            ArticleListContent(sections: sections, onSelect: viewModel.navigateToDetail)
        case let .error(error):
            ErrorView(error: ErrorDecorator(title: error.title,
                                            message: error.message,
                                            retryAction: { retryTrigger.toggle() }))
        }
    }
}
```

## 5) Router

`<Feature>Router.swift` is always generated. `<Feature>RouteResolver.swift` is optional: add it only when the feature owns destinations. A feature that only pushes routes another resolver already handles needs just the Router.

### 5.1) Router (Route enum + Protocol + Impl)
```swift
// Features/Article/Navigation/ArticleRouter.swift

// MARK: - ArticleRoute

enum ArticleRoute: Hashable, Codable {
    case detail(articleId: String)
    case comments(articleId: String)
}

// MARK: - ArticleRouter

@MainActor
protocol ArticleRouter: Sendable {
    func navigateToDetail(articleId: String)
    func navigateToComments(articleId: String)
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

    func navigateToComments(articleId: String) {
        appRouter.push(ArticleRoute.comments(articleId: articleId))
    }

    func goBack() {
        appRouter.pop()
    }
}
```

### 5.2) Route Resolver (optional)
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
                destination(for: route)
            }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func destination(for route: ArticleRoute) -> some View {
        switch route {
        case let .detail(articleId):
            ArticleDetailFactory.makeView(articleId: articleId, appRouter: appRouter, dependencies: dependencies)
        case let .comments(articleId):
            ArticleCommentsFactory.makeView(articleId: articleId, appRouter: appRouter, dependencies: dependencies)
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

Each destination is its own screen feature with its own Factory. The destination View stores its ViewModel with `@State`, so calling the Factory again inside `navigationDestination` does not reset it; keep Factories cheap.

### 5.3) Register in App Root
Add the resolver modifier inside the `NavigationStack` in `App/Navigation/RootNavigationView.swift` (`appRouter` and `dependencies` are already properties there):
```swift
NavigationStack(path: $appRouter.path) {
    ArticleFactory.makeView(appRouter: appRouter, dependencies: dependencies)
        .withArticleRoutes(appRouter: appRouter, dependencies: dependencies)
}
```

To make a route deep-linkable, also handle it in `AppNavigationCoordinator.navigate(to:)` (see `ARCHITECTURE.md`, Deep Linking).

## 6) Dependency Injection

**Rule**: Everything is injected. No default values. All dependencies are protocol implementations. App-lifetime dependencies (the shared `APIClient`, and the `SwiftDataStack` when SwiftData is enabled) come from `AppDependencies`; never create an `APIClientImpl` inside a Factory.

```swift
// Features/Article/DI/ArticleFactory.swift

// MARK: - ArticleFactory

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

## 7) Previews

The generated `[Feature]...Mock` types live in the **test target** (`[Project]Tests/Mocks/`), so `#Preview` in the app target cannot use them. For previews, add small preview-only implementations of the UseCase and Router protocols in the app target (for example `ArticlePreviewUseCase` and `ArticlePreviewRouter`, wrapped in `#if DEBUG`) and inject them:

```swift
// MARK: - Previews

#Preview("Loaded") {
    ArticleView(
        viewModel: ArticleViewModel(
            useCase: ArticlePreviewUseCase(result: .success([])),
            decoratorMapper: ArticleDecoratorMapperImpl(),
            router: ArticlePreviewRouter()
        )
    )
}

#Preview("Error") {
    ArticleView(
        viewModel: ArticleViewModel(
            useCase: ArticlePreviewUseCase(result: .failure(DomainError.network)),
            decoratorMapper: ArticleDecoratorMapperImpl(),
            router: ArticlePreviewRouter()
        )
    )
}
```

## 8) Tests (Minimum)

### Test Locations

`anvil feature` generates these tests and mocks; extend them as the feature grows.

```
[Project]Tests/
  Domain/[Feature]/UseCases/
    [Feature]UseCaseTests.swift
  Data/[Feature]/
    Repositories/
      [Feature]RepositoryTests.swift
    Mappers/
      [Feature]DTOMapperTests.swift
  Features/[Feature]/Presentation/
    ViewModels/
      [Feature]ViewModelTests.swift
    Mappers/
      [Feature]DecoratorMapperTests.swift
  Mocks/
    [Feature]UseCaseMock.swift
    [Feature]RepositoryMock.swift
    [Feature]RouterMock.swift
    [Feature]RemoteDataSourceMock.swift
    [Feature]DTOMapperMock.swift
    [Feature]DecoratorMapperMock.swift
```

### What to Test
- **UseCase**: success and error propagation (if there's logic).
- **ViewModel**: success -> state `.loaded`, `DomainError` -> state `.error`, cancellation -> previous state.
- **Repository**: DTO -> Domain mapping, `APIError` -> `DomainError` mapping (e.g. HTTP 404 -> `.notFound`).
- **DTOMapper**: correct mapping from DTOs to models.
- **Router**: verify correct route is pushed.
- **DecoratorMapper**: correct mapping from models to decorators.

---

## 9) Codable Patterns

### DTO Design Rules

```swift
// Data/Article/DTO/ArticleDTO.swift
struct ArticleDTO: Sendable, Codable {
    let id: String
    let title: String
    let content: String
    let publishedAt: String
    let authorId: String
}
```

### Date Handling

```swift
// Keep as String in DTO, parse in mapper
struct ArticleDTO: Sendable, Codable {
    let publishedAt: String
}

// In DTOMapper
struct ArticleDTOMapperImpl: ArticleDTOMapper {
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func map(_ dto: ArticleDTO) -> ArticleModel {
        ArticleModel(
            id: dto.id,
            title: dto.title,
            body: dto.content,
            publishedAt: dateFormatter.date(from: dto.publishedAt) ?? Date()
        )
    }
}
```

---

## 10) External API Features (APIEndpoint Pattern)

When a feature uses an **external third-party API**, use the `APIEndpoint` protocol instead of the `Endpoint` struct. This pattern encapsulates the base URL within the endpoint itself.

> See `networking.md` for full `APIEndpoint` protocol details.

### When to Use Which

| Scenario | Endpoint Type | Base URL |
|----------|--------------|----------|
| Your own backend API | `Endpoint` struct | From `EnvironmentConfiguration` |
| External API (GitHub, etc.) | `APIEndpoint` protocol | Embedded in endpoint |
