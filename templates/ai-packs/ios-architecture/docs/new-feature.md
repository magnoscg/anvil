# new-feature.md — Create a Feature

Checklist for adding one screen (a feature) across Domain, Data and Presentation, with the rule behind each step.
Examples use the feature `Article` and omit the `// MARK: -` headers and doc comments the generator emits (`swiftui-code-style.md`).

## 0) Scaffold First

Run `anvil feature Article` inside the project. It asks four questions (Local `UserDefaults` data source, Keychain storage, RouteResolver, UI tests), writes every file below plus tests and mocks, and prints the wiring steps. Hand-written files are how names and folders drift.

Decide before running it:
- Feature name: one feature = one screen. If another screen already models the concept, reuse its `Domain/<Concept>/` and `Data/<Concept>/` code instead of keeping a second copy.
- Data sources (Remote only, or also Local, Keychain or SwiftData) and whether the feature owns destinations (RouteResolver) or only pushes routes that another resolver handles.
- Which `DomainError` cases the UI must tell apart. Reuse `DomainError`; add a case only when the UI needs it.

After scaffolding you still have to:
1. Replace the placeholder fields (`id`, `name`, `description`) in `ArticleModel`, `ArticleDTO`, `ArticleDecorator` and both mappers.
2. Replace the `fatalError("TODO: ...")` body of `ArticleRemoteDataSourceImpl.fetch()` with a real request (section 3).
3. Define the route cases and register the feature in the app root (section 5).
4. Extend the generated tests (section 8).

## 1) Where the Files Go

```
Domain/Article/
  Models/ArticleModel.swift
  UseCases/ArticleUseCase.swift, ArticleUseCaseImpl.swift   # protocol and implementation, one file each
  Repositories/ArticleRepository.swift                      # protocol, owned by Domain
Data/Article/
  Repositories/ArticleRepositoryImpl.swift
  DataSources/ArticleRemoteDataSource.swift                 # protocol + Impl
  DataSources/ArticleLocalDataSource.swift, ArticleKeychainDataSource.swift   # optional, protocol + Impl
  DTO/ArticleDTO.swift
  Mappers/ArticleDTOMapper.swift                            # protocol + Impl
  DataStubs/StubArticleRemoteDataSource.swift, FixtureArticleRemoteDataSource.swift   # optional (UI tests), Debug only
Features/Article/
  DI/ArticleFactory.swift
  UI/ArticleView.swift, ArticleState.swift, ArticleDecorator.swift
  UI/Components/                                            # feature-only subviews, add when needed
  Presentation/ViewModels/ArticleViewModel.swift
  Presentation/Mappers/ArticleDecoratorMapper.swift         # protocol + Impl
  Navigation/ArticleRouter.swift                            # Route enum + protocol + Impl
  Navigation/ArticleRouteResolver.swift                     # optional
```

UseCase and Repository keep protocol and implementation in separate files (the Repository pair lives in two layers). DataSources, mappers and the Router keep protocol and `Impl` in one file. The whole tree is in `PROJECT-STRUCTURE.md`.

## 2) Domain

- **Model**: a `struct` that is `Sendable`, `Equatable` and `Identifiable`, because it crosses layers and tasks.
- **Errors**: the shared `DomainError` (`Domain/Common/DomainError.swift`). No per-feature error enum: one type keeps the ViewModel's `catch` and `ErrorDecorator.from(_:)` complete.
- **Repository protocol**: in `Domain/Article/Repositories/`. Domain owns the contract and Data implements it, so Domain never imports a Data type.
- **UseCase**: protocol + `Impl`. The `Impl` holds business rules and does not catch or map errors; they arrive typed from the Repository.

```swift
// Domain/Article/Models/ArticleModel.swift
struct ArticleModel: Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let description: String
}

// Domain/Article/Repositories/ArticleRepository.swift
protocol ArticleRepository: Sendable {
    func fetch() async throws -> [ArticleModel]
}

// Domain/Article/UseCases/ArticleUseCase.swift
protocol ArticleUseCase: Sendable {
    func execute() async throws -> [ArticleModel]
}

// Domain/Article/UseCases/ArticleUseCaseImpl.swift
struct ArticleUseCaseImpl: ArticleUseCase, Sendable {
    private let repository: ArticleRepository

    init(repository: ArticleRepository) {
        self.repository = repository
    }

    func execute() async throws -> [ArticleModel] {
        try await repository.fetch()
    }
}
```

