# Testing Rules — Swift Testing (`import Testing`)

> Related skills: `/axiom:audit testing`, `axiom:axiom-swift-testing`
> Axiom complementa: Flaky test diagnosis, CI patterns

## Framework

- Use `import Testing` (avoid XCTest except for legacy).
- Swift Testing is the standard for iOS 18+.

## What to Test (Priority)

| Priority | Component | What to Verify |
|----------|-----------|----------------|
| 🔴 High | UseCase | Success / error / edge cases / business logic |
| 🔴 High | ViewModel | State transitions (loading → loaded, loading → error) |
| 🔴 High | Error Mappers | `DomainError.map` / `DomainError.catching` (`APIError`, `DecodingError` → `DomainError`, cancellation passes through) and `ErrorDecorator.from(_:)` |
| 🟡 Medium | Repository | DTO mapping; data-source failure thrown as `DomainError`; `CancellationError` propagated |
| 🟡 Medium | DecoratorMapper | Model → Decorator mapping |
| 🟢 Low | Router | Emits correct routes |

## File Structure

`Example/ArquitecturaTests/` mirrors the source tree:

```
ArquitecturaTests/
├─ App/
│  ├─ Application/SplashScreen/SplashScreenViewModelTests.swift
│  └─ Navigation/AppNavigationCoordinatorTests.swift
├─ Core/
│  ├─ Common/Models/ErrorDecoratorMappingTests.swift
│  └─ Networking/            # APIEndpointTests, APIErrorTests, InterceptorChainTests, PokeAPIEndpointTests
├─ Data/
│  ├─ Common/DomainErrorMappingTests.swift
│  └─ <Concept>/
│     ├─ DataSources/<Feature><Kind>DataSourceTests.swift
│     ├─ Mappers/<Feature>DTOMapperTests.swift
│     └─ Repositories/<Feature>RepositoryTests.swift
├─ Domain/
│  └─ <Concept>/
│     └─ UseCases/<Feature>UseCaseTests.swift
├─ Features/
│  └─ <Feature>/
│     └─ Presentation/
│        ├─ ViewModels/<Feature>ViewModelTests.swift
│        └─ Mappers/<Feature>DecoratorMapperTests.swift
├─ Mocks/                    # Mock<Feature><Type>.swift (UseCase, Repository, Router, RemoteDataSource, mappers)
└─ ArquitecturaTests.xctestplan
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
@Test("Load features successfully returns loaded state")
func loadFeaturesSuccessfullyReturnsLoadedState() async { }
```

## Complete Example: ViewModel

```swift
// ArquitecturaTests/Features/[Feature]/Presentation/ViewModels/FeatureViewModelTests.swift
import Testing
@testable import Arquitectura

@MainActor
@Suite("FeatureViewModel Tests")
struct FeatureViewModelTests {

    // MARK: - Properties

    private var useCaseMock: MockFeatureUseCase
    private var routerMock: MockFeatureRouter
    private var sut: FeatureViewModel

    // MARK: - Setup

    init() async {
        useCaseMock = MockFeatureUseCase()
        routerMock = MockFeatureRouter()
        sut = FeatureViewModel(useCase: useCaseMock,
                               router: routerMock,
                               decoratorMapper: FeatureDecoratorMapperImpl())
    }

    // MARK: - Success

    @Test("Given success, when loadFeatures, then state is loaded with sections")
    func testGivenSuccessWhenLoadThenStateIsLoaded() async {
        // Given
        let models = [FeatureModel.stub(id: "123", name: "Test Feature")]
        await useCaseMock.setExecuteResult(.success(models))

        // When
        await sut.loadFeatures()

        // Then
        guard case .loaded(let sections) = sut.state else {
            Issue.record("Expected loaded state, got \(sut.state)")
            return
        }
        #expect(sections.count >= 1)
    }

    // MARK: - Error

    @Test("Given DomainError, when loadFeatures, then state is the mapped error")
    func testGivenErrorWhenLoadThenError() async {
        // Given
        await useCaseMock.setExecuteResult(.failure(DomainError.network))

        // When
        await sut.loadFeatures()

        // Then
        #expect(sut.state == .error(ErrorDecorator.from(.network)))
    }

    // MARK: - Cancellation

    @Test("Given cancellation, when loadFeatures, then previous state is restored")
    func testGivenCancellationWhenLoadThenPreviousState() async {
        // Given
        await useCaseMock.setExecuteResult(.failure(CancellationError()))

        // When
        await sut.loadFeatures()

        // Then
        #expect(sut.state == .idle)
    }

    // MARK: - Navigation

    @Test("Given featureId, when navigateToDetail, then router is called")
    func testNavigateToDetailCallsRouter() async {
        // Given
        let featureId = "test-feature-id"

        // When
        sut.navigateToDetail(featureId: featureId)

        // Then
        #expect(routerMock.navigateToDetailCallCount == 1)
        #expect(routerMock.navigateToDetailFeatureId == featureId)
    }

}
```

