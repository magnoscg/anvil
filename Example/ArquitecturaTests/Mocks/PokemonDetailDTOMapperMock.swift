import Foundation
@testable import Arquitectura

// MARK: - PokemonDetailDTOMapperMock

/// Mock implementation of PokemonDetailDTOMapper for testing.
/// Uses struct since the protocol's map method is nonisolated and synchronous.
struct PokemonDetailDTOMapperMock: PokemonDetailDTOMapper {
    // MARK: - Properties

    /// The result to return from map calls.
    let mapResult: PokemonDetailModel

    // MARK: - PokemonDetailDTOMapper

    nonisolated func map(detailDTO: PokemonDetailDTO, speciesDTO: PokemonSpeciesDTO?) -> PokemonDetailModel {
        mapResult
    }
}
