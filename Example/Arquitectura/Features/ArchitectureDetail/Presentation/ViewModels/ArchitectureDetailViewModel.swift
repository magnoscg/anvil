import Foundation

// MARK: - ArchitectureDetailViewModel

/// ViewModel for the Architecture Detail screen
@MainActor
@Observable
final class ArchitectureDetailViewModel {
    // MARK: - Properties

    private(set) var state: ArchitectureDetailState = .idle

    let featureId: String
    private let useCase: ArchitectureDetailUseCase
    private let router: ArchitectureDetailRouter
    private let decoratorMapper: ArchitectureDetailDecoratorMapper

    // MARK: - Init

    init(featureId: String,
         useCase: ArchitectureDetailUseCase,
         router: ArchitectureDetailRouter,
         decoratorMapper: ArchitectureDetailDecoratorMapper) {
        self.featureId = featureId
        self.useCase = useCase
        self.router = router
        self.decoratorMapper = decoratorMapper
    }

    // MARK: - Public Methods

    func loadFeature() async {
        guard state != .loading else {
            return
        }

        let previousState = state
        state = .loading

        do {
            guard let model = try await useCase.execute(id: featureId) else {
                state = .error(ErrorDecorator.notFound)
                return
            }
            let decorator = decoratorMapper.map(model)
            state = .loaded(decorator)
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

    func navigateToPokemonList() {
        router.navigateToPokemonList()
    }

    func goBack() {
        router.goBack()
    }

    func retryLoad() async {
        await loadFeature()
    }
}
