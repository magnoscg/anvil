import Foundation
import os

// MARK: - URLSessionFactory

/// Creates the app's `URLSession` from the environment configuration.
/// The session waits for connectivity instead of failing at once while offline, bounded by the
/// resource timeout, and installs `SSLPinningDelegate` for the API host when pinning is enabled.
enum URLSessionFactory {
    // MARK: - Properties

    private nonisolated static let logger = Logger(subsystem: "com.magnos.Arquitectura", category: "Networking")

    // MARK: - Public Methods

    /// Creates a URLSession configured for the given environment.
    /// When pinning is enabled without valid hashes (none, a placeholder, or a pin cut short by an xcconfig
    /// `//` comment), connections to the API host are rejected, a fault is logged and debug builds assert:
    /// a misconfigured build fails closed instead of shipping without pinning.
    /// - Parameter configuration: The environment configuration with timeouts and pinning settings.
    /// - Returns: A URLSession owned by the caller, who must invalidate it when done.
    static func makeSession(configuration: EnvironmentConfiguration) -> URLSession {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = configuration.requestTimeout
        sessionConfiguration.timeoutIntervalForResource = configuration.requestTimeout * 2
        sessionConfiguration.waitsForConnectivity = true

        guard configuration.sslPinningEnabled else {
            return URLSession(configuration: sessionConfiguration)
        }

        let pins = configuration.sslPublicKeyHashes
        if pins.isEmpty || !pins.allSatisfy(SSLPinningDelegate.isValidPin) {
            logger.fault("SSL pinning is enabled without valid SSL_PUBLIC_KEY_HASHES: API connections will be rejected")
            assertionFailure("SSL_PINNING_ENABLED=YES needs valid sha256/<base64> pins in SSL_PUBLIC_KEY_HASHES for \(configuration.environment)")
        }
        let delegate = SSLPinningDelegate(publicKeyHashes: configuration.sslPublicKeyHashes,
                                          pinnedHosts: Set([configuration.baseURL.host()].compactMap(\.self)))
        return URLSession(configuration: sessionConfiguration, delegate: delegate, delegateQueue: nil)
    }
}
