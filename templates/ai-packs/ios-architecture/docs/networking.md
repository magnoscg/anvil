# Networking Guide

> Modern async/await networking patterns with URLSession.

## Overview

This guide covers the async networking layer: dual-endpoint system, interceptor chain, error handling, retry policies, and connectivity monitoring.

---

## Architecture Overview

The networking layer uses a **dual-endpoint system**:

| Endpoint Type | Use Case | Base URL Source |
|---------------|----------|----------------|
| `Endpoint` (struct) | Internal APIs | `EnvironmentConfiguration` (Info.plist -> xcconfig) |
| `APIEndpoint` (protocol) | External APIs (GitHub, etc.) | Embedded in the endpoint itself |

Both are consumed by the same `APIClient` protocol through separate overloads.

---

## APIClient Protocol

```swift
// Core/Networking/APIClient.swift

protocol APIClient: Sendable {
    /// For internal API endpoints — baseURL comes from EnvironmentConfiguration.
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T

    /// For external API endpoints — baseURL is embedded in the endpoint.
    func request<T: Decodable & Sendable>(_ endpoint: some APIEndpoint) async throws -> T
}
```

### APIClientImpl

The default implementation (`APIClientImpl`) is a `final class` (not struct) because it holds a `URLSession` reference and manages its lifecycle.

```swift
// Core/Networking/APIClientImpl.swift

final class APIClientImpl: APIClient, @unchecked Sendable {
    private let session: URLSession
    private let configuration: EnvironmentConfiguration
    private let decoder: JSONDecoder
    private let interceptors: [any RequestInterceptor]

    init(configuration: EnvironmentConfiguration = EnvironmentConfigurationImpl(),
         session: URLSession? = nil,
         decoder: JSONDecoder = JSONDecoder(),
         interceptors: [any RequestInterceptor]? = nil) {
        self.configuration = configuration
        self.session = session ?? URLSessionFactory.makeSession(configuration: configuration)
        self.decoder = decoder
        self.interceptors = interceptors ?? Self.defaultInterceptors()
    }

    deinit {
        session.invalidateAndCancel()
    }
}
```

**Key design decisions:**
- `@unchecked Sendable` — safe because all properties are `let` and `URLSession` is thread-safe
- Session created via `URLSessionFactory` which configures SSL pinning based on environment
- `deinit` invalidates the session to prevent resource leaks

---

## Endpoint (Internal APIs)

`Endpoint` is a **struct** (not a protocol) that represents an internal API endpoint. The base URL and API version come from `EnvironmentConfiguration`.

```swift
// Core/Networking/Endpoint.swift

struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let queryParameters: [String: any CustomStringConvertible & Sendable]?
    let headers: [String: String]?
    let body: Data?
    let contentType: ContentType
    let requiresAuthentication: Bool

    func buildURL(baseURL: URL, apiVersion: String) -> URL?
    func buildRequest(baseURL: URL, apiVersion: String) -> URLRequest?
}
```

### Static Factory Methods

```swift
// GET request
let endpoint = Endpoint.get(path: "/articles")

// GET with query parameters
let endpoint = Endpoint.get(path: "/articles", queryParameters: ["page": 1, "limit": 20])

// POST with Encodable body
let endpoint = try Endpoint.post(path: "/articles", body: articleDTO)

// PUT with Encodable body
let endpoint = try Endpoint.put(path: "/articles/\(id)", body: updatedDTO)

// DELETE
let endpoint = Endpoint.delete(path: "/articles/\(id)")
```

### Supporting Types

```swift
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum ContentType: String, Sendable {
    case json = "application/json"
    case formURLEncoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
    case textPlain = "text/plain"
}
```

---

## APIEndpoint (External APIs)

`APIEndpoint` is a **protocol** for external APIs where the base URL is fixed and known at compile time. Each external API defines its own conforming type.

```swift
// Core/Networking/APIEndpoint.swift

protocol APIEndpoint: Sendable {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryParameters: [String: any CustomStringConvertible & Sendable]? { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var contentType: ContentType { get }
    func buildRequest() -> URLRequest?
}
```

Default implementations are provided for: `method` (.get), `queryParameters` (nil), `headers` (nil), `body` (nil), `contentType` (.json), and `buildRequest()`.

### Example: External API

```swift
// Core/Networking/ExternalAPI/ExternalAPIEndpoint.swift

struct ExternalAPIEndpoint: APIEndpoint, Sendable {
    private static let externalBaseURL = URL(string: "https://api.example.com/v1")!

    var baseURL: URL { Self.externalBaseURL }
    let path: String
    let queryParameters: [String: any CustomStringConvertible & Sendable]?

    private init(path: String,
                 queryParameters: [String: any CustomStringConvertible & Sendable]? = nil) {
        self.path = path
        self.queryParameters = queryParameters
    }
}

extension ExternalAPIEndpoint {
    static func articleList(limit: Int, offset: Int) -> ExternalAPIEndpoint {
        ExternalAPIEndpoint(path: "/articles",
                            queryParameters: ["limit": limit, "offset": offset])
    }

    static func articleDetail(id: Int) -> ExternalAPIEndpoint {
        ExternalAPIEndpoint(path: "/articles/\(id)")
    }
}
```

### Usage in DataSource

```swift
struct ArticleRemoteDataSourceImpl: ArticleRemoteDataSource {
    private let apiClient: APIClient

    func fetchArticles(limit: Int, offset: Int) async throws -> ArticleResponseDTO {
        let endpoint = ExternalAPIEndpoint.articleList(limit: limit, offset: offset)
        return try await apiClient.request(endpoint)
    }
}
```

---

## Error Handling

### APIError

