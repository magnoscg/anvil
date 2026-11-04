# new-feature.md — Create a Feature (Checklist)

> Step-by-step checklist for creating a new feature in Clean Architecture.
> Related skills: `axiom-swiftui-architecture`
> Axiom complementa: Patterns for features with widgets, extensions

## 0) Quick Decisions (Before Coding)
- Screen name: `[Feature]` (Features are per screen)
- Domain concept: reuse an existing `Domain/<Concept>/` if the screen works with the same business concept (`PokemonList` and `PokemonDetail` both use `Domain/Pokemon`), or create a new one
- Required routes (push/sheet/deeplink); does the feature need its own RouteResolver?
- ViewModel states (idle/loading/loaded/error)
- Errors: repositories expose the shared `DomainError` — no per-feature error enum
- Data sources needed: Remote (API) / Static (in-code data) / bundled JSON
- UI test target exists in project? (If yes, plan accessibility identifiers and stub DataSources)

## 1) Folder Structure

Create files in **three separate locations** (paths relative to `Example/Arquitectura/`):

### Domain Layer (Global, by concept)
```
Domain/<Concept>/
  Models/
    [Feature]Model.swift              # Domain model
  Repositories/
    [Feature]Repository.swift         # Protocol (owned by Domain)
  UseCases/
    [Feature]UseCase.swift            # Protocol
    [Feature]UseCaseImpl.swift        # Implementation
```

### Data Layer (Global, mirrors Domain)
```
Data/<Concept>/
  Repositories/
    [Feature]RepositoryImpl.swift     # Impl only, wraps work in DomainError.catching
  DataSources/
    [Feature]RemoteDataSource.swift   # Protocol (only if API calls)
    [Feature]RemoteDataSourceImpl.swift # (only if API calls)
    [Feature]StaticDataSource.swift   # Protocol + Impl (only if in-code data)
    [Feature]JSONDataSource.swift     # Protocol + Impl (only if bundled JSON)
  DTO/
    [Feature]DTO.swift                # (only if decoding API/JSON)
  Mappers/
    [Feature]DTOMapper.swift          # Protocol (only if there are DTOs)
    [Feature]DTOMapperImpl.swift
```

### Features (Presentation Only, per screen)
```
Features/[Feature]/
  DI/
    [Feature]Factory.swift

  UI/
    [Feature]View.swift               # Main view
    [Feature]State.swift              # State enum only
    [Feature]Decorator.swift          # Decorators (section, item)
    Components/
      [Feature]FeatureRow.swift

  Presentation/
    ViewModels/
      [Feature]ViewModel.swift
    Mappers/
      [Feature]DecoratorMapper.swift  # Protocol
      [Feature]DecoratorMapperImpl.swift

  Navigation/
    [Feature]Router.swift             # Route enum + Protocol + Impl (always)
    [Feature]RouteResolver.swift      # Only if the feature resolves its own routes
```

`ErrorDecorator` is shared from `Core/Common/Models/ErrorDecorator.swift`; don't create one per feature.

## 2) Domain

- **Model**: plain `struct` (Sendable is inferred for internal value types).
- **Repository Protocol**: `Domain/<Concept>/Repositories/[Feature]Repository.swift`, `: Sendable`. Document that it throws `DomainError` or `CancellationError`.
- **UseCase Protocol + Impl**: business logic orchestration. The UseCase does **not** catch or map errors.

```swift
// Domain/Feature/Models/FeatureModel.swift
struct FeatureModel: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let title: String
    let body: String
    let category: Category
    let publishedAt: Date

    // MARK: - Category

    enum Category: String, CaseIterable {
        case news = "News"
        case tutorial = "Tutorial"
    }
}

// Domain/Feature/Repositories/FeatureRepository.swift
protocol FeatureRepository: Sendable {
    func fetchFeatures() async throws -> [FeatureModel]
}

// Domain/Feature/UseCases/FeatureUseCase.swift
protocol FeatureUseCase: Sendable {
    func execute() async throws -> [FeatureModel]
}

// Domain/Feature/UseCases/FeatureUseCaseImpl.swift
struct FeatureUseCaseImpl: FeatureUseCase {
    // MARK: - Properties

    private let repository: FeatureRepository

    // MARK: - Init

    init(repository: FeatureRepository) {
        self.repository = repository
    }

    // MARK: - FeatureUseCase

    func execute() async throws -> [FeatureModel] {
        try await repository.fetchFeatures()
    }
}
```

