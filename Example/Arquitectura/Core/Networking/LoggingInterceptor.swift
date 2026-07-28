import Foundation
import os

// MARK: - LoggingInterceptor

/// Interceptor that logs HTTP request and response details.
/// Only logs in DEBUG builds to avoid leaking sensitive information in production.
///
/// This struct is `nonisolated` because it's used in networking code that runs off the main actor.
nonisolated struct LoggingInterceptor: RequestInterceptor {
    // MARK: - Types

    /// Log level for controlling verbosity
    enum LogLevel: Int, Comparable {
        case none = 0
        case minimal = 1
        case standard = 2
        case verbose = 3

        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Properties

    private let level: LogLevel
    private let logger: Logger

    // MARK: - Init

    /// Creates a logging interceptor.
    /// - Parameter level: The log level (default: .standard in DEBUG, .none in release)
    init(level: LogLevel? = nil) {
        #if DEBUG
        self.level = level ?? .standard
        #else
        self.level = level ?? .none
        #endif
        self.logger = Logger(subsystem: "com.magnos.Arquitectura", category: "Network")
    }

    // MARK: - RequestInterceptor

    func intercept(request: URLRequest,
                   next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) async throws -> (Data,
                                                                                                          HTTPURLResponse) {
        guard level > .none else {
            return try await next(request)
        }

        let requestId = UUID().uuidString.prefix(8)
        let startTime = CFAbsoluteTimeGetCurrent()

        logRequest(request, id: String(requestId))

        do {
            let (data, response) = try await next(request)
            let duration = CFAbsoluteTimeGetCurrent() - startTime

            logResponse(response, data: data, duration: duration, id: String(requestId))

            return (data, response)
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logError(error, duration: duration, id: String(requestId))
            throw error
        }
    }
}

// MARK: - Private Logging Methods

private extension LoggingInterceptor {
    func logRequest(_ request: URLRequest, id: String) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"

        switch level {
        case .none:
            break

        case .minimal:
            logger.debug("[\(id)] \(method) \(url)")

        case .standard:
            var message = "[\(id)] -> \(method) \(url)"
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                let headersList = headers.keys.sorted().joined(separator: ", ")
                message += "\n  Headers: [\(headersList)]"
            }
            logger.debug("\(message)")

        case .verbose:
            var message = "[\(id)] -> \(method) \(url)"
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                message += "\n  Headers: \(formatHeaders(headers))"
            }
            if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                let truncated = bodyString.prefix(1000)
                message += "\n  Body: \(truncated)\(bodyString.count > 1000 ? "..." : "")"
            }
            logger.debug("\(message)")
        }
    }

    func logResponse(_ response: HTTPURLResponse, data: Data, duration: TimeInterval, id: String) {
        let statusCode = response.statusCode
        let statusEmoji = statusEmoji(for: statusCode)
        let url = response.url?.absoluteString ?? "unknown"

        switch level {
        case .none:
            break

        case .minimal:
            logger.debug("[\(id)] \(statusEmoji) \(statusCode) (\(String(format: "%.2f", duration * 1000))ms)")

        case .standard:
            let size = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)
            logger
                .debug("[\(id)] <- \(statusEmoji) \(statusCode) \(url)\n  Duration: \(String(format: "%.2f", duration * 1000))ms | Size: \(size)")

        case .verbose:
            var message = "[\(id)] <- \(statusEmoji) \(statusCode) \(url)"
            message += "\n  Duration: \(String(format: "%.2f", duration * 1000))ms"
            message += "\n  Size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory))"

            if let headers = response.allHeaderFields as? [String: String], !headers.isEmpty {
                message += "\n  Headers: \(formatHeaders(headers))"
            }

            if let bodyString = String(data: data, encoding: .utf8) {
                let truncated = bodyString.prefix(2000)
                message += "\n  Body: \(truncated)\(bodyString.count > 2000 ? "..." : "")"
            }

            logger.debug("\(message)")
        }
    }

    func logError(_ error: Error, duration: TimeInterval, id: String) {
        logger
            .error("[\(id)] <- FAILED after \(String(format: "%.2f", duration * 1000))ms: \(error.localizedDescription)")
    }

    func formatHeaders(_ headers: [String: String]) -> String {
        // Mask sensitive headers
        let sensitiveKeys = ["authorization", "x-api-key", "cookie", "set-cookie"]
        let masked = headers.mapValues { value -> String in
            value
        }.map { key, value in
            if sensitiveKeys.contains(key.lowercased()) {
                return "\(key): [REDACTED]"
            }
            return "\(key): \(value)"
        }
        return masked.sorted().joined(separator: ", ")
    }

    func statusEmoji(for code: Int) -> String {
        switch code {
        case 200 ..< 300: "OK"
        case 300 ..< 400: "REDIRECT"
        case 400 ..< 500: "CLIENT_ERROR"
        case 500 ..< 600: "SERVER_ERROR"
        default: "UNKNOWN"
        }
    }
}
