# Swift 6 Concurrency Guide

> Patterns for Swift 6 strict concurrency compliance in Clean Architecture.

## Overview

Swift 6 enforces strict concurrency checking. This guide covers patterns to achieve data-race safety while maintaining Clean Architecture.

### Project Settings (generated)

| Setting | Value | Consequence |
|---------|-------|-------------|
| `SWIFT_VERSION` | `6.0` by default (Swift 6 language mode) | Data-race errors are compile errors |
| `SWIFT_STRICT_CONCURRENCY` | `complete` (app and test targets) | Full `Sendable` checking |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | not set (no default isolation) | Types are **nonisolated** unless annotated |

Because there is no default actor isolation, isolation is explicit:

- **`@MainActor`**: ViewModels, Routers (protocol + Impl), Factories, `AppRouter` / `AppRouterImpl`, `AppNavigationCoordinator` (and `SwiftDataStack` / `PersistenceAssembly` when SwiftData is enabled).
- **Nonisolated `Sendable` structs**: UseCases, Repositories, DataSources, DTOMappers and DecoratorMappers. Their `async` methods run off the main actor.

Don't add `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` without revisiting these rules: it would make every unannotated type, UseCases and Repositories included, `@MainActor`.

---

## Sendable Requirements

### When to Use Sendable

| Type | Sendable? | Reason |
|------|-----------|--------|
| Domain Models | **Required** | Cross actor boundaries |
| DTOs | **Required** | Cross actor boundaries |
| UseCases (struct) | **Required** | Called from different actors |
| Repositories (struct) | **Required** | Called from different actors |
| DataSources (struct) | **Required** | Called from different actors |
| Mappers (protocol) | **Required** | Used across actor boundaries |
| Decorators | **Recommended** | May be passed between actors |
| ViewModels | **NO** | Already @MainActor isolated |
| Views | **NO** | SwiftUI handles isolation |

### Making Types Sendable

```swift
// MARK: - Domain Model (Sendable by default if all properties are Sendable)

struct ArticleModel: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let body: String
    let category: Category

    enum Category: String, Sendable, CaseIterable {
        case news, tutorial, review
    }
}

// MARK: - Protocol with Sendable

protocol ArticleUseCase: Sendable {
    func execute() async throws -> [ArticleModel]
}

protocol ArticleRepository: Sendable {
    func fetchArticles() async throws -> [ArticleModel]
}

protocol ArticleDTOMapper: Sendable {
    func map(_ dto: ArticleDTO) -> ArticleModel
}
```

### @unchecked Sendable (Use Sparingly)

Use only when you have thread-safe code that the compiler cannot verify:

```swift
// Core/Networking/Security/SSLPinningDelegate.swift (excerpt)
final class SSLPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let pinnedPublicKeyHashes: Set<String>
    private let isEnabled: Bool

    init(publicKeyHashes: [String], isEnabled: Bool = true) {
        self.pinnedPublicKeyHashes = Set(publicKeyHashes)
        self.isEnabled = isEnabled
        super.init()
    }
}
```

---

## Actor Isolation

### @MainActor for ViewModels

ViewModels are always explicitly `@MainActor` because they update UI state:

```swift
// MARK: - ArticleViewModel

@MainActor
@Observable
final class ArticleViewModel {
    // MARK: - Properties

    private(set) var state: ArticleState = .idle

    private let useCase: ArticleUseCase
    private let decoratorMapper: ArticleDecoratorMapper

    // MARK: - Public Methods

    func loadArticles() async {
        guard state != .loading else { return }

        let previousState = state
        state = .loading

        do {
            let models = try await useCase.execute()
            state = .loaded(models.map { decoratorMapper.map($0) })
        } catch is CancellationError {
            state = previousState
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }
}
```

### Non-isolated UseCases and Repositories

UseCases and Repositories are NOT `@MainActor`. They are nonisolated `Sendable` structs, so when a `@MainActor` ViewModel awaits them, their `async` methods run off the main actor and the ViewModel resumes on the main actor afterwards:

```swift
// MARK: - ArticleUseCaseImpl

struct ArticleUseCaseImpl: ArticleUseCase {
    // MARK: - Properties

    private let repository: ArticleRepository

    // MARK: - Public Methods

    func execute() async throws -> [ArticleModel] {
        try await repository.fetchArticles()
    }
}
```

