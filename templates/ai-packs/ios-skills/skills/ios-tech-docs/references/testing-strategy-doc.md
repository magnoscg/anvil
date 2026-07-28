# Testing Strategy Documentation Template

Use this template when the user asks to document: testing strategy, test conventions, mocking, test pyramid, CI testing, or "how to write tests".

---

## Template Structure

```markdown
# [Project Name] - Testing Strategy

{toc}

## 1. Test Pyramid

```
         ┌─────────┐
         │ UI/E2E  │  ~5%   (slow, fragile, high confidence)
        ┌┴─────────┴┐
        │Integration │  ~15%  (medium speed, real dependencies)
       ┌┴────────────┴┐
       │  Unit Tests   │  ~80%  (fast, isolated, high volume)
       └──────────────┘
```

| Level | Framework | Speed | What It Tests |
|-------|----------|-------|--------------|
| Unit | Swift Testing | <1s per test | Business logic, ViewModels, mappers |
| Integration | XCTest | 1-5s per test | Repository + DataSource interaction |
| UI/E2E | XCUITest | 5-30s per test | Full user flows, accessibility |

## 2. What to Test by Layer

### Domain Layer (Use Cases)
| Component | What to Test | Priority |
|-----------|-------------|----------|
| UseCase | Business rules, input validation, edge cases | ✅ Always |
| Entity | Computed properties, Equatable/Hashable conformance | ✅ Always |
| Mapper | DTO → Entity mapping, nil handling, edge values | ✅ Always |

### Presentation Layer (ViewModels)
| Component | What to Test | Priority |
|-----------|-------------|----------|
| ViewModel | State changes after actions | ✅ Always |
| ViewModel | Loading/error/empty states | ✅ Always |
| ViewModel | Action sequencing (load → success/error) | ✅ Always |
| ViewModel | Derived/computed state | ⚠️ If complex |

### Data Layer (Repositories)
| Component | What to Test | Priority |
|-----------|-------------|----------|
| Repository | Data source coordination (cache + network) | ✅ Always |
| Repository | Offline fallback behavior | ✅ Always |
| DataSource mock | Correct API endpoint construction | ⚠️ If complex |
| DTO decoding | JSON → DTO with real API responses | ✅ Always |

### UI Layer (Views)
| Component | What to Test | Priority |
|-----------|-------------|----------|
| Critical flows | Login, purchase, onboarding | ✅ Always |
| Navigation | Tab switching, push/pop, deep links | ⚠️ Key flows |
| Accessibility | VoiceOver, Dynamic Type | ⚠️ Key screens |

## 3. Conventions

### 3.1 File Naming

| Source File | Test File | Location |
|------------|----------|----------|
| `LoginViewModel.swift` | `LoginViewModelTests.swift` | `Tests/UnitTests/Presentation/` |
| `LoginUseCase.swift` | `LoginUseCaseTests.swift` | `Tests/UnitTests/Domain/` |
| `AuthRepository.swift` | `AuthRepositoryTests.swift` | `Tests/IntegrationTests/` |
| Login flow | `LoginFlowUITests.swift` | `Tests/UITests/` |

### 3.2 Test Structure

Use **Given → When → Then** (Arrange → Act → Assert):

```swift
@Test("Login succeeds with valid credentials")
func loginSuccess() async throws {
    // Given
    let mockUseCase = MockLoginUseCase(result: .success(.mockUser))
    let viewModel = LoginViewModel(loginUseCase: mockUseCase)

    // When
    await viewModel.login(email: "test@example.com", password: "password")

    // Then
    #expect(viewModel.isLoading == false)
    #expect(viewModel.error == nil)
    #expect(viewModel.isAuthenticated == true)
}
```

### 3.3 Test Naming Convention

**Swift Testing (preferred):**
```swift
@Test("Description of what is being tested and expected outcome")
func descriptiveFunctionName() async throws { ... }
```

**XCTest (legacy):**
```swift
func test_methodName_givenCondition_expectedOutcome() { ... }
// Example: test_login_givenInvalidCredentials_showsError()
```

### 3.4 Test Organization with MARK

```swift
struct LoginViewModelTests {
    // MARK: - Subject & Dependencies
    let mockLoginUseCase = MockLoginUseCase()
    var sut: LoginViewModel { LoginViewModel(loginUseCase: mockLoginUseCase) }

