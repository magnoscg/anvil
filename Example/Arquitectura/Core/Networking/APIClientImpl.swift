import Foundation

// MARK: - APIClientImpl

/// Default implementation of APIClient that handles network requests.
/// Configured with environment-specific settings including SSL pinning.
/// Supports a chain of request interceptors for logging, retry, auth, etc.
///
/// ## Thread Safety
/// This class conforms to `Sendable` via `@unchecked` because:
/// - All stored properties are immutable (`let` constants)
/// - `URLSession` is designed to be thread-safe
/// - `decoderFactory` creates a new decoder per request (no shared mutable state)
///
/// - Warning: DO NOT add mutable (`var`) properties without re-analyzing thread safety!
final class APIClientImpl: APIClient, @unchecked Sendable {
    // MARK: - Properties

    private let session: URLSession
    private let configuration: EnvironmentConfiguration
    private let decoderFactory: @Sendable () -> JSONDecoder
    private let interceptorChain: DefaultInterceptorChain

    // MARK: - Init

    /// Creates an API client with the given configuration.
    /// - Parameters:
    ///   - configuration: Environment configuration (must be injected explicitly).
    ///   - session: URLSession to use (defaults to a session configured for the environment).
    ///   - decoderFactory: Factory closure to create a JSONDecoder per request (thread-safe).
    ///   - interceptorChain: Concrete interceptor chain (default: logging + retry).
    init(configuration: EnvironmentConfiguration,
         session: URLSession? = nil,
         decoderFactory: @escaping @Sendable () -> JSONDecoder = { JSONDecoder() },
         interceptorChain: DefaultInterceptorChain = DefaultInterceptorChain()) {
        self.configuration = configuration
        self.session = session ?? URLSessionFactory.makeSession(configuration: configuration)
        self.decoderFactory = decoderFactory
        self.interceptorChain = interceptorChain
    }

    // MARK: - Deinit

    deinit {
        session.invalidateAndCancel()
    }

    // MARK: - APIClient

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        guard let request = endpoint.buildRequest(baseURL: configuration.baseURL,
                                                  apiVersion: configuration.apiVersion) else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }

    func request<T: Decodable & Sendable>(_ endpoint: some APIEndpoint) async throws -> T {
        guard let request = endpoint.buildRequest() else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }
}

// MARK: - Private Methods

private extension APIClientImpl {
    /// Performs the actual network request through the interceptor chain and decodes the response.
    /// Shared logic between internal (Endpoint) and external (APIEndpoint) requests.
    /// - Parameter request: The configured URLRequest to execute.
    /// - Returns: The decoded response of type T.
    /// - Throws: APIError if the request fails.
    func performRequest<T: Decodable & Sendable>(_ request: URLRequest) async throws -> T {
        let session = self.session

        do {
            let (data, httpResponse) = try await interceptorChain.execute(request) { request in
                try await Self.executeRequest(request, session: session)
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
            }

            do {
                let decoder = decoderFactory()
                return try decoder.decode(T.self, from: data)
            } catch let error as DecodingError {
                throw APIError.decodingError(error)
            }
        } catch let error as URLError {
            if error.code == .cancelled {
                throw CancellationError()
            }
            throw APIError.networkError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown(SendableError(error))
        }
    }

    /// Core request executor that performs the actual URLSession data task.
    /// This is the innermost function in the interceptor chain.
    static func executeRequest(_ request: URLRequest, session: URLSession) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(SendableError(URLError(.badServerResponse)))
        }

        return (data, httpResponse)
    }
}
