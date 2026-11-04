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

    // MARK: - Device State

    @Test("A GET that fails because the device is offline is not retried",
          arguments: [URLError.Code.notConnectedToInternet,
                      .dataNotAllowed,
                      .internationalRoamingOff,
                      .callIsActive])
    func deviceStateFailureIsNotRetried(code: URLError.Code) async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "GET")

        let interceptor = self.interceptor
        await #expect(throws: URLError.self) {
            _ = try await interceptor.intercept(request: request) { _ in
                await counter.increment()
                throw URLError(code)
            }
        }
        let callCount = await counter.count
        #expect(callCount == 1)
    }

    // MARK: - Time Budget and Retry-After

    @Test("No retry starts once the policy's time budget is spent")
    func noRetryAfterTimeBudget() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "GET")
        let interceptor = RetryInterceptor(policy: RetryPolicy(maxRetries: 2,
                                                               baseDelay: 0.001,
                                                               maxDelay: 0.001,
                                                               jitterFactor: 0,
                                                               maxElapsedTime: 0))

        _ = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503)
        }

        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test("A Retry-After longer than the time budget returns the response without retrying")
    func longRetryAfterIsNotRetried() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "GET")
        let interceptor = RetryInterceptor(policy: RetryPolicy(maxRetries: 2,
                                                               baseDelay: 0.001,
                                                               maxDelay: 600,
                                                               jitterFactor: 0,
                                                               maxElapsedTime: 30))

        let (_, response) = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503, headerFields: ["Retry-After": "120"])
        }

        #expect(response.statusCode == 503)
        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test("A Retry-After longer than maxDelay returns the response without retrying")
    func retryAfterBeyondMaxDelayIsNotRetried() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "GET")
        let interceptor = RetryInterceptor(policy: RetryPolicy(maxRetries: 2,
                                                               baseDelay: 0.001,
                                                               maxDelay: 5,
                                                               jitterFactor: 0,
                                                               maxElapsedTime: 600))

        _ = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 429, headerFields: ["Retry-After": "10"])
        }

        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test("A 429 with Retry-After: 0 is retried")
    func zeroRetryAfterIsRetried() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "GET")

        _ = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 429, headerFields: ["Retry-After": "0"])
        }

        let callCount = await counter.count
        #expect(callCount == 3)
    }

    @Test("Retry-After is read as delay-seconds")
    func retryAfterSeconds() throws {
        let (_, response) = try Self.makeResponse(for: makeRequest(method: "GET"),
                                                  statusCode: 503,
                                                  headerFields: ["Retry-After": "120"])

        #expect(RetryInterceptor.retryAfter(from: response) == 120)
    }

    @Test("Retry-After is read as an HTTP date relative to now")
    func retryAfterHTTPDate() throws {
        let now = Date(timeIntervalSince1970: 1_445_412_480)
        let (_, response) = try Self.makeResponse(for: makeRequest(method: "GET"),
                                                  statusCode: 503,
                                                  headerFields: ["Retry-After": "Wed, 21 Oct 2015 07:28:30 GMT"])

        #expect(RetryInterceptor.retryAfter(from: response, now: now) == 30)
    }

    @Test("A Retry-After date in the past means no wait")
    func retryAfterPastDate() throws {
        let now = Date(timeIntervalSince1970: 1_445_412_480)
        let (_, response) = try Self.makeResponse(for: makeRequest(method: "GET"),
                                                  statusCode: 503,
                                                  headerFields: ["Retry-After": "Wed, 21 Oct 2015 07:27:00 GMT"])

        #expect(RetryInterceptor.retryAfter(from: response, now: now) == 0)
    }

    @Test("An invalid or missing Retry-After is ignored", arguments: ["soon", "-5", nil] as [String?])
    func invalidRetryAfterIsIgnored(value: String?) throws {
        let headerFields = value.map { ["Retry-After": $0] }
        let (_, response) = try Self.makeResponse(for: makeRequest(method: "GET"),
                                                  statusCode: 503,
                                                  headerFields: headerFields)

        #expect(RetryInterceptor.retryAfter(from: response) == nil)
    }

    // MARK: - Method and Header Matching

    @Test("Idempotent methods are retried regardless of case", arguments: ["get", "HEAD", "Delete", "OPTIONS"])
    func idempotentMethodsAreRetried(method: String) async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: method)

        _ = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503)
        }

        let callCount = await counter.count
        #expect(callCount == 3)
    }

    @Test("The Idempotency-Key header is matched case-insensitively")
    func lowercaseIdempotencyKeyIsRetried() async throws {
        let counter = CallCounter()
        var request = try makeRequest(method: "POST")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "idempotency-key")

        _ = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503)
        }

        let callCount = await counter.count
        #expect(callCount == 3)
    }

    @Test("An empty Idempotency-Key does not make a POST retryable")
    func emptyIdempotencyKeyIsIgnored() async throws {
        let counter = CallCounter()
        var request = try makeRequest(method: "POST")
        request.setValue("  ", forHTTPHeaderField: "Idempotency-Key")

        _ = try await interceptor.intercept(request: request) { request in
            await counter.increment()
            return try Self.makeResponse(for: request, statusCode: 503)
        }

        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test("A request from an already cancelled task is not sent")
    func cancelledTaskIsNotSent() async throws {
        let counter = CallCounter()
        let request = try makeRequest(method: "POST")
        let interceptor = self.interceptor

        let task = Task {
            while !Task.isCancelled {
                await Task.yield()
            }
            _ = try await interceptor.intercept(request: request) { request in
                await counter.increment()
                return try Self.makeResponse(for: request, statusCode: 200)
            }
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        let callCount = await counter.count
        #expect(callCount == 0)
    }

    // MARK: - Helpers

    private func makeRequest(method: String) throws -> URLRequest {
        var request = URLRequest(url: try #require(URL(string: "https://example.com/orders")))
        request.httpMethod = method
        return request
    }

    private nonisolated static func makeResponse(for request: URLRequest,
                                                 statusCode: Int,
                                                 headerFields: [String: String]? = nil) throws -> (Data, HTTPURLResponse) {
        let url = try #require(request.url)
        let response = try #require(HTTPURLResponse(url: url,
                                                    statusCode: statusCode,
                                                    httpVersion: nil,
                                                    headerFields: headerFields))
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