### Mapper Isolation Rules

All mappers are nonisolated `Sendable` structs. Their protocol and Impl live in one file, and no `nonisolated` keyword is needed because nothing is isolated by default.

| Mapper Type | Location | Isolation | Called from |
|-------------|----------|-----------|-------------|
| **DecoratorMapper** | `Features/.../Presentation/Mappers/` | nonisolated | ViewModels (main actor) |
| **DTOMapper** | `Data/.../Mappers/` | nonisolated | Repositories (any context) |
| **SDModelMapper** (SwiftData only) | `Data/.../Mappers/` | nonisolated | The repository's background `ModelExecutor` |

```swift
// MARK: - FeatureDecoratorMapper

protocol FeatureDecoratorMapper: Sendable {
    func map(_ model: FeatureModel) -> FeatureDecorator
}

// MARK: - FeatureDecoratorMapperImpl

struct FeatureDecoratorMapperImpl: FeatureDecoratorMapper {
    // MARK: - Public Methods

    func map(_ model: FeatureModel) -> FeatureDecorator {
        FeatureDecorator(id: model.id, displayName: model.name, subtitle: model.description)
    }
}

// MARK: - FeatureDTOMapper

protocol FeatureDTOMapper: Sendable {
    func map(_ dto: FeatureDTO) -> FeatureModel
}

// MARK: - FeatureDTOMapperImpl

struct FeatureDTOMapperImpl: FeatureDTOMapper {
    // MARK: - Public Methods

    func map(_ dto: FeatureDTO) -> FeatureModel {
        FeatureModel(id: dto.id, name: dto.name, description: dto.description)
    }
}
```

### Domain Models and Memberwise Inits

Without default actor isolation, a struct's memberwise init is nonisolated, so Data-layer code running off the main actor can create Domain models directly. No explicit `nonisolated init` is needed. If a target ever enables `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, unannotated types (and their memberwise inits) become `@MainActor`, and the models, mappers and repositories used off the main actor must then be marked `nonisolated` explicitly.

### Custom Actors for Shared State

When you need shared mutable state, use an actor:

```swift
actor ArticleCache {
    private var cache: [String: ArticleModel] = [:]

    func get(_ id: String) -> ArticleModel? {
        cache[id]
    }

    func set(_ article: ArticleModel) {
        cache[article.id] = article
    }

    func clear() {
        cache.removeAll()
    }
}
```

---

## @preconcurrency for Legacy APIs

Use `@preconcurrency` when importing modules that haven't adopted Sendable:

```swift
@preconcurrency import SomeLegacyFramework

class LegacyDelegate: @preconcurrency SomeLegacyProtocol {
    // ...
}
```

---

## assumeIsolated Pattern

Use `MainActor.assumeIsolated` when you know code runs on MainActor but compiler doesn't:

```swift
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    MainActor.assumeIsolated {
        viewModel.selectItem(at: indexPath.row)
    }
}
```

**Warning**: Only use when you are 100% certain of the execution context. Crashes if wrong.

---

## SwiftData Concurrency

> Applies only when the project was generated with SwiftData (see `swiftdata.md`).

### The Golden Rule

> **NEVER pass SwiftData models between actors. Pass IDs instead.**

SwiftData models are bound to their `ModelContext` and are NOT thread-safe.

### Wrong vs Right

```swift
// WRONG: Passing model across actors
@MainActor
class ArticleViewModel {
    func saveArticle(_ article: ArticleSDModel) async {
        await repository.save(article)  // CRASH RISK
    }
}

// RIGHT: Pass ID, fetch on target context
@MainActor
class ArticleViewModel {
    func saveArticle(_ articleId: UUID) async {
        await repository.save(articleId: articleId)
    }
}
```

### ModelExecutor for Background Operations

Each SwiftData repository receives its own `ModelExecutor`, created in its Factory with `dependencies.swiftDataStack.makeBackgroundExecutor()`. Never share an executor between repositories and never use the main `ModelContext` from a repository.

