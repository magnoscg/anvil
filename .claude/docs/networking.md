# Networking Guide

> Modern async/await networking patterns with URLSession.
> Related skills: `/axiom:audit networking`, `axiom:axiom-ios-networking`, `axiom:axiom-codable`
> Axiom complementa: Network.framework, NWConnection, network diagnostics

## Overview

This guide covers the async networking layer: dual-endpoint system, interceptor chain, error handling, retry policies, SSL pinning, and connectivity monitoring.

---

## Architecture Overview

The networking layer uses a **dual-endpoint system**:

| Endpoint Type | Use Case | Base URL Source |
|---------------|----------|----------------|
| `Endpoint` (struct) | Internal APIs | `EnvironmentConfiguration` (Info.plist → xcconfig) |
| `APIEndpoint` (protocol) | External APIs (PokeAPI, GitHub, etc.) | Embedded in the endpoint itself |

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
    // MARK: - Properties

    private let session: URLSession
    private let ownsSession: Bool
    private let configuration: EnvironmentConfiguration
    private let decoderFactory: @Sendable () -> JSONDecoder
    private let interceptorChain: DefaultInterceptorChain

    // MARK: - Init

    init(configuration: EnvironmentConfiguration,
         session: URLSession? = nil,
         decoderFactory: @escaping @Sendable () -> JSONDecoder = { JSONDecoder() },
         interceptorChain: DefaultInterceptorChain = DefaultInterceptorChain()) {
        self.configuration = configuration
        if let session {
            self.session = session
            ownsSession = false
        } else {
            self.session = URLSessionFactory.makeSession(configuration: configuration)
            ownsSession = true
        }
        self.decoderFactory = decoderFactory
        self.interceptorChain = interceptorChain
    }

    // MARK: - Deinit

    deinit {
        if ownsSession {
            session.finishTasksAndInvalidate()
        }
    }
}
```

**Key design decisions:**
- `@unchecked Sendable` — safe because all properties are `let`, `URLSession` is thread-safe, and `decoderFactory` creates a new decoder per request
- `configuration` has no default: `AppDependencies` creates `EnvironmentConfigurationImpl()` (which `throws`) and injects it. Features never create an `APIClientImpl`; they get the shared one from `AppDependencies.apiClient`
- Session created via `URLSessionFactory` which configures SSL pinning based on environment
- Interceptors: `DefaultInterceptorChain` holds `LoggingInterceptor` + `RetryInterceptor` as typed properties (no `any RequestInterceptor` array on the hot path)
- The client invalidates only a session it created (`finishTasksAndInvalidate()` in `deinit`, which also releases the pinning delegate). An injected session belongs to the caller and may be shared, so the client never invalidates it

### Error and Cancellation Handling in `performRequest`

- Non-2xx status → `APIError.httpError(statusCode:data:)`.
- Decoding failure → `APIError.decodingError(DecodingError)`.
- `URLError` with code `.cancelled` → `CancellationError` (so cancellation keeps propagating); any other `URLError` → `APIError.networkError`.
- Anything else → `APIError.unknown(SendableError(error))`.

### Interceptor Chain Configuration

```swift
DefaultInterceptorChain()
DefaultInterceptorChain(logging: LoggingInterceptor(level: .verbose),
                        retry: RetryInterceptor(policy: .none))
```

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
let endpoint = try Endpoint.post(path: "/articles", body: featureDTO)

// PUT with Encodable body
let endpoint = try Endpoint.put(path: "/articles/\(id)", body: updatedDTO)

// DELETE
let endpoint = Endpoint.delete(path: "/articles/\(id)")

// Custom: body with specific method
let endpoint = try Endpoint.withBody(path: "/custom", method: .patch, body: patchDTO)
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

### Example: PokeAPI

```swift
// Core/Networking/PokeAPI/PokeAPIEndpoint.swift

struct PokeAPIEndpoint: APIEndpoint, Sendable {
    private static let pokeAPIBaseURL = URL(string: "https://pokeapi.co/api/v2")!

    var baseURL: URL { Self.pokeAPIBaseURL }
    let path: String
    let queryParameters: [String: any CustomStringConvertible & Sendable]?

    private init(path: String,
                 queryParameters: [String: any CustomStringConvertible & Sendable]? = nil) {
        self.path = path
        self.queryParameters = queryParameters
    }
}

