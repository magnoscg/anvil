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

        let clock = ContinuousClock()
        let start = clock.now
        var attempt = 0

        while true {
            let delay: TimeInterval
            do {
                let (data, response) = try await next(request)
                guard isRetryableStatusCode(response.statusCode),
                      let retryDelay = delayBeforeRetry(attempt: attempt,
                                                        elapsed: start.duration(to: clock.now),
                                                        retryAfter: Self.retryAfter(from: response)) else {
                    return (data, response)
                }
                logRetry(attempt: attempt, delay: retryDelay, reason: "HTTP \(response.statusCode)")
                delay = retryDelay
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                guard isRetryable(error),
                      let retryDelay = delayBeforeRetry(attempt: attempt,
                                                        elapsed: start.duration(to: clock.now),
                                                        retryAfter: nil) else {
                    throw error
                }
                logRetry(attempt: attempt, delay: retryDelay, reason: error.localizedDescription)
                delay = retryDelay
            }
            try await Task.sleep(for: .seconds(delay))
            attempt += 1
        }
    }
}

// MARK: - Retry-After

extension RetryInterceptor {
    /// Reads the `Retry-After` header of a response, as delay-seconds or as an HTTP date.
    /// - Parameters:
    ///   - response: The HTTP response that may carry the header.
    ///   - now: The current date, used to turn an HTTP date into a delay.
    /// - Returns: The delay in seconds the server asked for, or nil when the header is absent or invalid.
    nonisolated static func retryAfter(from response: HTTPURLResponse, now: Date = Date()) -> TimeInterval? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After")?
            .trimmingCharacters(in: .whitespaces), !value.isEmpty else {
            return nil
        }
        if let seconds = Int(value) {
            return seconds >= 0 ? TimeInterval(seconds) : nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        guard let date = formatter.date(from: value) else {
            return nil
        }
        return max(0, date.timeIntervalSince(now))
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

    /// Determines if a failed attempt can be retried.
    func isRetryable(_ error: any Error) -> Bool {
        switch error {
        case let urlError as URLError:
            Self.retryableURLErrorCodes.contains(urlError.code)
        case let apiError as APIError:
            apiError.isRetryable
        default:
            false
        }
    }

    /// Returns how long to wait before the next attempt, or nil when no retry may start.
    /// A `Retry-After` value from the server replaces the backoff delay. No retry is scheduled when
    /// the attempts are used up or the retry would start after the policy's time budget.
    func delayBeforeRetry(attempt: Int, elapsed: Duration, retryAfter: TimeInterval?) -> TimeInterval? {
        guard policy.shouldRetry(attempt: attempt) else {
            return nil
        }
        let delay = retryAfter ?? policy.delay(for: attempt)
        let elapsedSeconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        return policy.fitsTimeBudget(elapsed: elapsedSeconds, delay: delay) ? delay : nil
    }

    func logRetry(attempt: Int, delay: TimeInterval, reason: String) {
        #if DEBUG
        logger
            .debug("Retry attempt \(attempt + 1)/\(self.policy.maxRetries) after \(String(format: "%.2f", delay))s - Reason: \(reason)")
        #endif
    }
}
