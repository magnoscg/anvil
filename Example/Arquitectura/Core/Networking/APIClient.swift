import Foundation

// MARK: - APIClient

/// Protocol defining the API client interface for making network requests.
protocol APIClient: Sendable {
    /// Performs a network request and decodes the response.
    /// Used for internal API endpoints that require environment configuration.
    /// - Parameter endpoint: The endpoint configuration for the request.
    /// - Returns: The decoded response of type T.
    /// - Throws: APIError if the request fails.
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T

    /// Performs a network request using a self-contained APIEndpoint.
    /// Used for external APIs (PokeAPI, GitHub, etc.) where baseURL is embedded in the endpoint.
    /// - Parameter endpoint: The self-contained endpoint with its own baseURL.
    /// - Returns: The decoded response of type T.
    /// - Throws: APIError if the request fails.
    func request<T: Decodable & Sendable>(_ endpoint: some APIEndpoint) async throws -> T
}
