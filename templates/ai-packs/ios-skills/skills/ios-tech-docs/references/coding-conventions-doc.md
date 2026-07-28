# Coding Conventions Documentation Template

Use this template when the user asks to document: coding conventions, style guide, naming conventions, linting rules, code standards, PR process, or "how should I write code".

---

## Template Structure

```markdown
# [Project Name] - Coding Conventions

{toc}

## 1. Swift Style Guide

### Base Reference
We follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with the project-specific additions documented below.

## 2. Naming Conventions

### 2.1 Types

| Kind | Convention | Example |
|------|-----------|---------|
| View | `[Feature]View` | `LoginView`, `ProfileView` |
| ViewModel | `[Feature]ViewModel` | `LoginViewModel`, `ProfileViewModel` |
| UseCase | `[Verb][Noun]UseCase` | `FetchProductsUseCase`, `LoginUseCase` |
| Repository Protocol | `[Name]RepositoryProtocol` | `AuthRepositoryProtocol` |
| Repository Impl | `[Name]Repository` | `AuthRepository` |
| DTO | `[Name]DTO` | `UserDTO`, `ProductDTO` |
| Mapper | `[Name]Mapper` | `UserMapper` |
| DataSource | `[Name][Type]DataSource` | `AuthRemoteDataSource`, `AuthLocalDataSource` |
| Error | `[Feature]Error` | `LoginError`, `NetworkError` |
| Mock | `Mock[Protocol]` | `MockLoginUseCase`, `MockAuthRepository` |
| Test | `[Class]Tests` | `LoginViewModelTests` |
| Extension | `[Type]+[Purpose]` | `String+Validation.swift`, `Date+Formatting.swift` |

### 2.2 Functions

| Context | Convention | Example |
|---------|-----------|---------|
| Action methods | Verb phrase | `func login()`, `func fetchProducts()` |
| Boolean properties | `is/has/should` prefix | `isLoading`, `hasError`, `shouldRefresh` |
| Factory methods | `make` prefix | `func makeLoginViewModel()` |
| Event handlers | `handle` prefix or `on` prefix | `func handleTap()`, `func onAppear()` |
| Async functions | Always `async throws` | `func fetchItems() async throws -> [Item]` |

### 2.3 Files

| Content | File name | Example |
|---------|----------|---------|
| Single type | Type name | `LoginView.swift` |
| Extension | `Type+Purpose` | `String+Validation.swift` |
| Protocol | Protocol name | `AuthRepositoryProtocol.swift` |
| Constants | `[Scope]Constants` | `AppConstants.swift`, `APIConstants.swift` |

## 3. Access Control

### Default Access Levels

| Context | Default | Rationale |
|---------|---------|-----------|
| Types in App target | `internal` (implicit) | Only accessed within the app |
| Types in SPM module | `internal` + `public` for API | Explicit module boundary |
| Properties | `private` or `internal` | Minimize exposure |
| Methods | `private` for helpers, `internal`/`public` for API | Explicit scope |
| Test helpers | `internal` (same module) or `@testable import` | Test-only access |

### Rules

```swift
// ✅ Good: Minimal access, explicitly scoped
final class AuthRepository: AuthRepositoryProtocol {
    private let remoteDataSource: AuthRemoteDataSource  // private — internal detail
    private let tokenStore: TokenStore                   // private — internal detail

    func login(email: String, password: String) async throws -> User {  // protocol requirement — internal
        // ...
    }

    private func cacheUser(_ user: User) {  // private — helper
        // ...
    }
}

// 🚫 Bad: Everything is exposed
class AuthRepository {
    var remoteDataSource: AuthRemoteDataSource  // unnecessarily public
    var tokenStore: TokenStore                   // unnecessarily public

    func cacheUser(_ user: User) {  // should be private
        // ...
    }
}
```

## 4. Optional Handling

### Convention Table

| Pattern | When to Use | Example |
|---------|------------|---------|
| `guard let` | Early exit, unwrap for rest of scope | Function preconditions |
| `if let` | Conditional use, short scope | Optional binding in closures |
| `??` (nil coalescing) | Default value fallback | `name ?? "Unknown"` |
| `map` / `flatMap` | Transform optional without unwrapping | `url.map { URLRequest(url: $0) }` |
| Force unwrap `!` | **Only** in tests, previews, or IBOutlet (never in production code) | `XCTUnwrap(value)` |

```swift
// ✅ Good: guard for preconditions
func processUser(_ user: User?) {
    guard let user else { return }
    // use `user` safely for the rest of the function
}

// ✅ Good: if let for conditional branches
if let errorMessage = viewModel.error?.localizedDescription {
    showAlert(message: errorMessage)
}

