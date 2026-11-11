# Testing

Unit-test rules for the generated architecture: Swift Testing conventions, what to cover per layer, mocks, and the canonical ViewModel and Repository tests. UI tests are in `ui-testing.md`.

## Rules

- **Framework.** Unit tests use Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`). XCTest stays only for UI tests (`ui-testing.md`) and performance metrics (`XCTMetric`).
- **Suite.** A `struct` that holds `sut` and its mocks as `private var` and builds them in a synchronous `init()`. Every test gets a fresh instance, so no state leaks between tests. Make `init` `async` only when it awaits something.
- **Names.** Given/When/Then goes in the display name, `@Test("Given …, when …, then …")`. The function is `<method>_<condition>_<expectedResult>`, as in `load_success_setsLoadedState`.
- **Body.** No comments inside a test body, phase markers included: the display name already states the scenario. Separate arrange, act and assert with one blank line. `// MARK: -` is fine outside functions.
- **Determinism.** No `Task.sleep`, no `Date()` in test data (use a fixed value such as `Date(timeIntervalSince1970: 0)`), no dependence on test order: tests run in parallel by default.
- **State.** The State is `Equatable`, so compare it whole: `#expect(sut.state == .error(.from(.network)))`. Two `.error` states are equal when title and message match. Do not unpack it with `guard case … else { Issue.record(…) }`: that checks the case and ignores the payload.
- **Unwrapping.** `try #require(…)` for optionals and casts (`let first = try #require(sut.items.first)`), not a bare `as?`, `if let` or `guard let`: the test stops there and reports the failed expression.
- **Errors.** `#expect(throws:)`, with `await` when the closure is async. Pass a value for `Equatable` errors (`DomainError.notFound`) and a type otherwise (`CancellationError.self`). No `do`/`catch` + `Issue.record` + `as?`: it takes five lines per assertion and passes when nothing is thrown if the `Issue.record` is forgotten.
- **Known failures.** `withKnownIssue` instead of `.disabled`: the test still compiles and runs, and you are told when the issue is fixed.
- **Isolation.** `@MainActor` on a suite only when the SUT is MainActor-isolated: ViewModels and Routers. Never on UseCase, Repository or mapper suites: with the generated build settings (no default actor isolation) those types are nonisolated, and an annotated suite would keep compiling if one became MainActor-isolated by mistake. Other isolation modes: `swift-concurrency.md`.

## What to test

| Component | Priority | Cases to cover |
|---|---|---|
| UseCase | High | Success; the Repository error propagates unchanged; business rules and edge cases |
| ViewModel | High | Success -> `.loaded` and `items`; `DomainError` -> `.error(.from(_:))`; any other error -> `.error(.generic)`; `CancellationError` -> previous state, no error shown; `load()` while `.loading` is ignored; navigation passes the right arguments to the Router |
| Error mapping | High | In the Repository (`DomainError.catching`): each `APIError` -> its `DomainError`, and the mapper is not called; `CancellationError` propagates unmapped |
| Repository | Medium | Success: data source and mapper called once, mapped models returned |
| DTOMapper, DecoratorMapper | Medium | Field-by-field mapping with the real `…Impl`, no mocks |
| Router | Low | Pushes the expected route |

## Test target layout

```text
[Project]Tests/                     written by `anvil feature Article`; mirrors the app tree
+- Domain/Article/UseCases/ArticleUseCaseTests.swift
+- Data/Article/Repositories/ArticleRepositoryTests.swift
+- Data/Article/Mappers/ArticleDTOMapperTests.swift
+- Features/Article/Presentation/ViewModels/ArticleViewModelTests.swift
+- Features/Article/Presentation/Mappers/ArticleDecoratorMapperTests.swift
+- Mocks/Article{UseCase,Repository,RemoteDataSource,DTOMapper,DecoratorMapper,Router}Mock.swift
```

UI tests live in `[Project]UITests/` and their stubs in the app, Debug only (`ui-testing.md`). The generator covers `fetch()` / `execute()` / `load()`. When a feature grows, extend these suites and mocks instead of starting new files. Nothing is generated for `Core/`: add `[Project]Tests/Core/` by hand.