## 3) Data

- **RepositoryImpl**: implements the Domain protocol and wraps its work in `try await DomainError.catching { ... }`, so it throws only `DomainError` or `CancellationError`.
- **Errors are mapped once**, in `Data/Common/DomainErrorMapping.swift` (`DomainError.catching`, `DomainError.map`). DataSources throw `APIError` or their own errors and never map to `DomainError`: two mapping sites hide which layer decided.
- **A DataSource `init` does no I/O**: it only stores dependencies. A Factory can run many times (section 5), so reading or decoding in `init` repeats that work. Do it inside the `async throws` method.
- **DTOMapper**: DTO -> Model through two `map(_:)` overloads (one DTO, an array); `ArticleDTOMapperImpl` sits in the same file as the protocol. The Repository property is named `mapper`.
- **Isolation**: whether this code runs on or off the main actor depends on the project's build settings. Read `swift-concurrency.md` before adding `nonisolated`, `@concurrent` or `@MainActor`.

| DataSource | Use for | Returns |
|---|---|---|
| `ArticleRemoteDataSource` | API calls through the shared `APIClient` | `[ArticleDTO]` |
| `ArticleLocalDataSource` (optional) | small cache in `UserDefaults` | `[ArticleDTO]` |
| `ArticleKeychainDataSource` (optional) | secrets through `KeychainHelper` (`security-privacy.md`) | `String?` |
| SwiftData | persistent models, when the project enables it | see `swiftdata.md` |

The optional Local and Keychain data sources are injected into `ArticleRepositoryImpl`, but the generated `fetch()` does not call them yet.

```swift
// Data/Article/DataSources/ArticleRemoteDataSource.swift
protocol ArticleRemoteDataSource: Sendable {
    func fetch() async throws -> [ArticleDTO]
}

struct ArticleRemoteDataSourceImpl: ArticleRemoteDataSource {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetch() async throws -> [ArticleDTO] {
        try await apiClient.request(Endpoint.get(path: "/articles"))
    }
}

// Data/Article/Mappers/ArticleDTOMapper.swift
protocol ArticleDTOMapper: Sendable {
    func map(_ dto: ArticleDTO) -> ArticleModel
    func map(_ dtos: [ArticleDTO]) -> [ArticleModel]
}

// Data/Article/Repositories/ArticleRepositoryImpl.swift
struct ArticleRepositoryImpl: ArticleRepository {
    private let remoteDataSource: ArticleRemoteDataSource
    private let mapper: ArticleDTOMapper

    init(remoteDataSource: ArticleRemoteDataSource,
         mapper: ArticleDTOMapper) {
        self.remoteDataSource = remoteDataSource
        self.mapper = mapper
    }

    func fetch() async throws -> [ArticleModel] {
        try await DomainError.catching {
            let dtos = try await remoteDataSource.fetch()
            return mapper.map(dtos)
        }
    }
}
```

### DTOs, Dates and Formatters

- `ArticleDTO` is `Sendable`, `Equatable` and `Codable` with explicit `CodingKeys`, so renaming a property never changes the wire format by accident.
- Keep a date (say a new `publishedAt` field) as `String` in the DTO and parse it in the DTOMapper with a format style: `try Date(dto.publishedAt, strategy: .iso8601)`. A mapper that can fail becomes `throws` (protocol, `Impl` and `ArticleDTOMapperMock`) and is called with `try` inside `DomainError.catching`; never fall back to `Date()`.
- **Never `try?` in a decoder or a mapper**: it turns bad data into missing data. Let the error travel: `APIClientImpl` wraps decoding failures in `APIError.decodingError`, and `DomainError.catching` maps them to `DomainError.parsing`.
- **Formatters**: never create a `DateFormatter`, `ISO8601DateFormatter` or `NumberFormatter` inline, and never store one in a mapper, View or ViewModel. Format with `.formatted()` (`model.publishedAt.formatted(date: .abbreviated, time: .omitted)`) and parse with `Date.ISO8601FormatStyle`. A formatter that must be shared is a single static instance in `Core/Common/Extensions/`. Configuring a formatter and formatting with it is the costly part, and a mapper is rebuilt on every Factory call.