// 🚫 Bad: force unwrap in production
let name = user!.name  // will crash if nil
```

## 5. Error Handling

### Convention

| Pattern | When to Use |
|---------|------------|
| `try` | Default — propagate errors to caller |
| `try?` | **Only** when nil is an acceptable result AND you log the error |
| `try!` | **Never** in production code |
| Explicit `catch` | When you need to handle specific error types differently |
| `catch` with pattern matching | When mapping domain errors to user-facing messages |

```swift
// ✅ Good: explicit catch with mapping
do {
    let user = try await authRepository.login(email: email, password: password)
    self.user = user
} catch let error as AuthError {
    self.error = error  // domain error, already user-friendly
} catch {
    self.error = AuthError.unknown(error)  // wrap unknown errors
}

// ⚠️ Acceptable ONLY if logged:
let cachedUser = try? localStore.getUser()
if cachedUser == nil {
    logger.info("No cached user found")
}

// 🚫 Bad: silent error swallowing
let user = try? authRepository.login(email: e, password: p)  // error silently lost
```

## 6. Code Organization with MARK

### 6.1 ViewModel Standard Sections

```swift
@Observable
final class FeatureViewModel {
    // MARK: - State
    var items: [Item] = []
    var isLoading = false
    var error: FeatureError?

    // MARK: - Derived State
    var isEmpty: Bool { items.isEmpty && !isLoading }

    // MARK: - Dependencies
    private let fetchItemsUseCase: FetchItemsUseCaseProtocol

    // MARK: - Init
    init(fetchItemsUseCase: FetchItemsUseCaseProtocol) {
        self.fetchItemsUseCase = fetchItemsUseCase
    }

    // MARK: - Actions
    func loadItems() async { ... }
    func refresh() async { ... }
    func deleteItem(_ item: Item) async { ... }
}
```

### 6.2 View Standard Sections

```swift
struct FeatureView: View {
    // MARK: - Properties
    @State var viewModel: FeatureViewModel
    @Environment(AppRouter.self) var router

    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("Feature")
            .task { await viewModel.loadItems() }
    }

    // MARK: - Subviews
    @ViewBuilder
    private var content: some View { ... }

    private var headerSection: some View { ... }

    private var listSection: some View { ... }

    // MARK: - Actions
    private func handleItemTap(_ item: Item) { ... }
}
```

### 6.3 Protocol + Implementation

```swift
// MARK: - Protocol
protocol AuthRepositoryProtocol: Sendable {
    func login(email: String, password: String) async throws -> User
    func logout() async throws
}

// MARK: - Implementation
final class AuthRepository: AuthRepositoryProtocol {
    // MARK: - Dependencies
    private let remoteDataSource: AuthRemoteDataSource
    private let localDataSource: AuthLocalDataSource

    // MARK: - Init
    init(remote: AuthRemoteDataSource, local: AuthLocalDataSource) { ... }

    // MARK: - AuthRepositoryProtocol
    func login(email: String, password: String) async throws -> User { ... }
    func logout() async throws { ... }

    // MARK: - Private Helpers
    private func cacheUser(_ user: User) { ... }
}
```

## 7. Swift Concurrency Rules

1. **Use `async/await`** for all asynchronous work — no completion handlers
2. **Mark ViewModels with `@Observable`** — not `ObservableObject`
3. **Use `@MainActor`** on ViewModels and any type that updates UI state
4. **Mark protocols as `Sendable`** when they cross concurrency boundaries
5. **Use `Task { }` in views** for calling async ViewModel actions
6. **Never use `DispatchQueue.main.async`** — use `@MainActor` instead
7. **Use structured concurrency** (`async let`, `TaskGroup`) over unstructured `Task { }`

```swift
// ✅ Good
@MainActor @Observable
final class FeatureViewModel {
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await fetchItemsUseCase.execute()
        } catch {
            self.error = .fromError(error)
        }
    }
}

// 🚫 Bad
class FeatureViewModel: ObservableObject {
    func loadItems() {
        DispatchQueue.main.async { self.isLoading = true }
        fetchItemsUseCase.execute { [weak self] result in
            DispatchQueue.main.async { ... }
        }
    }
}
```

## 8. Value Types vs Reference Types

### Decision Tree

| Question | If Yes → | If No → |
|----------|----------|---------|
| Does it need identity? (is it "this specific object"?) | `class` | `struct` |
| Does it have mutable shared state? | `actor` | `struct` |
| Is it a simple data container? | `struct` | Consider `class` |
| Is it a ViewModel? | `class` (with `@Observable`) | `struct` |
| Is it a domain entity? | `struct` (Sendable) | - |

### Rules

1. **Default to `struct`** for data types — value semantics, thread-safe, Sendable
2. **Use `class` only for**: ViewModels (`@Observable`), UIKit interop, reference identity needed
3. **Use `actor` for**: Mutable shared state that needs thread safety
4. **Use `enum` for**: Closed sets (errors, states, routes, config)

## 9. Documentation Comments

### When to Document

| Context | Documentation Required? |
|---------|----------------------|
| Public API (SPM module boundary) | ✅ Always — `///` doc comment |
| Protocol methods | ✅ Always — consumers need to understand the contract |
| Complex business logic | ✅ Always — explain the "why" |
| Simple properties | ❌ Skip — `var name: String` is self-documenting |
| Private helpers | ⚠️ Only if non-obvious |
| Test functions | ❌ Skip — `@Test("description")` serves as documentation |

