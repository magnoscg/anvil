# Testing Rules — Swift Testing (`import Testing`)

## Framework

- Use `import Testing` (avoid XCTest except for legacy).
- Swift Testing is the standard for iOS 18+.

## What to Test (Priority)

| Priority | Component | What to Verify |
|----------|-----------|----------------|
| High | UseCase | Success / error / edge cases / business logic |
| High | ViewModel | State transitions (loading -> loaded, loading -> error) |
| High | Error Mappers | APIError -> DomainError correctly |
| Medium | Repository | Data and error mapping |
| Medium | DecoratorMapper | Model -> Decorator mapping |
| Low | Router | Emits correct routes |

## File Structure

```
[Project]Tests/
+- Domain/
|  +- <Feature>/
|     +- UseCases/
|        +- <Feature>UseCaseTests.swift
+- Data/
|  +- <Feature>/
|     +- Repositories/
|        +- <Feature>RepositoryTests.swift
+- Features/
|  +- <Feature>/
|     +- Presentation/
|        +- ViewModels/
|        |  +- <Feature>ViewModelTests.swift
|        +- Mappers/
|           +- <Feature>DecoratorMapperTests.swift
+- Core/
|  +- Networking/
|     +- APIClientTests.swift
+- Mocks/
   +- Mock<Feature>UseCase.swift
   +- Mock<Feature>Repository.swift
   +- Mock<Feature>Router.swift
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

    private var useCaseMock: MockArticleUseCase
    private var routerMock: MockArticleRouter
    private var sut: ArticleViewModel

    // MARK: - Setup

    init() async {
        useCaseMock = MockArticleUseCase()
        routerMock = MockArticleRouter()
        sut = ArticleViewModel(
            useCase: useCaseMock,
            router: routerMock
        )
    }

    // MARK: - Success

    @Test("Given success, when loadArticles, then state is loaded with sections")
    func testGivenSuccessWhenLoadThenStateIsLoaded() async {
        // Given
        let models = [ArticleModel.stub(id: "123", title: "Test Article")]
        await useCaseMock.setExecuteResult(.success(models))

        // When
        await sut.loadArticles()

        // Then
        guard case .loaded(let sections) = sut.state else {
            Issue.record("Expected loaded state, got \(sut.state)")
            return
        }
        #expect(sections.count >= 1)
    }

    // MARK: - Error

    @Test("Given error, when loadArticles, then state is error")
    func testGivenErrorWhenLoadThenError() async {
        // Given
        await useCaseMock.setExecuteResult(.failure(NSError(domain: "test", code: 1)))

        // When
        await sut.loadArticles()

        // Then
        guard case .error(let errorDecorator) = sut.state else {
            Issue.record("Expected error state, got \(sut.state)")
            return
        }
        #expect(errorDecorator.isRetryable == true)
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

## Mocks (Actors for Concurrency)

### Rules

- Simple mocks, no external frameworks.
- Use `actor` for mocks that need concurrency safety.
- Track calls with `private(set) var callCount: Int = 0`.
- Naming: `Mock<ProtocolName>` (prefix).

### Template: Mock UseCase

```swift
// [Project]Tests/Mocks/MockArticleUseCase.swift
import Foundation
@testable import MyApp

actor MockArticleUseCase: ArticleUseCase {

    // MARK: - Properties

    var executeResult: Result<[ArticleModel], Error> = .success([])
    var executeCallCount = 0

    // MARK: - Test Helpers

    func setExecuteResult(_ result: Result<[ArticleModel], Error>) {
        executeResult = result
    }

    // MARK: - ArticleUseCase

    func execute() async throws -> [ArticleModel] {
        executeCallCount += 1

        switch executeResult {
        case .success(let models):
            return models
        case .failure(let error):
            throw error
        }
    }
}
```

### Template: Mock Repository

```swift
// [Project]Tests/Mocks/MockArticleRepository.swift
import Foundation
@testable import MyApp

actor MockArticleRepository: ArticleRepository {

    // MARK: - Properties

    var fetchArticlesResult: Result<[ArticleModel], Error> = .success([])
    var fetchArticlesCallCount = 0

    // MARK: - Test Helpers

    func setFetchArticlesResult(_ result: Result<[ArticleModel], Error>) {
        fetchArticlesResult = result
    }

    // MARK: - ArticleRepository

    func fetchArticles() async throws -> [ArticleModel] {
        fetchArticlesCallCount += 1

        switch fetchArticlesResult {
        case .success(let models):
            return models
        case .failure(let error):
            throw error
        }
    }
}
```

### Template: Mock Router

```swift
// [Project]Tests/Mocks/MockArticleRouter.swift
import Foundation
@testable import MyApp

@MainActor
final class MockArticleRouter: ArticleRouter {

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

@MainActor
@Suite("ArticleUseCase Tests")
struct ArticleUseCaseTests {

    // MARK: - Tests

    @Test("Execute returns articles")
    func executeReturnsArticles() async throws {
        // Given
        let mockRepository = MockArticleRepository()
        await mockRepository.setFetchArticlesResult(.success([.stub(), .stub()]))

        let useCase = ArticleUseCaseImpl(repository: mockRepository)

        // When
        let result = try await useCase.execute()

        // Then
        #expect(result.count == 2)
    }

    @Test("Execute propagates repository error")
    func executePropagatesError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 42)
        let mockRepository = MockArticleRepository()
        await mockRepository.setFetchArticlesResult(.failure(expectedError))

        let useCase = ArticleUseCaseImpl(repository: mockRepository)

        // When/Then
        do {
            _ = try await useCase.execute()
            Issue.record("Expected error to be thrown")
        } catch {
            let nsError = error as NSError
            #expect(nsError.code == 42)
        }
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
| Known error | State `.error`, ErrorDecorator with correct `isRetryable` |
| Unknown error | State `.error` with generic decorator |
| Loading | State `.loading` before completion |
| Idempotency | Call twice, verify expected behavior |
| Cancellation | Doesn't change state if Task was cancelled |
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
