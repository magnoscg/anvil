# Networking

The async HTTP layer of a generated project: one `APIClient` over `URLSession`, typed errors that stop in Data, retries behind an idempotency gate, and SSL pinning configured from xcconfig.

Code lives in `Core/Networking/` (client, endpoints, errors, interceptors, `Security/`) and `App/Config/` (environment). Feature code touches only `APIClient`, `Endpoint` or `APIEndpoint`, and `DomainError`.

## Two endpoint types, one client

| Type | Use it for | Base URL |
|------|------------|----------|
| `Endpoint` (struct) | The app's own backend | `EnvironmentConfiguration.baseURL` + `/<apiVersion>` + `path` |
| `APIEndpoint` (protocol) | Third-party APIs | Declared by the conforming type |

```swift
protocol APIClient: Sendable {
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
    func request<T: Decodable & Sendable>(_ endpoint: some APIEndpoint) async throws -> T
}
```

- Two types because the backend's host and version change per scheme, so they must not be written at call sites, while a third-party host is fixed and belongs next to its paths.
- Only a RemoteDataSource calls `APIClient`. Repositories, UseCases and ViewModels never see it.
- `T` is inferred from the call site, so DTOs are `Decodable & Sendable`.

## `APIClientImpl`: one client, one owned session

```swift
final class APIClientImpl: APIClient, @unchecked Sendable {
    init(configuration: EnvironmentConfiguration,
         session: URLSession? = nil,
         decoder: JSONDecoder = JSONDecoder(),
         interceptors: [any RequestInterceptor]? = nil)
}
```

- **One instance per app.** The throwing init of `AppDependencies` builds `EnvironmentConfigurationImpl()` and `APIClientImpl(configuration:)`; factories receive it as `dependencies.apiClient` and pass it down. A factory never creates its own client: each one would open another session and connection pool. `configuration` has no default value because building it can throw.
- **Session ownership.** With `session: nil` the client builds its own session with `URLSessionFactory.makeSession(configuration:)` and calls `finishTasksAndInvalidate()` on it in `deinit`: in-flight requests finish and the pinning delegate is released. An injected session belongs to the caller, may be shared, and is never invalidated by the client. Do not use `URLSession.shared`: it carries neither the pinning delegate nor the timeouts.
- **Interceptors.** `nil` means `APIClientImpl.defaultInterceptors()`, which is `[RetryInterceptor()]`. `minimalInterceptors()` is empty. A custom array replaces the default, so include `RetryInterceptor()` in it if you still want retries.
- **Decoder.** One `JSONDecoder` instance serves every request. Set its strategies before injecting it and never mutate it afterwards.
- **`@unchecked Sendable`.** The invariant: all five stored properties (`session`, `ownsSession`, `decoder`, `interceptorChain`, `configuration`) are `let` constants of `Sendable` types, and the class has no mutable state. `URLSession` is thread-safe; the decoder is safe only while nobody reconfigures it. Adding a `var` breaks the invariant: put that state in an actor instead. `SSLPinningDelegate` relies on the same invariant and documents it in its file. See `swift-concurrency.md` for when `@unchecked Sendable` is acceptable.

## Configuration

```swift
protocol EnvironmentConfiguration: Sendable {
    var environment: AppEnvironment { get }
    var baseURL: URL { get }
    var apiVersion: String { get }
    var requestTimeout: TimeInterval { get }
    var resourceTimeout: TimeInterval { get }
    var sslPinningEnabled: Bool { get }
    var sslPublicKeyHashes: [String] { get }
}
```

- `EnvironmentConfigurationImpl()` reads `Info.plist`, which the scheme xcconfig fills at build time: `API_BASE_URL` (required; the init throws `EnvironmentConfigurationError.missingBaseURL` or `.invalidBaseURL`), `API_VERSION` (default `v1`), `REQUEST_TIMEOUT` (default 30 s), `SSL_PINNING_ENABLED` and `SSL_PUBLIC_KEY_HASHES`. `resourceTimeout` is fixed at 60 s.
- `AppEnvironment` has one case per scheme and reads `APP_ENVIRONMENT`.
- A second init takes every value explicitly, for tests and previews.
- A new setting needs three edits: the xcconfig key, the `Info.plist` entry and the property here. Everything in `Info.plist` ships readable in the bundle, so it holds no secrets (see `security-privacy.md`).

