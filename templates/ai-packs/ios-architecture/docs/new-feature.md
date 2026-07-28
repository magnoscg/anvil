# new-feature.md — Create a Feature (Checklist)

## 0) Quick Decisions (Before Coding)
- Feature name: `[Feature]`
- Required routes (push/sheet/deeplink)
- ViewModel states (idle/loading/loaded/error)
- Domain errors it can throw
- Data sources needed: Remote (API) / Local (Database) / Both

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
```

### Data Layer (Global)
```
Data/[Feature]/
  Repositories/
    [Feature]Repository.swift         # Protocol
    [Feature]RepositoryImpl.swift     # Implementation
  DataSources/
    [Feature]RemoteDataSource.swift   # Protocol (only if API calls)
    [Feature]RemoteDataSourceImpl.swift # (only if API calls)
    [Feature]LocalDataSource.swift    # Protocol (only if database)
    [Feature]LocalDataSourceImpl.swift # (only if database)
  DTO/
    [Feature]DTO.swift                # (only if API calls)
  Mappers/
    [Feature]DTOMapper.swift          # Protocol (only if API calls)
    [Feature]DTOMapperImpl.swift      # (only if API calls)
```

### Features (Presentation Only)
```
Features/[Feature]/
  DI/
    [Feature]Factory.swift

  UI/
    [Feature]View.swift               # Main view
    [Feature]State.swift              # State enum only
    [Feature]Decorator.swift          # Decorators (section, item, error)
    Components/
      [Feature]FeatureRow.swift
      [Feature]DetailView.swift

  Presentation/
    ViewModels/
      [Feature]ViewModel.swift
    Mappers/
      [Feature]DecoratorMapper.swift  # Protocol
      [Feature]DecoratorMapperImpl.swift

  Navigation/                         # 2 files only
    [Feature]Router.swift             # Route enum + Protocol + Impl
    [Feature]RouteResolver.swift
```

## 2) Domain

- **Model**: `Sendable` if crossing boundaries.
- **Error**: enum with business error cases (optional).
- **UseCase Protocol + Impl**: business logic orchestration.

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

// Domain/Article/UseCases/ArticleUseCase.swift
protocol ArticleUseCase: Sendable {
    func execute() async throws -> [ArticleModel]
}

// Domain/Article/UseCases/ArticleUseCaseImpl.swift
struct ArticleUseCaseImpl: ArticleUseCase {
    private let repository: ArticleRepository

    init(repository: ArticleRepository) {
        self.repository = repository
    }

    func execute() async throws -> [ArticleModel] {
        try await repository.fetchArticles()
    }
}
```

## 3) Data

- **Repository Protocol + Impl**: data access contract and implementation.
- **DataSources**: Remote (API) and/or Local (Database).
- **DTO**: Data Transfer Object (only for API responses).
- **DTOMapper Protocol + Impl**: transformations DTO -> Domain Model.
- **Error mapping**: `APIError` -> `DomainError`.

### DataSource Rules

| DataSource | When to use | Returns |
|------------|-------------|---------|
| RemoteDataSource | Feature makes API calls | `[FeatureDTO]` |
| LocalDataSource | Feature uses database (SwiftData) | `[FeatureModel]` |

### Repository with DTOMapper

```swift
// Data/Article/Repositories/ArticleRepository.swift
protocol ArticleRepository: Sendable {
    func fetchArticles() async throws -> [ArticleModel]
}

// Data/Article/Repositories/ArticleRepositoryImpl.swift
struct ArticleRepositoryImpl: ArticleRepository {
    private let remoteDataSource: ArticleRemoteDataSource
    private let dtoMapper: ArticleDTOMapper

    init(
        remoteDataSource: ArticleRemoteDataSource,
        dtoMapper: ArticleDTOMapper
    ) {
        self.remoteDataSource = remoteDataSource
        self.dtoMapper = dtoMapper
    }

    func fetchArticles() async throws -> [ArticleModel] {
        let dtos = try await remoteDataSource.fetchArticles()
        return dtos.map { dtoMapper.mapToDomain($0) }
    }
}
```

