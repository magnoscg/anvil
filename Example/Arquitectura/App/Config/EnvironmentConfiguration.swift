import Foundation

// MARK: - EnvironmentConfiguration

/// Protocol defining the configuration values needed for networking based on the current environment.
protocol EnvironmentConfiguration: Sendable {
    var environment: AppEnvironment { get }
    var baseURL: URL { get }
    var apiVersion: String { get }
    var requestTimeout: TimeInterval { get }
    var sslPinningEnabled: Bool { get }
    var sslPublicKeyHashes: [String] { get }
}

// MARK: - Default Values

extension EnvironmentConfiguration {
    var requestTimeout: TimeInterval {
        30.0
    }
}

// MARK: - EnvironmentConfigurationError

/// Errors thrown when environment configuration is invalid or missing.
enum EnvironmentConfigurationError: Error {
    /// API_BASE_URL key is missing or empty in Info.plist
    case missingBaseURL
    /// API_BASE_URL value is not a valid URL
    case invalidBaseURL(String)
}

// MARK: - EnvironmentConfigurationImpl

/// Default implementation that reads configuration from Info.plist.
/// Values are populated from xcconfig files at build time.
struct EnvironmentConfigurationImpl: EnvironmentConfiguration {
    // MARK: - Properties

    let environment: AppEnvironment
    let baseURL: URL
    let apiVersion: String
    let requestTimeout: TimeInterval
    let sslPinningEnabled: Bool
    let sslPublicKeyHashes: [String]

    // MARK: - Init

    /// Initializes configuration by reading values from Info.plist.
    /// - Throws: `EnvironmentConfigurationError` if required values are missing or invalid.
    init() throws {
        self.environment = AppEnvironment.current

        let bundle = Bundle.main
        let infoDictionary = bundle.infoDictionary ?? [:]

        guard let baseURLString = infoDictionary["API_BASE_URL"] as? String,
              !baseURLString.isEmpty else {
            throw EnvironmentConfigurationError.missingBaseURL
        }
        guard let url = URL(string: baseURLString) else {
            throw EnvironmentConfigurationError.invalidBaseURL(baseURLString)
        }
        self.baseURL = url

        self.apiVersion = infoDictionary["API_VERSION"] as? String ?? "v1"

        if let timeoutString = infoDictionary["REQUEST_TIMEOUT"] as? String,
           let timeout = TimeInterval(timeoutString) {
            self.requestTimeout = timeout
        } else {
            self.requestTimeout = 30.0
        }

        let sslEnabledString = infoDictionary["SSL_PINNING_ENABLED"] as? String ?? "NO"
        self.sslPinningEnabled = sslEnabledString.uppercased() == "YES"

        let hashesString = infoDictionary["SSL_PUBLIC_KEY_HASHES"] as? String ?? ""
        self.sslPublicKeyHashes = hashesString
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Custom Init (for testing/preview)

    /// Creates a custom configuration. Useful for testing or SwiftUI previews.
    init(environment: AppEnvironment,
         baseURL: URL,
         apiVersion: String = "v1",
         requestTimeout: TimeInterval = 30.0,
         sslPinningEnabled: Bool = false,
         sslPublicKeyHashes: [String] = []) {
        self.environment = environment
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.requestTimeout = requestTimeout
        self.sslPinningEnabled = sslPinningEnabled
        self.sslPublicKeyHashes = sslPublicKeyHashes
    }
}
