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
        let listResponse = try await remoteDataSource.fetchPokemonList(limit: limit, offset: offset)
        let pokemon = try await fetchDetailsInParallel(for: listResponse.results)
        let hasMore = listResponse.next != nil

        return PokemonListRepositoryResult(pokemon: pokemon,
                                           totalCount: listResponse.count,
                                           hasMore: hasMore)
    }

    // MARK: - Private Methods

    /// Fetches Pokemon details in parallel using TaskGroup.
    /// - Parameter results: Array of Pokemon list results containing names and URLs.
    /// - Returns: Array of Pokemon domain models sorted by ID.
    private func fetchDetailsInParallel(for results: [PokemonListResultDTO]) async throws -> [PokemonListModel] {
        try await withThrowingTaskGroup(of: PokemonListModel?.self) { group in
            for result in results {
                guard let pokemonID = result.extractedID else { continue }

                group.addTask {
                    do {
                        let detail = try await self.remoteDataSource.fetchPokemonDetail(id: pokemonID)
                        return self.dtoMapper.mapToDomain(detail)
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        Self.logger
                            .warning("Failed to fetch Pokemon detail id=\(pokemonID): \(error.localizedDescription)")
                        return nil
                    }
                }
            }

            var models: [PokemonListModel] = []
            for try await model in group {
                if let model {
                    models.append(model)
                }
            }

            return models.sorted { $0.id < $1.id }
        }
    }
}