### External APIs

| Scenario | Endpoint type | Base URL |
|---|---|---|
| The app's own backend | `Endpoint` struct | from `EnvironmentConfiguration` |
| Third-party API | a type conforming to `APIEndpoint` | embedded in the endpoint |

Both go through `APIClient.request(_:)`. Protocol details and a full example: `networking.md`.

## 4) Presentation

- **State** (`UI/ArticleState.swift`): `idle`, `loading`, `loaded`, `error(ErrorDecorator)`. Loaded items live in the ViewModel (`items`), not in the enum. `ErrorDecorator` carries a closure, so the generated `==` is written by hand and compares title and message.
- **Decorator** (`UI/ArticleDecorator.swift`): display-ready values only (`id`, `displayName`, `subtitle`); `Sendable`, `Identifiable`, `Equatable`.
- **DecoratorMapper**: Model -> Decorator through `map(_:)`; a `Sendable` struct declared without `@MainActor`. All formatting happens here, so Views never format.
- **ViewModel**: `@MainActor @Observable final class`. Actions are plain methods (no Action/Event enums) and every dependency is injected through `init` with no default value. On `CancellationError` it restores the previous state: `.task` is cancelled when the view goes away, and a state stuck in `.loading` would stop the next `load()` at its `guard`.
- **Errors**: `DomainError` -> `ErrorDecorator.from(error)`, anything else -> `.generic`. `ErrorDecorator` is shared (`Core/Common/Models/`); there is no per-feature error decorator.

```swift
// Features/Article/Presentation/ViewModels/ArticleViewModel.swift
@MainActor
@Observable
final class ArticleViewModel {
    private(set) var state: ArticleState = .idle
    private(set) var items: [ArticleDecorator] = []

    private let useCase: ArticleUseCase
    private let decoratorMapper: ArticleDecoratorMapper
    private let router: ArticleRouter

    init(useCase: ArticleUseCase,
         decoratorMapper: ArticleDecoratorMapper,
         router: ArticleRouter) {
        self.useCase = useCase
        self.decoratorMapper = decoratorMapper
        self.router = router
    }

    func load() async {
        guard state != .loading else { return }

        let previousState = state
        state = .loading

        do {
            let models = try await useCase.execute()
            let decorators = models.map { decoratorMapper.map($0) }
            items = decorators
            state = .loaded
        } catch is CancellationError {
            state = previousState
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }

    func navigateToDetail(id: String) {
        router.navigateToDetail(id: id)
    }
}
```

### View

- Store the ViewModel as `@State private var` with no inline value and assign it in `init`, after every other stored property. `@State` keeps the first instance for the lifetime of the view's identity, so a repeated Factory call does not reset the screen.
- First load: `.task { await viewModel.load() }`. It starts when the view appears and is cancelled when it goes away.
- Retry: the action starts its own `Task` and calls the same method: `retryAction: { [viewModel] in Task { await viewModel.load() } }`. Capture `viewModel`, not `self`, because `ErrorDecorator.retryAction` is `@Sendable`. Do not restart `.task(id:)` with a flag: a reload on demand does not depend on an id.
- `.idle` renders `Color.clear`, so nothing flashes before the first load starts.

```swift
// Features/Article/UI/ArticleView.swift
@State
private var viewModel: ArticleViewModel

init(viewModel: ArticleViewModel) {
    self.viewModel = viewModel
}
```

The complete View, with `body`, the retry in `errorView(error:)` and the reason for each line, is in `swiftui-code-style.md`.

### Accessibility Identifiers and UI-Test Stubs

With "Include UI tests" the scaffold adds `Shared/AccessibilityIDs/ArticleAccessibilityID.swift` (ids named `article_<element>`, such as `article_retry_button`), stub and fixture DataSources, a Page Object and Screen tests that pass as generated. It applies the ids in `ArticleView`, adds the stub branch to `ArticleFactory` and registers the screen in `UITestScreenRegistry`. A new id goes into the enum and the View reads it from there, as in `.accessibilityIdentifier(ArticleAccessibilityID.retryButton)`; never repeat the string literal. The naming convention, the launch contract and the stubs are in `ui-testing.md`.

## 5) Navigation