## 3) Data

- **Repository Impl** (`Data/<Concept>/Repositories/`): conforms to the Domain protocol. If it can fail, wrap its body in `try await DomainError.catching { ... }` so it throws only `DomainError` or `CancellationError`.
- **DataSources**: Remote (API), Static (in-code) or JSON (bundled file). They throw `APIError` or their own errors; they never map to `DomainError`.
- **DTO**: Data Transfer Object for decoded payloads. Mark `init(from:)` `nonisolated` (see `PokemonListDTO`).
- **DTOMapper Protocol + Impl**: transformations DTO → Domain Model, methods `nonisolated`.
- **Error mapping**: done once, in `Data/Common/DomainError+Mapping.swift` (`APIError` / `DecodingError` → `DomainError`). Don't add mapping code to the feature.

### DataSource Rules

| DataSource | When to use | Returns | Example |
|------------|-------------|---------|---------|
| RemoteDataSource | Feature makes API calls | DTOs | `PokemonListRemoteDataSourceImpl` |
| StaticDataSource | Data is defined in code | Domain models | `ArchitectureStaticDataSourceImpl` |
| JSONDataSource | Data is a bundled JSON file | DTOs | `ArchitectureDetailJSONDataSourceImpl` |

DataSource `init`s must not do I/O: Factories can run many times. Read/decode inside the `async throws` method, off the main actor with `@concurrent` when it is heavy (see `swift-concurrency.md`).

### Repository with DTOMapper

```swift
// Data/Feature/Repositories/FeatureRepositoryImpl.swift
struct FeatureRepositoryImpl: FeatureRepository {
    // MARK: - Properties

    private let remoteDataSource: FeatureRemoteDataSource
    private let dtoMapper: FeatureDTOMapper

    // MARK: - Init

    init(remoteDataSource: FeatureRemoteDataSource,
         dtoMapper: FeatureDTOMapper) {
        self.remoteDataSource = remoteDataSource
        self.dtoMapper = dtoMapper
    }

    // MARK: - FeatureRepository

    func fetchFeatures() async throws -> [FeatureModel] {
        try await DomainError.catching {
            let dtos = try await remoteDataSource.fetchFeatures()
            return dtos.map { dtoMapper.mapToDomain($0) }
        }
    }
}
```

### RemoteDataSource (returns DTO)

```swift
// Data/Feature/DataSources/FeatureRemoteDataSource.swift
protocol FeatureRemoteDataSource: Sendable {
    func fetchFeatures() async throws -> [FeatureDTO]
}

// Data/Feature/DataSources/FeatureRemoteDataSourceImpl.swift
struct FeatureRemoteDataSourceImpl: FeatureRemoteDataSource {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchFeatures() async throws -> [FeatureDTO] {
        try await apiClient.request(FeatureEndpoint.list)
    }
}
```

### DTOMapper

```swift
// Data/Feature/Mappers/FeatureDTOMapper.swift
protocol FeatureDTOMapper: Sendable {
    nonisolated func mapToDomain(_ dto: FeatureDTO) -> FeatureModel
}

// Data/Feature/Mappers/FeatureDTOMapperImpl.swift
struct FeatureDTOMapperImpl: FeatureDTOMapper {
    nonisolated func mapToDomain(_ dto: FeatureDTO) -> FeatureModel {
        FeatureModel(
            id: dto.id,
            title: dto.title,
            body: dto.content,
            category: FeatureModel.Category(rawValue: dto.category) ?? .news,
            publishedAt: Date(timeIntervalSince1970: dto.timestamp)
        )
    }
}
```

## 4) Presentation

### State (in UI folder)

```swift
// Features/Feature/UI/FeatureState.swift
enum FeatureState: Equatable {
    case idle
    case loading
    case loaded([FeatureSectionDecorator])
    case error(ErrorDecorator)
}
```

### Decorators (in UI folder)