// Factory methods
extension PokeAPIEndpoint {
    static func pokemonList(limit: Int, offset: Int) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon",
                        queryParameters: ["limit": limit, "offset": offset])
    }

    static func pokemonDetail(id: Int) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon/\(id)")
    }

    static func pokemonDetail(name: String) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon/\(name.lowercased())")
    }
}
```

### Usage in DataSource

```swift
struct PokemonListRemoteDataSourceImpl: PokemonListRemoteDataSource {
    private let apiClient: APIClient

    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponseDTO {
        let endpoint = PokeAPIEndpoint.pokemonList(limit: limit, offset: offset)
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

    // Attempts multiple common JSON keys: "message"/"error"/"error_message",
    // "code"/"error_code", "details"/"error_description"

    static func decode(from data: Data?) -> APIErrorResponse?
}

// Access from APIError:
extension APIError {
    var serverError: APIErrorResponse? {
        guard case let .httpError(_, data) = self else { return nil }
        return APIErrorResponse.decode(from: data)
    }
}
```

### Error Mapping to Domain

DataSources throw `APIError`. The translation to the shared `DomainError` happens once, in the Data layer (`Data/Common/DomainError+Mapping.swift`), and repositories apply it with `DomainError.catching`. Domain never sees `APIError`, and features don't define their own error enums.

| `APIError` | `DomainError` |
|------------|---------------|
| `.networkError`, `.invalidURL` | `.network` |
| `.httpError` with status 404 | `.notFound` |
| `.httpError` with any other status | `.server` |
| `.decodingError` (and a raw `DecodingError`) | `.parsing` |
| `.unknown` (and any other error) | `.unknown` |

```swift
// Data/<Concept>/Repositories/<Feature>RepositoryImpl.swift
func fetchFeatures() async throws -> [FeatureModel] {
    try await DomainError.catching {
        let dtos = try await remoteDataSource.fetchFeatures()
        return dtos.map { dtoMapper.mapToDomain($0) }
    }
}
```

`CancellationError` passes through `DomainError.catching` unchanged. See `ARCHITECTURE.md` → Error Handling Between Layers.

### DON'T: Pre-flight Connectivity Checks

```swift
// WRONG: Checking connectivity before request
if networkMonitor.isConnected {
    let data = try await apiClient.request(endpoint)
}

// RIGHT: Just make the request, handle errors
do {
    let data: FeatureDTO = try await apiClient.request(endpoint)
} catch let error as APIError where error.isRetryable {
    // Show retry UI
} catch {
    // Show error
}
```

---

## Interceptor Chain

Requests pass through a chain of `RequestInterceptor`s before reaching the network. Each interceptor can modify the request, the response, or add cross-cutting behavior.

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

### InterceptorChain

```swift
nonisolated struct InterceptorChain: Sendable {
    typealias Executor = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    private let interceptors: [any RequestInterceptor]
    private let coreExecutor: Executor

    func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Builds chain from inside out: last interceptor wraps core, first is outermost
        let chain = interceptors.reversed().reduce(coreExecutor) { next, interceptor in
            { request in try await interceptor.intercept(request: request, next: next) }
        }
        return try await chain(request)
    }
}
```

### Built-in Interceptors

#### LoggingInterceptor

Logs requests/responses with configurable verbosity. Only active in DEBUG builds by default.

```swift
nonisolated struct LoggingInterceptor: RequestInterceptor {
    enum LogLevel: Int, Sendable, Comparable {
        case none = 0      // No logging
        case minimal = 1   // Method + URL + status code
        case standard = 2  // + headers summary + duration + size
        case verbose = 3   // + full headers + body preview
    }

    init(level: LogLevel? = nil)  // Default: .standard in DEBUG, .none in release
}
```

Features:
- Request ID tracking for correlating request/response logs
- Duration measurement
- Sensitive header redaction (Authorization, API keys, cookies)
- Body truncation in verbose mode

#### RetryInterceptor

Implements retry logic with exponential backoff. Only retries transient errors, and only on requests that are
safe to resend: an idempotent method (GET, HEAD, PUT, DELETE, OPTIONS, TRACE) or any request carrying a
non-empty `Idempotency-Key` header. POST and PATCH without that header are sent once, because a lost response
or a 5xx after the server applied them would otherwise duplicate the side effect. Cancellation is checked first.

```swift
nonisolated struct RetryInterceptor: RequestInterceptor {
    init(policy: RetryPolicy = .default)
}
```

Features:
- Retries on 5xx HTTP errors and 429 (rate limiting)
- Retries on transient URLError codes (timeout, connection lost, DNS failure, etc.) while the retry still starts
  within the time budget. With the default 30 s budget and 30 s request timeout, a timed-out request is reported,
  not retried
- Does not retry errors that describe the device state (`notConnectedToInternet`, `dataNotAllowed`,
  `internationalRoamingOff`, `callIsActive`): the session already waits for connectivity, and a retry seconds later
  fails the same way
- Honors `Retry-After` on a 429 or 5xx, as delay-seconds or as an HTTP date, in place of its backoff. A wait
  longer than `maxDelay`, or one that would end after `maxElapsedTime`, returns the response as is
- Starts no retry after the policy's `maxElapsedTime`
- Respects `CancellationError` — never retries cancellation
- Uses `RetryPolicy` for backoff configuration

#### PassthroughInterceptor

No-op interceptor for testing.

### Custom Interceptor Example (Auth)

Interceptors in `Core/Networking/` are `nonisolated struct`s (the target uses default MainActor isolation). `APIClientImpl` runs a `DefaultInterceptorChain`, which holds exactly `LoggingInterceptor` + `RetryInterceptor`; adding a custom interceptor means adding it to `DefaultInterceptorChain` (or using the generic `InterceptorChain`).

```swift
nonisolated struct AuthInterceptor: RequestInterceptor {
    let tokenProvider: TokenProvider

    func intercept(
        request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        var modifiedRequest = request
        if let token = try await tokenProvider.validToken() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await next(modifiedRequest)
    }
}
```

### Token Refresh & Expiry

When the server returns `401 Unauthorized`, the interceptor should attempt token refresh before failing. `Example/` has no auth; this is a pattern to adopt. `APIError` has no `unauthorized` case, so a missing token is reported as a 401 `httpError`:

```swift
nonisolated struct AuthInterceptor: RequestInterceptor {
    // MARK: - Properties

    private let tokenProvider: TokenProvider

    // MARK: - RequestInterceptor

    func intercept(request: URLRequest,
                   next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) async throws
        -> (Data, HTTPURLResponse) {
        guard let token = try await tokenProvider.validToken() else {
            throw APIError.httpError(statusCode: 401, data: nil)
        }
        var authorizedRequest = request
        authorizedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await next(authorizedRequest)
    }
}

