import Foundation
import os
import Testing
@testable import Arquitectura

// MARK: - APIClientImplTests

@Suite
struct APIClientImplTests {
    // MARK: - Session Ownership Tests

    @Test("Releasing the client does not invalidate an injected session")
    func injectedSessionStaysValid() async throws {
        let observer = SessionInvalidationObserver()
        let session = URLSession(configuration: .ephemeral, delegate: observer, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        _ = try APIClientImpl(configuration: makeConfiguration(), session: session)
        try await Task.sleep(for: .milliseconds(500))

        #expect(!observer.didInvalidate)
    }

    @Test("The invalidation observer reports an invalidated session")
    func observerReportsInvalidation() async throws {
        let observer = SessionInvalidationObserver()
        let session = URLSession(configuration: .ephemeral, delegate: observer, delegateQueue: nil)

        session.finishTasksAndInvalidate()
        for _ in 0 ..< 50 where !observer.didInvalidate {
            try await Task.sleep(for: .milliseconds(20))
        }

        #expect(observer.didInvalidate)
    }

    // MARK: - Helpers

    private func makeConfiguration() throws -> EnvironmentConfigurationImpl {
        try EnvironmentConfigurationImpl(environment: .development,
                                         baseURL: #require(URL(string: "https://example.com")))
    }
}

// MARK: - SessionInvalidationObserver

/// Records whether the URLSession it delegates for has been invalidated.
nonisolated final class SessionInvalidationObserver: NSObject, URLSessionDelegate, Sendable {
    // MARK: - Properties

    private let state = OSAllocatedUnfairLock(initialState: false)

    var didInvalidate: Bool {
        state.withLock { $0 }
    }

    // MARK: - URLSessionDelegate

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
        state.withLock { $0 = true }
    }
}