### RemoteDataSource (returns DTO)

```swift
// Data/Article/DataSources/ArticleRemoteDataSource.swift
protocol ArticleRemoteDataSource: Sendable {
    func fetchArticles() async throws -> [ArticleDTO]
}

// Data/Article/DataSources/ArticleRemoteDataSourceImpl.swift
struct ArticleRemoteDataSourceImpl: ArticleRemoteDataSource {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchArticles() async throws -> [ArticleDTO] {
        try await apiClient.request(ArticleEndpoint.list)
    }
}
```

### DTOMapper

```swift
// Data/Article/Mappers/ArticleDTOMapper.swift
protocol ArticleDTOMapper: Sendable {
    func mapToDomain(_ dto: ArticleDTO) -> ArticleModel
}

// Data/Article/Mappers/ArticleDTOMapperImpl.swift
struct ArticleDTOMapperImpl: ArticleDTOMapper {
    func mapToDomain(_ dto: ArticleDTO) -> ArticleModel {
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
struct ArticleSectionDecorator: Identifiable, Equatable {
    let id: String
    let title: String
    let items: [ArticleItemDecorator]
}

struct ArticleItemDecorator: Identifiable, Equatable {
    let id: String
    let title: String
    let formattedDate: String
}
```

### DecoratorMapper (in Presentation/Mappers)

```swift
// Features/Article/Presentation/Mappers/ArticleDecoratorMapper.swift
protocol ArticleDecoratorMapper {
    func map(_ model: ArticleModel) -> ArticleItemDecorator
    func mapToSections(_ models: [ArticleModel]) -> [ArticleSectionDecorator]
}

// Features/Article/Presentation/Mappers/ArticleDecoratorMapperImpl.swift
struct ArticleDecoratorMapperImpl: ArticleDecoratorMapper {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    func map(_ model: ArticleModel) -> ArticleItemDecorator {
        ArticleItemDecorator(
            id: model.id,
            title: model.title,
            formattedDate: dateFormatter.string(from: model.publishedAt)
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
@MainActor
@Observable
final class ArticleViewModel {

    private(set) var state: ArticleState = .idle

    private let useCase: ArticleUseCase
    private let router: ArticleRouter
    private let decoratorMapper: ArticleDecoratorMapper

    init(
        useCase: ArticleUseCase,
        router: ArticleRouter,
        decoratorMapper: ArticleDecoratorMapper
    ) {
        self.useCase = useCase
        self.router = router
        self.decoratorMapper = decoratorMapper
    }

    func loadArticles() async {
        guard state != .loading else { return }
        state = .loading

        do {
            let models = try await useCase.execute()
            let sections = decoratorMapper.mapToSections(models)
            state = .loaded(sections)
        } catch is CancellationError {
            return
        } catch {
            state = .error(ErrorDecorator.generic)
        }
    }

    func navigateToDetail(articleId: String) {
        router.navigateToDetail(articleId: articleId)
    }
}
```

### View (in UI folder)

```swift
// Features/Article/UI/ArticleView.swift
struct ArticleView: View {

    @State var viewModel: ArticleViewModel

    var body: some View {
        content
            .task { await viewModel.loadArticles() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let sections):
            ArticleListContent(sections: sections, onSelect: viewModel.navigateToDetail)
        case .error(let error):
            ErrorView(error: error, onRetry: { Task { await viewModel.loadArticles() } })
        }
    }
}
```

## 5) Router (2 Files Pattern)

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
protocol ArticleRouter {
    func navigateToDetail(articleId: String)
    func navigateToComments(articleId: String)
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

    func navigateToComments(articleId: String) {
        appRouter.push(ArticleRoute.comments(articleId: articleId))
    }

