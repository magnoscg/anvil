import Foundation
import os

// MARK: - RetryInterceptor

/// Interceptor that implements retry logic with exponential backoff.
/// Only retries requests that fail with retryable errors (network issues, server errors).
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

    private static let retryableURLErrorCodes: Set<URLError.Code> = [.timedOut,
                                                                     .networkConnectionLost,
                                                                     .notConnectedToInternet,
                                                                     .cannotFindHost,
                                                                     .cannotConnectToHost,
                                                                     .dnsLookupFailed,
                                                                     .internationalRoamingOff,
                                                                     .callIsActive,
                                                                     .dataNotAllowed]

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
