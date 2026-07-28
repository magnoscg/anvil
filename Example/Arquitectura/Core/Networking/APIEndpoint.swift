import Foundation

// MARK: - APIEndpoint

/// Protocol defining a self-contained API endpoint.
/// Each endpoint knows its own baseURL and can build a complete URLRequest.
/// Use this for external APIs (PokeAPI, GitHub, etc.) where the base URL is fixed.
protocol APIEndpoint: Sendable {
    /// Base URL for this endpoint (e.g., "https://pokeapi.co/api/v2")
    var baseURL: URL { get }

    /// Path component (e.g., "/pokemon", "/users/123")
    var path: String { get }

    /// HTTP method
    var method: HTTPMethod { get }

    /// Query parameters
    var queryParameters: [String: any CustomStringConvertible & Sendable]? { get }

    /// Custom headers
    var headers: [String: String]? { get }

    /// Request body data
    var body: Data? { get }

    /// Content type for the request
    var contentType: ContentType { get }

    /// Builds a complete URLRequest (no external parameters needed)
    func buildRequest() -> URLRequest?
}

// MARK: - Default Implementation

extension APIEndpoint {
    var method: HTTPMethod {
        .get
    }

    var queryParameters: [String: any CustomStringConvertible & Sendable]? {
        nil
    }

    var headers: [String: String]? {
        nil
    }

    var body: Data? {
        nil
    }

    var contentType: ContentType {
        .json
    }

    func buildRequest() -> URLRequest? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            return nil
        }

        components.path += path

        if let queryParameters, !queryParameters.isEmpty {
            components.queryItems = queryParameters
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        }

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        return request
    }
}
