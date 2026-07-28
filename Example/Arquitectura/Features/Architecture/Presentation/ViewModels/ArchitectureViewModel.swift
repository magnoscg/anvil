import Foundation

// MARK: - ArchitectureViewModel

/// ViewModel for the Architecture screen that displays architecture features
@MainActor
@Observable
final class ArchitectureViewModel {
    // MARK: - Properties

    private(set) var state: ArchitectureState = .idle

    private let useCase: ArchitectureUseCase
    private let router: ArchitectureRouter
    private let decoratorMapper: ArchitectureDecoratorMapper

    // MARK: - Init

    init(useCase: ArchitectureUseCase,
         router: ArchitectureRouter,
         decoratorMapper: ArchitectureDecoratorMapper) {
        self.useCase = useCase
        self.router = router
        self.decoratorMapper = decoratorMapper
    }

    // MARK: - Public Methods

    /// Loads architecture features and updates state
    func loadFeatures() async {
        guard state != .loading else { return }

        let previousState = state
        state = .loading

        do {
            let features = try await useCase.execute()
            let sections = decoratorMapper.mapToSections(features)
            state = .loaded(sections)
        } catch is CancellationError {
            // Restore previous state on cancellation to avoid stuck .loading
            state = previousState
            return
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }

    /// Navigates to feature detail
    func navigateToDetail(featureId: String) {
        router.navigateToDetail(featureId: featureId)
    }

    /// Retry loading features (used by retry button)
    func retryLoad() async {
        await loadFeatures()
    }
}
