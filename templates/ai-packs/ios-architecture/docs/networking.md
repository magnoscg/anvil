# Networking Guide

> Modern async/await networking patterns with URLSession.

## Overview

This guide covers the async networking layer: dual-endpoint system, interceptor chain, error handling, retry policies, SSL pinning, and connectivity monitoring.

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

// MARK: - APIClientImpl

final class APIClientImpl: APIClient, @unchecked Sendable {
    // MARK: - Properties

    private let session: URLSession
    private let ownsSession: Bool
    private let decoder: JSONDecoder
    private let interceptorChain: InterceptorChain
    private let configuration: EnvironmentConfiguration

    // MARK: - Init

    init(configuration: EnvironmentConfiguration,
         session: URLSession? = nil,
         decoder: JSONDecoder = JSONDecoder(),
         interceptors: [any RequestInterceptor]? = nil)

    deinit {
        if ownsSession {
            session.finishTasksAndInvalidate()
        }
    }
}
```

**Key design decisions:**
- Created once in `AppDependencies` (`APIClientImpl(configuration: EnvironmentConfigurationImpl())`) and shared through `dependencies.apiClient`. Factories never create their own client.
- `@unchecked Sendable` — safe because all properties are `let` and `URLSession` is thread-safe
- Without an injected `session`, it builds one with `URLSessionFactory.makeSession(configuration:)` (see Security below), which waits for connectivity and applies SSL pinning when the environment enables it
- Requests go through an `InterceptorChain` (default: `[RetryInterceptor()]`)
- It invalidates only a session it created (`finishTasksAndInvalidate()` in `deinit`, which also releases the pinning delegate). An injected session belongs to the caller and may be shared, so the client never invalidates it

### Error Translation in APIClientImpl

| Failure | Thrown as |
|---------|-----------|
| Non-2xx status | `APIError.httpError(statusCode:data:)` |
| `DecodingError` while decoding `T` | `APIError.decodingError` |
| `URLError.cancelled` **and** `Task.isCancelled` | `CancellationError` |
| Any other `URLError` (including `.cancelled` without task cancellation, e.g. a rejected authentication challenge) | `APIError.networkError` |
| `CancellationError` | rethrown unchanged |
| Anything else | `APIError.unknown(SendableError)` |

Requiring `Task.isCancelled` keeps real failures that URLSession reports as `.cancelled` visible instead of silently restoring the previous screen state.

---

## Endpoint (Internal APIs)

`Endpoint` is a **struct** (not a protocol) that represents an internal API endpoint. The base URL and API version come from `EnvironmentConfiguration`.

```swift
// Core/Networking/Endpoint.swift

struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let queryParameters: [String: String]?
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
let endpoint = Endpoint.get(path: "/articles", queryParameters: ["page": "1", "limit": "20"])

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
                .timedOut, .networkConnectionLost,
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

`APIError` never leaves the Data layer. Every `RepositoryImpl` wraps its work in `try await DomainError.catching { ... }` (`Data/Common/DomainErrorMapping.swift`), which rethrows `CancellationError` unchanged and maps everything else with `DomainError.map(_:)`:

| Error | `DomainError` |
|-------|---------------|
| `APIError.networkError`, `APIError.invalidURL` | `.network` |
| `APIError.httpError` 401 | `.unauthorized` |
| `APIError.httpError` 404 | `.notFound` |
| `APIError.httpError` (other status) | `.server` |
| `APIError.decodingError` or a raw `DecodingError` | `.parsing` |
| `APIError.unknown` or any other error | `.unknown` |
| An existing `DomainError` | unchanged |

```swift
// MARK: - ArticleRepositoryImpl

struct ArticleRepositoryImpl: ArticleRepository {
    // MARK: - Public Methods

    func fetchArticles() async throws -> [ArticleModel] {
        try await DomainError.catching {
            let dtos = try await remoteDataSource.fetchArticles()
            return mapper.map(dtos)
        }
    }
}
```

UseCases don't catch or map; the ViewModel turns the `DomainError` into an `ErrorDecorator` with `ErrorDecorator.from(_:)`. Need the server's message (`apiError.serverError?.message`) in the UI? Add a case to `DomainError` and map it in `DomainErrorMapping`, rather than exposing `APIError`.

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

Implements retry logic with exponential backoff. Only retries transient errors, and only on requests that are
safe to resend: an idempotent method (GET, HEAD, PUT, DELETE, OPTIONS, TRACE) or any request carrying a
non-empty `Idempotency-Key` header. POST and PATCH without that header are sent once, because a lost response
or a 5xx after the server applied them would otherwise duplicate the side effect. Cancellation is checked first.

```swift
struct RetryInterceptor: RequestInterceptor {
    init(policy: RetryPolicy = .default)
}
```

