import Foundation

// MARK: - DomainError

/// Domain-level error type used across all features.
/// Maps from data layer errors (e.g., `APIError`) and is mapped to `ErrorDecorator` in the presentation layer.
enum DomainError: Error {
    /// A network-related error occurred (connectivity, timeout, etc.)
    case network

    /// The requested resource was not found
    case notFound

    /// The server returned an error (5xx, rate limiting, etc.)
    case server

    /// Data could not be decoded or parsed
    case parsing

    /// An unknown or unexpected error occurred
    case unknown
}