protocol TokenProvider: Sendable {
    /// Returns a valid token, refreshing if expired
    func validToken() async throws -> String?
    /// Clears all tokens (logout)
    func clearTokens() async
}
```

For Keychain storage of tokens, see `security-privacy.md` → Keychain section.

### Logout Flow

```swift
// In UseCase or ViewModel
func logout() async {
    await tokenProvider.clearTokens()
    // Navigate to login via Router
    router.navigateToLogin()
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
    let jitterFactor: Double  // 0.0 to 1.0
    let maxElapsedTime: TimeInterval

    func delay(for attempt: Int) -> TimeInterval   // Exponential backoff + jitter
    func shouldRetry(attempt: Int) -> Bool
    func fitsTimeBudget(elapsed: TimeInterval, delay: TimeInterval) -> Bool
}
```

`maxElapsedTime` is a time budget measured from the first attempt: no retry starts after it. It bounds when the last
attempt can start, not how long that attempt runs, so the worst case is the budget plus one resource timeout
(about 90 s with the defaults) instead of four full timeouts plus backoff.

### Preset Policies

| Policy | Max Retries | Base Delay | Max Delay | Jitter | Time Budget | Use Case |
|--------|-------------|------------|-----------|--------|-------------|----------|
| `.default` | 3 | 1.0s | 30.0s | 0.3 | 30s | Standard requests |
| `.none` | 0 | 0 | 0 | 0 | 0 | No retries |
| `.aggressive` | 5 | 2.0s | 60.0s | 0.25 | 120s | Critical operations |
| `.quick` | 2 | 0.5s | 5.0s | 0.2 | 10s | Fast operations |

---

## Network Connectivity

### NetworkMonitor

```swift
// Core/Networking/NetworkMonitor.swift

protocol NetworkMonitor: Sendable {
    var isConnected: Bool { get }
    var isExpensive: Bool { get }       // Cellular, hotspot
    var isConstrained: Bool { get }     // Low Data Mode
    var connectionType: ConnectionType { get }
}

nonisolated enum ConnectionType: String, Sendable {
    case wifi, cellular, wiredEthernet, loopback, other, none
}
```

`NetworkMonitorImpl` uses `NWPathMonitor` and is `@Observable` for SwiftUI integration. It reports no connection
until the first path update arrives. Use it to show connectivity in the UI, never to decide whether to send a
request: the session waits for connectivity, and a check made before the request can be stale when it runs.

---

## Security: SSL Pinning

### URLSessionFactory

Creates the app's `URLSession`. `APIClientImpl` calls it when no session is injected and owns the result.

```swift
// Core/Networking/Security/URLSessionFactory.swift