- `ArticleRouter.swift` is always generated: the `ArticleRoute` enum, a `@MainActor` protocol and `ArticleRouterImpl`, a `@MainActor struct` that forwards to `AppRouter` (`push`, `pop`, `popToRoot`). The ViewModel depends on the feature protocol, never on `AppRouter`.
- Routes are `Hashable` and `Codable` and carry ids, not models. `Codable` is what lets the `NavigationPath` be saved and restored between launches; `AppRouter.push` accepts nothing else.
- `ArticleRouteResolver.swift` is optional: add it only when the feature owns destinations. Each destination is its own screen with its own Factory.
- SwiftUI can call a destination closure more than once for the same screen. `@State` keeps the first ViewModel, but every call builds the dependency graph again, so keep Factories cheap.

```swift
// Features/Article/Navigation/ArticleRouter.swift
enum ArticleRoute: Hashable, Codable {
    case detail(id: String)
}

@MainActor
protocol ArticleRouter: Sendable {
    func navigateToDetail(id: String)
    func goBack()
}
```

The resolver is a `ViewModifier` that holds `appRouter` and `dependencies`, declares `.navigationDestination(for: ArticleRoute.self)` and maps each case to the destination's `Factory.makeView(...)`; the generated `.detail` destination is a `Text` placeholder. Show the screen by calling `ArticleFactory.makeView(appRouter:dependencies:)` at the root of the `NavigationStack` or from another feature's resolver, and register the resolver on the root view inside the `NavigationStack` of `App/Navigation/RootNavigationView.swift`, where `appRouter` and `dependencies` are already properties: `.withArticleRoutes(appRouter: appRouter, dependencies: dependencies)`.

To open a route from a URL, handle it in `AppNavigationCoordinator.navigate(to:)`. A deep link replaces the stack; it never pushes on top (`ARCHITECTURE.md`).

## 6) Dependency Injection

- `ArticleFactory` is a `@MainActor enum` with one entry point, `makeView(appRouter:dependencies:)`, and one private `static func make...` per dependency, each returning the protocol type.
- Everything is injected through `init`: no default values, no singletons.
- App-lifetime objects (the shared `APIClient`, and `SwiftDataStack` when SwiftData is enabled) come from `AppDependencies`. Never create an `APIClientImpl` in a Factory: each one builds its own `URLSession` and interceptor chain.

```swift
// Features/Article/DI/ArticleFactory.swift
@MainActor
enum ArticleFactory {
    static func makeView(appRouter: AppRouter, dependencies: AppDependencies) -> some View {
        let viewModel = makeViewModel(appRouter: appRouter, apiClient: dependencies.apiClient)
        return ArticleView(viewModel: viewModel)
    }
}
```

## 7) Previews

The scaffold writes no `#Preview`. The generated mocks belong to the test target, so the app target cannot see them: add small `private` stubs of the UseCase and Router protocols at the bottom of the View file and one `#Preview` per state that draws something different. The stubs and an example are in `swiftui-code-style.md`.

## 8) Tests

`anvil feature` writes five suites under `<Project>Tests/`, in the same folders as the code they test (`Domain/Article/UseCases/`, `Data/Article/Repositories/`, `Data/Article/Mappers/`, `Features/Article/Presentation/ViewModels/` and `.../Mappers/`), plus six mocks in `Mocks/` named `Article<Type>Mock` (UseCase, Repository, Router, RemoteDataSource, DTOMapper, DecoratorMapper). The optional Local and Keychain data sources add their mocks, and the Local one a round-trip suite in `Data/Article/DataSources/`. Extend them as the feature grows. Test style and mocks are in `testing.md`; how to run them is in `tooling.md`.

What each suite must cover:
- **UseCase**: success, and a `DomainError` from the repository passing through unchanged.
- **Repository**: DTOs are mapped; a data-source failure is thrown as the mapped `DomainError` (HTTP 404 -> `.notFound`); `CancellationError` propagates as `CancellationError`, never as a `DomainError` (`#expect(throws: CancellationError.self)`).
- **DTOMapper and DecoratorMapper**: every field, including parse failures and formatted strings.
- **ViewModel**: success -> `.loaded` and `items`; `DomainError` -> `.error`; cancellation -> previous state; navigation methods call the router.
- **Route**: a case with associated values encodes and decodes to an equal value.
