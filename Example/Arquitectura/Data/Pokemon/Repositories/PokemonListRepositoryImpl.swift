import Foundation
import os

// MARK: - PokemonListRepositoryImpl

/// Implementation of PokemonListRepository that fetches Pokemon data from PokeAPI.
/// Uses parallel requests to fetch Pokemon details efficiently.
struct PokemonListRepositoryImpl: PokemonListRepository {
    // MARK: - Properties

    private nonisolated static let logger = Logger(subsystem: "com.magnos.Arquitectura",
                                                   category: "PokemonListRepository")

    private let remoteDataSource: PokemonListRemoteDataSource
    private let dtoMapper: PokemonListDTOMapper

    // MARK: - Init

    /// Creates a repository with the given data source and mapper.
    /// - Parameters:
    ///   - remoteDataSource: The remote data source for PokeAPI calls.
    ///   - dtoMapper: The mapper for converting DTOs to domain models.
    init(remoteDataSource: PokemonListRemoteDataSource,
         dtoMapper: PokemonListDTOMapper) {
        self.remoteDataSource = remoteDataSource
        self.dtoMapper = dtoMapper
    }

    // MARK: - PokemonListRepository

    func getPokemonList(limit: Int, offset: Int) async throws -> PokemonListRepositoryResult {
        try await DomainError.catching {
            let listResponse = try await remoteDataSource.fetchPokemonList(limit: limit, offset: offset)
            let pokemon = try await fetchDetailsInParallel(for: listResponse.results)
            let hasMore = listResponse.next != nil

            return PokemonListRepositoryResult(pokemon: pokemon,
                                               totalCount: listResponse.count,
                                               hasMore: hasMore)
        }
    }

    // MARK: - Private Methods

    /// Fetches Pokemon details in parallel using TaskGroup.
    /// Individual failures are logged and skipped, but if every detail fails the first error is
    /// thrown, so a failed load never turns into an empty page.
    /// - Parameter results: Array of Pokemon list results containing names and URLs.
    /// - Returns: Array of Pokemon domain models sorted by ID.
    /// - Throws: The first detail error when no detail could be loaded, or `CancellationError`.
    private func fetchDetailsInParallel(for results: [PokemonListResultDTO]) async throws -> [PokemonSummaryModel] {
        try await withThrowingTaskGroup(of: Result<PokemonSummaryModel, any Error>.self) { group in
            for result in results {
                guard let pokemonID = result.extractedID else { continue }

                group.addTask {
                    do {
                        let detail = try await self.remoteDataSource.fetchPokemonDetail(id: pokemonID)
                        return .success(self.dtoMapper.mapToDomain(detail))
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        Self.logger
                            .warning("Failed to fetch Pokemon detail id=\(pokemonID): \(error.localizedDescription)")
                        return .failure(error)
                    }
                }
            }

            var models: [PokemonSummaryModel] = []
            var firstFailure: (any Error)?
            for try await outcome in group {
                switch outcome {
                case let .success(model):
                    models.append(model)
                case let .failure(error):
                    firstFailure = firstFailure ?? error
                }
            }

            if models.isEmpty, let firstFailure {
                throw firstFailure
            }

            return models.sorted { $0.id < $1.id }
        }
    }
}
