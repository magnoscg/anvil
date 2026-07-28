# SwiftData Integration Guide

> Patterns for SwiftData persistence in Clean Architecture (iOS 17+).

## Overview

SwiftData provides a declarative approach to data persistence. This guide covers how to integrate it correctly with Clean Architecture while maintaining thread safety.

---

## SwiftData Stack Setup

### ModelContainer Configuration

```swift
// Core/Persistence/ModelContainer+Shared.swift
import SwiftData

extension ModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            ArticleSDModel.self,
            UserSDModel.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// In-memory container for previews and tests
    static let preview: ModelContainer = {
        let schema = Schema([
            ArticleSDModel.self,
            UserSDModel.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
```

### SwiftDataStack for Dependency Injection

```swift
// Core/Persistence/SwiftDataStack.swift
import SwiftData

@MainActor
final class SwiftDataStack {
    let container: ModelContainer

    init(container: ModelContainer = .shared) {
        self.container = container
    }

    /// Creates an isolated ModelExecutor for background operations
    func makeBackgroundExecutor() -> ModelExecutor {
        DefaultSerialModelExecutor(
            modelContext: ModelContext(container)
        )
    }

    /// Main context for UI operations (use sparingly)
    var mainContext: ModelContext {
        container.mainContext
    }
}
```

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

```swift
// Data/Article/Repositories/ArticleRepositoryImpl.swift
struct ArticleRepositoryImpl: ArticleRepository {
    private let modelExecutor: ModelExecutor

    init(modelExecutor: ModelExecutor) {
        self.modelExecutor = modelExecutor
    }

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

    func save(_ model: ArticleModel) async throws {
        try await modelExecutor.perform {
            let descriptor = FetchDescriptor<ArticleSDModel>(
                predicate: #Predicate { $0.id == model.id }
            )

            if let existing = try modelExecutor.modelContext.fetch(descriptor).first {
                existing.update(from: model)
            } else {
                let sdModel = ArticleSDModel(from: model)
                modelExecutor.modelContext.insert(sdModel)
            }

            try modelExecutor.modelContext.save()
        }
    }
}
```

---

## ModelExecutor for Background Operations

### Why ModelExecutor?

- `ModelContext` is **NOT** thread-safe
- Main context blocks UI during heavy operations
- `ModelExecutor` provides isolated context for background work

### DefaultSerialModelExecutor

```swift
// In Factory
@MainActor
enum ArticleFactory {
    static func makeRepository(stack: SwiftDataStack) -> ArticleRepository {
        ArticleRepositoryImpl(
            modelExecutor: stack.makeBackgroundExecutor()
        )
    }
}
```

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
        return sdModels.map { ArticleModel(from: $0) }
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
}
```

### Domain Model (Clean - No SwiftData)

```swift
// Domain/Article/Models/ArticleModel.swift
struct ArticleModel: Sendable, Equatable, Identifiable {
    let id: UUID
    var title: String
    var body: String

    init(id: UUID = UUID(), title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }

    init(from sdModel: ArticleSDModel) {
        self.id = sdModel.id
        self.title = sdModel.title
        self.body = sdModel.body
    }
}
```

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

// Create dedicated executor for background
let executor = DefaultSerialModelExecutor(modelContext: ModelContext(container))

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
@Suite("ArticleRepository Tests")
struct ArticleRepositoryTests {

    @Test func saveAndFetch() async throws {
        // Given
        let container = ModelContainer.preview
        let executor = DefaultSerialModelExecutor(
            modelContext: ModelContext(container)
        )
        let repository = ArticleRepositoryImpl(modelExecutor: executor)

        let article = ArticleModel(title: "Test", body: "Content")

        // When
        try await repository.save(article)
        let fetched = try await repository.fetchArticle(id: article.id)

        // Then
        #expect(fetched?.title == "Test")
    }
}
```

### Mock Repository (No SwiftData in Tests)

```swift
// Tests/Mocks/MockArticleRepository.swift
actor MockArticleRepository: ArticleRepository {
    var articles: [ArticleModel] = []

    func fetchArticle(id: UUID) async throws -> ArticleModel? {
        articles.first { $0.id == id }
    }

    func save(_ model: ArticleModel) async throws {
        articles.append(model)
    }
}
```
