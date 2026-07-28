import Foundation

// MARK: - PokemonDetailUseCaseImpl

/// Implementation of PokemonDetailUseCase that delegates to the repository.
/// The repository handles data fetching, parallel calls, and DTO mapping.
struct PokemonDetailUseCaseImpl: PokemonDetailUseCase {
    // MARK: - Properties

    private let repository: PokemonDetailRepository

    // MARK: - Init

    /// Creates a use case with the given repository.
    /// - Parameter repository: The repository for fetching Pokemon detail data.
    init(repository: PokemonDetailRepository) {
        self.repository = repository
    }

    // MARK: - PokemonDetailUseCase

    func execute(pokemonId: Int) async throws -> PokemonDetailModel {
        do {
            return try await repository.fetchPokemonDetail(id: pokemonId)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw DomainError.map(error)
        }
    }
}