Features:
- Retries on 5xx HTTP errors and 429 (rate limiting)
- Retries on transient URLError codes (timeout, connection lost, DNS failure, etc.) while the retry still starts within the time budget. With the default 30 s budget and 30 s request timeout, a timed-out request is reported, not retried
- Does not retry `notConnectedToInternet`: the session already waits for connectivity, and a retry seconds later fails the same way
- Honors `Retry-After` on a 429 or 5xx, as delay-seconds or as an HTTP date, in place of its backoff. A wait longer than `maxDelay`, or one that would end after `maxElapsedTime`, returns the response as is
- Starts no retry after the policy's `maxElapsedTime`
- Respects cancellation — checks it before the first attempt and never retries a `CancellationError`
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
    let maxElapsedTime: TimeInterval

    func delay(for attempt: Int) -> TimeInterval
    func shouldRetry(attempt: Int) -> Bool
    func fitsTimeBudget(elapsed: TimeInterval, delay: TimeInterval) -> Bool
}
```

`maxElapsedTime` is a time budget measured from the first attempt: no retry starts after it. It bounds when the last attempt can start, not how long that attempt runs, so the worst case is the budget plus one resource timeout (about 90 s with the defaults).

### Preset Policies

| Policy | Max Retries | Base Delay | Max Delay | Time Budget | Use Case |
|--------|-------------|------------|-----------|-------------|----------|
| `.default` | 3 | 1.0s | 30.0s | 30s | Standard requests |
| `.none` | 0 | 0 | 0 | 0 | No retries |
| `.aggressive` | 5 | 2.0s | 60.0s | 120s | Critical operations |
| `.quick` | 2 | 0.5s | 5.0s | 10s | Fast operations |

---

## Network Connectivity

### NetworkMonitor

```swift
// Core/Networking/NetworkMonitor.swift

@MainActor
protocol NetworkMonitor {
    var isConnected: Bool { get }
    var isExpensive: Bool { get }
    var isConstrained: Bool { get }
    var connectionType: ConnectionType { get }
}

nonisolated enum ConnectionType: String, Sendable {
    case wifi, cellular, wiredEthernet, loopback, other, none
}
```

`NetworkMonitorImpl` is a `@MainActor @Observable final class` that uses `NWPathMonitor` and publishes updates on the main actor for SwiftUI. It reports no connection until the first path update arrives. It is not part of `AppDependencies` by default; inject it where you need it.

Use it to show connectivity in the UI, never to decide whether to send a request (see "DON'T: Pre-flight Connectivity Checks").

---

## Security: SSL Pinning

### URLSessionFactory

```swift
// Core/Networking/Security/URLSessionFactory.swift

enum URLSessionFactory {
    static func makeSession(configuration: EnvironmentConfiguration) -> URLSession
}
```

- `waitsForConnectivity = true`: an offline request waits for a connection instead of failing at once. `resourceTimeout` (60 s by default) bounds the wait.
- Low Data Mode is allowed. Mark only non-essential requests with `request.allowsConstrainedNetworkAccess = false`.
- `SSL_PINNING_ENABLED = YES` installs `SSLPinningDelegate` for the `baseURL` host. Without valid hashes (none, the generated placeholder, or a pin cut short by an xcconfig `//` comment) connections to the API host are rejected (fail closed), a fault is logged, and debug builds assert.

### SSLPinningDelegate

Only the API host (`baseURL`) is pinned. After the system validates the certificate chain, the connection is accepted only if the SHA-256 of the SubjectPublicKeyInfo of a certificate in the chain matches a pin. Other hosts reached through the same session (any external `APIEndpoint`) and challenges other than server trust get the system's default handling. To pin an external host too, pass its host and pins to `SSLPinningDelegate` in `URLSessionFactory`. Supported keys: RSA of any size or exponent, and EC P-256/P-384/P-521.

Compute a pin (the scheme xcconfig shows the full command):

```bash
openssl s_client -connect api.example.com:443 -servername api.example.com 2>/dev/null | \
  openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
```

Set `SSL_PUBLIC_KEY_HASHES` to comma-separated `sha256/<base64>` values, writing any `//` inside a pin as `/$()/` because an xcconfig reads `//` as a comment. Pin the current key and a backup key (or an intermediate) so the certificate can rotate without an app update. The generated Production scheme enables pinning with a placeholder hash, so it rejects every connection until you replace it.

---

## Networking Checklist

### Architecture

- [ ] APIClient is protocol-based and injectable
- [ ] Internal endpoints use `Endpoint` struct with factory methods
- [ ] External endpoints use `APIEndpoint` protocol
- [ ] Errors are typed (`APIError`) and mapped between layers

### Error Handling

- [ ] All `APIError` cases handled in `DomainError.map` (`Data/Common/DomainErrorMapping.swift`)
- [ ] Repositories wrap their work in `DomainError.catching`; UseCases don't catch or map
- [ ] `CancellationError` propagated (not swallowed); only a cancelled `Task` turns `URLError.cancelled` into it
- [ ] Server error responses parsed via `APIErrorResponse`

### Interceptors

- [ ] Default chain includes retry
- [ ] Custom interceptors conform to `RequestInterceptor: Sendable`
- [ ] Auth token injection via interceptor (not in APIClient)

### Security

- [ ] Real pins, plus a backup pin, in the production xcconfig (`SSL_PINNING_ENABLED`, `SSL_PUBLIC_KEY_HASHES`)
- [ ] Sensitive headers redacted in logs

### Performance

- [ ] A dedicated `URLSession` (not `URLSession.shared`) owned by `APIClientImpl`
- [ ] `waitsForConnectivity` kept on the session (set by `URLSessionFactory`)
- [ ] Retry policy tuned per request type, including its time budget
- [ ] No connectivity check before sending a request
