import Foundation
import Testing
@testable import Arquitectura

// MARK: - DomainErrorMappingTests

@Suite
@MainActor
struct DomainErrorMappingTests {
    // MARK: - APIError to DomainError Mapping

    @Test("Maps APIError.networkError to DomainError.network")
    func mapsNetworkError() {
        let apiError = APIError.networkError(URLError(.notConnectedToInternet))
        let result = DomainError.map(apiError)
        #expect(result == .network)
    }

    @Test("Maps APIError.invalidURL to DomainError.network")
    func mapsInvalidURL() {
        let result = DomainError.map(APIError.invalidURL)
        #expect(result == .network)
    }

    @Test("Maps APIError.httpError 404 to DomainError.notFound")
    func mapsHttp404() {
        let apiError = APIError.httpError(statusCode: 404, data: nil)
        let result = DomainError.map(apiError)
        #expect(result == .notFound)
    }

    @Test("Maps APIError.httpError 500 to DomainError.server")
    func mapsHttp500() {
        let apiError = APIError.httpError(statusCode: 500, data: nil)
        let result = DomainError.map(apiError)
        #expect(result == .server)
    }

    @Test("Maps APIError.httpError 401 to DomainError.server")
    func mapsHttp401() {
        let apiError = APIError.httpError(statusCode: 401, data: nil)
        let result = DomainError.map(apiError)
        #expect(result == .server)
    }

    @Test("Maps APIError.decodingError to DomainError.parsing")
    func mapsDecodingError() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "test")
        let apiError = APIError.decodingError(.dataCorrupted(context))
        let result = DomainError.map(apiError)
        #expect(result == .parsing)
    }

    @Test("Maps APIError.unknown to DomainError.unknown")
    func mapsUnknownAPIError() {
        let apiError = APIError.unknown(SendableError(NSError(domain: "test", code: 1)))
        let result = DomainError.map(apiError)
        #expect(result == .unknown)
    }

    // MARK: - Pass-through and Unknown Errors

    @Test("Passes through existing DomainError unchanged")
    func passesThroughDomainError() {
        let result = DomainError.map(DomainError.notFound)
        #expect(result == .notFound)
    }

    @Test("Maps a local DecodingError to DomainError.parsing")
    func mapsLocalDecodingError() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "test")
        let result = DomainError.map(DecodingError.dataCorrupted(context))
        #expect(result == .parsing)
    }

    @Test("Maps arbitrary Error to DomainError.unknown")
    func mapsArbitraryError() {
        let result = DomainError.map(NSError(domain: "test", code: 42))
        #expect(result == .unknown)
    }

    // MARK: - Catching

    @Test("catching returns the operation's value")
    func catchingReturnsValue() async throws {
        let value = try await DomainError.catching { 42 }

        #expect(value == 42)
    }

    @Test("catching converts APIError into the mapped DomainError")
    func catchingMapsAPIError() async {
        do {
            _ = try await DomainError.catching { () async throws -> Int in
                throw APIError.httpError(statusCode: 503, data: nil)
            }
            Issue.record("Expected an error to be thrown")
        } catch {
            #expect(error as? DomainError == .server)
        }
    }

    @Test("catching converts unknown errors into DomainError.unknown")
    func catchingMapsUnknownError() async {
        do {
            _ = try await DomainError.catching { () async throws -> Int in
                throw NSError(domain: "test", code: 1)
            }
            Issue.record("Expected an error to be thrown")
        } catch {
            #expect(error as? DomainError == .unknown)
        }
    }

    @Test("catching treats a failure after cancellation as cancellation")
    func catchingTreatsFailureAfterCancellationAsCancellation() async {
        let task = Task { () async throws -> Int in
            try await DomainError.catching { () async throws -> Int in
                while !Task.isCancelled {
                    await Task.yield()
                }
                throw APIError.unknown(SendableError(NSError(domain: "test", code: 1)))
            }
        }
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected cancellation")
        } catch {
            #expect(error is CancellationError)
        }
    }

    @Test("catching rethrows CancellationError unchanged")
    func catchingRethrowsCancellation() async {
        await #expect(throws: CancellationError.self) {
            try await DomainError.catching { () async throws -> Int in
                throw CancellationError()
            }
        }
    }
}
