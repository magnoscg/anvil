# create-tests.md — Quick Test Templates (Swift Testing)

> Full reference in `testing.md`. This doc is just copy-paste.

## ViewModel

```swift
// [Project]Tests/Features/[Feature]/Presentation/ViewModels/[Feature]ViewModelTests.swift
import Testing
@testable import MyApp

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
        sut = [Feature]ViewModel(
            useCase: useCaseMock,
            router: routerMock
        )
    }

    // MARK: - Success

    @Test("Given success, when load, then state is loaded")
    func testGivenSuccessWhenLoadThenLoaded() async {
        // Given
        await useCaseMock.setExecuteResult(.success([.stub()]))

        // When
        await sut.loadItems()

        // Then
        guard case .loaded(let sections) = sut.state else {
            Issue.record("Expected loaded state, got \(sut.state)")
            return
        }
        #expect(sections.count >= 1)
    }

    // MARK: - Error

    @Test("Given error, when load, then state is error")
    func testGivenErrorWhenLoadThenError() async {
        // Given
        await useCaseMock.setExecuteResult(.failure(NSError(domain: "test", code: 1)))

        // When
        await sut.loadItems()

        // Then
        guard case .error(let errorDecorator) = sut.state else {
            Issue.record("Expected error state, got \(sut.state)")
            return
        }
        #expect(errorDecorator.isRetryable == true)
    }

    // MARK: - Navigation

    @Test("Given itemId, when navigateToDetail, then router is called")
    func testNavigateToDetailCallsRouter() {
        // Given
        let itemId = "test-id"

        // When
        sut.navigateToDetail(itemId: itemId)

        // Then
        #expect(routerMock.navigateToDetailCallCount == 1)
        #expect(routerMock.navigateToDetailItemId == itemId)
    }
}
```

## Mock UseCase

```swift
// [Project]Tests/Mocks/Mock[Feature]UseCase.swift
import Foundation
@testable import MyApp

actor Mock[Feature]UseCase: [Feature]UseCase {

    // MARK: - Properties

    var executeResult: Result<[[Feature]Model], Error> = .success([])
    var executeCallCount = 0

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
// [Project]Tests/Mocks/Mock[Feature]Repository.swift
import Foundation
@testable import MyApp

actor Mock[Feature]Repository: [Feature]Repository {

    // MARK: - Properties

    var fetchItemsResult: Result<[[Feature]Model], Error> = .success([])
    var fetchItemsCallCount = 0

    // MARK: - Test Helpers

    func setFetchItemsResult(_ result: Result<[[Feature]Model], Error>) {
        fetchItemsResult = result
    }

    // MARK: - [Feature]Repository

    func fetchItems() async throws -> [[Feature]Model] {
        fetchItemsCallCount += 1

        switch fetchItemsResult {
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
// [Project]Tests/Mocks/Mock[Feature]Router.swift
import Foundation
@testable import MyApp

@MainActor
final class Mock[Feature]Router: [Feature]Router {

    // MARK: - Properties

    var navigateToDetailItemId: String?
    var navigateToDetailCallCount = 0
    var goBackCallCount = 0

    // MARK: - [Feature]Router

    func navigateToDetail(itemId: String) {
        navigateToDetailItemId = itemId
        navigateToDetailCallCount += 1
    }

    func goBack() {
        goBackCallCount += 1
    }
}
```

## DecoratorMapper Tests

```swift
// [Project]Tests/Features/[Feature]/Presentation/Mappers/[Feature]DecoratorMapperTests.swift
import Testing
@testable import MyApp

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
// [Project]Tests/Domain/[Feature]/UseCases/[Feature]UseCaseTests.swift
import Testing
@testable import MyApp

@MainActor
@Suite("[Feature]UseCase Tests")
struct [Feature]UseCaseTests {

    @Test("Execute returns items")
    func executeReturnsItems() async throws {
        // Given
        let mockRepository = Mock[Feature]Repository()
        await mockRepository.setFetchItemsResult(.success([.stub(), .stub()]))

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
        await mockRepository.setFetchItemsResult(.failure(NSError(domain: "test", code: 1)))

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
// [Project]Tests/Data/[Feature]/Repositories/[Feature]RepositoryTests.swift
import Testing
@testable import MyApp

@MainActor
@Suite("[Feature]Repository Tests")
struct [Feature]RepositoryTests {

    @Test("FetchItems returns items")
    func fetchItemsReturnsItems() async throws {
        // Given
        let mockDataSource = Mock[Feature]RemoteDataSource()
        let mockMapper = Mock[Feature]DTOMapper()
        let repository = [Feature]RepositoryImpl(
            remoteDataSource: mockDataSource,
            dtoMapper: mockMapper
        )

        // When
        let items = try await repository.fetchItems()

        // Then
        #expect(items.count > 0)
    }
}
```

## Stubs

```swift
// [Project]Tests/Support/Stubs/[Feature]Model+Stub.swift
@testable import MyApp

extension [Feature]Model {
    static func stub(
        id: String = "stub-id",
        name: String = "Stub Name",
        description: String = "Stub description",
        category: Category = .default
    ) -> [Feature]Model {
        [Feature]Model(
            id: id,
            name: name,
            description: description,
            category: category
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
            description: "Description"
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
