# Swift 6 Concurrency Guide

> Patterns for Swift 6 strict concurrency compliance in Clean Architecture.

## Overview

Swift 6 enforces strict concurrency checking. This guide covers patterns to achieve data-race safety while maintaining Clean Architecture.

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
    func mapToDomain(_ dto: ArticleDTO) -> ArticleModel
}
```

### @unchecked Sendable (Use Sparingly)

Use only when you have thread-safe code that the compiler cannot verify:

```swift
final class SSLPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let pinnedHashes: Set<String>

    init(pinnedHashes: Set<String>) {
        self.pinnedHashes = pinnedHashes
    }
}
```

---

## Actor Isolation

### @MainActor for ViewModels

ViewModels are always `@MainActor` because they update UI state:

```swift
@MainActor
@Observable
final class ArticleViewModel {
    private(set) var state: ArticleState = .idle

    private let useCase: ArticleUseCase

    func loadArticles() async {
        state = .loading
        do {
            let models = try await useCase.execute()
            state = .loaded(models)
        } catch {
            state = .error(ErrorDecorator.generic)
        }
    }
}
```

### Non-isolated UseCases and Repositories

UseCases and Repositories are NOT `@MainActor` — they run in the caller's context:

```swift
struct ArticleUseCaseImpl: ArticleUseCase {
    private let repository: ArticleRepository

    func execute() async throws -> [ArticleModel] {
        try await repository.fetchArticles()
    }
}
```

### Mapper Isolation Rules

Different mappers have different isolation needs:

| Mapper Type | Location | Isolation | Reason |
|-------------|----------|-----------|--------|
| **DecoratorMapper** | `Features/.../Presentation/Mappers/` | `@MainActor` | Called from ViewModels, outputs to Views |
| **DTOMapper** | `Data/.../Mappers/` | `nonisolated` | Called from Repositories (any context) |
| **SDModelMapper** | `Data/.../Mappers/` | `nonisolated` | Called from background ModelExecutor |

#### DecoratorMapper (@MainActor)

```swift
@MainActor
protocol FeatureDecoratorMapper: Sendable {
    func map(_ model: DomainModel) -> ItemDecorator
}

@MainActor
struct FeatureDecoratorMapperImpl: FeatureDecoratorMapper {
    func map(_ model: DomainModel) -> ItemDecorator {
        // Simple transformation, runs on main actor
    }
}
```

#### DTOMapper / SDModelMapper (nonisolated)

```swift
protocol FeatureDTOMapper: Sendable {
    nonisolated func mapToDomain(_ dto: FeatureDTO) -> FeatureModel
}

struct FeatureDTOMapperImpl: FeatureDTOMapper {
    nonisolated func mapToDomain(_ dto: FeatureDTO) -> FeatureModel {
        FeatureModel(id: dto.id, name: dto.name)
    }
}
```

### Domain Models with nonisolated init

With Main Actor Mode enabled, Swift auto-generates `@MainActor` memberwise inits.
Domain models created from Data layer need explicit `nonisolated` init.

**IMPORTANT**: The init must be inside the struct body (not an extension) to suppress the auto-generated memberwise init:

```swift
struct FeatureModel: Sendable, Equatable {
    let id: String
    let name: String
    let customField: String?

    // MARK: - Initializer

    nonisolated init(id: String,
                     name: String,
                     customField: String? = nil) {
        self.id = id
        self.name = name
        self.customField = customField
    }
}
```

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

```swift
struct ArticleRepositoryImpl: ArticleRepository {
    private let modelExecutor: ModelExecutor

    func fetchArticle(id: UUID) async throws -> ArticleModel? {
        try await modelExecutor.perform {
            let descriptor = FetchDescriptor<ArticleSDModel>(
                predicate: #Predicate { $0.id == id }
            )
            guard let sdModel = try modelExecutor.modelContext.fetch(descriptor).first else {
                return nil
            }
            return ArticleModel(from: sdModel)
        }
    }
}
```

---

## Task Management

### Task Cancellation

Always handle cancellation properly:

```swift
func loadArticles() async {
    state = .loading

    do {
        let articles = try await useCase.execute()
        state = .loaded(articles)
    } catch is CancellationError {
        return
    } catch {
        state = .error(ErrorDecorator.generic)
    }
}
```

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
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch(query)
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
| `@MainActor` | ViewModels, UI-related classes |
| `actor` | Shared mutable state |
| `@preconcurrency` | Legacy API imports |
| `assumeIsolated` | Known context, compiler unaware |
| `Task.detached` | Truly independent work |
| `.task(id:)` | View-driven async operations |
