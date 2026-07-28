import Foundation
import Testing
@testable import Arquitectura

// MARK: - APIEndpointTests

@Suite
@MainActor
struct APIEndpointTests {
    // MARK: - Test Endpoint

    /// A simple test endpoint that conforms to APIEndpoint
    private struct TestEndpoint: APIEndpoint {
        var baseURL: URL
        var path: String
        var method: HTTPMethod = .get
        var queryParameters: [String: any CustomStringConvertible & Sendable]?
        var headers: [String: String]?
        var body: Data?
        var contentType: ContentType = .json
    }

    // MARK: - Tests

    @Test("buildRequest creates valid URL with path")
    func buildRequestCreatesValidURL() throws {
        // Given
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/users/123")

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request != nil)
        #expect(request?.url?.absoluteString == "https://api.example.com/users/123")
    }

    @Test("buildRequest appends sorted query parameters")
    func buildRequestAppendsQueryParameters() throws {
        // Given
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/pokemon",
                                        queryParameters: ["offset": 20, "limit": 10])

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request != nil)
        let url = request?.url?.absoluteString ?? ""
        #expect(url.contains("limit=10"))
        #expect(url.contains("offset=20"))
        // Parameters should be sorted alphabetically
        let queryRange = try #require(url.range(of: "?"))
        let query = String(url[queryRange.upperBound...])
        #expect(query.hasPrefix("limit=10"))
    }

    @Test("buildRequest sets HTTP method")
    func buildRequestSetsHTTPMethod() throws {
        // Given
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/users",
                                        method: .post)

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request?.httpMethod == "POST")
    }

    @Test("buildRequest sets content type header")
    func buildRequestSetsContentType() throws {
        // Given
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/data",
                                        contentType: .json)

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("buildRequest includes custom headers")
    func buildRequestIncludesCustomHeaders() throws {
        // Given
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/secure",
                                        headers: ["Authorization": "Bearer token123"])

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
    }

    @Test("buildRequest includes body data")
    func buildRequestIncludesBody() throws {
        // Given
        let bodyData = "{\"name\":\"test\"}".data(using: .utf8)
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/users",
                                        method: .post,
                                        body: bodyData)

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request?.httpBody == bodyData)
    }

    @Test("buildRequest with no query parameters omits query string")
    func buildRequestWithNoQueryParameters() throws {
        // Given
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/users")

        // When
        let request = endpoint.buildRequest()

        // Then
        #expect(request?.url?.query == nil)
    }

    @Test("Default values use GET method and JSON content type")
    func defaultValues() throws {
        // Given
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/test")

        // Then
        #expect(endpoint.method == .get)
        #expect(endpoint.contentType == .json)
        #expect(endpoint.queryParameters == nil)
        #expect(endpoint.headers == nil)
        #expect(endpoint.body == nil)
    }
}