```swift
// Features/Feature/UI/FeatureDecorator.swift
struct FeatureSectionDecorator: Identifiable, Equatable {
    let id: String
    let title: String
    let items: [FeatureItemDecorator]
}

struct FeatureItemDecorator: Identifiable, Equatable {
    let id: String
    let title: String
    let formattedDate: String
}
```

### DecoratorMapper (in Presentation/Mappers)

```swift
// Features/Feature/Presentation/Mappers/FeatureDecoratorMapper.swift
protocol FeatureDecoratorMapper: Sendable {
    func map(_ model: FeatureModel) -> FeatureItemDecorator
    func mapToSections(_ models: [FeatureModel]) -> [FeatureSectionDecorator]
}

// Features/Feature/Presentation/Mappers/FeatureDecoratorMapperImpl.swift
struct FeatureDecoratorMapperImpl: FeatureDecoratorMapper {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    func map(_ model: FeatureModel) -> FeatureItemDecorator {
        FeatureItemDecorator(
            id: model.id,
            title: model.title,
            formattedDate: dateFormatter.string(from: model.publishedAt)
        )
    }

    func mapToSections(_ models: [FeatureModel]) -> [FeatureSectionDecorator] {
        Dictionary(grouping: models, by: \.category)
            .map { category, items in
                FeatureSectionDecorator(
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
// Features/Feature/Presentation/ViewModels/FeatureViewModel.swift
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

### View (in UI folder)

The View stores the ViewModel in `@State` through an explicit `init` (`State(initialValue:)`), and retries by changing the `.task(id:)` value instead of creating a loose `Task` (same as `ArchitectureView`, `PokemonListView`).

```swift
// Features/Feature/UI/FeatureView.swift
import SwiftUI

// MARK: - FeatureView

struct FeatureView: View {
    // MARK: - Properties

    @State
    private var viewModel: FeatureViewModel

    @State
    private var retryTrigger = false

    // MARK: - Init

    init(viewModel: FeatureViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        content
            .task(id: retryTrigger) {
                await viewModel.loadFeatures()
            }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView()
        case let .loaded(sections):
            FeatureListContent(sections: sections, onSelect: viewModel.navigateToDetail)
        case let .error(error):
            ErrorView(error: error) {
                retryTrigger.toggle()
            }
        }
    }
}
```

## 4.5) Accessibility Identifiers (If UI Tests Enabled)

> Only required if the project has a `[Project]UITests` target.
> Full reference: `ui-testing.md` and `create-ui-tests.md`

### AccessibilityID Enum

Create in `Features/[Feature]/UI/[Feature]AccessibilityID.swift`:

```swift
// Features/Feature/UI/FeatureAccessibilityID.swift
enum FeatureAccessibilityID {

    // MARK: - Screen Containers

    static let loadingIndicator = "feature.loadingIndicator"
    static let errorView = "feature.errorView"
    static let retryButton = "feature.retryButton"
    static let emptyView = "feature.emptyView"

    // MARK: - List

    static let list = "feature.list"
    static func row(id: String) -> String { "feature.row.\(id)" }

    // MARK: - Detail

    static let title = "feature.title"
    static let favoriteButton = "feature.favoriteButton"
}
```

### Apply to Views

Add `.accessibilityIdentifier()` to the View's state rendering:

```swift
@ViewBuilder
private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
        LoadingStateView()
            .accessibilityIdentifier(FeatureAccessibilityID.loadingIndicator)
    case let .loaded(sections):
        FeatureListContent(sections: sections, onSelect: viewModel.navigateToDetail)
            .accessibilityIdentifier(FeatureAccessibilityID.list)
    case let .error(error):
        ErrorView(error: error) {
            retryTrigger.toggle()
        }
        .accessibilityIdentifier(FeatureAccessibilityID.errorView)
    }
}
```

For list rows, add identifier with model ID:

```swift
Button { onSelect(decorator.id) } label: {
    // row content
}
.accessibilityIdentifier(FeatureAccessibilityID.row(id: decorator.id))
```

## 4.6) Stub DataSources (If UI Tests Enabled)

> Only required if the project has a `[Project]UITests` target.

Create in `Features/[Feature]/DataStubs/`, wrapped in `#if DEBUG`:

