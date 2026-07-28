import Foundation
import os

// MARK: - PokemonDetailRepositoryImpl

/// Implementation of PokemonDetailRepository that fetches Pokemon data from PokeAPI.
/// Combines detail and species endpoints in parallel with partial failure support.
struct PokemonDetailRepositoryImpl: PokemonDetailRepository {
    // MARK: - Properties

    private nonisolated static let logger = Logger(subsystem: "com.magnos.Arquitectura",
                                                   category: "PokemonDetailRepository")

    private let remoteDataSource: PokemonDetailRemoteDataSource
    private let dtoMapper: PokemonDetailDTOMapper

    // MARK: - Init

    /// Creates a repository with the given data source and mapper.
    /// - Parameters:
    ///   - remoteDataSource: The remote data source for PokeAPI calls.
    ///   - dtoMapper: The mapper for converting DTOs to domain models.
    init(remoteDataSource: PokemonDetailRemoteDataSource, dtoMapper: PokemonDetailDTOMapper) {
        self.remoteDataSource = remoteDataSource
        self.dtoMapper = dtoMapper
    }

    // MARK: - PokemonDetailRepository

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailModel {
        async let detail = remoteDataSource.fetchPokemonDetail(id: id)
        async let species = try fetchSpeciesOptional(id: id)

        return try await dtoMapper.map(detailDTO: detail, speciesDTO: species)
    }

    // MARK: - Private Methods

    /// Fetches species data with explicit error handling.
    /// CancellationError is always re-thrown. Other errors are logged and return nil.
    private func fetchSpeciesOptional(id: Int) async throws -> PokemonSpeciesDTO? {
        do {
            return try await remoteDataSource.fetchPokemonSpecies(id: id)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Self.logger.warning("Failed to fetch Pokemon species id=\(id): \(error.localizedDescription)")
            return nil
        }
    }
}
