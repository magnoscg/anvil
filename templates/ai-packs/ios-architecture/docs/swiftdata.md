# SwiftData Integration Guide

> Patterns for SwiftData persistence in Clean Architecture (iOS 17+).

## Overview

SwiftData provides a declarative approach to data persistence. This guide covers how to integrate it correctly with Clean Architecture while maintaining thread safety.

> **SwiftData is optional.** It is generated only when the project is created with SwiftData enabled. Without it, none of the files below exist and the project has no persistence stack; add them by hand following this guide if you need SwiftData later.

### What the Generator Creates (SwiftData enabled)

| File | Purpose |
|------|---------|
| `Core/Persistence/SwiftDataStack.swift` | `@MainActor final class SwiftDataStack`: owns the `ModelContainer` and vends one `ModelExecutor` per repository |
| `Core/Persistence/ModelContainerShared.swift` | `ModelContainer.shared` (on disk) and `ModelContainer.preview` (in memory) |
| `App/DI/PersistenceAssembly.swift` | Helpers to build production / preview stacks and executors |

And it wires the stack at the composition root:

- `@main` (`App/Application/AppMain.swift`) creates the `SwiftDataStack`, attaches `.modelContainer(swiftDataStack.container)` to the `WindowGroup` and passes the stack to `AppDependencies(swiftDataStack:)`.
- `AppDependencies.swiftDataStack` is how Factories reach it. Each Factory calls `dependencies.swiftDataStack.makeBackgroundExecutor()` once per repository.

The generated schema is empty: add your `@Model` types to both containers.

---

## SwiftData Stack Setup

### ModelContainer Configuration

```swift
// Core/Persistence/ModelContainerShared.swift
import SwiftData

// MARK: - ModelContainer + Shared

extension ModelContainer {
    // MARK: - Production

    static let shared: ModelContainer = {
        let schema = Schema([
            ArticleSDModel.self,
            UserSDModel.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - Preview

    static let preview: ModelContainer = {
        let schema = Schema([
            ArticleSDModel.self,
            UserSDModel.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
}
```

### SwiftDataStack for Dependency Injection

```swift
// Core/Persistence/SwiftDataStack.swift
import SwiftData

// MARK: - SwiftDataStack

@MainActor
final class SwiftDataStack {
    // MARK: - Properties

    let container: ModelContainer

    // MARK: - Init

    init(container: ModelContainer = .shared) {
        self.container = container
    }

    // MARK: - Executor Factory

    func makeBackgroundExecutor() -> ModelExecutor {
        DefaultSerialModelExecutor(
            modelContext: ModelContext(container)
        )
    }
}
```

There is intentionally no `mainContext` accessor: repositories never use the main `ModelContext`.

### PersistenceAssembly

```swift
// App/DI/PersistenceAssembly.swift
import SwiftData

// MARK: - PersistenceAssembly

@MainActor
enum PersistenceAssembly {
    // MARK: - Registration

    static func makeSwiftDataStack() -> SwiftDataStack {
        SwiftDataStack(container: .shared)
    }

    static func makePreviewSwiftDataStack() -> SwiftDataStack {
        SwiftDataStack(container: .preview)
    }

    // MARK: - Executor Factory

    static func makeExecutor(from stack: SwiftDataStack) -> ModelExecutor {
        stack.makeBackgroundExecutor()
    }
}
```

Use `makePreviewSwiftDataStack()` for SwiftUI previews and tests.

---

## Thread Safety: Pass IDs, Not Models

### The Golden Rule

> **NEVER pass SwiftData models between actors. Pass IDs instead.**

SwiftData models are bound to their `ModelContext` and are **NOT thread-safe**.

### Wrong vs Right

