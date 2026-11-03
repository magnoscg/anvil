# Testing Rules — Swift Testing (`import Testing`)

## Framework

- Use `import Testing` (avoid XCTest except for legacy).
- Swift Testing is the standard for iOS 18+.

## What to Test (Priority)

| Priority | Component | What to Verify |
|----------|-----------|----------------|
| High | UseCase | Success / error / edge cases / business logic |
| High | ViewModel | State transitions (loading -> loaded, loading -> error) |
| High | Error Mapping | `APIError` -> `DomainError` (`DomainError.map` / repository tests) |
| Medium | Repository | Data and error mapping |
| Medium | DTOMapper | DTO -> Model mapping |
| Medium | DecoratorMapper | Model -> Decorator mapping |
| Low | Router | Emits correct routes |

## File Structure

`anvil feature` generates the Domain, Data, Features and Mocks files below for every feature. The test target builds with the same `SWIFT_STRICT_CONCURRENCY = complete` and no default actor isolation as the app.

```
[Project]Tests/
+- Domain/
|  +- <Feature>/
|     +- UseCases/
|        +- <Feature>UseCaseTests.swift
+- Data/
|  +- <Feature>/
|     +- Repositories/
|     |  +- <Feature>RepositoryTests.swift
|     +- Mappers/
|        +- <Feature>DTOMapperTests.swift
+- Features/
|  +- <Feature>/
|     +- Presentation/
|        +- ViewModels/
|        |  +- <Feature>ViewModelTests.swift
|        +- Mappers/
|           +- <Feature>DecoratorMapperTests.swift
+- Core/                                  # Add by hand when needed
|  +- Networking/
|     +- APIClientTests.swift
+- Mocks/
   +- <Feature>UseCaseMock.swift
   +- <Feature>RepositoryMock.swift
   +- <Feature>RouterMock.swift
   +- <Feature>RemoteDataSourceMock.swift
   +- <Feature>DTOMapperMock.swift
   +- <Feature>DecoratorMapperMock.swift
```

## Naming & Structure

### Given / When / Then Pattern

Use the pattern in the test name or in comments:

```swift
@Test("Given success, when load, then state is loaded with sections")
func testGivenSuccessWhenLoadThenStateIsLoaded() async {
    // Given
    // When
    // Then
}
```

### Alternative Naming

Also valid: descriptive name without `test` prefix:

```swift
@Test("Load articles successfully returns loaded state")
func loadArticlesSuccessfullyReturnsLoadedState() async { }
```

## Complete Example: ViewModel

```swift
// [Project]Tests/Features/Article/Presentation/ViewModels/ArticleViewModelTests.swift
import Testing
@testable import MyApp

@MainActor
@Suite("ArticleViewModel Tests")
struct ArticleViewModelTests {

    // MARK: - Properties

    private var useCaseMock: ArticleUseCaseMock
    private var decoratorMapperMock: ArticleDecoratorMapperMock
    private var routerMock: ArticleRouterMock
    private var sut: ArticleViewModel

    // MARK: - Setup

    init() {
        useCaseMock = ArticleUseCaseMock()
        decoratorMapperMock = ArticleDecoratorMapperMock()
        routerMock = ArticleRouterMock()
        sut = ArticleViewModel(useCase: useCaseMock,
                               decoratorMapper: decoratorMapperMock,
                               router: routerMock)
    }

    // MARK: - Success

    @Test("Given success, when loadArticles, then state is loaded with sections")
    func testGivenSuccessWhenLoadThenStateIsLoaded() async {
        // Given
        let models = [ArticleModel.stub(id: "123", title: "Test Article")]
        useCaseMock.executeResult = .success(models)

        // When
        await sut.loadArticles()

        // Then
        guard case .loaded(let sections) = sut.state else {
            Issue.record("Expected loaded state, got \(sut.state)")
            return
        }
        #expect(sections.count >= 1)
        #expect(useCaseMock.executeCallCount == 1)
    }

    // MARK: - Error

    @Test("Given DomainError.network, when loadArticles, then state is the network error")
    func testGivenErrorWhenLoadThenError() async {
        // Given
        useCaseMock.executeResult = .failure(DomainError.network)

        // When
        await sut.loadArticles()

        // Then
        guard case .error(let errorDecorator) = sut.state else {
            Issue.record("Expected error state, got \(sut.state)")
            return
        }
        #expect(errorDecorator.title == ErrorDecorator.network.title)
    }

    // MARK: - Navigation

    @Test("Given articleId, when navigateToDetail, then router is called")
    func testNavigateToDetailCallsRouter() async {
        // Given
        let articleId = "test-article-id"

        // When
        sut.navigateToDetail(articleId: articleId)

        // Then
        #expect(routerMock.navigateToDetailCallCount == 1)
        #expect(routerMock.navigateToDetailArticleId == articleId)
    }
}
```

