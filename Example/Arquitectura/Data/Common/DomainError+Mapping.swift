import Foundation

// MARK: - DomainError + Error Mapping

/// Data-layer translation of transport and data-source errors into `DomainError`.
/// It lives in Data so that Domain never depends on `APIError` or any other infrastructure type.
extension DomainError {
    /// Runs a Data-layer operation and rethrows any failure as a `DomainError`.
    /// `CancellationError`, and any failure that arrives after the task was cancelled (for example
    /// a retry backoff interrupted by cancellation and wrapped by the client), is rethrown as
    /// `CancellationError` so cancellation keeps propagating instead of surfacing as an error.
    /// Repository implementations wrap their work in it, so Domain only ever sees domain errors.
    /// It runs in the caller's isolation, so a repository moved off the main actor stays off it.
    /// - Parameters:
    ///   - isolation: The caller's isolation, inferred with `#isolation`.
    ///   - operation: The data access to perform.
    /// - Returns: The operation's result.
    nonisolated static func catching<T>(isolation: isolated (any Actor)? = #isolation,
                                        _ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch is CancellationError {
            throw CancellationError()
        } catch where Task.isCancelled {
            throw CancellationError()
        } catch {
            throw map(error)
        }
    }

    /// Maps any error to a typed DomainError.
    /// - Parameter error: The error to map
    /// - Returns: A typed DomainError
    nonisolated static func map(_ error: Error) -> DomainError {
        if let domainError = error as? DomainError {
            return domainError
        }

        if let apiError = error as? APIError {
            return mapAPIError(apiError)
        }

        if error is DecodingError {
            return .parsing
        }

        return .unknown
    }

    // MARK: - Private

    private nonisolated static func mapAPIError(_ error: APIError) -> DomainError {
        switch error {
        case .networkError:
            .network
        case let .httpError(statusCode, _):
            statusCode == 404 ? .notFound : .server
        case .decodingError:
            .parsing
        case .invalidURL:
            .network
        case .unknown:
            .unknown
        }
    }
}