## Example: DecoratorMapper Test

```swift
// ArquitecturaTests/Features/[Feature]/Presentation/Mappers/FeatureDecoratorMapperTests.swift
import Testing
@testable import Arquitectura

@MainActor
@Suite("FeatureDecoratorMapper Tests")
struct FeatureDecoratorMapperTests {

    // MARK: - Properties

    private var sut: FeatureDecoratorMapperImpl

    // MARK: - Setup

    init() {
        sut = FeatureDecoratorMapperImpl()
    }

    // MARK: - Single Mapping

    @Test("Given implemented model, when map, then decorator has correct status")
    func testImplementedModelMapping() async {
        // Given
        let model = FeatureModel(
            id: "1",
            name: "Test",
            description: "Desc",
            category: .architecture,
            isImplemented: true
        )

        // When
        let decorator = sut.map(model)

        // Then
        #expect(decorator.id == "1")
        #expect(decorator.statusIcon == "checkmark.circle.fill")
        #expect(decorator.statusColor == .implemented)
    }

    // MARK: - Section Mapping

    @Test("Given models with different categories, when mapToSections, then grouped correctly")
    func testMapToSectionsGroupsByCategory() async {
        // Given
        let models = [
            FeatureModel.stub(category: .architecture),
            FeatureModel.stub(category: .ui),
            FeatureModel.stub(category: .architecture)
        ]

        // When
        let sections = sut.mapToSections(models)

        // Then
        #expect(sections.count == 2)

        let architectureSection = sections.first { $0.title == "Architecture" }
        #expect(architectureSection?.features.count == 2)
    }
}
```

## Mocks (Actors for Concurrency)

### Rules

- Simple mocks, no external frameworks.
- Use `actor` for UseCase, Repository and DataSource mocks; `@MainActor final class` for Router mocks (the Router protocols are `@MainActor`).
- Track calls with `private(set) var` properties and expose `set...Result` helpers.
- Naming: `Mock<ProtocolName>` (prefix), in `ArquitecturaTests/Mocks/`.

### Template: Mock UseCase

```swift
// ArquitecturaTests/Mocks/MockFeatureUseCase.swift
import Foundation
@testable import Arquitectura

actor MockFeatureUseCase: FeatureUseCase {

    // MARK: - Properties

    private(set) var executeResult: Result<[FeatureModel], Error> = .success([])
    private(set) var executeCallCount = 0

    // MARK: - Test Helpers

    func setExecuteResult(_ result: Result<[FeatureModel], Error>) {
        executeResult = result
    }

    // MARK: - FeatureUseCase

    func execute() async throws -> [FeatureModel] {
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
// ArquitecturaTests/Mocks/MockFeatureRepository.swift
import Foundation
@testable import Arquitectura

actor MockFeatureRepository: FeatureRepository {

    // MARK: - Properties

    private(set) var fetchFeaturesResult: Result<[FeatureModel], Error> = .success([])
    private(set) var fetchFeaturesCallCount = 0

    // MARK: - Test Helpers

    func setFetchFeaturesResult(_ result: Result<[FeatureModel], Error>) {
        fetchFeaturesResult = result
    }

    // MARK: - FeatureRepository

    func fetchFeatures() async throws -> [FeatureModel] {
        fetchFeaturesCallCount += 1

        switch fetchFeaturesResult {
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
// ArquitecturaTests/Mocks/MockFeatureRouter.swift
import Foundation
@testable import Arquitectura

@MainActor
final class MockFeatureRouter: FeatureRouter {

    // MARK: - Properties

    var navigateToDetailFeatureId: String?
    var navigateToDetailCallCount = 0
    var goBackCallCount = 0

    // MARK: - FeatureRouter

    func navigateToDetail(featureId: String) {
        navigateToDetailFeatureId = featureId
        navigateToDetailCallCount += 1
    }

    func goBack() {
        goBackCallCount += 1
    }
}
```