enum URLSessionFactory {
    static func makeSession(configuration: EnvironmentConfiguration) -> URLSession
}
```

Behavior:
- `waitsForConnectivity = true`: an offline request waits for a connection instead of failing at once. The
  resource timeout (twice `requestTimeout`) bounds the wait.
- Low Data Mode is allowed. Mark only non-essential requests (prefetching, large media) with
  `request.allowsConstrainedNetworkAccess = false`. Set on the session, it would hold every request in Low Data
  Mode until it timed out, because the session waits for an unconstrained network that never comes.
- `SSL_PINNING_ENABLED = YES` installs `SSLPinningDelegate` for the `baseURL` host. Without valid hashes (none, a
  placeholder, or a pin cut short by an xcconfig `//` comment) connections to the API host are rejected (fail
  closed), a fault is logged, and debug builds assert. In an xcconfig, write any `//` inside a pin as `/$()/`.

### SSLPinningDelegate

Public key pinning for the API host (`baseURL`). After the system validates the certificate chain, the connection
is accepted only if the SHA-256 of the SubjectPublicKeyInfo of a certificate in the chain matches a pin. Other
hosts reached through the same session, such as PokeAPI or any external `APIEndpoint`, and challenges other than
server trust get the system's default handling.

```swift
// Core/Networking/Security/SSLPinningDelegate.swift

final class SSLPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    init(publicKeyHashes: [String], pinnedHosts: Set<String>, isEnabled: Bool = true)
    nonisolated func acceptsChain(withPins pins: [String]) -> Bool
    nonisolated static func publicKeyPins(in trust: SecTrust) -> [String]
    nonisolated static func publicKeyPin(for key: SecKey) -> String?
}
```

- `SecKeyCopyExternalRepresentation` returns only the raw key, so the delegate rebuilds the DER
  SubjectPublicKeyInfo around it before hashing. Supported keys: RSA of any size or exponent, and EC
  P-256/P-384/P-521.
- Compute a pin with the command in `Production.xcconfig`:
  `openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`.
- Pin the current key and a backup key (or an intermediate) so the certificate can rotate without an app update.

Configuration via xcconfig:
```
// Dev.xcconfig
SSL_PINNING_ENABLED = NO

// Prod.xcconfig
SSL_PINNING_ENABLED = YES
SSL_PUBLIC_KEY_HASHES = sha256/AAAA...,sha256/BBBB...
```

### EnvironmentConfiguration

```swift
protocol EnvironmentConfiguration: Sendable {
    var environment: AppEnvironment { get }
    var baseURL: URL { get }
    var apiVersion: String { get }
    var requestTimeout: TimeInterval { get }
    var sslPinningEnabled: Bool { get }
    var sslPublicKeyHashes: [String] { get }
}
```

`EnvironmentConfigurationImpl` reads all values from Info.plist (populated by xcconfig).

---

## Deprecated APIs to Avoid

| Deprecated | Replacement |
|------------|-------------|
| `SCNetworkReachability` | `NWPathMonitor` |
| `CFSocket` | `NWConnection` |
| `URLSession.dataTask` with completion | `URLSession.data(for:)` async |
| Synchronous network calls | Async/await |

---

## Networking Checklist

### Architecture

- [ ] APIClient is protocol-based and injectable
- [ ] Internal endpoints use `Endpoint` struct with factory methods
- [ ] External endpoints use `APIEndpoint` protocol
- [ ] Errors are typed (`APIError`) and mapped between layers

### Error Handling

- [ ] All `APIError` cases handled in `DomainError.map` (`Data/Common/DomainError+Mapping.swift`)
- [ ] Every repository that can fail wraps its work in `DomainError.catching`
- [ ] `CancellationError` propagated (not swallowed)
- [ ] Server error responses parsed via `APIErrorResponse`

### Interceptors

- [ ] Default chain includes logging + retry
- [ ] Custom interceptors conform to `RequestInterceptor: Sendable`
- [ ] Auth token injection via interceptor (not in APIClient)

### Security

- [ ] SSL pinning configured in production xcconfig, with a backup pin
- [ ] Public key hashes rotated before certificate expiry
- [ ] Sensitive headers redacted in logs

### Performance

- [ ] Using `URLSessionFactory` (not `URLSession.shared`) for proper lifecycle
- [ ] `waitsForConnectivity` enabled for resilience
- [ ] Retry policy tuned per request type, including its time budget
- [ ] No connectivity check before sending a request

### Run Audit

```bash
/axiom:audit networking
```

Checks for:
- Deprecated networking APIs
- Missing error handling
- Hardcoded URLs
- ATS violations