    // MARK: - Login Success
    @Test("Login succeeds with valid credentials")
    func loginSuccess() async throws { ... }

    // MARK: - Login Failure
    @Test("Login shows error on invalid credentials")
    func loginInvalidCredentials() async throws { ... }

    // MARK: - Loading State
    @Test("Login shows loading state during request")
    func loginLoadingState() async throws { ... }

    // MARK: - Validation
    @Test("Login disables button when email is empty")
    func loginEmptyEmail() { ... }
}
```

## 4. Mocking Strategy

### 4.1 Protocol-Based Mocks

Every dependency is defined as a protocol. Mocks implement the protocol with configurable behavior:

```swift
// Protocol (in Domain layer)
protocol LoginUseCaseProtocol: Sendable {
    func execute(email: String, password: String) async throws -> User
}

// Mock (in Tests)
final class MockLoginUseCase: LoginUseCaseProtocol {
    var result: Result<User, LoginError> = .success(.mock)
    var executeCallCount = 0
    var lastEmail: String?

    func execute(email: String, password: String) async throws -> User {
        executeCallCount += 1
        lastEmail = email
        return try result.get()
    }
}
```

### 4.2 Mock Naming Convention

| Real Type | Mock Type | Location |
|-----------|----------|----------|
| `LoginUseCase` | `MockLoginUseCase` | `Tests/Mocks/Domain/` |
| `AuthRepository` | `MockAuthRepository` | `Tests/Mocks/Data/` |
| `APIClient` | `MockAPIClient` | `Tests/Mocks/Networking/` |

### 4.3 Test Fixtures

```swift
extension User {
    static var mock: User {
        User(id: UUID(), email: "test@example.com", displayName: "Test User", role: .standard)
    }

    static var admin: User {
        User(id: UUID(), email: "admin@example.com", displayName: "Admin User", role: .admin)
    }
}
```

### 4.4 Mock Folder Structure

```
Tests/
├── Mocks/
│   ├── Domain/
│   │   ├── MockLoginUseCase.swift
│   │   └── MockFetchProductsUseCase.swift
│   ├── Data/
│   │   ├── MockAuthRepository.swift
│   │   └── MockProductRepository.swift
│   └── Networking/
│       └── MockAPIClient.swift
├── Fixtures/
│   ├── User+Mock.swift
│   ├── Product+Mock.swift
│   └── JSON/
│       ├── login_success.json
│       └── login_error.json
├── UnitTests/
├── IntegrationTests/
└── UITests/
```

## 5. JSON Fixture Files

For testing API response decoding, store JSON fixtures:

```swift
// Load JSON fixture in tests
func loadJSON(_ filename: String) throws -> Data {
    let bundle = Bundle(for: type(of: self))
    let url = bundle.url(forResource: filename, withExtension: "json")!
    return try Data(contentsOf: url)
}

@Test("UserDTO decodes correctly from API response")
func userDTODecoding() throws {
    let json = try loadJSON("login_success")
    let dto = try JSONDecoder().decode(AuthResponse.self, from: json)
    #expect(dto.user.email == "test@example.com")
}
```

## 6. Swift Testing (Primary Framework)

### Migration from XCTest

| XCTest | Swift Testing | Notes |
|--------|--------------|-------|
| `XCTestCase` class | `struct` (no class needed) | Swift Testing uses value types |
| `func testXxx()` | `@Test func xxx()` | No `test` prefix required |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` | Unified assertion macro |
| `XCTAssertThrowsError` | `#expect(throws: ErrorType.self)` | Type-safe error expectations |
| `setUpWithError()` | `init() throws` | Standard initializer |
| `tearDown()` | `deinit` | Standard cleanup |
| `XCTSkipIf` | `@Test(.disabled("reason"))` | Declarative skip |
| `measure { }` | Not yet available | Use XCTest for performance tests |

