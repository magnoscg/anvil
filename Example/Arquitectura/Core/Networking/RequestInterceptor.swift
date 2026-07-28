import Foundation

// MARK: - RequestInterceptor

/// Protocol for intercepting and modifying network requests/responses.
/// Interceptors form a chain where each can modify the request, execute the next handler,
/// and optionally modify or handle the response.
///
/// ## Usage Example
/// ```swift
/// struct MyInterceptor: RequestInterceptor {
///     func intercept(
///         request: URLRequest,
///         next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
///     ) async throws -> (Data, HTTPURLResponse) {
///         // Modify request before sending
///         var modifiedRequest = request
///         modifiedRequest.setValue("Bearer token", forHTTPHeaderField: "Authorization")
///
///         // Execute the chain
///         let (data, response) = try await next(modifiedRequest)
///
///         // Optionally handle/modify response
///         return (data, response)
///     }
/// }
/// ```
protocol RequestInterceptor: Sendable {
    /// Intercepts a request and optionally modifies it before/after execution.
    /// - Parameters:
    ///   - request: The URLRequest to potentially modify
    ///   - next: The next handler in the chain to execute
    /// - Returns: The response data and HTTP response
    /// - Throws: Any error from the request or interceptor logic
    func intercept(request: URLRequest,
                   next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) async throws -> (Data,
                                                                                                          HTTPURLResponse)
}

// MARK: - InterceptorChain

/// Builds and executes a chain of request interceptors.
/// The chain wraps each interceptor around the next, with the core executor at the center.
///
/// This struct is `nonisolated` because it's used in networking code that runs off the main actor.
nonisolated struct InterceptorChain {
    // MARK: - Types

    /// The core request executor function type
    typealias Executor = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    // MARK: - Properties

    private let interceptors: [any RequestInterceptor]
    private let coreExecutor: Executor

    // MARK: - Init

    /// Creates an interceptor chain.
    /// - Parameters:
    ///   - interceptors: Array of interceptors to apply (first interceptor is outermost)
    ///   - coreExecutor: The base executor that performs the actual network request
    init(interceptors: [any RequestInterceptor], coreExecutor: @escaping Executor) {
        self.interceptors = interceptors
        self.coreExecutor = coreExecutor
    }

    // MARK: - Methods

    /// Executes the request through the interceptor chain.
    /// - Parameter request: The initial URLRequest
    /// - Returns: The response data and HTTP response
    /// - Throws: Any error from the chain
    func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Build the chain from inside out
        // Last interceptor wraps the core executor, first interceptor is outermost
        let chain = interceptors.reversed().reduce(coreExecutor) { next, interceptor in
            { request in
                try await interceptor.intercept(request: request, next: next)
            }
        }

        return try await chain(request)
    }
}

// MARK: - DefaultInterceptorChain

/// Concrete interceptor chain that holds `LoggingInterceptor` + `RetryInterceptor` as typed properties.
/// Eliminates existential container overhead (`any RequestInterceptor`) on the hot network path.
/// Constructed once at `APIClientImpl.init` and reused for every request.
nonisolated struct DefaultInterceptorChain {
    // MARK: - Properties

    private let logging: LoggingInterceptor
    private let retry: RetryInterceptor

    // MARK: - Init

    init(logging: LoggingInterceptor = LoggingInterceptor(),
         retry: RetryInterceptor = RetryInterceptor()) {
        self.logging = logging
        self.retry = retry
    }

    // MARK: - Methods

    /// Executes the request through the concrete chain: logging → retry → core executor.
    func execute(_ request: URLRequest,
                 coreExecutor: @escaping @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) async throws
        -> (Data, HTTPURLResponse) {
        try await logging.intercept(request: request) { request in
            try await self.retry.intercept(request: request, next: coreExecutor)
        }
    }
}

// MARK: - Empty Interceptor

/// A no-op interceptor that simply passes through to the next handler.
/// Useful as a placeholder or for testing.
nonisolated struct PassthroughInterceptor: RequestInterceptor {
    func intercept(request: URLRequest,
                   next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) async throws -> (Data,
                                                                                                          HTTPURLResponse) {
        try await next(request)
    }
}