    func goBack() {
        appRouter.pop()
    }
}
```

### 5.2) Route Resolver
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
                case .comments(let articleId):
                    ArticleFactory.makeCommentsView(articleId: articleId, appRouter: appRouter)
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

### 5.3) Register in App Root
Add the resolver modifier to your App:
```swift
NavigationStack(path: $appRouter.path) {
    HomeFactory.makeView(appRouter: appRouter)
        .withArticleRoutes(appRouter: appRouter)
}
```

## 6) Dependency Injection

**Rule**: Everything is injected. No default values. All dependencies are protocol implementations.

```swift
// Features/Article/DI/ArticleFactory.swift
@MainActor
enum ArticleFactory {

    // MARK: - Public Methods

    static func makeView(appRouter: AppRouter) -> ArticleView {
        let viewModel = makeViewModel(appRouter: appRouter)
        return ArticleView(viewModel: viewModel)
    }

    static func makeDetailView(articleId: String, appRouter: AppRouter) -> ArticleDetailView {
        ArticleDetailView(articleId: articleId)
    }
}

// MARK: - Private Factory Methods

private extension ArticleFactory {

    static func makeAPIClient() -> APIClient {
        APIClientImpl()
    }

    static func makeRemoteDataSource() -> ArticleRemoteDataSource {
        ArticleRemoteDataSourceImpl(apiClient: makeAPIClient())
    }

    static func makeDTOMapper() -> ArticleDTOMapper {
        ArticleDTOMapperImpl()
    }

    static func makeRepository() -> ArticleRepository {
        ArticleRepositoryImpl(
            remoteDataSource: makeRemoteDataSource(),
            dtoMapper: makeDTOMapper()
        )
    }

    static func makeUseCase(repository: ArticleRepository) -> ArticleUseCase {
        ArticleUseCaseImpl(repository: repository)
    }

    static func makeRouter(appRouter: AppRouter) -> ArticleRouter {
        ArticleRouterImpl(appRouter: appRouter)
    }

    static func makeDecoratorMapper() -> ArticleDecoratorMapper {
        ArticleDecoratorMapperImpl()
    }

    static func makeViewModel(appRouter: AppRouter) -> ArticleViewModel {
        let repository = makeRepository()
        let useCase = makeUseCase(repository: repository)
        let router = makeRouter(appRouter: appRouter)
        let decoratorMapper = makeDecoratorMapper()

        return ArticleViewModel(
            useCase: useCase,
            router: router,
            decoratorMapper: decoratorMapper
        )
    }
}
```

## 7) Previews

```swift
#Preview("Loaded") {
    let mockUseCase = MockArticleUseCase()
    await mockUseCase.setExecuteResult(.success([.stub(), .stub()]))
    return ArticleView(
        viewModel: ArticleViewModel(
            useCase: mockUseCase,
            router: MockArticleRouter(),
            decoratorMapper: ArticleDecoratorMapperImpl()
        )
    )
}

#Preview("Error") {
    let mockUseCase = MockArticleUseCase()
    await mockUseCase.setExecuteResult(.failure(NSError(domain: "", code: 0)))
    return ArticleView(
        viewModel: ArticleViewModel(
            useCase: mockUseCase,
            router: MockArticleRouter(),
            decoratorMapper: ArticleDecoratorMapperImpl()
        )
    )
}
```

## 8) Tests (Minimum)

### Test Locations

```
[Project]Tests/
  Domain/[Feature]/UseCases/
    [Feature]UseCaseTests.swift
  Data/[Feature]/Repositories/
    [Feature]RepositoryTests.swift
  Features/[Feature]/Presentation/
    ViewModels/
      [Feature]ViewModelTests.swift
    Mappers/
      [Feature]DecoratorMapperTests.swift
  Mocks/
    Mock[Feature]Repository.swift
    Mock[Feature]UseCase.swift
    Mock[Feature]Router.swift
```

### What to Test
- **UseCase**: success and error (if there's logic).
- **ViewModel**: success -> state `.loaded`, error -> state `.error`.
- **Repository**: DTO -> Domain mapping, error mapping.
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

    func mapToDomain(_ dto: ArticleDTO) -> ArticleModel {
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