## Endpoints

### `Endpoint` (own backend)

Properties: `path`, `method`, `queryParameters: [String: String]?`, `headers`, `body: Data?`, and `contentType` (default `.json`). `path` starts with `/`; the client prepends `/<apiVersion>`. Build endpoints with the static factories:

```swift
Endpoint.get(path: "/articles", queryParameters: ["page": "1"])
try Endpoint.post(path: "/articles", body: articleDTO)
try Endpoint.put(path: "/articles/\(id)", body: articleDTO)
Endpoint.delete(path: "/articles/\(id)")
try Endpoint.withBody(path: "/articles/\(id)", method: .patch, body: patchDTO)
```

- `post`, `put` and `withBody` encode the body as JSON (the `encoder:` parameter replaces the default `JSONEncoder`) and throw when encoding fails. `withBody` is how you send PATCH, or any other method with a body.
- The factories take no headers and always send JSON. Custom headers or another `ContentType` (`formURLEncoded`, `multipartFormData`, `textPlain`) go through the memberwise init with a ready-made `body`.

### `APIEndpoint` (third-party API)

Required: `baseURL` and `path`. An extension supplies `method` (`.get`), `queryParameters` (`nil`), `headers` (`nil`), `body` (`nil`), `contentType` (`.json`) and `buildRequest()`. Write one type per external API, with a static factory per call:

```swift
struct NewsAPIEndpoint: APIEndpoint {
    // swiftlint:disable:next force_unwrapping
    private static let host = URL(string: "https://news.example.com/v2")!

    var baseURL: URL { Self.host }
    let path: String
    let queryParameters: [String: any CustomStringConvertible & Sendable]?

    static func articles(limit: Int, offset: Int) -> NewsAPIEndpoint {
        NewsAPIEndpoint(path: "/articles", queryParameters: ["limit": limit, "offset": offset])
    }
}
```

The generated SwiftLint configuration opts in to `force_unwrapping`, hence the directive on the literal URL.

### In a RemoteDataSource

```swift
struct ArticleRemoteDataSourceImpl: ArticleRemoteDataSource {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetch() async throws -> [ArticleDTO] {
        try await apiClient.request(Endpoint.get(path: "/articles"))
    }
}
```

`anvil feature` generates this type in `Data/Article/DataSources/` with a `fatalError` placeholder in `fetch()`: replace it with the real endpoint. A DataSource returns DTOs and lets errors through untouched.

## Errors

### What `APIClientImpl` throws

| Failure | Thrown as |
|---------|-----------|
| The endpoint cannot build a URL | `APIError.invalidURL` |
| Status outside 200...299 | `APIError.httpError(statusCode:data:)` |
| `DecodingError` while decoding `T` | `APIError.decodingError` |
| `URLError.cancelled` while `Task.isCancelled` | `CancellationError` |
| Any other `URLError`, including `.cancelled` without task cancellation | `APIError.networkError` |
| `CancellationError` | rethrown unchanged |
| A response that is not HTTP, or anything else | `APIError.unknown(SendableError)` |

`Task.isCancelled` is required because URLSession also reports `.cancelled` when the pinning delegate rejects a challenge. Treating that as cancellation would restore the previous screen state silently instead of showing an error.

`APIError` has exactly those five cases. `isRetryable` is true for 5xx, 429 and five transient `URLError` codes: `timedOut`, `networkConnectionLost`, `cannotFindHost`, `cannotConnectToHost` and `dnsLookupFailed`. `serverError` decodes the body of an `httpError` into `APIErrorResponse` (`message`, `code`, `details`, `errors`), accepting the common alternative keys (`error`, `error_message`, `error_code`, `error_description`), and returns `nil` when the body has another shape.

### `APIError` stops in Data

Every `RepositoryImpl` wraps its work in `DomainError.catching { }` (`Data/Common/DomainErrorMapping.swift`). It rethrows `CancellationError`, turns any failure that arrives after the task was cancelled into `CancellationError`, and maps everything else with `DomainError.map(_:)`:

| Error | `DomainError` |
|-------|---------------|
| `APIError.networkError`, `APIError.invalidURL` | `.network` |
| `APIError.httpError` 401 | `.unauthorized` |
| `APIError.httpError` 404 | `.notFound` |
| `APIError.httpError`, any other status | `.server` |
| `APIError.decodingError`, or a raw `DecodingError` | `.parsing` |
| `APIError.unknown`, or any other error | `.unknown` |
| A `DomainError` | unchanged |

```swift
struct ArticleRepositoryImpl: ArticleRepository {
    func fetch() async throws -> [ArticleModel] {
        try await DomainError.catching {
            let dtos = try await remoteDataSource.fetch()
            return mapper.map(dtos)
        }
    }
}
```

- The mapping lives in Data so that Domain never depends on `APIError` or any other infrastructure type.
- UseCases do not catch or map. The ViewModel catches `DomainError` and builds the screen error with `ErrorDecorator.from(_:)` (see `ARCHITECTURE.md`). No layer above Data writes `catch let error as APIError`.
- Never swallow `CancellationError` or turn it into a `DomainError`: the ViewModel restores its previous state on cancellation.
- Does the UI need the server's message or another status? Add a case to `DomainError` and map it in `DomainErrorMapping.swift`. Do not expose `APIError`.

## Interceptors

```swift
protocol RequestInterceptor: Sendable {
    func intercept(
        request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse)
}
```

`InterceptorChain` wraps the session call: the first interceptor in the array is the outermost and the last one calls the network. An interceptor can change the request, inspect the response or call `next` more than once. It sees raw responses, because the status check and the decoding run after the chain, in the client. Write interceptors as structs with immutable state.

### `RetryInterceptor`

The only interceptor the generator ships. It applies these rules in order:

1. **Cancellation first.** It checks for cancellation before the first attempt and never retries a `CancellationError`.
2. **Idempotency gate.** It retries only a request that is safe to resend: GET, HEAD, PUT, DELETE, OPTIONS or TRACE, or any method that carries a non-empty `Idempotency-Key` header. A POST or PATCH without the header is sent once, because a lost response or a 5xx after the server applied the change would duplicate the side effect. To make a POST retryable, send a key the server deduplicates on, using the memberwise `Endpoint` init (`headers: ["Idempotency-Key": key]`).
3. **What it retries.** A response with status 5xx or 429, and the five transient `URLError` codes listed under "Errors". It is an allow-list: every other failure is returned or thrown at once. That covers `notConnectedToInternet` and the other device-state codes, because the session already waits for connectivity and a retry seconds later would fail the same way.
4. **`Retry-After`.** On a retryable response, a `Retry-After` header (delay-seconds or an HTTP date) replaces the backoff. If it asks for more than `maxDelay`, or the wait would end after the time budget, the response is returned as is.
5. **Budget.** No retry starts once `maxRetries` is used up, or when its wait would end after `maxElapsedTime`. When retries run out on a 5xx or 429, the last response comes back and the client throws `httpError`.

### `RetryPolicy`

`delay(for:)` is `baseDelay * 2^attempt`, capped at `maxDelay`, plus or minus up to `jitterFactor` of that value. `maxElapsedTime` counts from the first attempt and bounds when the last attempt may start, not how long it runs: the worst case is the budget plus one resource timeout, about 90 s with the defaults. With the default 30 s budget and 30 s request timeout, a request that times out is reported, not retried.

| Policy | Max retries | Base delay | Max delay | Jitter | Time budget | Use |
|--------|-------------|------------|-----------|--------|-------------|-----|
| `.default` | 3 | 1 s | 30 s | 0.3 | 30 s | Standard requests |
| `.quick` | 2 | 0.5 s | 5 s | 0.2 | 10 s | Fast operations |
| `.aggressive` | 5 | 2 s | 60 s | 0.25 | 120 s | Critical operations |
| `.none` | 0 | 0 | 0 | 0 | 0 | No retries |

The policy is a property of the interceptor, so it is set per client, not per request: `interceptors: [RetryInterceptor(policy: .quick)]`.

### Authentication (add your own)

The generator ships no authentication: no token provider and no auth interceptor. When the API needs a token:

- Write a `RequestInterceptor` that sets the `Authorization` header and pass it in `interceptors:` together with `RetryInterceptor()`.
- The token comes from a Data-layer source backed by the Keychain (see `security-privacy.md`), never from a ViewModel.
- `Endpoint` carries no auth flag, and an interceptor receives only the `URLRequest`. If some endpoints must go out without a token, let the interceptor decide by path; never invent a marker header, because it travels to the server.
- A 401 already maps to `DomainError.unauthorized`. The ViewModel and its Router decide the navigation; a UseCase or Repository never navigates.

## Connectivity

- **No pre-flight check.** Do not test connectivity before sending: the answer can be stale by the time the request runs, and the session already waits for a connection. Send the request and handle `DomainError.network`.
- **`NetworkMonitor` is for the UI only.** It is a `@MainActor` protocol with `isConnected`, `isExpensive`, `isConstrained` and `connectionType`. `NetworkMonitorImpl` is `@MainActor @Observable` over `NWPathMonitor`. It reports no connection until the first path update arrives, so the initial `false` does not mean offline. It is not part of `AppDependencies`: create it where the UI needs it and inject it.

## Session and SSL pinning

`URLSessionFactory.makeSession(configuration:)` builds the session the client owns:

- `timeoutIntervalForRequest` is `requestTimeout` (30 s) and `timeoutIntervalForResource` is `resourceTimeout` (60 s).
- `waitsForConnectivity = true`: an offline request waits for a connection instead of failing at once, and the resource timeout bounds the wait.
- Low Data Mode stays allowed. Mark only non-essential requests (prefetching, large media) with `request.allowsConstrainedNetworkAccess = false`. Set on the session, it would hold every request in Low Data Mode until the timeout.
- `SSL_PINNING_ENABLED = YES` installs `SSLPinningDelegate` for the host of `baseURL`. If the pin list is empty or any pin is malformed (the generated placeholder, or a pin cut short by an xcconfig `//`), it logs a fault and debug builds assert. With no well-formed pin, every connection to the API host is rejected: a misconfigured build fails closed instead of shipping without pinning.

### Pinning rules

- **What is pinned.** Only the API host. Other hosts reached through the same session (any `APIEndpoint`) and challenges other than server trust get the system's default handling. To pin a third-party host too, add its host and pins to the `SSLPinningDelegate` created in `URLSessionFactory`.
- **What a pin is.** `sha256/<base64>`, the SHA-256 of a certificate's SubjectPublicKeyInfo. The system validates the chain first; the connection is then accepted if any certificate in the chain matches a pin. `SecKeyCopyExternalRepresentation` returns only the raw key, so the delegate rebuilds the DER SubjectPublicKeyInfo around it to match what `openssl` hashes. Supported keys: RSA of any size and EC P-256, P-384 and P-521. Any other key type yields no pin and never matches.
- **Where pins live.** `SSL_PUBLIC_KEY_HASHES` in the scheme xcconfig, comma-separated. An xcconfig reads `//` as the start of a comment even inside a value: write any `//` in a pin as `/$()/`, as `API_BASE_URL` does. Pins are hashes of public keys, not secrets.
- **Rotation.** Pin the current key and a backup key (or an intermediate), so the certificate can rotate without an app update.
- **Generated defaults.** The last scheme is the production one. It is generated with pinning on and a placeholder pin, so it rejects every API connection until you set real pins. The other schemes have pinning off.
- **How a mismatch surfaces.** As `APIError.networkError` with `URLError.cancelled`, which maps to `DomainError.network`.

Compute a pin (each scheme xcconfig carries the same command):

```bash
openssl s_client -connect api.example.com:443 -servername api.example.com 2>/dev/null | \
  openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
```

ATS rules are in `security-privacy.md`.

Deeper reference (Axiom plugin, if installed): `axiom-networking` (`skills/networking-discipline.md`, `skills/networking-diag.md`, `skills/network-framework-ref.md`) for URLSession with structured concurrency, why a reachability check before a request races, recycling the session when the app returns to the foreground, `taskIsWaitingForConnectivity` for a "waiting for network" state, ATS failures and public-key pinning; the `networking-auditor` agent scans for deprecated APIs and anti-patterns.
