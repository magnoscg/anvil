import Foundation
import SwiftUI
import Testing
@testable import Arquitectura

// MARK: - ArchitectureViewModelTests

@Suite
@MainActor
struct ArchitectureViewModelTests {
    // MARK: - Tests

    @Test("Initial state is idle")
    func initialStateIsCorrect() {
        let mockUseCase = ArchitectureUseCaseMock()
        let mockRouter = ArchitectureRouterMock()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()

        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        #expect(viewModel.state == .idle)
    }

    @Test("loadFeatures updates state to loaded with sections")
    func loadFeaturesUpdatesStateToLoaded() async throws {
        let mockUseCase = ArchitectureUseCaseMock()
        let mockRouter = ArchitectureRouterMock()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()
        let features = [ArchitectureModel(id: "1",
                                          name: "Clean Architecture",
                                          description: "Layered architecture",
                                          category: .architecture,
                                          isImplemented: true,
                                          customIcon: nil)]
        mockUseCase.executeResult = .success(features)
        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        await viewModel.loadFeatures()

        let sections = try #require(viewModel.state.loadedSections)
        #expect(sections.count == 1)
        #expect(mockUseCase.executeCallCount == 1)
    }

    @Test("loadFeatures updates state to error on failure")
    func loadFeaturesUpdatesStateToError() async {
        let mockUseCase = ArchitectureUseCaseMock()
        let mockRouter = ArchitectureRouterMock()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()
        mockUseCase.executeResult = .failure(NSError(domain: "test", code: 1))
        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        await viewModel.loadFeatures()

        #expect(viewModel.state == .error(.generic))
        #expect(ErrorDecorator.generic.isRetryable == true)
    }

    @Test("navigateToDetail calls router with correct featureId")
    func navigateToDetailCallsRouter() {
        let mockUseCase = ArchitectureUseCaseMock()
        let mockRouter = ArchitectureRouterMock()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()
        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)
        let featureId = "test-feature-id"

        viewModel.navigateToDetail(featureId: featureId)

        #expect(mockRouter.navigateToDetailCallCount == 1)
        #expect(mockRouter.navigateToDetailFeatureId == featureId)
    }

    @Test("loadFeatures restores previous state on cancellation")
    func loadFeaturesRestoresPreviousStateOnCancellation() async {
        let mockUseCase = ArchitectureUseCaseMock()
        let mockRouter = ArchitectureRouterMock()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()
        mockUseCase.executeResult = .failure(CancellationError())
        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)
        #expect(viewModel.state == .idle)

        await viewModel.loadFeatures()

        #expect(viewModel.state == .idle)
    }

    @Test("loadFeatures restores loaded state on cancellation after successful load")
    func loadFeaturesRestoresLoadedStateOnCancellation() async {
        let mockUseCase = ArchitectureUseCaseMock()
        let mockRouter = ArchitectureRouterMock()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()
        let features = [ArchitectureModel(id: "1",
                                          name: "Clean Architecture",
                                          description: "Layered architecture",
                                          category: .architecture,
                                          isImplemented: true,
                                          customIcon: nil)]
        let loadedState = ArchitectureState.loaded(decoratorMapper.mapToSections(features))
        mockUseCase.executeResult = .success(features)
        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)
        await viewModel.loadFeatures()
        #expect(viewModel.state == loadedState)
        mockUseCase.executeResult = .failure(CancellationError())

        await viewModel.loadFeatures()

        #expect(viewModel.state == loadedState)
    }

    @Test("loadFeatures ignores duplicate calls while loading")
    func loadFeaturesIgnoresDuplicateWhileLoading() async {
        let mockUseCase = ArchitectureUseCaseMock()
        let mockRouter = ArchitectureRouterMock()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()
        mockUseCase.executeResult = .success([])
        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)
        mockUseCase.onExecute = { await viewModel.loadFeatures() }

        await viewModel.loadFeatures()

        #expect(mockUseCase.executeCallCount == 1)
    }
}

// MARK: - ArchitectureState + Loaded sections

private extension ArchitectureState {
    var loadedSections: [ArchitectureSectionDecorator]? {
        if case let .loaded(sections) = self {
            sections
        } else {
            nil
        }
    }
}
