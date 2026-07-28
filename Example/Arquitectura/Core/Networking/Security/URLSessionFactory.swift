import Foundation

// MARK: - URLSessionFactory

/// Factory for creating configured URLSession instances.
/// Handles SSL pinning configuration based on the environment.
enum URLSessionFactory {
    // MARK: - Public Methods

    /// Creates a URLSession configured for the given environment.
    /// - Parameters:
    ///   - configuration: The environment configuration containing SSL pinning settings.
    ///   - additionalConfiguration: Optional closure to apply additional URLSessionConfiguration settings.
    /// - Returns: A configured URLSession instance.
    static func makeSession(configuration: EnvironmentConfiguration,
                            additionalConfiguration: ((URLSessionConfiguration) -> Void)? = nil) -> URLSession {
        let sessionConfig = URLSessionConfiguration.default

        // Timeouts
        sessionConfig.timeoutIntervalForRequest = configuration.requestTimeout
        sessionConfig.timeoutIntervalForResource = configuration.requestTimeout * 2

        // Wait for connectivity instead of failing immediately
        sessionConfig.waitsForConnectivity = true

        // Respect Low Data Mode — non-essential requests will fail with
        // URLError.networkUnavailableReason == .constrained instead of silently using data
        sessionConfig.allowsConstrainedNetworkAccess = false

        // Apply additional configuration if provided
        additionalConfiguration?(sessionConfig)

        // Validate SSL pinning configuration consistency
        #if DEBUG
        if configuration.sslPinningEnabled, configuration.sslPublicKeyHashes.isEmpty {
            assertionFailure("SSL_PINNING_ENABLED=YES but SSL_PUBLIC_KEY_HASHES is empty in \(configuration.environment). Pinning will NOT be active.")
        }
        #endif

        // Create session with SSL pinning if enabled
        if configuration.sslPinningEnabled, !configuration.sslPublicKeyHashes.isEmpty {
            let delegate = SSLPinningDelegate(publicKeyHashes: configuration.sslPublicKeyHashes,
                                              isEnabled: true)
            return URLSession(configuration: sessionConfig,
                              delegate: delegate,
                              delegateQueue: nil)
        }

        // Return session without pinning
        return URLSession(configuration: sessionConfig)
    }

    /// Creates a default URLSession without SSL pinning.
    /// Useful for development or testing.
    /// - Parameter timeout: Request timeout interval in seconds.
    /// - Returns: A URLSession instance with default configuration.
    static func makeDefaultSession(timeout: TimeInterval = 30.0) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.waitsForConnectivity = true
        config.allowsConstrainedNetworkAccess = false
        return URLSession(configuration: config)
    }

    /// Creates an ephemeral URLSession (no caching, cookies, or credentials stored).
    /// Useful for sensitive requests or testing.
    /// - Parameter configuration: The environment configuration.
    /// - Returns: An ephemeral URLSession instance.
    static func makeEphemeralSession(configuration: EnvironmentConfiguration) -> URLSession {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = configuration.requestTimeout
        sessionConfig.timeoutIntervalForResource = configuration.requestTimeout * 2
        sessionConfig.waitsForConnectivity = true
        sessionConfig.allowsConstrainedNetworkAccess = false

        if configuration.sslPinningEnabled, !configuration.sslPublicKeyHashes.isEmpty {
            let delegate = SSLPinningDelegate(publicKeyHashes: configuration.sslPublicKeyHashes,
                                              isEnabled: true)
            return URLSession(configuration: sessionConfig,
                              delegate: delegate,
                              delegateQueue: nil)
        }

        return URLSession(configuration: sessionConfig)
    }
}
