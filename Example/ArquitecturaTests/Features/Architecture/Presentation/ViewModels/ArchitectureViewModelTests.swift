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
        let mockUseCase = MockArchitectureUseCase()
        let mockRouter = MockArchitectureRouter()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()

        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        #expect(viewModel.state == .idle)
    }

    @Test("loadFeatures updates state to loaded with sections")
    func loadFeaturesUpdatesStateToLoaded() async {
        // Given
        let mockUseCase = MockArchitectureUseCase()
        let mockRouter = MockArchitectureRouter()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()

        let features = [ArchitectureModel(id: "1",
                                          name: "Clean Architecture",
                                          description: "Layered architecture",
                                          category: .architecture,
                                          isImplemented: true,
                                          customIcon: nil)]
        await mockUseCase.setExecuteResult(.success(features))

        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        // When
        await viewModel.loadFeatures()

        // Then
        guard case let .loaded(sections) = viewModel.state else {
            #expect(Bool(false), "Expected loaded state, got \(viewModel.state)")
            return
        }

        #expect(sections.count == 1)
        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == 1)
    }

    @Test("loadFeatures updates state to error on failure")
    func loadFeaturesUpdatesStateToError() async {
        // Given
        let mockUseCase = MockArchitectureUseCase()
        let mockRouter = MockArchitectureRouter()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()

        await mockUseCase.setExecuteResult(.failure(NSError(domain: "test", code: 1)))

        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        // When
        await viewModel.loadFeatures()

        // Then
        guard case let .error(decorator) = viewModel.state else {
            #expect(Bool(false), "Expected error state, got \(viewModel.state)")
            return
        }

        #expect(decorator.isRetryable == true)
    }

    @Test("navigateToDetail calls router with correct featureId")
    func navigateToDetailCallsRouter() {
        // Given
        let mockUseCase = MockArchitectureUseCase()
        let mockRouter = MockArchitectureRouter()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()

        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)
        let featureId = "test-feature-id"

        // When
        viewModel.navigateToDetail(featureId: featureId)

        // Then
        #expect(mockRouter.navigateToDetailCallCount == 1)
        #expect(mockRouter.navigateToDetailFeatureId == featureId)
    }

    @Test("loadFeatures restores previous state on cancellation")
    func loadFeaturesRestoresPreviousStateOnCancellation() async {
        // Given
        let mockUseCase = MockArchitectureUseCase()
        let mockRouter = MockArchitectureRouter()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()

        // Configure mock to throw CancellationError
        await mockUseCase.setExecuteResult(.failure(CancellationError()))

        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        // Verify initial state is idle
        #expect(viewModel.state == .idle)

        // When
        await viewModel.loadFeatures()

        // Then — state should be restored to idle, not stuck in loading
        #expect(viewModel.state == .idle)
    }

    @Test("loadFeatures restores loaded state on cancellation after successful load")
    func loadFeaturesRestoresLoadedStateOnCancellation() async {
        // Given
        let mockUseCase = MockArchitectureUseCase()
        let mockRouter = MockArchitectureRouter()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()

        let features = [ArchitectureModel(id: "1",
                                          name: "Clean Architecture",
                                          description: "Layered architecture",
                                          category: .architecture,
                                          isImplemented: true,
                                          customIcon: nil)]
        await mockUseCase.setExecuteResult(.success(features))

        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        // First load succeeds
        await viewModel.loadFeatures()
        guard case .loaded = viewModel.state else {
            #expect(Bool(false), "Expected loaded state")
            return
        }

        // Configure mock to throw CancellationError on next call
        await mockUseCase.setExecuteResult(.failure(CancellationError()))

        // When — reload (which gets cancelled)
        await viewModel.loadFeatures()

        // Then — state should be restored to loaded, not stuck in loading
        guard case .loaded = viewModel.state else {
            #expect(Bool(false), "Expected state to be restored to loaded, got \(viewModel.state)")
            return
        }
    }

    @Test("loadFeatures ignores duplicate calls while loading")
    func loadFeaturesIgnoresDuplicateWhileLoading() async {
        // Given
        let mockUseCase = MockArchitectureUseCase()
        let mockRouter = MockArchitectureRouter()
        let decoratorMapper = ArchitectureDecoratorMapperImpl()

        await mockUseCase.setExecuteResult(.success([]))

        let viewModel = ArchitectureViewModel(useCase: mockUseCase,
                                              router: mockRouter,
                                              decoratorMapper: decoratorMapper)

        // When
        async let first: () = viewModel.loadFeatures()
        async let second: () = viewModel.loadFeatures()
        _ = await (first, second)

        // Then
        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == 1)
    }
}
