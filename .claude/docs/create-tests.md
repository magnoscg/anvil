# create-tests.md — Quick Test Templates (Swift Testing)

> Full reference in `testing.md`. This doc is just copy-paste.
> Related skills: `axiom-swift-testing`

## ViewModel

```swift
// ArquitecturaTests/Features/[Feature]/Presentation/ViewModels/[Feature]ViewModelTests.swift
import Testing
@testable import Arquitectura

@MainActor
@Suite("[Feature]ViewModel Tests")
struct [Feature]ViewModelTests {

    // MARK: - Properties

    private var useCaseMock: Mock[Feature]UseCase
    private var routerMock: Mock[Feature]Router
    private var sut: [Feature]ViewModel

    // MARK: - Setup

    init() async {
        useCaseMock = Mock[Feature]UseCase()
        routerMock = Mock[Feature]Router()
        sut = [Feature]ViewModel(useCase: useCaseMock,
                                 router: routerMock,
                                 decoratorMapper: [Feature]DecoratorMapperImpl())
    }

    // MARK: - Success

    @Test("Given success, when load, then state is loaded")
    func testGivenSuccessWhenLoadThenLoaded() async {
        // Given
        await useCaseMock.setExecuteResult(.success([.stub()]))

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

    @Test("Given DomainError, when load, then state is the mapped error")
    func testGivenErrorWhenLoadThenError() async {
        // Given
        await useCaseMock.setExecuteResult(.failure(DomainError.network))

        // When
        await sut.loadFeatures()

        // Then
        #expect(sut.state == .error(ErrorDecorator.from(.network)))
    }

    // MARK: - Cancellation

    @Test("Given cancellation, when load, then previous state is restored")
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
    func testNavigateToDetailCallsRouter() {
        // Given
        let featureId = "test-id"

        // When
        sut.navigateToDetail(featureId: featureId)

        // Then
        #expect(routerMock.navigateToDetailCallCount == 1)
        #expect(routerMock.navigateToDetailFeatureId == featureId)
    }
}
```

## Mock UseCase

```swift
// ArquitecturaTests/Mocks/Mock[Feature]UseCase.swift
import Foundation
@testable import Arquitectura

actor Mock[Feature]UseCase: [Feature]UseCase {

    // MARK: - Properties

    private(set) var executeResult: Result<[[Feature]Model], Error> = .success([])
    private(set) var executeCallCount = 0

    // MARK: - Test Helpers

    func setExecuteResult(_ result: Result<[[Feature]Model], Error>) {
        executeResult = result
    }

    // MARK: - [Feature]UseCase

    func execute() async throws -> [[Feature]Model] {
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

## Mock Repository

```swift
// ArquitecturaTests/Mocks/Mock[Feature]Repository.swift
import Foundation
@testable import Arquitectura