```swift
// WRONG: Passing model across actors
@MainActor
class ArticleViewModel {
    func saveArticle(_ article: ArticleSDModel) async {
        await repository.save(article)
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

### Repository Pattern with IDs

A SwiftData repository is an `actor` conforming to `ModelActor`. `ModelExecutor` only exposes `modelContext`; it has no API to run a closure. Running the work on the executor is the actor's job: `ModelActor` uses `modelExecutor` as the actor's executor and provides `modelContext`, so every method body runs on the repository's own executor and context.

```swift
// Data/Article/Repositories/ArticleRepositoryImpl.swift
import SwiftData

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
        do {
            let descriptor = FetchDescriptor<ArticleSDModel>(
                predicate: #Predicate { $0.id == id }
            )
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw DomainError.map(error)
        }
    }

    func save(_ model: ArticleModel) async throws {
        do {
            let articleId = model.id
            let descriptor = FetchDescriptor<ArticleSDModel>(
                predicate: #Predicate { $0.id == articleId }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                existing.update(from: model)
            } else {
                modelContext.insert(ArticleSDModel(from: model))
            }

            try modelContext.save()
        } catch {
            throw DomainError.map(error)
        }
    }
}
```

- This is what the `@ModelActor` macro generates (`nonisolated let modelExecutor`, `nonisolated let modelContainer`), except that the macro's `init(modelContainer:)` creates its own `DefaultSerialModelExecutor`. Here the executor is **injected** instead, so the Factory decides where it comes from and each repository gets its own from `dependencies.swiftDataStack.makeBackgroundExecutor()`.
- `@Model` objects never leave the actor: every method maps to Domain models (`toDomain()`) before returning.
- The repository protocol (`ArticleRepository`) lives in `Domain/Article/Repositories/` and knows nothing about SwiftData; the actor satisfies its `async` requirements.
- Errors: only `DomainError` leaves the repository. The work is synchronous inside the actor, so each method catches and rethrows `DomainError.map(error)` (SwiftData errors map to `DomainError.unknown`). Passing an actor-isolated closure to the nonisolated `DomainError.catching` would send it out of the actor.

---

## ModelExecutor for Background Operations

### Why ModelExecutor?

- `ModelContext` is **NOT** thread-safe
- Main context blocks UI during heavy operations
- `ModelExecutor` provides isolated context for background work

### DefaultSerialModelExecutor

```swift
// Features/Article/DI/ArticleFactory.swift

// MARK: - ArticleFactory

@MainActor
enum ArticleFactory {
    // MARK: - Public Methods

    static func makeView(appRouter: AppRouter, dependencies: AppDependencies) -> some View {
        let viewModel = makeViewModel(appRouter: appRouter, dependencies: dependencies)
        return ArticleView(viewModel: viewModel)
    }
}

// MARK: - Private Factory Methods

private extension ArticleFactory {
    // MARK: - Repositories

    static func makeRepository(dependencies: AppDependencies) -> ArticleRepository {
        let stack = dependencies.swiftDataStack
        return ArticleRepositoryImpl(modelExecutor: stack.makeBackgroundExecutor(),
                                     modelContainer: stack.container)
    }
}
```

Call `makeBackgroundExecutor()` once per repository; never share an executor between repositories. Each call wraps a fresh `ModelContext(container)` in a `DefaultSerialModelExecutor`.

### Custom ModelActor (Advanced)

For complex operations, create a dedicated actor:

```swift
// Data/Article/Actors/ArticlePersistenceActor.swift
@ModelActor
actor ArticlePersistenceActor {

    func fetchAll() throws -> [ArticleModel] {
        let descriptor = FetchDescriptor<ArticleSDModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let sdModels = try modelContext.fetch(descriptor)
        return sdModels.map { $0.toDomain() }
    }

    func save(_ model: ArticleModel) throws {
        let sdModel = ArticleSDModel(from: model)
        modelContext.insert(sdModel)
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<ArticleSDModel>(
            predicate: #Predicate { $0.id == id }
        )
        if let sdModel = try modelContext.fetch(descriptor).first {
            modelContext.delete(sdModel)
            try modelContext.save()
        }
    }
}
```

---

## SwiftData Model Design

### Naming Convention

| Type | Naming | Location |
|------|--------|----------|
| SwiftData Model | `ArticleSDModel` | `Data/<Feature>/Models/` |
| Domain Model | `ArticleModel` | `Domain/<Feature>/Models/` |

### SwiftData Model Example

```swift
// Data/Article/Models/ArticleSDModel.swift
import SwiftData

@Model
final class ArticleSDModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var comments: [CommentSDModel]?

    init(id: UUID = UUID(), title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    convenience init(from model: ArticleModel) {
        self.init(id: model.id, title: model.title, body: model.body)
    }

    func update(from model: ArticleModel) {
        self.title = model.title
        self.body = model.body
        self.updatedAt = Date()
    }

    // MARK: - Domain Mapping

    func toDomain() -> ArticleModel {
        ArticleModel(id: id, title: title, body: body)
    }
}
```

Mapping between `ArticleSDModel` and `ArticleModel` lives in **Data** (here, in the SD model file or a mapper in `Data/<Feature>/Mappers/`), because Data depends on Domain and never the other way around.

### Domain Model (Clean - No SwiftData)

```swift
// Domain/Article/Models/ArticleModel.swift

// MARK: - ArticleModel

struct ArticleModel: Sendable, Equatable, Identifiable {
    // MARK: - Properties

    let id: UUID
    var title: String
    var body: String

    // MARK: - Init