### Format

```swift
/// Authenticates the user with email and password.
///
/// - Parameters:
///   - email: The user's email address. Must be a valid email format.
///   - password: The user's password. Minimum 8 characters.
/// - Returns: The authenticated user.
/// - Throws: `AuthError.invalidCredentials` if email/password combination is wrong.
///           `AuthError.accountLocked` after 5 failed attempts.
func login(email: String, password: String) async throws -> User
```

## 10. Pre-Commit Hooks

### Setup

```bash
# Install pre-commit hooks
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Hook Script

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Auto-format staged Swift files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$')
if [ -n "$STAGED_FILES" ]; then
    echo "$STAGED_FILES" | xargs swiftformat
    echo "$STAGED_FILES" | xargs git add
fi

# Lint check
swiftlint lint --strict --quiet
if [ $? -ne 0 ]; then
    echo "❌ SwiftLint errors found. Fix before committing."
    exit 1
fi
```

## 11. SwiftUI Best Practices

1. **Prefer small, composable views** — extract subviews when body exceeds ~30 lines
2. **Use `@ViewBuilder` computed properties** for conditional content
3. **Never put business logic in views** — delegate to ViewModel
4. **Use `#Preview` macro** for all views with multiple states
5. **Prefer `@Environment` for DI** over init injection for shared services
6. **Use `task` modifier** over `onAppear` for async work

## 12. Protocol-First Design

1. **Define protocols for all dependencies** — enables testing via mocks
2. **Protocols live in Domain layer** — implementations in Data layer
3. **Keep protocols minimal** — only methods the consumer needs
4. **Use `any` keyword** for existential types, `some` for opaque types

```swift
// ✅ Good: Protocol in Domain, implementation in Data
// Domain/
protocol ProductRepository: Sendable {
    func fetchProducts() async throws -> [Product]
}

// Data/
final class ProductRepositoryImpl: ProductRepository {
    func fetchProducts() async throws -> [Product] { ... }
}
```

## 13. Linting & Formatting

### SwiftLint Configuration

Key rules enforced:
```yaml
# .swiftlint.yml (highlights)
opt_in_rules:
  - empty_count
  - closure_spacing
  - force_unwrapping
  - implicit_return
  - sorted_imports

disabled_rules:
  - trailing_whitespace  # SwiftFormat handles this

line_length:
  warning: 120
  error: 150

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 800
```

### SwiftFormat Configuration

```
# .swiftformat
--indent 4
--maxwidth 120
--wraparguments before-first
--wrapcollections before-first
--stripunusedargs closure-only
--importgrouping alpha
```

### Running Locally

```bash
# Run lint check
swiftlint lint

# Auto-fix formatting
swiftformat .

# Both (pre-commit)
swiftformat . && swiftlint lint --strict
```

## 14. Git & PR Conventions

### Branch Naming

| Branch Type | Pattern | Example |
|-------------|---------|---------|
| Feature | `feature/JIRA-XXX-short-description` | `feature/APP-123-login-screen` |
| Bugfix | `bugfix/JIRA-XXX-short-description` | `bugfix/APP-456-crash-on-launch` |
| Hotfix | `hotfix/JIRA-XXX-short-description` | `hotfix/APP-789-token-refresh` |
| Chore | `chore/short-description` | `chore/update-dependencies` |

### Commit Messages

```
type(scope): short description

[optional body]

[optional footer: JIRA-XXX]
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `ci`

### PR Template

```markdown
## Description
Brief description of changes.

## Type
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Test
- [ ] Documentation

## Changes
- Change 1
- Change 2

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manually tested on simulator
- [ ] Tested on device

## Documentation
- [ ] Documentation updated
- [ ] No documentation changes needed

## Screenshots (if UI changes)
| Before | After |
|--------|-------|
| | |
```

## 15. Related Documentation

- [Architecture Overview](./01-Architecture-Overview.md) — Layer rules
- [Testing Strategy](./07-Testing-Strategy.md) — Test naming conventions
- [Project Structure](./02-Project-Structure.md) — File locations

---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Owner | [Team/Individual responsible for maintenance] |
| Created | [Date] |
| Last Updated | [Date] |
| Last Verified | [Date - when conventions were last validated against codebase] |
| Review Schedule | [Quarterly/Semi-annually] |
| Status | Draft |
| Labels | `ios`, `swift`, `conventions`, `style-guide`, `[project-name]` |
```

## Writing Guidelines

- Be prescriptive, not suggestive — "Use X" not "Consider using X"
- Include ✅ Good and 🚫 Bad code examples side by side
- Document the MARK sections — developers use them as mental framework
- Include SwiftLint/SwiftFormat configs as part of the conventions
- The PR template is documentation too — include it here
- Cover access control conventions — explicit scoping prevents unintended exposure
- Document optional handling patterns — guard vs if let vs ?? vs map
- Specify error handling rules — when to use try vs try? vs explicit catch
- Include value type conventions — struct vs class vs actor vs enum decision tree
