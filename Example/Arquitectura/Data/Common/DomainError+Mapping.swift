import Foundation

// MARK: - DomainError + Error Mapping

/// Data-layer translation of transport and data-source errors into `DomainError`.
/// It lives in Data so that Domain never depends on `APIError` or any other infrastructure type.
extension DomainError {
    /// Runs a Data-layer operation and rethrows any failure as a `DomainError`.
    /// `CancellationError` is rethrown unchanged so cancellation keeps propagating.
    /// Repository implementations wrap their work in it, so Domain only ever sees domain errors.
    /// - Parameter operation: The data access to perform.
    /// - Returns: The operation's result.
    static func catching<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw map(error)
        }
    }

    /// Maps any error to a typed DomainError.
    /// - Parameter error: The error to map
    /// - Returns: A typed DomainError
    static func map(_ error: Error) -> DomainError {
        if let domainError = error as? DomainError {
            return domainError
        }

        if let apiError = error as? APIError {
            return mapAPIError(apiError)
        }

        return .unknown
    }

    // MARK: - Private

    private static func mapAPIError(_ error: APIError) -> DomainError {
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
