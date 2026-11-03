import Foundation
import Testing
@testable import Arquitectura

// MARK: - RetryInterceptorTests

@Suite
struct RetryInterceptorTests {
    // MARK: - Properties

    private let interceptor = RetryInterceptor(policy: RetryPolicy(maxRetries: 2,
                                                                   baseDelay: 0.001,
                                                                   maxDelay: 0.001,
                                                                   jitterFactor: 0))

    // MARK: - Idempotent Methods

    @Test("GET receiving 503 is retried up to maxRetries")
    func getIsRetried() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "GET")

        let (_, response) = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503)
        }

        #expect(response.statusCode == 503)
        let callCount = await counter.count
        #expect(callCount == 3)
    }

    @Test("PUT receiving 503 is retried")
    func putIsRetried() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "PUT")

        _ = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503)
        }

        let callCount = await counter.count
        #expect(callCount == 3)
    }

    // MARK: - Non-idempotent Methods

    @Test("POST receiving 503 is not retried")
    func postIsNotRetried() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "POST")

        let (_, response) = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503)
        }

        #expect(response.statusCode == 503)
        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test("PATCH failing with a lost connection is not retried")
    func patchNetworkFailureIsNotRetried() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "PATCH")

        let interceptor = self.interceptor
        await #expect(throws: URLError.self) {
            _ = try await interceptor.intercept(request: request) { _ in
                await counter.increment()
                throw URLError(.networkConnectionLost)
            }
        }
        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test("POST with an Idempotency-Key header is retried")
    func postWithIdempotencyKeyIsRetried() async throws {
        let counter = CallCounter()
        var request = try makeRequest(method: "POST")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")

        _ = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503)
        }

        let callCount = await counter.count
        #expect(callCount == 3)
    }

    // MARK: - Helpers

    private func makeRequest(method: String) throws -> URLRequest {
        var request = URLRequest(url: try #require(URL(string: "https://example.com/orders")))
        request.httpMethod = method
        return request
    }

    private nonisolated static func makeResponse(for request: URLRequest, statusCode: Int) throws -> (Data, HTTPURLResponse) {
        let url = try #require(request.url)
        let response = try #require(HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil))
        return (Data(), response)
    }
}

// MARK: - CallCounter

/// Counts how many times the core executor was called, safely across concurrent tasks.
private actor CallCounter {
    // MARK: - Properties

    private(set) var count = 0

    // MARK: - Methods

    func increment() {
        count += 1
    }
}
