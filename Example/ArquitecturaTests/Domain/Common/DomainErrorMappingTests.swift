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

    @Test("Maps arbitrary Error to DomainError.unknown")
    func mapsArbitraryError() {
        let result = DomainError.map(NSError(domain: "test", code: 42))
        #expect(result == .unknown)
    }
}

// MARK: - ErrorDecoratorMappingTests

@Suite
@MainActor
struct ErrorDecoratorMappingTests {
    @Test("Maps DomainError.network to ErrorDecorator.network")
    func mapsNetworkToDecorator() {
        let result = ErrorDecorator.from(.network)
        #expect(result == .network)
        #expect(result.isRetryable == true)
    }

    @Test("Maps DomainError.notFound to ErrorDecorator.notFound")
    func mapsNotFoundToDecorator() {
        let result = ErrorDecorator.from(.notFound)
        #expect(result == .notFound)
        #expect(result.isRetryable == false)
    }

    @Test("Maps DomainError.server to ErrorDecorator.server")
    func mapsServerToDecorator() {
        let result = ErrorDecorator.from(.server)
        #expect(result == .server)
        #expect(result.isRetryable == true)
    }

    @Test("Maps DomainError.parsing to ErrorDecorator.generic")
    func mapsParsingToGeneric() {
        let result = ErrorDecorator.from(.parsing)
        #expect(result == .generic)
    }

    @Test("Maps DomainError.unknown to ErrorDecorator.generic")
    func mapsUnknownToGeneric() {
        let result = ErrorDecorator.from(.unknown)
        #expect(result == .generic)
    }
}