### Test Organization with @Suite

```swift
@Suite("Authentication")
struct AuthTests {
    let mockAuthService = MockAuthService()

    @Suite("Login")
    struct LoginTests {
        @Test("succeeds with valid credentials")
        func validLogin() async throws {
            // ...
        }

        @Test("fails with invalid password")
        func invalidPassword() async throws {
            // ...
        }
    }

    @Suite("Logout")
    struct LogoutTests {
        @Test("clears stored tokens")
        func clearTokens() async throws {
            // ...
        }
    }
}
```

### Parameterized Tests

```swift
@Test("validates email format", arguments: [
    ("user@example.com", true),
    ("invalid-email", false),
    ("user@", false),
    ("@example.com", false),
    ("user@example", false),
])
func emailValidation(email: String, isValid: Bool) {
    #expect(EmailValidator.isValid(email) == isValid)
}
```

### Async Testing with Confirmation

```swift
@Test("notifies observers on state change")
func stateNotification() async {
    await confirmation("observer called") { confirm in
        let viewModel = ViewModel()
        viewModel.onStateChange = { _ in confirm() }
        await viewModel.loadData()
    }
}
```

## 7. Async/Await Testing Patterns

### Testing @MainActor ViewModels

```swift
@Test("ViewModel updates state on main actor")
@MainActor
func viewModelState() async {
    let viewModel = HomeViewModel(useCase: MockFetchItemsUseCase())
    await viewModel.loadItems()

    #expect(viewModel.isLoading == false)
    #expect(viewModel.items.count == 3)
}
```

### Testing Task Cancellation

```swift
@Test("cancels in-flight request on new search")
func searchCancellation() async throws {
    let viewModel = SearchViewModel(searchUseCase: MockSearchUseCase(delay: .seconds(5)))

    // Start first search
    let task1 = Task { await viewModel.search(query: "hello") }

    // Immediately start second search (should cancel first)
    try await Task.sleep(for: .milliseconds(50))
    await viewModel.search(query: "world")

    task1.cancel()
    #expect(viewModel.results.first?.query == "world")
}
```

### Testing with `.serialized` Trait

```swift
@Suite("Database operations", .serialized)
struct DatabaseTests {
    // Tests run sequentially — necessary for shared mutable state
    @Test("creates record") func create() async throws { ... }
    @Test("reads record") func read() async throws { ... }
    @Test("deletes record") func delete() async throws { ... }
}
```

## 8. Performance Testing

### Baseline Measurement (XCTest)

```swift
// Performance tests still require XCTest (Swift Testing doesn't support measure yet)
final class PerformanceTests: XCTestCase {
    func testListRenderingPerformance() {
        let items = (0..<1000).map { Item.mock(id: $0) }
        measure {
            _ = items.filter { $0.isActive }.sorted(by: \.name)
        }
    }
}
```

### Regression Detection

| Metric | Baseline | Threshold | Action |
|--------|----------|-----------|--------|
| Item list filtering | 5ms | +20% | Investigate |
| JSON decoding (1000 items) | 50ms | +30% | Investigate |
| Image processing | 200ms | +50% | Block PR |

## 9. Snapshot Testing (if applicable)

| Tool | Purpose | Configuration |
|------|---------|---------------|
| [swift-snapshot-testing] | View snapshot comparison | Record mode: manual |
| Perceptual diff threshold | Pixel comparison tolerance | 1% for text, 5% for images |

```swift
@Test("ProfileView matches snapshot")
func profileSnapshot() {
    let view = ProfileView(user: .mock)
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone15Pro)))
}
```

## 10. Network Stubbing

### URLProtocol Stubbing