    init(id: UUID = UUID(), title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}
```

The Domain model has no initializer that takes `ArticleSDModel`: Domain must not know Data types.

---

## Schema Migrations

### Lightweight Migration (Automatic)

SwiftData handles simple changes automatically:
- Adding new properties with default values
- Removing properties
- Renaming (with `@Attribute(originalName:)`)

```swift
@Model
final class ArticleSDModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var summary: String = ""
    @Attribute(originalName: "content") var body: String
}
```

### VersionedSchema (Breaking Changes)

For breaking changes, use versioned schemas:

```swift
enum ArticleSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ArticleSDModelV1.self]
    }

    @Model
    final class ArticleSDModelV1 {
        var id: UUID
        var title: String
        var content: String
    }
}

enum ArticleSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ArticleSDModel.self]
    }
}

enum ArticleMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ArticleSchemaV1.self, ArticleSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: ArticleSchemaV1.self,
        toVersion: ArticleSchemaV2.self
    ) { context in
        let articles = try context.fetch(FetchDescriptor<ArticleSchemaV1.ArticleSDModelV1>())
        for article in articles {
            // Transform data
        }
        try context.save()
    }
}
```

---

## Anti-patterns to Avoid

### DO NOT

```swift
// Don't use @Query in ViewModels
@Observable
class ArticleViewModel {
    @Query var articles: [ArticleSDModel]  // WRONG
}

// Don't access mainContext from background
Task.detached {
    let context = container.mainContext  // CRASH RISK
}

// Don't pass models between actors
await repository.save(articleSDModel)  // CRASH RISK

// Don't use SwiftData in Domain layer
// Domain/Article/Models/ArticleModel.swift
import SwiftData  // WRONG - Domain should be pure Swift
```

### DO

```swift
// Use @Query only in Views (if needed)
struct ArticleListView: View {
    @Query var articles: [ArticleSDModel]
}

// Create one dedicated executor per repository, in its Factory
let executor = dependencies.swiftDataStack.makeBackgroundExecutor()

// Pass IDs between actors
await repository.save(articleId: article.id)

// Keep Domain layer pure
// Domain/Article/Models/ArticleModel.swift
import Foundation
```

---

## Integration with Clean Architecture

### Layer Boundaries

```
+-------------------------------------------------------------+
|  PRESENTATION                                                |
|  - Views may use @Query for read-only lists (optional)       |
|  - ViewModels work with Domain models only                   |
|  - No SwiftData imports in ViewModels                        |
+-------------------------------------------------------------+
                              |
+-------------------------------------------------------------+
|  DOMAIN                                                      |
|  - Pure Swift models (no SwiftData)                          |
|  - UseCases orchestrate repositories                         |
|  - No persistence framework imports                          |
+-------------------------------------------------------------+
                              |
+-------------------------------------------------------------+
|  DATA                                                        |
|  - SwiftData models (ArticleSDModel)                         |
|  - Repositories use ModelExecutor                            |
|  - Map SD models <-> Domain models                           |
|  - Handle migrations                                         |
+-------------------------------------------------------------+
```

---

## Testing SwiftData

### In-Memory Container for Tests

```swift
@MainActor
@Suite("ArticleRepositoryImpl Tests")
struct ArticleRepositoryImplTests {
    // MARK: - Tests

    @Test func saveAndFetch() async throws {
        // Given
        let stack = PersistenceAssembly.makePreviewSwiftDataStack()
        let repository = ArticleRepositoryImpl(modelExecutor: stack.makeBackgroundExecutor(),
                                               modelContainer: stack.container)

        let article = ArticleModel(title: "Test", body: "Content")

        // When
        try await repository.save(article)
        let fetched = try await repository.fetchArticle(id: article.id)

        // Then
        #expect(fetched?.title == "Test")
    }
}
```

`SwiftDataStack` is `@MainActor`, so the suite is `@MainActor`; the repository still works on its own executor. `ModelContainer.preview` is a single in-memory container shared by every test, so use unique IDs (or build a fresh in-memory `ModelContainer` per test) to keep tests independent.

### Mock Repository (No SwiftData in Tests)

Follow the generated mock style: `[Project]Tests/Mocks/<Feature><Type>Mock.swift`, a `final class ... @unchecked Sendable` with `Result` properties and recorded calls.

```swift
// [Project]Tests/Mocks/ArticleRepositoryMock.swift
import Foundation
@testable import MyApp

// MARK: - ArticleRepositoryMock

final class ArticleRepositoryMock: ArticleRepository, @unchecked Sendable {
    // MARK: - Properties

    var fetchArticleResult: Result<ArticleModel?, Error> = .success(nil)
    var savedModels: [ArticleModel] = []

    // MARK: - ArticleRepository

    func fetchArticle(id: UUID) async throws -> ArticleModel? {
        try fetchArticleResult.get()
    }

    func save(_ model: ArticleModel) async throws {
        savedModels.append(model)
    }
}
```