## Mocks

- Hand-written, no mocking framework. Named `<Feature><Type>Mock` (suffix), one per file in `[Project]Tests/Mocks/`.
- Mocks of nonisolated protocols (UseCase, Repository, DataSource, mappers) are `final class <Feature><Type>Mock: <Protocol>, @unchecked Sendable`: a `Result` to stub and a call counter, assigned directly from the test, with no `await` as an `actor` would need.
- Limit of `@unchecked Sendable`: the mutable state has no lock. That is safe only while each test owns its mocks and the SUT calls them one at a time. If the SUT calls a mock in parallel (`async let`, task group), make that mock an `actor` or guard its state with `Mutex` (`Synchronization`, iOS 18+).
- Mocks of `@MainActor` protocols (Routers) are `@MainActor final class` with plain properties; they need no `@unchecked Sendable`.
- Throw what the real layer throws: a DataSource mock throws `APIError`; Repository and UseCase mocks throw `DomainError`. The ViewModel maps only `DomainError`; anything else becomes `.generic`.

```swift
final class ArticleUseCaseMock: ArticleUseCase, @unchecked Sendable {
    var executeResult: Result<[ArticleModel], Error> = .success([])
    var executeCallCount = 0

    func execute() async throws -> [ArticleModel] {
        executeCallCount += 1
        return try executeResult.get()
    }
}
```

## ViewModel suite

```swift
@MainActor
@Suite("ArticleViewModel Tests")
struct ArticleViewModelTests {
    private var mockUseCase: ArticleUseCaseMock
    private var mockDecoratorMapper: ArticleDecoratorMapperMock
    private var mockRouter: ArticleRouterMock
    private var sut: ArticleViewModel

    init() {
        mockUseCase = ArticleUseCaseMock()
        mockDecoratorMapper = ArticleDecoratorMapperMock()
        mockRouter = ArticleRouterMock()
        sut = ArticleViewModel(useCase: mockUseCase, decoratorMapper: mockDecoratorMapper, router: mockRouter)
    }

    @Test("Given use case returns models, when load, then state is loaded")
    func load_success_setsLoadedState() async {
        mockUseCase.executeResult = .success([ArticleModel(id: "1", name: "First", description: "First item")])

        await sut.load()

        #expect(sut.state == .loaded)
        #expect(sut.items.count == 1)
        #expect(mockUseCase.executeCallCount == 1)
    }

    @Test("Given use case throws DomainError.network, when load, then state is the network error")
    func load_domainError_setsMappedErrorState() async {
        mockUseCase.executeResult = .failure(DomainError.network)

        await sut.load()

        #expect(sut.state == .error(.from(.network)))
    }

    @Test("Given a loaded screen, when a reload is cancelled, then the loaded state is kept")
    func load_cancelled_restoresPreviousState() async {
        mockUseCase.executeResult = .success([ArticleModel(id: "1", name: "First", description: "First item")])
        await sut.load()
        mockUseCase.executeResult = .failure(CancellationError())

        await sut.load()

        #expect(sut.state == .loaded)
        #expect(sut.items.count == 1)
    }
}
```

## Repository: error mapping and cancellation

```swift
@Test("Given data source throws HTTP 404, when fetch, then throws DomainError.notFound")
func fetch_dataSourceThrows_throwsDomainError() async {
    mockRemoteDataSource.fetchResult = .failure(APIError.httpError(statusCode: 404, data: nil))

    await #expect(throws: DomainError.notFound) { try await sut.fetch() }
    #expect(mockDTOMapper.mapMultipleCallCount == 0)
}

@Test("Given data source is cancelled, when fetch, then CancellationError propagates")
func fetch_cancelled_propagatesCancellationError() async {
    mockRemoteDataSource.fetchResult = .failure(CancellationError())

    await #expect(throws: CancellationError.self) { try await sut.fetch() }
}
```

## Running tests and deeper reference

- Commands to run the tests: `tooling.md`.
- Deeper reference (Axiom plugin, if installed): `axiom-testing` (`skills/swift-testing.md`, `skills/testing-async.md`) for confirmations, parameterized tests, traits and `.serialized`.