```swift
// Features/Feature/DataStubs/StubFeatureRemoteDataSource.swift
#if DEBUG
import Foundation

struct StubFeatureRemoteDataSource: FeatureRemoteDataSource {

    func fetchFeatures() async throws -> [FeatureDTO] {
        [
            FeatureDTO(
                id: "stub-1",
                title: "UI Test Feature One",
                content: "Content for testing",
                publishedAt: "2026-01-15T10:00:00Z",
                authorId: "author-1"
            ),
            FeatureDTO(
                id: "stub-2",
                title: "UI Test Feature Two",
                content: "More test content",
                publishedAt: "2026-01-16T14:30:00Z",
                authorId: "author-2"
            )
        ]
    }
}
#endif
```

### Factory Integration

Add to existing Factory:

```swift
static var isUITestMode: Bool {
    CommandLine.arguments.contains("-UITestMode")
}

private static func makeRemoteDataSource(apiClient: APIClient) -> FeatureRemoteDataSource {
    #if DEBUG
    if let fixtureName = ProcessInfo.processInfo.environment["FIXTURE_features"] {
        return FixtureFeatureRemoteDataSource(fixtureName: fixtureName)
    }
    if isUITestMode {
        return StubFeatureRemoteDataSource()
    }
    #endif
    return FeatureRemoteDataSourceImpl(apiClient: apiClient)
}
```

## 5) Router (Router always, RouteResolver only when needed)

### 5.1) Router (Route enum + Protocol + Impl)
```swift
// Features/Feature/Navigation/FeatureRouter.swift

// MARK: - FeatureRoute

enum FeatureRoute: Hashable, Codable {
    case detail(featureId: String)
    case comments(featureId: String)
}

// MARK: - FeatureRouter

@MainActor
protocol FeatureRouter: Sendable {
    func navigateToDetail(featureId: String)
    func navigateToComments(featureId: String)
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

    func navigateToComments(featureId: String) {
        appRouter.push(FeatureRoute.comments(featureId: featureId))
    }

    func goBack() {
        appRouter.pop()
    }
}
```

### 5.2) Route Resolver (only if the feature resolves its own routes)

Skip this file when the feature only pushes routes that another resolver already handles (e.g. `ArchitectureDetailRouterImpl` pushes `PokemonListRoute.list`).

```swift
// Features/Feature/Navigation/FeatureRouteResolver.swift
import SwiftUI

// MARK: - FeatureRouteResolver

struct FeatureRouteResolver: ViewModifier {
    // MARK: - Properties

    let appRouter: AppRouter
    let dependencies: AppDependencies

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
            FeatureDetailFactory.makeView(featureId: featureId, appRouter: appRouter, dependencies: dependencies)
        case let .comments(featureId):
            FeatureCommentsFactory.makeView(featureId: featureId, appRouter: appRouter, dependencies: dependencies)
        }
    }
}

// MARK: - View Extension

extension View {
    func withFeatureRoutes(appRouter: AppRouter, dependencies: AppDependencies) -> some View {
        modifier(FeatureRouteResolver(appRouter: appRouter, dependencies: dependencies))
    }
}
```

Each destination screen is its own feature with its own Factory (`PokemonListRouteResolver` calls `PokemonListFactory` and `PokemonDetailFactory`). The Factory runs inside `navigationDestination`, possibly many times, so it must stay cheap.

### 5.3) Register in RootNavigationView
Add the resolver modifier in `App/Navigation/RootNavigationView.swift`, next to the existing ones:
```swift
NavigationStack(path: $appRouter.path) {
    ArchitectureFactory.makeView(appRouter: appRouter)
        .withArchitectureRoutes(appRouter: appRouter)
        .withPokemonListRoutes(appRouter: appRouter, dependencies: dependencies)
        .withFeatureRoutes(appRouter: appRouter, dependencies: dependencies)
}
```

### 5.4) Deep Link (optional)
If the screen must be reachable by URL, add a host to `navigate(to:)` in `App/Navigation/AppNavigationCoordinator.swift`. Build a full `NavigationPath` and call `replaceStack(with:)`; deep links replace the stack, they never push on top. Add a test in `ArquitecturaTests/App/Navigation/AppNavigationCoordinatorTests.swift`.

