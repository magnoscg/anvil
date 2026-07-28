import Foundation
@testable import Arquitectura

// MARK: - MockPokemonDetailDTOMapper

/// Mock implementation of PokemonDetailDTOMapper for testing.
/// Uses struct since the protocol's map method is nonisolated and synchronous.
struct MockPokemonDetailDTOMapper: PokemonDetailDTOMapper {
    // MARK: - Properties

    /// The result to return from map calls.
    let mapResult: PokemonDetailModel

    // MARK: - PokemonDetailDTOMapper

    nonisolated func map(detailDTO: PokemonDetailDTO, speciesDTO: PokemonSpeciesDTO?) -> PokemonDetailModel {
        mapResult
    }
}
