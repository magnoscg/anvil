import Foundation

// MARK: - ErrorDecorator

/// Decorator for displaying error state in UI.
/// Shared across all features for consistent error presentation.
struct ErrorDecorator: Equatable {
    // MARK: - Properties

    let title: String
    let message: String
    let isRetryable: Bool

    // MARK: - Static Factories

    static let generic = ErrorDecorator(title: String(localized: "error.title.generic"),
                                        message: String(localized: "error.message.generic"),
                                        isRetryable: true)

    static let notFound = ErrorDecorator(title: String(localized: "error.title.notFound"),
                                         message: String(localized: "error.message.notFound"),
                                         isRetryable: false)

    static let network = ErrorDecorator(title: String(localized: "error.title.network"),
                                        message: String(localized: "error.message.network"),
                                        isRetryable: true)

    static let server = ErrorDecorator(title: String(localized: "error.title.server"),
                                       message: String(localized: "error.message.server"),
                                       isRetryable: true)
}

// MARK: - DomainError Mapping

extension ErrorDecorator {
    /// Maps a DomainError to the appropriate ErrorDecorator for UI display.
    /// - Parameter error: The domain error to map
    /// - Returns: An ErrorDecorator with user-facing title, message, and retry capability
    static func from(_ error: DomainError) -> ErrorDecorator {
        switch error {
        case .network:
            .network
        case .notFound:
            .notFound
        case .server:
            .server
        case .parsing:
            .generic
        case .unknown:
            .generic
        }
    }
}