```swift
// Core/Networking/APIError.swift

nonisolated enum APIError: Error, Sendable {
    case networkError(URLError)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(DecodingError)
    case invalidURL
    case unknown(SendableError)
}
```

**Note:** Uses `SendableError` wrapper (not `String`) to maintain Sendable compliance:

```swift
nonisolated struct SendableError: Error, Sendable {
    let error: any Error
    init(_ error: any Error) { self.error = error }
    var localizedDescription: String { error.localizedDescription }
}
```

### Retryable Errors

```swift
extension APIError {
    var isRetryable: Bool {
        switch self {
        case let .networkError(urlError):
            let retryableCodes: [URLError.Code] = [
                .timedOut, .networkConnectionLost, .notConnectedToInternet,
                .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed
            ]
            return retryableCodes.contains(urlError.code)
        case let .httpError(statusCode, _):
            return statusCode >= 500 || statusCode == 429
        case .decodingError, .invalidURL, .unknown:
            return false
        }
    }
}
```

### Server Error Response

```swift
// Core/Networking/APIErrorResponse.swift

nonisolated struct APIErrorResponse: Decodable, Sendable, Equatable {
    let message: String?
    let code: String?
    let details: String?
    let errors: [String: [String]]?

    static func decode(from data: Data?) -> APIErrorResponse?
}

extension APIError {
    var serverError: APIErrorResponse? {
        guard case let .httpError(_, data) = self else { return nil }
        return APIErrorResponse.decode(from: data)
    }
}
```

### Error Mapping to Domain

```swift
enum ArticleError: Error {
    case notFound
    case serverError(String?)
    case networkUnavailable
    case unknown

    init(from apiError: APIError) {
        switch apiError {
        case .networkError:
            self = .networkUnavailable
        case let .httpError(statusCode, _) where statusCode == 404:
            self = .notFound
        case .httpError:
            self = .serverError(apiError.serverError?.message)
        case .decodingError, .invalidURL, .unknown:
            self = .unknown
        }
    }
}
```

### DON'T: Pre-flight Connectivity Checks

```swift
// WRONG: Checking connectivity before request
if networkMonitor.isConnected {
    let data = try await apiClient.request(endpoint)
}

// RIGHT: Just make the request, handle errors
do {
    let data: ArticleDTO = try await apiClient.request(endpoint)
} catch let error as APIError where error.isRetryable {
    // Show retry UI
} catch {
    // Show error
}
```

---

## Interceptor Chain

Requests pass through a chain of `RequestInterceptor`s before reaching the network.

### RequestInterceptor Protocol

```swift
// Core/Networking/RequestInterceptor.swift

protocol RequestInterceptor: Sendable {
    func intercept(
        request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse)
}
```

### Built-in Interceptors

#### RetryInterceptor

Implements retry logic with exponential backoff. Only retries transient errors.

```swift
nonisolated struct RetryInterceptor: RequestInterceptor {
    init(policy: RetryPolicy = .default)
}
```

Features:
- Retries on 5xx HTTP errors and 429 (rate limiting)
- Retries on transient URLError codes (timeout, connection lost, DNS failure, etc.)
- Respects `CancellationError` — never retries cancellation
- Uses `RetryPolicy` for backoff configuration

### Custom Interceptor Example (Auth)

```swift
struct AuthInterceptor: RequestInterceptor {
    let tokenProvider: TokenProvider

    func intercept(
        request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        var modifiedRequest = request
        if let token = try await tokenProvider.getToken() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await next(modifiedRequest)
    }
}
```

---

## Retry Policy

```swift
// Core/Networking/RetryPolicy.swift

nonisolated struct RetryPolicy: Sendable, Equatable {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let jitterFactor: Double

    func delay(for attempt: Int) -> TimeInterval
    func shouldRetry(attempt: Int) -> Bool
}
```

### Preset Policies

| Policy | Max Retries | Base Delay | Max Delay | Use Case |
|--------|-------------|------------|-----------|----------|
| `.default` | 3 | 1.0s | 30.0s | Standard requests |
| `.none` | 0 | 0 | 0 | No retries |
| `.aggressive` | 5 | 2.0s | 60.0s | Critical operations |
| `.quick` | 2 | 0.5s | 5.0s | Fast operations |

---

## Network Connectivity

### NetworkMonitor

```swift
// Core/Networking/NetworkMonitor.swift

protocol NetworkMonitor: Sendable {
    var isConnected: Bool { get }
    var isExpensive: Bool { get }
    var isConstrained: Bool { get }
    var connectionType: ConnectionType { get }
}

nonisolated enum ConnectionType: String, Sendable {
    case wifi, cellular, wiredEthernet, loopback, other, none
}
```

`NetworkMonitorImpl` uses `NWPathMonitor` and is `@Observable` for SwiftUI integration.

---

## Networking Checklist

### Architecture

- [ ] APIClient is protocol-based and injectable
- [ ] Internal endpoints use `Endpoint` struct with factory methods
- [ ] External endpoints use `APIEndpoint` protocol
- [ ] Errors are typed (`APIError`) and mapped between layers

### Error Handling

- [ ] All `APIError` cases handled in domain error mapping
- [ ] `CancellationError` propagated (not swallowed)
- [ ] Server error responses parsed via `APIErrorResponse`

### Interceptors

- [ ] Default chain includes retry
- [ ] Custom interceptors conform to `RequestInterceptor: Sendable`
- [ ] Auth token injection via interceptor (not in APIClient)

### Security

- [ ] SSL pinning configured in production xcconfig
- [ ] Sensitive headers redacted in logs

### Performance

- [ ] Using `URLSessionFactory` (not `URLSession.shared`) for proper lifecycle
- [ ] `waitsForConnectivity` enabled for resilience
- [ ] Retry policy tuned per request type
