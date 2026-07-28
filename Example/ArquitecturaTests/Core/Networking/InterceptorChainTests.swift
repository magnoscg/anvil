import Foundation
import Testing
@testable import Arquitectura

// MARK: - InterceptorChainTests

@Suite
struct InterceptorChainTests {
    // MARK: - Chain Execution

    @Test("Chain executes through logging and retry to core executor")
    func chainExecutesThroughAllInterceptors() async throws {
        let chain = DefaultInterceptorChain()

        let expectedData = "test".data(using: .utf8)!
        let url = try #require(URL(string: "https://example.com"))
        let expectedResponse = try #require(HTTPURLResponse(url: url,
                                                            statusCode: 200,
                                                            httpVersion: nil,
                                                            headerFields: nil))

        let (data, response) = try await chain
            .execute(URLRequest(url: url)) { _ in
                (expectedData, expectedResponse)
            }

        #expect(data == expectedData)
        #expect(response.statusCode == 200)
    }

    @Test("Chain is reused across multiple requests without recreation")
    func chainIsReusedAcrossRequests() async throws {
        // Same chain instance used for both requests
        let chain = DefaultInterceptorChain()
        let firstURL = try #require(URL(string: "https://example.com/1"))
        let secondURL = try #require(URL(string: "https://example.com/2"))

        let response1 = try await chain
            .execute(URLRequest(url: firstURL)) { _ in
                ("one".data(using: .utf8)!, HTTPURLResponse(url: firstURL,
                                                            statusCode: 200,
                                                            httpVersion: nil,
                                                            headerFields: nil)!)
            }

        let response2 = try await chain
            .execute(URLRequest(url: secondURL)) { _ in
                ("two".data(using: .utf8)!, HTTPURLResponse(url: secondURL,
                                                            statusCode: 200,
                                                            httpVersion: nil,
                                                            headerFields: nil)!)
            }

        #expect(String(data: response1.0, encoding: .utf8) == "one")
        #expect(String(data: response2.0, encoding: .utf8) == "two")
    }

    @Test("Chain propagates errors from core executor")
    func chainPropagatesErrors() async throws {
        let chain = DefaultInterceptorChain()
        let url = try #require(URL(string: "https://example.com"))

        await #expect(throws: APIError.self) {
            try await chain.execute(URLRequest(url: url)) { _ in
                throw APIError.invalidURL
            }
        }
    }

    @Test("Chain returns correct HTTP response metadata")
    func chainPreservesResponseMetadata() async throws {
        let chain = DefaultInterceptorChain()
        let url = try #require(URL(string: "https://example.com"))

        let (_, response) = try await chain
            .execute(URLRequest(url: url)) { _ in
                (Data(), HTTPURLResponse(url: url,
                                         statusCode: 201,
                                         httpVersion: nil,
                                         headerFields: ["Content-Type": "application/json"])!)
            }

        #expect(response.statusCode == 201)
    }
}
