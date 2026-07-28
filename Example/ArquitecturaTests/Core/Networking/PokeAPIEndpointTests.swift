import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokeAPIEndpointTests

@Suite
@MainActor
struct PokeAPIEndpointTests {
    // MARK: - Pokemon List Endpoint

    @Test("pokemonList endpoint builds correct URL with pagination")
    func pokemonListEndpoint() {
        // Given
        let endpoint = PokeAPIEndpoint.pokemonList(limit: 20, offset: 40)

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request != nil)
        let url = request?.url?.absoluteString ?? ""
        #expect(url.contains("pokeapi.co/api/v2/pokemon"))
        #expect(url.contains("limit=20"))
        #expect(url.contains("offset=40"))
    }

    @Test("pokemonList endpoint uses GET method")
    func pokemonListUsesGet() {
        let endpoint = PokeAPIEndpoint.pokemonList(limit: 10, offset: 0)
        let request = endpoint.buildRequest()
        #expect(request?.httpMethod == "GET")
    }

    // MARK: - Pokemon Detail Endpoint

    @Test("pokemonDetail by ID builds correct URL")
    func pokemonDetailByID() {
        // Given
        let endpoint = PokeAPIEndpoint.pokemonDetail(id: 25)

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request != nil)
        let url = request?.url?.absoluteString ?? ""
        #expect(url.contains("pokeapi.co/api/v2/pokemon/25"))
        // Detail endpoint should have no query parameters
        #expect(request?.url?.query == nil)
    }

    @Test("pokemonDetail by name builds correct URL")
    func pokemonDetailByName() {
        // Given
        let endpoint = PokeAPIEndpoint.pokemonDetail(name: "Pikachu")

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request != nil)
        let url = request?.url?.absoluteString ?? ""
        // Name should be lowercased
        #expect(url.contains("pokeapi.co/api/v2/pokemon/pikachu"))
    }

    @Test("pokemonDetail by name lowercases input")
    func pokemonDetailByNameLowercases() {
        let endpoint = PokeAPIEndpoint.pokemonDetail(name: "CHARIZARD")
        let request = endpoint.buildRequest()
        let url = request?.url?.absoluteString ?? ""
        #expect(url.contains("/charizard"))
        #expect(!url.contains("CHARIZARD"))
    }

    @Test("pokemonSpecies by ID builds correct URL")
    func pokemonSpeciesByID() {
        let endpoint = PokeAPIEndpoint.pokemonSpecies(id: 25)
        let request = endpoint.buildRequest()

        #expect(request != nil)
        let url = request?.url?.absoluteString ?? ""
        #expect(url.contains("pokeapi.co/api/v2/pokemon-species/25"))
        #expect(request?.url?.query == nil)
    }

    // MARK: - Base URL Tests

    @Test("All endpoints use PokeAPI v2 base URL")
    func allEndpointsUseCorrectBaseURL() {
        let endpoints: [PokeAPIEndpoint] = [.pokemonList(limit: 10, offset: 0),
                                            .pokemonDetail(id: 1),
                                            .pokemonDetail(name: "bulbasaur"),
                                            .pokemonSpecies(id: 1)]

        for endpoint in endpoints {
            #expect(endpoint.baseURL.absoluteString == "https://pokeapi.co/api/v2")
        }
    }
}
