import Foundation
import Testing
@testable import Arquitectura

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