```swift
class MockURLProtocol: URLProtocol {
    static var responseHandlers: [String: (URLRequest) -> (Data, HTTPURLResponse)] = [:]

    override class func canInit(with request: URLRequest) -> Bool { true }

    override func startLoading() {
        guard let url = request.url?.absoluteString,
              let handler = Self.responseHandlers[url] else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let (data, response) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
}
```

## 11. Feature Flag Testing

```swift
@Test("shows new paywall when flag enabled")
func newPaywallFlag() async {
    let flags = MockFeatureFlagService(overrides: [.premiumPaywallV2: true])
    let viewModel = PaywallViewModel(featureFlags: flags)

    #expect(viewModel.showNewPaywall == true)
}

@Test("shows legacy paywall when flag disabled")
func legacyPaywallFlag() async {
    let flags = MockFeatureFlagService(overrides: [.premiumPaywallV2: false])
    let viewModel = PaywallViewModel(featureFlags: flags)

    #expect(viewModel.showNewPaywall == false)
}
```

## 12. Flaky Test Prevention

### Common Causes & Fixes

| Cause | Fix |
|-------|-----|
| Shared mutable state between tests | Use fresh instances in each test (struct-based tests) |
| Time-dependent logic | Inject `Clock` protocol, use `TestClock` |
| Notification ordering | Use `confirmation()` instead of `sleep()` |
| File system side effects | Use temp directories, clean up in deinit |
| Network dependency | Always stub, never hit real network in unit tests |

### Rules

1. **Never use `Thread.sleep()` or `Task.sleep()` in tests** — use `confirmation()` or `TestClock`
2. **No shared mutable state** — each test creates its own dependencies
3. **Deterministic test data** — use factories with fixed values, not random
4. **Isolated file system** — temp directories, cleaned up after each test

## 13. CI Pipeline Testing

### What Runs When

| Trigger | Tests Run | Timeout | Required |
|---------|----------|---------|----------|
| PR opened/updated | Unit + Integration | 10 min | ✅ Must pass |
| Merge to develop | Unit + Integration + UI | 30 min | ✅ Must pass |
| Nightly build | Full suite + Performance | 60 min | ⚠️ Notify on fail |
| Release candidate | Full suite + UI on devices | 90 min | ✅ Must pass |

### CI Configuration

```yaml
# Example CI step
- name: Run tests
  run: |
    xcodebuild test \
      -scheme "[ProjectName]" \
      -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
      -resultBundlePath TestResults.xcresult
```

## 14. Coverage Goals

| Layer | Target Coverage | Current |
|-------|----------------|---------|
| Domain (UseCases) | >90% | [X]% |
| Presentation (ViewModels) | >80% | [X]% |
| Data (Repositories) | >70% | [X]% |
| Overall | >75% | [X]% |

> ⚠️ **Coverage is a guide, not a goal.** 100% coverage with bad tests is worse than 70% with meaningful tests.

## 15. Related Documentation

- [Architecture Overview](./01-Architecture-Overview.md) — Layer definitions
- [Coding Conventions](./10-Coding-Conventions.md) — Naming conventions apply to tests
- [CI/CD & Release](./11-CI-CD-Release.md) — Pipeline configuration

---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Owner | [Name/Team] |
| Created | [Date] |
| Last Updated | [Date] |
| Last Verified | [Date] |
| Review Schedule | [Quarterly/Semi-annual] |
| Status | Draft |
| Labels | `ios`, `swift`, `testing`, `ci`, `[project-name]` |
```

## Writing Guidelines

- Always include REAL mock examples from the project, not hypothetical ones
- The "What to Test by Layer" table is the most actionable section — be specific
- Document the actual CI pipeline commands, not just descriptions
- Update coverage numbers periodically (quarterly at minimum)
- Include fixture JSON files for API response testing
- Prioritize Swift Testing over XCTest for all new tests (XCTest only for performance and legacy code)
- Document async/await testing patterns for ViewModels and UseCases
- Include flaky test prevention strategies and rules
- Provide clear migration paths from XCTest to Swift Testing where applicable
