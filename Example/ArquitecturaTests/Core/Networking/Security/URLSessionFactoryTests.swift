import Foundation
import Testing
@testable import Arquitectura

// MARK: - URLSessionFactoryTests

@Suite
struct URLSessionFactoryTests {
    // MARK: - Configuration Tests

    @Test("The session waits for connectivity, allows Low Data Mode and uses the configured timeouts")
    func sessionConfiguration() throws {
        let session = try URLSessionFactory.makeSession(configuration: makeConfiguration(requestTimeout: 15))
        defer { session.finishTasksAndInvalidate() }

        #expect(session.configuration.waitsForConnectivity)
        #expect(session.configuration.allowsConstrainedNetworkAccess)
        #expect(session.configuration.timeoutIntervalForRequest == 15)
        #expect(session.configuration.timeoutIntervalForResource == 30)
    }

    // MARK: - Pinning Tests

    @Test("Without pinning the session has no delegate")
    func noPinningHasNoDelegate() throws {
        let session = try URLSessionFactory.makeSession(configuration: makeConfiguration())
        defer { session.finishTasksAndInvalidate() }

        #expect(session.delegate == nil)
    }

    @Test("With pinning the session uses SSLPinningDelegate")
    func pinningInstallsDelegate() throws {
        let configuration = try makeConfiguration(sslPinningEnabled: true,
                                                  sslPublicKeyHashes: ["sha256/3vIDjxskFtq6dc/Typn71SiUYMhzEKL5UjYAu1WBcgs="])
        let session = URLSessionFactory.makeSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }

        #expect(session.delegate is SSLPinningDelegate)
    }

    // MARK: - Helpers

    private func makeConfiguration(requestTimeout: TimeInterval = 30,
                                   sslPinningEnabled: Bool = false,
                                   sslPublicKeyHashes: [String] = []) throws -> EnvironmentConfigurationImpl {
        try EnvironmentConfigurationImpl(environment: .development,
                                         baseURL: #require(URL(string: "https://example.com")),
                                         requestTimeout: requestTimeout,
                                         sslPinningEnabled: sslPinningEnabled,
                                         sslPublicKeyHashes: sslPublicKeyHashes)
    }
}
