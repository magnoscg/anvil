import Foundation
@testable import Arquitectura

// MARK: - MockPokemonListDTOMapper

/// Mock implementation of PokemonListDTOMapper for testing.
/// Returns a fixed result model to avoid Swift 6 actor isolation issues across modules.
struct MockPokemonListDTOMapper: PokemonListDTOMapper {
    // MARK: - Properties

    /// The fixed model to return from all map calls.
    let mapResult: PokemonListModel

    // MARK: - PokemonListDTOMapper

    nonisolated func mapToDomain(_: PokemonListDTO) -> PokemonListModel {
        mapResult
    }

    nonisolated func mapToDomain(_ dtos: [PokemonListDTO]) -> [PokemonListModel] {
        dtos.map { mapToDomain($0) }
    }
}