## Mocks

### Rules

- Simple mocks, no external frameworks.
- Naming: `<Feature><Type>Mock` (suffix), one per file in `[Project]Tests/Mocks/`.
- Mocks of nonisolated protocols (UseCase, Repository, DataSource, mappers) are `final class ...: <Protocol>, @unchecked Sendable`, configured by assigning `Result` properties directly (no async setters). Each test owns its own instances, so the unchecked conformance is safe.
- Mocks of `@MainActor` protocols (Routers) are `@MainActor final class`.
- Track calls with plain counters (`var executeCallCount = 0`) and captured arguments.

### Template: UseCase Mock

```swift
// [Project]Tests/Mocks/ArticleUseCaseMock.swift
import Foundation
@testable import MyApp

// MARK: - ArticleUseCaseMock

final class ArticleUseCaseMock: ArticleUseCase, @unchecked Sendable {
    // MARK: - Properties

    var executeResult: Result<[ArticleModel], Error> = .success([])
    var executeCallCount = 0

    // MARK: - ArticleUseCase

    func execute() async throws -> [ArticleModel] {
        executeCallCount += 1
        return try executeResult.get()
    }
}
```

### Template: Repository Mock

```swift
// [Project]Tests/Mocks/ArticleRepositoryMock.swift
import Foundation
@testable import MyApp

// MARK: - ArticleRepositoryMock

final class ArticleRepositoryMock: ArticleRepository, @unchecked Sendable {
    // MARK: - Properties

    var fetchArticlesResult: Result<[ArticleModel], Error> = .success([])
    var fetchArticlesCallCount = 0

    // MARK: - ArticleRepository

    func fetchArticles() async throws -> [ArticleModel] {
        fetchArticlesCallCount += 1
        return try fetchArticlesResult.get()
    }
}
```

### Template: Router Mock

```swift
// [Project]Tests/Mocks/ArticleRouterMock.swift
import Foundation
@testable import MyApp

// MARK: - ArticleRouterMock

@MainActor
final class ArticleRouterMock: ArticleRouter {

    // MARK: - Properties

    var navigateToDetailArticleId: String?
    var navigateToDetailCallCount = 0
    var goBackCallCount = 0

    // MARK: - ArticleRouter

    func navigateToDetail(articleId: String) {
        navigateToDetailArticleId = articleId
        navigateToDetailCallCount += 1
    }

    func goBack() {
        goBackCallCount += 1
    }
}
```

## UseCase Tests

```swift
// [Project]Tests/Domain/Article/UseCases/ArticleUseCaseTests.swift
import Testing
@testable import MyApp

@Suite("ArticleUseCaseImpl Tests")
struct ArticleUseCaseImplTests {
    // MARK: - Properties

    private var repositoryMock: ArticleRepositoryMock
    private var sut: ArticleUseCaseImpl

    // MARK: - Setup

    init() {
        repositoryMock = ArticleRepositoryMock()
        sut = ArticleUseCaseImpl(repository: repositoryMock)
    }

    // MARK: - Tests

    @Test("Execute returns articles")
    func executeReturnsArticles() async throws {
        // Given
        repositoryMock.fetchArticlesResult = .success([.stub(), .stub()])

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 2)
        #expect(repositoryMock.fetchArticlesCallCount == 1)
    }

    @Test("Execute propagates the repository DomainError unchanged")
    func executePropagatesError() async {
        // Given
        repositoryMock.fetchArticlesResult = .failure(DomainError.network)

        // When/Then
        do {
            _ = try await sut.execute()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? DomainError == .network)
        }
    }
}
```

