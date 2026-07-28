import Foundation

// MARK: - APIError

/// Error types that can occur during network requests.
/// This enum is `nonisolated` because it's used in networking code that runs off the main actor.
nonisolated enum APIError: Error {
    case networkError(URLError)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(DecodingError)
    case invalidURL
    case unknown(SendableError)
}

// MARK: - SendableError

/// A wrapper for errors that need to be Sendable.
nonisolated struct SendableError: Error {
    let error: any Error

    init(_ error: any Error) {
        self.error = error
    }

    var localizedDescription: String {
        error.localizedDescription
    }
}

// MARK: - APIError + LocalizedError

extension APIError: LocalizedError {
    nonisolated var errorDescription: String? {
        switch self {
        case let .networkError(error):
            error.localizedDescription
        case let .httpError(statusCode, _):
            "HTTP Error: \(statusCode)"
        case let .decodingError(error):
            "Decoding Error: \(error.localizedDescription)"
        case .invalidURL:
            "Invalid URL"
        case let .unknown(error):
            error.localizedDescription
        }
    }
}

// MARK: - APIError + Retryable

extension APIError {
    /// Determines if this error is potentially transient and should be retried.
    /// Returns true for network errors and server-side HTTP errors (5xx, 429).
    var isRetryable: Bool {
        switch self {
        case let .networkError(urlError):
            // Retry on transient network issues
            let retryableCodes: [URLError.Code] = [.timedOut,
                                                   .networkConnectionLost,
                                                   .notConnectedToInternet,
                                                   .cannotFindHost,
                                                   .cannotConnectToHost,
                                                   .dnsLookupFailed]
            return retryableCodes.contains(urlError.code)

        case let .httpError(statusCode, _):
            // Retry on server errors (5xx) and rate limiting (429)
            return statusCode >= 500 || statusCode == 429

        case .decodingError, .invalidURL, .unknown:
            // These are not transient errors
            return false
        }
    }

    /// Extracts the server error response if available.
    /// - Returns: Decoded APIErrorResponse or nil
    var serverError: APIErrorResponse? {
        guard case let .httpError(_, data) = self else { return nil }
        return APIErrorResponse.decode(from: data)
    }
}
