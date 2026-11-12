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
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/users/123")

        let request = endpoint.buildRequest()

        #expect(request != nil)
        #expect(request?.url?.absoluteString == "https://api.example.com/users/123")
    }

    @Test("buildRequest appends sorted query parameters")
    func buildRequestAppendsQueryParameters() throws {
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/pokemon",
                                        queryParameters: ["offset": 20, "limit": 10])

        let request = endpoint.buildRequest()

        #expect(request != nil)
        let url = request?.url?.absoluteString ?? ""
        #expect(url.contains("limit=10"))
        #expect(url.contains("offset=20"))
        let queryRange = try #require(url.range(of: "?"))
        let query = String(url[queryRange.upperBound...])
        #expect(query.hasPrefix("limit=10"))
    }

    @Test("buildRequest sets HTTP method")
    func buildRequestSetsHTTPMethod() throws {
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/users",
                                        method: .post)

        let request = endpoint.buildRequest()

        #expect(request?.httpMethod == "POST")
    }

    @Test("buildRequest sets content type header")
    func buildRequestSetsContentType() throws {
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/data",
                                        contentType: .json)

        let request = endpoint.buildRequest()

        #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("buildRequest includes custom headers")
    func buildRequestIncludesCustomHeaders() throws {
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/secure",
                                        headers: ["Authorization": "Bearer token123"])

        let request = endpoint.buildRequest()

        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
    }

    @Test("buildRequest includes body data")
    func buildRequestIncludesBody() throws {
        let bodyData = "{\"name\":\"test\"}".data(using: .utf8)
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/users",
                                        method: .post,
                                        body: bodyData)

        let request = endpoint.buildRequest()

        #expect(request?.httpBody == bodyData)
    }

    @Test("buildRequest with no query parameters omits query string")
    func buildRequestWithNoQueryParameters() throws {
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/users")

        let request = endpoint.buildRequest()

        #expect(request?.url?.query == nil)
    }

    @Test("Default values use GET method and JSON content type")
    func defaultValues() throws {
        let endpoint = try TestEndpoint(baseURL: #require(URL(string: "https://api.example.com")),
                                        path: "/test")

        #expect(endpoint.method == .get)
        #expect(endpoint.contentType == .json)
        #expect(endpoint.queryParameters == nil)
        #expect(endpoint.headers == nil)
        #expect(endpoint.body == nil)
    }
}