## UseCase Tests

```swift
// ArquitecturaTests/Domain/<Concept>/UseCases/FeatureUseCaseTests.swift
import Testing
@testable import Arquitectura

@MainActor
@Suite("FeatureUseCase Tests")
struct FeatureUseCaseTests {

    // MARK: - Tests

    @Test("Execute returns features sorted by category")
    func executeReturnsSortedFeatures() async throws {
        // Given
        let unsortedModels = [
            FeatureModel.stub(category: .ui),
            FeatureModel.stub(category: .architecture),
            FeatureModel.stub(category: .security)
        ]

        let mockRepository = MockFeatureRepository()
        await mockRepository.setFetchFeaturesResult(.success(unsortedModels))

        let useCase = FeatureUseCaseImpl(repository: mockRepository)

        // When
        let result = try await useCase.execute()

        // Then
        #expect(result[0].category == .architecture)
        #expect(result[1].category == .security)
        #expect(result[2].category == .ui)
    }

    @Test("Execute propagates repository error")
    func executePropagatesError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 42)
        let mockRepository = MockFeatureRepository()
        await mockRepository.setFetchFeaturesResult(.failure(expectedError))

        let useCase = FeatureUseCaseImpl(repository: mockRepository)

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

## Repository Tests

Inject a mocked DataSource (an `actor` like `MockPokemonDetailRemoteDataSource`) and the real DTOMapper. Verify mapping, that failures come out as `DomainError`, and that cancellation propagates (see `PokemonDetailRepositoryTests`):

```swift
// ArquitecturaTests/Data/<Concept>/Repositories/FeatureRepositoryTests.swift
import Testing
@testable import Arquitectura

@Suite("FeatureRepository Tests")
struct FeatureRepositoryTests {
    // MARK: - Tests

    @Test("Data source failure is thrown as the mapped DomainError")
    func dataSourceFailureThrowsDomainError() async {
        // Given
        let mockDataSource = MockFeatureRemoteDataSource()
        await mockDataSource.setFetchFeaturesResult(.failure(APIError.httpError(statusCode: 500, data: nil)))
        let repository = FeatureRepositoryImpl(remoteDataSource: mockDataSource,
                                               dtoMapper: FeatureDTOMapperImpl())

        // When/Then
        do {
            _ = try await repository.fetchFeatures()
            Issue.record("Expected an error to be thrown")
        } catch {
            #expect(error as? DomainError == .server)
        }
    }

    @Test("Data source cancellation propagates CancellationError")
    func dataSourceCancellationPropagates() async {
        // Given
        let mockDataSource = MockFeatureRemoteDataSource()
        await mockDataSource.setFetchFeaturesResult(.failure(CancellationError()))
        let repository = FeatureRepositoryImpl(remoteDataSource: mockDataSource,
                                               dtoMapper: FeatureDTOMapperImpl())

        // When/Then
        do {
            _ = try await repository.fetchFeatures()
            Issue.record("Expected CancellationError to be thrown")
        } catch {
            #expect(error is CancellationError)
        }
    }
}
```

## Stubs

Add `.stub()` extensions to facilitate test data creation. `Example/` has no `Support/Stubs/` folder yet: its tests build models inline or with private `make…` helpers at the bottom of the test file (e.g. `PokemonDetailRepositoryTests.makeDetailDTO()`). Either style is fine; create `ArquitecturaTests/Support/Stubs/` when stubs are shared across files.

```swift
// ArquitecturaTests/Support/Stubs/FeatureModel+Stub.swift
@testable import Arquitectura

