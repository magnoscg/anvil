import Foundation

// MARK: - DomainError + Error Mapping

extension DomainError {
    /// Maps any error to a typed DomainError.
    /// Use this in UseCases to convert data layer errors into domain-level errors.
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
