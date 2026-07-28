import Foundation

// MARK: - RetryPolicy

/// Configuration for retry behavior with exponential backoff and jitter.
/// Provides sensible defaults for common scenarios.
///
/// This struct is `nonisolated` because it's a pure data container used in networking
/// code that runs off the main actor.
nonisolated struct RetryPolicy: Equatable {
    // MARK: - Properties

    /// Maximum number of retry attempts (0 means no retries)
    let maxRetries: Int

    /// Base delay between retries in seconds
    let baseDelay: TimeInterval

    /// Maximum delay cap in seconds
    let maxDelay: TimeInterval

    /// Jitter factor (0.0 to 1.0) to randomize delays
    let jitterFactor: Double

    // MARK: - Init

    /// Creates a retry policy with custom configuration.
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - baseDelay: Base delay in seconds (default: 1.0)
    ///   - maxDelay: Maximum delay cap in seconds (default: 30.0)
    ///   - jitterFactor: Jitter factor 0.0-1.0 (default: 0.3)
    init(maxRetries: Int = 3,
         baseDelay: TimeInterval = 1.0,
         maxDelay: TimeInterval = 30.0,
         jitterFactor: Double = 0.3) {
        self.maxRetries = max(0, maxRetries)
        self.baseDelay = max(0, baseDelay)
        self.maxDelay = max(0, maxDelay)
        self.jitterFactor = min(max(0, jitterFactor), 1.0)
    }

    // MARK: - Methods

    /// Calculates the delay for a given retry attempt using exponential backoff with jitter.
    /// - Parameter attempt: The current retry attempt (0-indexed)
    /// - Returns: The delay in seconds before the next retry
    func delay(for attempt: Int) -> TimeInterval {
        guard attempt >= 0 else { return 0 }

        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0 ... (jitterFactor * exponentialDelay))
        return min(exponentialDelay + jitter, maxDelay)
    }

    /// Checks if more retries are allowed for the given attempt count.
    /// - Parameter currentAttempt: The current attempt number (0-indexed)
    /// - Returns: True if another retry is allowed
    func shouldRetry(attempt currentAttempt: Int) -> Bool {
        currentAttempt < maxRetries
    }
}

// MARK: - Preset Policies

nonisolated extension RetryPolicy {
    /// Default retry policy: 3 retries with exponential backoff (1s, 2s, 4s base)
    static let `default` = RetryPolicy(maxRetries: 3,
                                       baseDelay: 1.0,
                                       maxDelay: 30.0,
                                       jitterFactor: 0.3)

    /// No retries - fail immediately on first error
    static let none = RetryPolicy(maxRetries: 0,
                                  baseDelay: 0,
                                  maxDelay: 0,
                                  jitterFactor: 0)

    /// Aggressive retry policy for critical operations: 5 retries with longer delays
    static let aggressive = RetryPolicy(maxRetries: 5,
                                        baseDelay: 2.0,
                                        maxDelay: 60.0,
                                        jitterFactor: 0.25)

    /// Quick retry policy for fast operations: 2 retries with short delays
    static let quick = RetryPolicy(maxRetries: 2,
                                   baseDelay: 0.5,
                                   maxDelay: 5.0,
                                   jitterFactor: 0.2)
}
