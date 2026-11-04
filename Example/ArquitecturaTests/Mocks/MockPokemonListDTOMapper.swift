import Foundation
@testable import Arquitectura

// MARK: - MockPokemonListDTOMapper

/// Mock implementation of PokemonListDTOMapper for testing.
/// Returns a fixed result model to avoid Swift 6 actor isolation issues across modules.
struct MockPokemonListDTOMapper: PokemonListDTOMapper {
    // MARK: - Properties

    /// The fixed model to return from all map calls.
    let mapResult: PokemonSummaryModel

    // MARK: - PokemonListDTOMapper

    nonisolated func mapToDomain(_: PokemonListDTO) -> PokemonSummaryModel {
        mapResult
    }

    nonisolated func mapToDomain(_ dtos: [PokemonListDTO]) -> [PokemonSummaryModel] {
        dtos.map { mapToDomain($0) }
    }
}