extension FeatureModel {
    static func stub(
        id: String = "stub-id",
        name: String = "Stub Feature",
        description: String = "Stub description",
        category: Category = .architecture,
        isImplemented: Bool = true
    ) -> FeatureModel {
        FeatureModel(
            id: id,
            name: name,
            description: description,
            category: category,
            isImplemented: isImplemented
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
@Test("Notification is sent when feature is saved")
func testNotificationSent() async throws {
    await confirmation("Feature saved notification") { confirm in
        let repository = FeatureRepositoryImpl()

        NotificationCenter.default.addObserver(
            forName: .featureSaved,
            object: nil,
            queue: nil
        ) { _ in
            confirm()
        }

        try await repository.save(FeatureModel.stub())
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

### Testing Cancellation

Make the mock throw `CancellationError()` and assert that the previous state is restored. This is deterministic, with no sleeps (same as `ArchitectureViewModelTests`, `PokemonListViewModelTests`):

```swift
@Test("loadFeatures restores loaded state on cancellation after successful load")
func testCancellationRestoresLoadedState() async {
    // Given
    let mockUseCase = MockFeatureUseCase()
    await mockUseCase.setExecuteResult(.success([.stub()]))
    let viewModel = FeatureViewModel(useCase: mockUseCase,
                                     router: MockFeatureRouter(),
                                     decoratorMapper: FeatureDecoratorMapperImpl())
    await viewModel.loadFeatures()
    let loadedState = viewModel.state

    // When
    await mockUseCase.setExecuteResult(.failure(CancellationError()))
    await viewModel.loadFeatures()

    // Then
    #expect(viewModel.state == loadedState)
}
```

### Testing Error Decorators

ViewModels only map `DomainError` (repositories already translated `APIError`), so the use case mock throws a `DomainError`:

```swift
@Test("Network error produces retryable decorator")
func testNetworkErrorDecorator() async {
    // Given
    let mockUseCase = MockFeatureUseCase()
    await mockUseCase.setExecuteResult(.failure(DomainError.network))

    let viewModel = FeatureViewModel(
        useCase: mockUseCase,
        router: MockFeatureRouter(),
        decoratorMapper: FeatureDecoratorMapperImpl()
    )

    // When
    await viewModel.loadFeatures()

    // Then
    guard case .error(let errorDecorator) = viewModel.state else {
        Issue.record("Expected error state")
        return
    }

    #expect(errorDecorator == .network)
    #expect(errorDecorator.isRetryable == true)
}
```

### Parameterized Tests

```swift
@Test("Category maps to correct section title", arguments: [
    (FeatureModel.Category.architecture, "Architecture"),
    (FeatureModel.Category.ui, "UI"),
    (FeatureModel.Category.data, "Data")
])
func testCategoryMapping(category: FeatureModel.Category, expectedTitle: String) {
    let mapper = FeatureDecoratorMapperImpl()
    let models = [FeatureModel.stub(category: category)]

    let sections = mapper.mapToSections(models)

    #expect(sections.first?.title == expectedTitle)
}
```

### ErrorDecorator Stubs

```swift
// Tests/Support/Stubs/ErrorDecorator+Stub.swift
extension ErrorDecorator {
    static func stub(
        title: String = "Error",
        message: String = "Something went wrong",
        isRetryable: Bool = true
    ) -> ErrorDecorator {
        ErrorDecorator(
            title: title,
            message: message,
            isRetryable: isRetryable
        )
    }

    static let networkStub = ErrorDecorator.stub(
        title: "Network Error",
        message: "Check your connection",
        isRetryable: true
    )

    static let notFoundStub = ErrorDecorator.stub(
        title: "Not Found",
        message: "Item doesn't exist",
        isRetryable: false
    )
}
```

### Testing MainActor Isolation

```swift
@MainActor
@Test("ViewModel updates state on MainActor")
func testMainActorIsolation() async {
    let viewModel = FeatureViewModel(...)

    // This runs on MainActor - safe to access state
    #expect(viewModel.state == .idle)

    await viewModel.loadFeatures()

    // Still on MainActor
    #expect(viewModel.state == .loaded([]))
}
```