UseCase suites don't need `@MainActor`: UseCases are nonisolated.

## Repository Tests (Error Mapping)

The repository is where `APIError` becomes `DomainError`, so test the mapping there:

```swift
// [Project]Tests/Data/Article/Repositories/ArticleRepositoryTests.swift

@Test("Given data source throws HTTP 404, when fetch, then throws DomainError.notFound")
func fetchMapsNotFound() async {
    // Given
    remoteDataSourceMock.fetchArticlesResult = .failure(APIError.httpError(statusCode: 404, data: nil))

    // When / Then
    do {
        _ = try await sut.fetchArticles()
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error as? DomainError == .notFound)
        #expect(dtoMapperMock.mapMultipleCallCount == 0)
    }
}
```

## Stubs

Add `.stub()` extensions to facilitate test data creation:

```swift
// [Project]Tests/Support/Stubs/ArticleModel+Stub.swift
@testable import MyApp

extension ArticleModel {
    static func stub(
        id: String = "stub-id",
        title: String = "Stub Article",
        body: String = "Stub body",
        category: Category = .news,
        publishedAt: Date = Date()
    ) -> ArticleModel {
        ArticleModel(
            id: id,
            title: title,
            body: body,
            category: category,
            publishedAt: publishedAt
        )
    }
}
```

## Typical Cases to Cover

| Case | What to Verify |
|------|----------------|
| Success | State `.loaded`, sections with correct data |
| Known error | `DomainError` -> State `.error` with the matching `ErrorDecorator` (`ErrorDecorator.from(_:)`) |
| Unknown error | State `.error` with `.generic` decorator |
| Loading | State `.loading` before completion |
| Idempotency | Call twice, verify expected behavior (`load()` ignores calls while `.loading`) |
| Cancellation | `CancellationError` restores the previous state, no error shown |
| Parameters | Mock captured correct parameters |

## Tips

- Keep tests deterministic (no long sleeps).
- Use `Issue.record()` instead of `XCTFail()`.
- Use `#expect()` instead of `XCTAssert*()`.
- ViewModel tests need `@MainActor`.
- Prefer simple stubs over complex fixtures.
- Use `// MARK: -` to organize sections in tests.

---

## Advanced Patterns

### Confirmation for Async Events

Use `confirmation` when testing that async events occur:

```swift
@Test("Notification is sent when article is saved")
func testNotificationSent() async throws {
    await confirmation("Article saved notification") { confirm in
        let repository = ArticleRepositoryImpl()

        NotificationCenter.default.addObserver(
            forName: .articleSaved,
            object: nil,
            queue: nil
        ) { _ in
            confirm()
        }

        try await repository.save(ArticleModel.stub())
    }
}
```

### .serialized Trait for Test Isolation

Use `.serialized` when tests must run sequentially (shared state, filesystem, etc.):

```swift
@Suite("Database Tests", .serialized)
struct DatabaseTests {

    @Test func testSave() async throws {
        // First test modifies database
    }

    @Test func testFetch() async throws {
        // Second test reads database
        // Runs AFTER testSave completes
    }
}
```

### Parameterized Tests

```swift
@Test("Category maps to correct section title", arguments: [
    (ArticleModel.Category.news, "News"),
    (ArticleModel.Category.tutorial, "Tutorial")
])
func testCategoryMapping(category: ArticleModel.Category, expectedTitle: String) {
    let mapper = ArticleDecoratorMapperImpl()
    let models = [ArticleModel.stub(category: category)]

    let sections = mapper.mapToSections(models)

    #expect(sections.first?.title == expectedTitle)
}
```

### Testing MainActor Isolation

```swift
@MainActor
@Test("ViewModel updates state on MainActor")
func testMainActorIsolation() async {
    let viewModel = ArticleViewModel(...)

    #expect(viewModel.state == .idle)

    await viewModel.loadArticles()

    #expect(viewModel.state == .loaded([]))
}
```
