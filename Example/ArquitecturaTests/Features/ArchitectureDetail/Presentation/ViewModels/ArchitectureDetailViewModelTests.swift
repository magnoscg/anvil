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
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()

        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        #expect(viewModel.state == .idle)
    }

    @Test("loadFeature updates state to loaded with decorator")
    func loadFeatureUpdatesStateToLoaded() async throws {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        let feature = makeDetailModel(id: "test-id",
                                      name: "Clean Architecture",
                                      subtitle: "A layered architecture pattern",
                                      isImplemented: true)
        mockUseCase.executeResult = .success(feature)
        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        await viewModel.loadFeature()

        let decorator = try #require(viewModel.state.loadedDecorator)
        #expect(decorator.id == "test-id")
        #expect(decorator.name == "Clean Architecture")
        #expect(mockUseCase.executeCallCount == 1)
    }

    @Test("loadFeature updates state to error when feature not found")
    func loadFeatureUpdatesStateToErrorWhenNotFound() async {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        mockUseCase.executeResult = .success(nil)
        let viewModel = ArchitectureDetailViewModel(featureId: "nonexistent-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        await viewModel.loadFeature()

        #expect(viewModel.state == .error(.notFound))
    }

    @Test("loadFeature updates state to error on failure")
    func loadFeatureUpdatesStateToErrorOnFailure() async {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        mockUseCase.executeResult = .failure(NSError(domain: "test", code: 1))
        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        await viewModel.loadFeature()

        #expect(viewModel.state == .error(.generic))
        #expect(ErrorDecorator.generic.isRetryable == true)
    }

    @Test("loadFeature passes correct featureId to useCase")
    func loadFeaturePassesCorrectId() async {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        let expectedId = "specific-feature-id"
        mockUseCase.executeResult = .success(nil)
        let viewModel = ArchitectureDetailViewModel(featureId: expectedId,
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        await viewModel.loadFeature()

        #expect(mockUseCase.executeLastId == expectedId)
    }

    @Test("loadFeature restores previous state on cancellation")
    func loadFeatureRestoresPreviousStateOnCancellation() async {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        mockUseCase.executeResult = .failure(CancellationError())
        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)
        #expect(viewModel.state == .idle)

        await viewModel.loadFeature()

        #expect(viewModel.state == .idle)
    }

    @Test("loadFeature restores loaded state on cancellation after successful load")
    func loadFeatureRestoresLoadedStateOnCancellation() async {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        let feature = makeDetailModel(id: "test-id",
                                      name: "Clean Architecture",
                                      subtitle: "Description",
                                      isImplemented: true)
        let loadedState = ArchitectureDetailState.loaded(mockMapper.map(feature))
        mockUseCase.executeResult = .success(feature)
        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)
        await viewModel.loadFeature()
        #expect(viewModel.state == loadedState)
        mockUseCase.executeResult = .failure(CancellationError())

        await viewModel.loadFeature()

        #expect(viewModel.state == loadedState)
    }

    @Test("loadFeature ignores duplicate calls while loading")
    func loadFeatureIgnoresDuplicateWhileLoading() async {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        mockUseCase.executeResult = .success(nil)
        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)
        mockUseCase.onExecute = { await viewModel.loadFeature() }

        await viewModel.loadFeature()

        #expect(mockUseCase.executeCallCount == 1)
    }

    @Test("goBack calls router")
    func goBackCallsRouter() {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        viewModel.goBack()

        #expect(mockRouter.goBackCallCount == 1)
    }

    @Test("navigateToPokemonList calls router")
    func navigateToPokemonListCallsRouter() {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        viewModel.navigateToPokemonList()

        #expect(mockRouter.navigateToPokemonListCallCount == 1)
    }

    @Test("retryLoad triggers new load")
    func retryLoadTriggersNewLoad() async {
        let mockUseCase = ArchitectureDetailUseCaseMock()
        let mockRouter = ArchitectureDetailRouterMock()
        let mockMapper = ArchitectureDetailDecoratorMapperMock()
        let feature = makeDetailModel(id: "test-id",
                                      name: "Test Feature",
                                      subtitle: "Description",
                                      isImplemented: true)
        mockUseCase.executeResult = .success(feature)
        let viewModel = ArchitectureDetailViewModel(featureId: "test-id",
                                                    useCase: mockUseCase,
                                                    router: mockRouter,
                                                    decoratorMapper: mockMapper)

        await viewModel.retryLoad()

        #expect(mockUseCase.executeCallCount == 1)
    }
}

// MARK: - ArchitectureDetailState + Loaded decorator

private extension ArchitectureDetailState {
    var loadedDecorator: ArchitectureDetailDecorator? {
        if case let .loaded(decorator) = self {
            decorator
        } else {
            nil
        }
    }
}
