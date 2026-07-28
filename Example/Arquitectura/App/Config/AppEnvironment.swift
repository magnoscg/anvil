import Foundation

// MARK: - AppEnvironment

/// Represents the application environment (development, staging, production).
/// The current environment is determined at runtime from the Info.plist configuration.
enum AppEnvironment: String, CaseIterable {
    case development
    case staging
    case production

    // MARK: - Current Environment

    /// Returns the current environment based on the ENVIRONMENT value in Info.plist.
    /// Falls back to development in DEBUG builds and production in RELEASE builds.
    static var current: AppEnvironment {
        guard let environmentString = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String,
              let environment = AppEnvironment(rawValue: environmentString) else {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
        return environment
    }

    // MARK: - Convenience Properties

    var isDevelopment: Bool {
        self == .development
    }

    var isStaging: Bool {
        self == .staging
    }

    var isProduction: Bool {
        self == .production
    }

    /// Returns true if the app is built in DEBUG mode
    var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .development: "Development"
        case .staging: "Staging"
        case .production: "Production"
        }
    }
}
