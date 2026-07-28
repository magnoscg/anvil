import Foundation

// MARK: - PokemonDetailViewModel

/// ViewModel for the PokemonDetail screen
@MainActor
@Observable
final class PokemonDetailViewModel {
    // MARK: - Properties

    private(set) var state: PokemonDetailState = .idle

    private let pokemonId: Int

    private let useCase: PokemonDetailUseCase
    private let decoratorMapper: PokemonDetailDecoratorMapper
    private let router: PokemonDetailRouter

    // MARK: - Init

    init(pokemonId: Int,
         useCase: PokemonDetailUseCase,
         decoratorMapper: PokemonDetailDecoratorMapper,
         router: PokemonDetailRouter) {
        self.pokemonId = pokemonId
        self.useCase = useCase
        self.decoratorMapper = decoratorMapper
        self.router = router
    }

    // MARK: - Public Methods

    /// Loads the Pokemon detail data
    func loadDetail() async {
        guard state != .loading else { return }

        let previousState = state
        state = .loading

        do {
            let result = try await useCase.execute(pokemonId: pokemonId)
            state = .loaded(decoratorMapper.map(result))
        } catch is CancellationError {
            state = previousState
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }
}