## 6) Dependency Injection

**Rule**: Everything is injected. No default values. All dependencies are protocol implementations. Shared app-lifetime objects (the `APIClient`) come from `AppDependencies`; never create an `APIClientImpl` in a Factory.

```swift
// Features/Feature/DI/FeatureFactory.swift

// MARK: - FeatureFactory

@MainActor
enum FeatureFactory {
    // MARK: - Public Methods

    static func makeView(appRouter: AppRouter, dependencies: AppDependencies) -> FeatureView {
        let viewModel = makeViewModel(appRouter: appRouter, apiClient: dependencies.apiClient)
        return FeatureView(viewModel: viewModel)
    }
}

// MARK: - Private Factory Methods

private extension FeatureFactory {
    // MARK: - DataSources

    static func makeRemoteDataSource(apiClient: APIClient) -> FeatureRemoteDataSource {
        FeatureRemoteDataSourceImpl(apiClient: apiClient)
    }

    // MARK: - Mappers

    static func makeDTOMapper() -> FeatureDTOMapper {
        FeatureDTOMapperImpl()
    }

    // MARK: - Repositories

    static func makeRepository(apiClient: APIClient) -> FeatureRepository {
        FeatureRepositoryImpl(remoteDataSource: makeRemoteDataSource(apiClient: apiClient),
                              dtoMapper: makeDTOMapper())
    }

    // MARK: - UseCases

    static func makeUseCase(repository: FeatureRepository) -> FeatureUseCase {
        FeatureUseCaseImpl(repository: repository)
    }

    // MARK: - Navigation

    static func makeRouter(appRouter: AppRouter) -> FeatureRouter {
        FeatureRouterImpl(appRouter: appRouter)
    }

    // MARK: - Decorator Mappers

    static func makeDecoratorMapper() -> FeatureDecoratorMapper {
        FeatureDecoratorMapperImpl()
    }

    // MARK: - ViewModels

    static func makeViewModel(appRouter: AppRouter, apiClient: APIClient) -> FeatureViewModel {
        FeatureViewModel(useCase: makeUseCase(repository: makeRepository(apiClient: apiClient)),
                         router: makeRouter(appRouter: appRouter),
                         decoratorMapper: makeDecoratorMapper())
    }
}
```

A feature without networking omits `dependencies` (see `ArchitectureFactory.makeView(appRouter:)`).

## 7) Previews

Previews use small private stubs declared at the bottom of the View file (see `PokemonListView.swift`), not the test-target mocks, which the app target cannot see.

```swift
// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        FeatureView(viewModel: FeatureViewModel(useCase: PreviewFeatureUseCase(),
                                                router: PreviewFeatureRouter(),
                                                decoratorMapper: FeatureDecoratorMapperImpl()))
    }
}

#Preview("Error") {
    NavigationStack {
        FeatureView(viewModel: FeatureViewModel(useCase: PreviewFeatureErrorUseCase(),
                                                router: PreviewFeatureRouter(),
                                                decoratorMapper: FeatureDecoratorMapperImpl()))
    }
}

// MARK: - Preview Helpers

private struct PreviewFeatureUseCase: FeatureUseCase {
    func execute() async throws -> [FeatureModel] {
        []
    }
}

private struct PreviewFeatureErrorUseCase: FeatureUseCase {
    func execute() async throws -> [FeatureModel] {
        throw DomainError.network
    }
}

@MainActor
private struct PreviewFeatureRouter: FeatureRouter {
    func navigateToDetail(featureId: String) {}
    func navigateToComments(featureId: String) {}
    func goBack() {}
}
```

## 8) Tests (Minimum)

### Test Locations

> **Note**: Tests live in `Example/ArquitecturaTests/` and mirror the source tree.

```
ArquitecturaTests/
  Domain/<Concept>/UseCases/
    [Feature]UseCaseTests.swift
  Data/<Concept>/Repositories/
    [Feature]RepositoryTests.swift
  Data/<Concept>/Mappers/
    [Feature]DTOMapperTests.swift
  Features/[Feature]/Presentation/
    ViewModels/
      [Feature]ViewModelTests.swift
    Mappers/
      [Feature]DecoratorMapperTests.swift
  Mocks/
    Mock[Feature]Repository.swift
    Mock[Feature]UseCase.swift
    Mock[Feature]Router.swift
    Mock[Feature]RemoteDataSource.swift
```

