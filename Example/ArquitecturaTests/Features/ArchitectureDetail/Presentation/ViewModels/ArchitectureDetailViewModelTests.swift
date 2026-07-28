import Foundation
import Testing
@testable import Arquitectura

// MARK: - ArchitectureDetailViewModelTests

@Suite
@MainActor
struct ArchitectureDetailViewModelTests {
    // MARK: - Helper Methods

    private func makeDetailModel(id: String = "test-id",
                                 name: String = "Test Feature",
                                 icon: String = "building.2",
                                 version: String? = "1.0",
                                 category: ArchitectureDetailModel.Category = .architecture,
                                 subtitle: String = "Test subtitle",
                                 isImplemented: Bool = true,
                                 filesInvolved: [ArchitectureDetailModel.FileInfo] = [],
                                 implementationDetails: String = "Implementation details",
                                 codeExample: ArchitectureDetailModel.CodeExample? = nil,
                                 bestPractices: [ArchitectureDetailModel.BestPractice] = [])
        -> ArchitectureDetailModel {
        ArchitectureDetailModel(id: id,
                                name: name,
                                icon: icon,
                                version: version,
                                category: category,
                                subtitle: subtitle,
                                isImplemented: isImplemented,
                                filesInvolved: filesInvolved,
                                implementationDetails: implementationDetails,
                                codeExample: codeExample,
                                bestPractices: bestPractices)
    }

    // MARK: - Tests

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        #expect(viewModel.state == .idle)
    }

    @Test("loadFeature updates state to loaded with decorator")
    func loadFeatureUpdatesStateToLoaded() async {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        let feature = makeDetailModel(id: "test-id",
                                      name: "Clean Architecture",
                                      subtitle: "A layered architecture pattern",
                                      isImplemented: true)
        await mockUseCase.setExecuteResult(.success(feature))

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // When
        await viewModel.loadFeature()

        // Then
        guard case let .loaded(decorator) = viewModel.state else {
            #expect(Bool(false), "Expected loaded state, got \(viewModel.state)")
            return
        }

        #expect(decorator.id == "test-id")
        #expect(decorator.name == "Clean Architecture")
        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == 1)
    }

    @Test("loadFeature updates state to error when feature not found")
    func loadFeatureUpdatesStateToErrorWhenNotFound() async {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        await mockUseCase.setExecuteResult(.success(nil))

        let viewModel = ArchitectureDetailViewModel(featureId: "nonexistent-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // When
        await viewModel.loadFeature()

        // Then
        guard case let .error(errorDecorator) = viewModel.state else {
            #expect(Bool(false), "Expected error state, got \(viewModel.state)")
            return
        }

        #expect(errorDecorator == .notFound)
    }

    @Test("loadFeature updates state to error on failure")
    func loadFeatureUpdatesStateToErrorOnFailure() async {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        await mockUseCase.setExecuteResult(.failure(NSError(domain: "test", code: 1)))

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // When
        await viewModel.loadFeature()

        // Then
        guard case let .error(errorDecorator) = viewModel.state else {
            #expect(Bool(false), "Expected error state, got \(viewModel.state)")
            return
        }

        #expect(errorDecorator.isRetryable == true)
    }

    @Test("loadFeature passes correct featureId to useCase")
    func loadFeaturePassesCorrectId() async {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()
        let expectedId = "specific-feature-id"

        await mockUseCase.setExecuteResult(.success(nil))

        let viewModel = ArchitectureDetailViewModel(featureId: expectedId,
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // When
        await viewModel.loadFeature()

        // Then
        let lastId = await mockUseCase.executeLastId
        #expect(lastId == expectedId)
    }

    @Test("loadFeature restores previous state on cancellation")
    func loadFeatureRestoresPreviousStateOnCancellation() async {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        // Configure mock to throw CancellationError
        await mockUseCase.setExecuteResult(.failure(CancellationError()))

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // Verify initial state is idle
        #expect(viewModel.state == .idle)

        // When
        await viewModel.loadFeature()

        // Then — state should be restored to idle, not stuck in loading
        #expect(viewModel.state == .idle)
    }

    @Test("loadFeature restores loaded state on cancellation after successful load")
    func loadFeatureRestoresLoadedStateOnCancellation() async {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        let feature = makeDetailModel(id: "test-id",
                                      name: "Clean Architecture",
                                      subtitle: "Description",
                                      isImplemented: true)
        await mockUseCase.setExecuteResult(.success(feature))

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // First load succeeds
        await viewModel.loadFeature()
        guard case .loaded = viewModel.state else {
            #expect(Bool(false), "Expected loaded state")
            return
        }

        // Configure mock to throw CancellationError on next call
        await mockUseCase.setExecuteResult(.failure(CancellationError()))

        // When — reload (which gets cancelled)
        await viewModel.loadFeature()

        // Then — state should be restored to loaded, not stuck in loading
        guard case .loaded = viewModel.state else {
            #expect(Bool(false), "Expected state to be restored to loaded, got \(viewModel.state)")
            return
        }
    }

    @Test("loadFeature ignores duplicate calls while loading")
    func loadFeatureIgnoresDuplicateWhileLoading() async {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        await mockUseCase.setExecuteResult(.success(nil))

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // When
        async let first: () = viewModel.loadFeature()
        async let second: () = viewModel.loadFeature()
        _ = await (first, second)

        // Then
        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == 1)
    }

    @Test("goBack calls router")
    func goBackCallsRouter() {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // When
        viewModel.goBack()

        // Then
        #expect(mockRouter.goBackCallCount == 1)
    }

    @Test("navigateToPokemonList calls router")
    func navigateToPokemonListCallsRouter() {
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        viewModel.navigateToPokemonList()

        #expect(mockRouter.navigateToPokemonListCallCount == 1)
    }

    @Test("retryLoad triggers new load")
    func retryLoadTriggersNewLoad() async {
        // Given
        let mockUseCase = MockArchitectureDetailUseCase()
        let mockRouter = MockArchitectureDetailRouter()
        let mockMapper = MockArchitectureDetailDecoratorMapper()

        let feature = makeDetailModel(id: "test-id",
                                      name: "Test Feature",
                                      subtitle: "Description",
                                      isImplemented: true)
        await mockUseCase.setExecuteResult(.success(feature))

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        // When
        await viewModel.retryLoad()

        // Then
        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == 1)
    }
}
