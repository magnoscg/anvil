import Foundation
import os

// MARK: - RetryInterceptor

/// Interceptor that implements retry logic with exponential backoff.
/// Only retries requests that are safe to resend (an idempotent HTTP method, or any request carrying an
/// `Idempotency-Key` header) and that fail with retryable errors (network issues, server errors).
/// A POST or PATCH whose response was lost may already have been applied by the server, so resending
/// it could duplicate the side effect. Errors that describe the device state (offline, cellular data
/// disabled, roaming off) are not retried: the session already waits for connectivity, and a retry a
/// few seconds later would fail the same way.
///
/// This struct is `nonisolated` because it's used in networking code that runs off the main actor.
nonisolated struct RetryInterceptor: RequestInterceptor {
    // MARK: - Properties

    private let policy: RetryPolicy
    private let logger: Logger

    // MARK: - Init

    /// Creates a retry interceptor with the specified policy.
    /// - Parameter policy: The retry policy to use (default: .default)
    init(policy: RetryPolicy = .default) {
        self.policy = policy
        self.logger = Logger(subsystem: "com.magnos.Arquitectura", category: "Retry")
    }

    // MARK: - RequestInterceptor

    func intercept(request: URLRequest,
                   next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) async throws -> (Data,
                                                                                                          HTTPURLResponse) {
        try Task.checkCancellation()

        guard Self.isSafeToRetry(request) else {
            return try await next(request)
        }

        var attempt = 0

        while true {
            do {
                let (data, response) = try await next(request)

                if isRetryableStatusCode(response.statusCode), policy.shouldRetry(attempt: attempt) {
                    let delay = policy.delay(for: attempt)
                    logRetry(attempt: attempt, delay: delay, reason: "HTTP \(response.statusCode)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    attempt += 1
                    continue
                }

                return (data, response)

            } catch let error as URLError {
                if isRetryableURLError(error), policy.shouldRetry(attempt: attempt) {
                    let delay = policy.delay(for: attempt)
                    logRetry(attempt: attempt, delay: delay, reason: error.localizedDescription)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    attempt += 1
                    continue
                }
                throw error

            } catch let error as APIError {
                if error.isRetryable, policy.shouldRetry(attempt: attempt) {
                    let delay = policy.delay(for: attempt)
                    logRetry(attempt: attempt, delay: delay, reason: error.localizedDescription)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    attempt += 1
                    continue
                }
                throw error

            } catch is CancellationError {
                throw CancellationError()

            } catch {
                throw error
            }
        }
    }
}

// MARK: - Private Methods

private extension RetryInterceptor {
    // MARK: - Static Collections

    private static let idempotentMethods: Set<String> = ["GET", "HEAD", "PUT", "DELETE", "OPTIONS", "TRACE"]
    private static let idempotencyKeyHeader = "Idempotency-Key"

    private static let retryableURLErrorCodes: Set<URLError.Code> = [.timedOut,
                                                                     .networkConnectionLost,
                                                                     .cannotFindHost,
                                                                     .cannotConnectToHost,
                                                                     .dnsLookupFailed,
                                                                     .callIsActive]

    /// Determines if resending the request cannot duplicate a side effect on the server.
    static func isSafeToRetry(_ request: URLRequest) -> Bool {
        if let idempotencyKey = request.value(forHTTPHeaderField: idempotencyKeyHeader),
           !idempotencyKey.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }
        let method = (request.httpMethod ?? "GET").uppercased()
        return idempotentMethods.contains(method)
    }

    /// Determines if an HTTP status code is retryable.
    func isRetryableStatusCode(_ statusCode: Int) -> Bool {
        statusCode >= 500 || statusCode == 429
    }

    /// Determines if a URLError is retryable.
    func isRetryableURLError(_ error: URLError) -> Bool {
        Self.retryableURLErrorCodes.contains(error.code)
    }

    func logRetry(attempt: Int, delay: TimeInterval, reason: String) {
        #if DEBUG
        logger
            .debug("Retry attempt \(attempt + 1)/\(self.policy.maxRetries) after \(String(format: "%.2f", delay))s - Reason: \(reason)")
        #endif
    }
}
