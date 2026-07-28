import Foundation

// MARK: - AppEnvironment

/// Represents the application environment.
/// The current environment is determined at runtime from the Info.plist configuration.
enum AppEnvironment: String, CaseIterable {
    case dev
    case stg
    case production

    // MARK: - Current Environment

    static var current: AppEnvironment {
        guard let environmentString = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String,
              let environment = AppEnvironment(rawValue: environmentString) else {
            #if DEBUG
            return .dev
            #else
            return .production
            #endif
        }
        return environment
    }

    // MARK: - Convenience Properties

    var isDev: Bool {
        self == .dev
    }

    var isStg: Bool {
        self == .stg
    }

    var isProduction: Bool {
        self == .production
    }

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
        case .dev: "Dev"
        case .stg: "Stg"
        case .production: "Production"
        }
    }
}