actor Mock[Feature]Repository: [Feature]Repository {

    // MARK: - Properties

    private(set) var fetchFeaturesResult: Result<[[Feature]Model], Error> = .success([])
    private(set) var fetchFeaturesCallCount = 0

    // MARK: - Test Helpers

    func setFetchFeaturesResult(_ result: Result<[[Feature]Model], Error>) {
        fetchFeaturesResult = result
    }

    // MARK: - [Feature]Repository

    func fetchFeatures() async throws -> [[Feature]Model] {
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

## Mock Router

```swift
// ArquitecturaTests/Mocks/Mock[Feature]Router.swift
import Foundation
@testable import Arquitectura

@MainActor
final class Mock[Feature]Router: [Feature]Router {

    // MARK: - Properties

    var navigateToDetailFeatureId: String?
    var navigateToDetailCallCount = 0
    var goBackCallCount = 0

    // MARK: - [Feature]Router

    func navigateToDetail(featureId: String) {
        navigateToDetailFeatureId = featureId
        navigateToDetailCallCount += 1
    }

    func goBack() {
        goBackCallCount += 1
    }
}
```

## DecoratorMapper Tests

```swift
// ArquitecturaTests/Features/[Feature]/Presentation/Mappers/[Feature]DecoratorMapperTests.swift
import Testing
@testable import Arquitectura

@MainActor
@Suite("[Feature]DecoratorMapper Tests")
struct [Feature]DecoratorMapperTests {

    // MARK: - Properties

    private var sut: [Feature]DecoratorMapperImpl

    // MARK: - Setup

    init() {
        sut = [Feature]DecoratorMapperImpl()
    }

    // MARK: - Single Mapping

    @Test("Given model, when map, then decorator has correct values")
    func testMapSingleModel() {
        // Given
        let model = [Feature]Model.stub(id: "1", name: "Test")

        // When
        let decorator = sut.map(model)

        // Then
        #expect(decorator.id == "1")
        #expect(decorator.name == "Test")
    }

    // MARK: - Section Mapping

    @Test("Given models, when mapToSections, then grouped by category")
    func testMapToSectionsGroupsByCategory() {
        // Given
        let models = [
            [Feature]Model.stub(category: .first),
            [Feature]Model.stub(category: .second),
            [Feature]Model.stub(category: .first)
        ]

        // When
        let sections = sut.mapToSections(models)

        // Then
        #expect(sections.count == 2)
    }
}
```

## UseCase Tests

```swift
// ArquitecturaTests/Domain/<Concept>/UseCases/[Feature]UseCaseTests.swift
import Testing
@testable import Arquitectura

@MainActor
@Suite("[Feature]UseCase Tests")
struct [Feature]UseCaseTests {

    @Test("Execute returns sorted features")
    func executeReturnsSortedFeatures() async throws {
        // Given
        let mockRepository = Mock[Feature]Repository()
        await mockRepository.setFetchFeaturesResult(.success([.stub(), .stub()]))

        let useCase = [Feature]UseCaseImpl(repository: mockRepository)

        // When
        let result = try await useCase.execute()

        // Then
        #expect(result.count == 2)
    }

    @Test("Execute propagates error")
    func executePropagatesError() async {
        // Given
        let mockRepository = Mock[Feature]Repository()
        await mockRepository.setFetchFeaturesResult(.failure(NSError(domain: "test", code: 1)))

        let useCase = [Feature]UseCaseImpl(repository: mockRepository)

        // When/Then
        do {
            _ = try await useCase.execute()
            Issue.record("Expected error")
        } catch {
            #expect((error as NSError).code == 1)
        }
    }
}
```

## Repository Tests

```swift
// ArquitecturaTests/Data/<Concept>/Repositories/[Feature]RepositoryTests.swift
import Testing
@testable import Arquitectura

@Suite("[Feature]Repository Tests")
struct [Feature]RepositoryTests {
    // MARK: - Tests

    @Test("Data source failure is thrown as the mapped DomainError")
    func dataSourceFailureThrowsDomainError() async {
        // Given
        let mockDataSource = Mock[Feature]RemoteDataSource()
        await mockDataSource.setFetchFeaturesResult(.failure(APIError.httpError(statusCode: 404, data: nil)))
        let repository = [Feature]RepositoryImpl(remoteDataSource: mockDataSource,
                                                 dtoMapper: [Feature]DTOMapperImpl())

        // When/Then
        do {
            _ = try await repository.fetchFeatures()
            Issue.record("Expected an error to be thrown")
        } catch {
            #expect(error as? DomainError == .notFound)
        }
    }

    @Test("Data source cancellation propagates CancellationError")
    func dataSourceCancellationPropagates() async {
        // Given
        let mockDataSource = Mock[Feature]RemoteDataSource()
        await mockDataSource.setFetchFeaturesResult(.failure(CancellationError()))
        let repository = [Feature]RepositoryImpl(remoteDataSource: mockDataSource,
                                                 dtoMapper: [Feature]DTOMapperImpl())

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

`Mock[Feature]RemoteDataSource` follows the same `actor` template as `Mock[Feature]Repository` above.

## Stubs

```swift
// ArquitecturaTests/Support/Stubs/[Feature]Model+Stub.swift
@testable import Arquitectura

extension [Feature]Model {
    static func stub(
        id: String = "stub-id",
        name: String = "Stub Name",
        description: String = "Stub description",
        category: Category = .default,
        isImplemented: Bool = true
    ) -> [Feature]Model {
        [Feature]Model(
            id: id,
            name: name,
            description: description,
            category: category,
            isImplemented: isImplemented
        )
    }
}

extension [Feature]ItemDecorator {
    static func stub(
        id: String = "stub-id",
        name: String = "Stub Display Name"
    ) -> [Feature]ItemDecorator {
        [Feature]ItemDecorator(
            id: id,
            name: name,
            description: "Description",
            statusIcon: "checkmark.circle.fill",
            statusColor: .implemented
        )
    }
}

extension ErrorDecorator {
    static func stub(
        title: String = "Error",
        message: String = "Something went wrong",
        isRetryable: Bool = true
    ) -> ErrorDecorator {
        ErrorDecorator(title: title, message: message, isRetryable: isRetryable)
    }
}
```
