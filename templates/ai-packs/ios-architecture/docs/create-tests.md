# create-tests.md — Quick Test Templates (Swift Testing)

> Full reference in `testing.md`. This doc is just copy-paste.
>
> `anvil feature [Feature]` already generates these tests and mocks (for a `fetch()` / `execute()` / `load()` feature). Use the templates below when you add methods or write tests by hand. Mocks are named `[Feature]<Type>Mock` and live in `[Project]Tests/Mocks/`.

## ViewModel

```swift
// [Project]Tests/Features/[Feature]/Presentation/ViewModels/[Feature]ViewModelTests.swift
import Testing
import Foundation
@testable import MyApp

@MainActor
@Suite("[Feature]ViewModel Tests")
struct [Feature]ViewModelTests {
    // MARK: - Properties

    private var mockUseCase: [Feature]UseCaseMock
    private var mockDecoratorMapper: [Feature]DecoratorMapperMock
    private var mockRouter: [Feature]RouterMock
    private var sut: [Feature]ViewModel

    // MARK: - Setup

    init() {
        mockUseCase = [Feature]UseCaseMock()
        mockDecoratorMapper = [Feature]DecoratorMapperMock()
        mockRouter = [Feature]RouterMock()
        sut = [Feature]ViewModel(useCase: mockUseCase,
                                 decoratorMapper: mockDecoratorMapper,
                                 router: mockRouter)
    }

    // MARK: - Success

    @Test("Given use case returns models, when load, then state is loaded")
    func load_success_setsLoadedState() async {
        // Given
        mockUseCase.executeResult = .success([.stub(id: "1")])
        mockDecoratorMapper.mapResult = .stub(id: "1")

        // When
        await sut.load()

        // Then
        #expect(sut.state == .loaded)
        #expect(sut.items.count == 1)
        #expect(mockUseCase.executeCallCount == 1)
    }

    // MARK: - Error

    @Test("Given use case throws DomainError, when load, then state is the mapped error")
    func load_domainError_setsErrorState() async {
        // Given
        mockUseCase.executeResult = .failure(DomainError.network)

        // When
        await sut.load()

        // Then
        #expect(sut.state == .error(ErrorDecorator.from(.network)))
    }

    // MARK: - Cancellation

    @Test("Given use case is cancelled, when load, then the previous state is restored")
    func load_cancelled_restoresPreviousState() async {
        // Given
        mockUseCase.executeResult = .failure(CancellationError())

        // When
        await sut.load()

        // Then
        #expect(sut.state == .idle)
    }

    // MARK: - Navigation

    @Test("Given item id, when navigateToDetail, then router is called")
    func navigateToDetail_callsRouter() {
        // Given
        let itemId = "test-id"

        // When
        sut.navigateToDetail(id: itemId)

        // Then
        #expect(mockRouter.navigateToDetailCallCount == 1)
        #expect(mockRouter.navigateToDetailId == itemId)
    }
}
```

## UseCase Mock

```swift
// [Project]Tests/Mocks/[Feature]UseCaseMock.swift
import Foundation
@testable import MyApp

// MARK: - [Feature]UseCaseMock

final class [Feature]UseCaseMock: [Feature]UseCase, @unchecked Sendable {
    // MARK: - Properties

    var executeResult: Result<[[Feature]Model], Error> = .success([])
    var executeCallCount = 0

    // MARK: - [Feature]UseCase

    func execute() async throws -> [[Feature]Model] {
        executeCallCount += 1
        return try executeResult.get()
    }
}
```

## Repository Mock

```swift
// [Project]Tests/Mocks/[Feature]RepositoryMock.swift
import Foundation
@testable import MyApp

// MARK: - [Feature]RepositoryMock

final class [Feature]RepositoryMock: [Feature]Repository, @unchecked Sendable {
    // MARK: - Properties

    var fetchResult: Result<[[Feature]Model], Error> = .success([])
    var fetchCallCount = 0

    // MARK: - [Feature]Repository

    func fetch() async throws -> [[Feature]Model] {
        fetchCallCount += 1
        return try fetchResult.get()
    }
}
```

`[Feature]RemoteDataSourceMock` follows the same shape (`fetchResult: Result<[[Feature]DTO], Error>`). `[Feature]DTOMapperMock` and `[Feature]DecoratorMapperMock` return a configurable `map...Result` and count calls.

## Router Mock

```swift
// [Project]Tests/Mocks/[Feature]RouterMock.swift
import Foundation
@testable import MyApp

// MARK: - [Feature]RouterMock

@MainActor
final class [Feature]RouterMock: [Feature]Router {
    // MARK: - Properties

    var navigateToDetailId: String?
    var navigateToDetailCallCount = 0
    var goBackCallCount = 0

    // MARK: - [Feature]Router

    func navigateToDetail(id: String) {
        navigateToDetailId = id
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
import Foundation
@testable import MyApp

@Suite("[Feature]DecoratorMapperImpl Tests")
struct [Feature]DecoratorMapperImplTests {
    // MARK: - Properties

    private var sut: [Feature]DecoratorMapperImpl

    // MARK: - Setup

    init() {
        sut = [Feature]DecoratorMapperImpl()
    }

    // MARK: - Mapping

    @Test("Given a domain model, when map, then returns correct decorator")
    func map_model_returnsCorrectDecorator() {
        // Given
        let model = [Feature]Model.stub(id: "1", name: "Test Name", description: "Test Description")

        // When
        let decorator = sut.map(model)

        // Then
        #expect(decorator.id == "1")
        #expect(decorator.displayName == "Test Name")
        #expect(decorator.subtitle == "Test Description")
    }
}
```