`ModelExecutor` only exposes `modelContext`; it cannot run a closure for you. The repository is therefore an `actor` conforming to `ModelActor`: the actor runs on the injected executor, and its methods use the protocol-provided `modelContext`. This is what `@ModelActor` generates, except that the executor is injected (the Factory passes `swiftDataStack.makeBackgroundExecutor()` and `swiftDataStack.container`) so each repository gets its own.

```swift
// MARK: - ArticleRepositoryImpl

actor ArticleRepositoryImpl: ArticleRepository, ModelActor {
    // MARK: - Properties

    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    // MARK: - Init

    init(modelExecutor: any ModelExecutor, modelContainer: ModelContainer) {
        self.modelExecutor = modelExecutor
        self.modelContainer = modelContainer
    }

    // MARK: - ArticleRepository

    func fetchArticle(id: UUID) async throws -> ArticleModel? {
        try await DomainError.catching {
            let descriptor = FetchDescriptor<ArticleSDModel>(
                predicate: #Predicate { $0.id == id }
            )
            return try modelContext.fetch(descriptor).first?.toDomain()
        }
    }
}
```

The `@Model` object stays inside the actor; only the `Sendable` Domain model is returned. See `swiftdata.md` for the full repository and its Factory.

---

## Task Management

### Task Cancellation

Always handle cancellation properly. Cancellation is not an error: restore the previous state instead of showing an error screen.

```swift
func loadArticles() async {
    guard state != .loading else { return }

    let previousState = state
    state = .loading

    do {
        let articles = try await useCase.execute()
        state = .loaded(articles)
    } catch is CancellationError {
        state = previousState
    } catch let error as DomainError {
        state = .error(ErrorDecorator.from(error))
    } catch {
        state = .error(.generic)
    }
}
```

Cancellation reaches the ViewModel as `CancellationError` through every layer:

- `APIClientImpl` turns `URLError.cancelled` into `CancellationError` only when `Task.isCancelled` is true. Any other `URLError.cancelled` (for example a rejected authentication challenge or an invalidated session) stays `APIError.networkError`, so it is not silently hidden.
- `RetryInterceptor` checks `Task.checkCancellation()` before each attempt and never retries a `CancellationError`.
- `DomainError.catching` runs in the caller's isolation (`#isolation`), rethrows `CancellationError`, and treats any failure after cancellation as cancellation; repositories that catch errors themselves must rethrow it first.

### Structured Concurrency in Views

Use `.task(id:)` for automatic cancellation:

```swift
struct ArticleView: View {
    @State private var viewModel: ArticleViewModel

    var body: some View {
        content
            .task(id: viewModel.articleId) {
                await viewModel.loadArticle()
            }
    }
}
```

### Unstructured Tasks (When Needed)

Store and cancel manually when you need unstructured concurrency:

```swift
@MainActor
@Observable
final class SearchViewModel {
    private var searchTask: Task<Void, Never>?

    func search(_ query: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self?.performSearch(query)
        }
    }
}
```

---

## Common Anti-Patterns

### DON'T: Capture self in detached tasks without isolation

```swift
// WRONG
Task.detached {
    self.updateState()
}

// RIGHT: Capture values, not self
let value = someValue
Task.detached {
    await processValue(value)
}
```

### DON'T: Access MainActor state from non-isolated context

```swift
// WRONG
func backgroundProcess() async {
    viewModel.state = .loading
}

// RIGHT: Use MainActor.run
func backgroundProcess() async {
    await MainActor.run {
        viewModel.state = .loading
    }
}
```

### DON'T: Forget Sendable on closure parameters

```swift
// WRONG
func process(completion: @escaping () -> Void) async {
    await someActor.doWork()
    completion()
}

// RIGHT: Mark closure as @Sendable
func process(completion: @escaping @Sendable () -> Void) async {
    await someActor.doWork()
    completion()
}
```

---

## Quick Reference

| Pattern | When to Use |
|---------|-------------|
| `Sendable` | All types crossing actor boundaries |
| `@MainActor` | ViewModels, Routers, Factories, `AppRouter`, `AppNavigationCoordinator`, UI-related classes |
| nonisolated `Sendable` struct | UseCases, Repositories, DataSources, mappers |
| `actor` | Shared mutable state |
| `@preconcurrency` | Legacy API imports |
| `assumeIsolated` | Known context, compiler unaware |
| `Task.detached` | Truly independent work |
| `.task(id:)` | View-driven async operations |
