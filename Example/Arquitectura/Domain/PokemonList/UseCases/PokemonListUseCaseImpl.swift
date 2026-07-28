import Foundation

// MARK: - PokemonListUseCaseImpl

/// Implementation of PokemonListUseCase that fetches Pokemon from the repository.
/// Converts page-based pagination to offset-based pagination for the API.
struct PokemonListUseCaseImpl: PokemonListUseCase {
    // MARK: - Properties

    private let repository: PokemonListRepository

    // MARK: - Init

    /// Creates a use case with the given repository.
    /// - Parameter repository: The repository for fetching Pokemon data.
    init(repository: PokemonListRepository) {
        self.repository = repository
    }

    // MARK: - PokemonListUseCase

    func execute(page: Int, pageSize: Int) async throws -> PokemonListResult {
        do {
            let offset = page * pageSize

            let result = try await repository.getPokemonList(limit: pageSize, offset: offset)

            return PokemonListResult(pokemon: result.pokemon,
                                     hasMore: result.hasMore,
                                     totalCount: result.totalCount)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw DomainError.map(error)
        }
    }
}