Mapper suites don't need `@MainActor`: mappers are nonisolated.

## UseCase Tests

```swift
// [Project]Tests/Domain/[Feature]/UseCases/[Feature]UseCaseTests.swift
import Testing
import Foundation
@testable import MyApp

@Suite("[Feature]UseCaseImpl Tests")
struct [Feature]UseCaseImplTests {
    // MARK: - Properties

    private var mockRepository: [Feature]RepositoryMock
    private var sut: [Feature]UseCaseImpl

    // MARK: - Setup

    init() {
        mockRepository = [Feature]RepositoryMock()
        sut = [Feature]UseCaseImpl(repository: mockRepository)
    }

    // MARK: - Success

    @Test("Given repository returns models, when execute, then returns them")
    func execute_success_returnsModels() async throws {
        // Given
        mockRepository.fetchResult = .success([.stub(), .stub()])

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 2)
        #expect(mockRepository.fetchCallCount == 1)
    }

    // MARK: - Error

    @Test("Given repository throws a DomainError, when execute, then propagates it")
    func execute_repositoryThrows_propagatesError() async {
        // Given
        mockRepository.fetchResult = .failure(DomainError.network)

        // When / Then
        do {
            _ = try await sut.execute()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? DomainError == .network)
        }
    }
}
```

## Repository Tests

```swift
// [Project]Tests/Data/[Feature]/Repositories/[Feature]RepositoryTests.swift
import Testing
import Foundation
@testable import MyApp

@Suite("[Feature]RepositoryImpl Tests")
struct [Feature]RepositoryImplTests {
    // MARK: - Properties

    private var mockRemoteDataSource: [Feature]RemoteDataSourceMock
    private var mockDTOMapper: [Feature]DTOMapperMock
    private var sut: [Feature]RepositoryImpl

    // MARK: - Setup

    init() {
        mockRemoteDataSource = [Feature]RemoteDataSourceMock()
        mockDTOMapper = [Feature]DTOMapperMock()
        sut = [Feature]RepositoryImpl(remoteDataSource: mockRemoteDataSource,
                                      mapper: mockDTOMapper)
    }

    // MARK: - Success

    @Test("Given data source returns DTOs, when fetch, then returns mapped models")
    func fetch_success_returnsMappedModels() async throws {
        // Given
        mockRemoteDataSource.fetchResult = .success([.stub(id: "1"), .stub(id: "2")])

        // When
        let result = try await sut.fetch()

        // Then
        #expect(result.count == 2)
        #expect(mockDTOMapper.mapMultipleCallCount == 1)
    }

    // MARK: - Error

    @Test("Given data source throws APIError 404, when fetch, then throws DomainError.notFound")
    func fetch_dataSourceThrows_throwsDomainError() async {
        // Given
        mockRemoteDataSource.fetchResult = .failure(APIError.httpError(statusCode: 404, data: nil))

        // When / Then
        do {
            _ = try await sut.fetch()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? DomainError == .notFound)
            #expect(mockDTOMapper.mapMultipleCallCount == 0)
        }
    }
}
```

## Stubs

```swift
// [Project]Tests/Support/Stubs/[Feature]Stubs.swift
import Foundation
@testable import MyApp

// MARK: - [Feature]Model + Stub

extension [Feature]Model {
    static func stub(id: String = "stub-id",
                     name: String = "Stub Name",
                     description: String = "Stub description") -> [Feature]Model {
        [Feature]Model(id: id, name: name, description: description)
    }
}

// MARK: - [Feature]DTO + Stub

extension [Feature]DTO {
    static func stub(id: String = "stub-id",
                     name: String = "Stub Name",
                     description: String = "Stub description") -> [Feature]DTO {
        [Feature]DTO(id: id, name: name, description: description)
    }
}

// MARK: - [Feature]Decorator + Stub

extension [Feature]Decorator {
    static func stub(id: String = "stub-id",
                     displayName: String = "Stub Display Name",
                     subtitle: String = "Stub subtitle") -> [Feature]Decorator {
        [Feature]Decorator(id: id, displayName: displayName, subtitle: subtitle)
    }
}

// MARK: - ErrorDecorator + Stub

extension ErrorDecorator {
    static func stub(title: String = "Error",
                     message: String = "Something went wrong",
                     retryAction: (@Sendable () -> Void)? = nil) -> ErrorDecorator {
        ErrorDecorator(title: title, message: message, retryAction: retryAction)
    }
}
```

The generated tests build models inline; these stubs are optional helpers you add yourself.