### What to Test
- **UseCase**: success and error (if there's logic); errors pass through unchanged.
- **ViewModel**: success → state `.loaded`, `DomainError` → state `.error(ErrorDecorator.from(error))`, cancellation → previous state.
- **Repository**: DTO → Domain mapping; a data-source failure is thrown as the mapped `DomainError`; `CancellationError` propagates (see `PokemonDetailRepositoryTests`).
- **Router**: verify correct route is pushed.
- **DecoratorMapper**: correct mapping from models to decorators.

### UI Tests (Optional)

If the project has a `[Project]UITests` target, also create:

```
[Project]UITests/
  Screens/[Feature]/
    [Feature]ScreenTests.swift       # All states: loaded, empty, error
  Support/Screens/
    [Feature]Screen.swift            # Page Object for element queries
```

> See `ui-testing.md` for full patterns and `create-ui-tests.md` for copy-paste templates.

---

## 9) Codable Patterns

### DTO Design Rules

`Example/` builds with default MainActor isolation, so DTO decoding must be made `nonisolated` explicitly to run off the main actor. The code uses two equivalent styles:
- `nonisolated struct ArchitectureDetailDTO: Codable, Sendable` (whole type nonisolated).
- `struct PokemonListDTO: Equatable` plus `extension PokemonListDTO: Codable` with a `nonisolated init(from:)` and explicit `CodingKeys`.

```swift
// Data/Feature/DTO/FeatureDTO.swift

// ✅ Make DTOs Sendable
struct FeatureDTO: Sendable, Codable {
    let id: String
    let title: String
    let content: String
    let publishedAt: String  // ISO8601 string from API
    let authorId: String
}
```

### Custom CodingKeys (When JSON Keys Differ)

```swift
struct FeatureDTO: Sendable, Codable {
    let id: String
    let title: String
    let content: String
    let publishedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content = "body_content"      // JSON: "body_content"
        case publishedAt = "published_at"  // JSON: "published_at"
    }
}
```

### Date Handling

```swift
// ❌ WRONG: Don't decode dates directly with default strategy
struct FeatureDTO: Codable {
    let publishedAt: Date  // Risky - depends on decoder configuration
}

// ✅ CORRECT: Keep as String in DTO, parse in mapper
struct FeatureDTO: Sendable, Codable {
    let publishedAt: String
}

// In DTOMapper
struct FeatureDTOMapperImpl: FeatureDTOMapper {
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func mapToDomain(_ dto: FeatureDTO) -> FeatureModel {
        FeatureModel(
            id: dto.id,
            title: dto.title,
            body: dto.content,
            publishedAt: dateFormatter.date(from: dto.publishedAt) ?? Date()
        )
    }
}
```

### Never Use `try?` in Decoders

```swift
// ❌ WRONG: Silent failure, data loss
let dto = try? JSONDecoder().decode(FeatureDTO.self, from: data)

// ✅ CORRECT: Let the DecodingError propagate
let dto = try JSONDecoder().decode(FeatureDTO.self, from: data)
```

`APIClientImpl` wraps decoding failures in `APIError.decodingError`. A DataSource that decodes by itself (like `ArchitectureDetailJSONDataSourceImpl`) lets the `DecodingError` propagate. Either way, the repository's `DomainError.catching` maps it to `DomainError.parsing`.

### Bridge Types for Structural Mismatches

When API structure doesn't match domain model:

```swift
// API returns nested structure
// { "user": { "profile": { "name": "John", "avatar_url": "..." } } }

// Bridge DTO matches API structure
struct UserResponseDTO: Sendable, Codable {
    let user: UserWrapperDTO

    struct UserWrapperDTO: Sendable, Codable {
        let profile: ProfileDTO
    }

    struct ProfileDTO: Sendable, Codable {
        let name: String
        let avatarUrl: String

        enum CodingKeys: String, CodingKey {
            case name
            case avatarUrl = "avatar_url"
        }
    }
}

// Domain model is flat
struct UserModel: Sendable, Equatable {
    let name: String
    let avatarUrl: URL?
}

// Mapper flattens the structure
struct UserDTOMapperImpl: UserDTOMapper {
    func mapToDomain(_ dto: UserResponseDTO) -> UserModel {
        UserModel(
            name: dto.user.profile.name,
            avatarUrl: URL(string: dto.user.profile.avatarUrl)
        )
    }
}
```

---

## 10) Route Codable Requirement

For state preservation (NavigationPath persistence), all route enums **MUST** conform to `Codable`:

```swift
// Features/Feature/Navigation/FeatureRouter.swift

// MARK: - FeatureRoute

enum FeatureRoute: Hashable, Codable {  // ← Add Codable
    case list
    case detail(featureId: String)
    case comments(featureId: String)
}
```

### Why Codable?

- `NavigationPath` uses `CodableRepresentation` for persistence
- Without Codable, navigation state cannot be saved/restored
- App termination loses user's navigation position

### Testing Codable Routes

```swift
@Test func routeEncodesAndDecodes() throws {
    let route = FeatureRoute.detail(featureId: "123")
    let data = try JSONEncoder().encode(route)
    let decoded = try JSONDecoder().decode(FeatureRoute.self, from: data)
    #expect(route == decoded)
}
```

---

## 11) External API Features (APIEndpoint Pattern)

When a feature uses an **external third-party API** (not your own backend), use the `APIEndpoint` protocol instead of the `Endpoint` struct. This pattern encapsulates the base URL within the endpoint itself.

> See `networking.md` for full `APIEndpoint` protocol details.

### When to Use Which

| Scenario | Endpoint Type | Base URL |
|----------|--------------|----------|
| Your own backend API | `Endpoint` struct | From `EnvironmentConfiguration` |
| External API (PokeAPI, GitHub, etc.) | `APIEndpoint` protocol | Embedded in endpoint |

### External API Endpoint

```swift
// Core/Networking/PokeAPI/PokeAPIEndpoint.swift
struct PokeAPIEndpoint: APIEndpoint {
    // MARK: - Constants

    private static let pokeAPIBaseURL: URL = {
        guard let url = URL(string: "https://pokeapi.co/api/v2") else {
            fatalError("Invalid PokeAPI base URL constant")
        }
        return url
    }()

    // MARK: - APIEndpoint Properties

    var baseURL: URL {
        Self.pokeAPIBaseURL
    }

    let path: String
    let queryParameters: [String: any CustomStringConvertible & Sendable]?

    // MARK: - Init

    private init(path: String,
                 queryParameters: [String: any CustomStringConvertible & Sendable]? = nil) {
        self.path = path
        self.queryParameters = queryParameters
    }
}

// MARK: - Factory Methods

extension PokeAPIEndpoint {
    static func pokemonList(limit: Int, offset: Int) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon",
                           queryParameters: ["limit": limit, "offset": offset])
    }

    static func pokemonDetail(id: Int) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon/\(id)")
    }
}
```

### External API DataSource

```swift
// Data/Pokemon/DataSources/PokemonListRemoteDataSourceImpl.swift
struct PokemonListRemoteDataSourceImpl: PokemonListRemoteDataSource {
    // MARK: - Properties

    private let apiClient: APIClient

    // MARK: - Init

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - PokemonListRemoteDataSource

    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponseDTO {
        let endpoint = PokeAPIEndpoint.pokemonList(limit: limit, offset: offset)
        return try await apiClient.request(endpoint)
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonListDTO {
        let endpoint = PokeAPIEndpoint.pokemonDetail(id: id)
        return try await apiClient.request(endpoint)
    }
}
```

`PokeAPIEndpoint.pokemonList(...)` resolves to the `APIEndpoint` overload of `APIClient.request`, not the `Endpoint` one.

### Key Differences from Internal API

1. **No `EnvironmentConfiguration`** needed — base URL is in the endpoint
2. **APIClient uses the `APIEndpoint` overload**: `request<T>(_ endpoint: some APIEndpoint)`
3. **Endpoint files live in** `Core/Networking/<APIName>/` (not in the feature folder)
4. **Same Data/Domain/Features pattern** applies for everything else
