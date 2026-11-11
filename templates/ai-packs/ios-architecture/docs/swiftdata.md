# SwiftData

How the optional SwiftData stack fits the architecture: wiring, the repository actor, models, migrations and tests. Isolation modes and `Sendable` rules are in `swift-concurrency.md`.

SwiftData is optional: `anvil init` generates the stack only when SwiftData is selected. Without it none of the files below exist; to add persistence later, create them by hand as described here.

**OS floor.** The floor is the project's deployment target (`IPHONEOS_DEPLOYMENT_TARGET`, iOS 18.0 by default), not SwiftData's own iOS 17. What this document uses works from iOS 17; `#Unique` and `#Index` need iOS 18 and model inheritance needs iOS 26. An API newer than the deployment target needs `@available` on the declaration or `#available` at the call site, plus a fallback for the older systems.

## What the generator creates

| File | Role |
|---|---|
| `Core/Persistence/SwiftDataStack.swift` | `@MainActor final class`: owns the `ModelContainer` and vends one `ModelExecutor` per repository |
| `Core/Persistence/ModelContainerShared.swift` | `ModelContainer.shared` (on disk) and `ModelContainer.preview` (in memory, for previews) |
| `App/DI/PersistenceAssembly.swift` | `@MainActor enum`: `makeSwiftDataStack()`, `makePreviewSwiftDataStack()`, `makeExecutor(from:)` |

- `@main` (`App/Application/AppMain.swift`) creates one `SwiftDataStack`, passes it to `AppDependencies(swiftDataStack:)` and attaches `.modelContainer(swiftDataStack.container)` to the `WindowGroup`.
- Factories reach the stack as `dependencies.swiftDataStack`.
- The generated schema is empty. Add every `@Model` type to the `Schema([...])` of both `shared` and `preview`, and keep the two lists identical. Known deviation: this file is the only place where Core names Data types.

```swift
// Core/Persistence/SwiftDataStack.swift
@MainActor
final class SwiftDataStack {
    let container: ModelContainer

    init(container: ModelContainer = .shared) {
        self.container = container
    }

    func makeBackgroundExecutor() -> ModelExecutor {
        DefaultSerialModelExecutor(
            modelContext: ModelContext(container)
        )
    }
}
```

There is no `mainContext` accessor on purpose: repositories never use the main `ModelContext`.

## Rules

- **Domain stays pure.** No `import SwiftData` in `Domain/`. `ArticleModel` is a `Sendable` struct and `ArticleRepository` (`Domain/Article/Repositories/`) is a plain `Sendable` protocol, so Domain compiles and is tested without the persistence framework.
- **`@Model` types belong to Data.** They are named `<Name>SDModel` and live in `Data/<Feature>/Models/`. The mapping to and from Domain lives in Data too: `toDomain()`, `init(from:)` and `update(from:)` on the SD model, or a mapper in `Data/<Feature>/Mappers/`. A Domain type never gets an initializer that takes an SD model.
- **Models never cross isolation.** `@Model` objects and `ModelContext` are not `Sendable`: pass ids in and Domain models out. In Swift 6 language mode sending one to another actor is a compile error, not a crash to hunt down later.
- **Never put `@MainActor` on a `@Model` class.** The macro adds nonisolated conformances, so the annotation does not compile, and the model has to be usable from the repository's actor.
- **One executor per repository.** Its Factory calls `makeBackgroundExecutor()` once for each repository it builds. An executor wraps one `ModelContext`: two repositories sharing it would share unsaved changes and wait on each other.
- **`@Query` only in Views, never in ViewModels, and only as an exception.** `ARCHITECTURE.md` keeps SwiftData out of Presentation. `@Query` is the one exception, because it reads the container from the SwiftUI environment and hands the View SD models, which are Data types. Keep it for a read-only list with no logic; everything else goes through UseCase and Repository.

## Repository

```swift
// Data/Article/Repositories/ArticleRepositoryImpl.swift
actor ArticleRepositoryImpl: ArticleRepository, ModelActor {
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    init(modelExecutor: any ModelExecutor, modelContainer: ModelContainer) {
        self.modelExecutor = modelExecutor
        self.modelContainer = modelContainer
    }

    func fetch() async throws -> [ArticleModel] {
        try await DomainError.catching {
            let descriptor = FetchDescriptor<ArticleSDModel>(sortBy: [SortDescriptor(\.name)])
            return try modelContext.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func save(_ model: ArticleModel) async throws {
        try await DomainError.catching {
            let articleId = model.id
            let descriptor = FetchDescriptor<ArticleSDModel>(predicate: #Predicate { $0.id == articleId })

            if let existing = try modelContext.fetch(descriptor).first {
                existing.update(from: model)
            } else {
                modelContext.insert(ArticleSDModel(from: model))
            }
            try modelContext.save()
        }
    }
}
```

- **`actor` + `ModelActor`.** `ModelExecutor` only exposes `modelContext`; it cannot run a closure for you. Conforming the actor to `ModelActor` makes `modelExecutor` the actor's executor and provides `modelContext`, so every method body runs on that executor with that context.
- **The executor is injected.** This is what the `@ModelActor` macro generates, except that the macro's `init(modelContainer:)` builds its own executor. Injecting it lets the Factory decide where it comes from and lets a test pass its own.
- **`DomainError.catching` around every method.** Only `DomainError` and `CancellationError` leave the repository; a SwiftData error becomes `.unknown`. It runs in the caller's isolation (`#isolation`), which is why its closure can use the actor's `modelContext`.
- **Copy the value a predicate compares into a local constant first** (`let articleId = model.id`). `#Predicate` cannot capture a Domain struct, so `$0.id == model.id` does not compile.

The Factory builds it. The generated Factory threads `dependencies.apiClient` through its private `make` helpers; a SwiftData feature threads `dependencies.swiftDataStack` the same way from `makeView(appRouter:dependencies:)`:

```swift
// Features/Article/DI/ArticleFactory.swift (excerpt)
private extension ArticleFactory {
    static func makeRepository(swiftDataStack: SwiftDataStack) -> ArticleRepository {
        ArticleRepositoryImpl(modelExecutor: swiftDataStack.makeBackgroundExecutor(),
                              modelContainer: swiftDataStack.container)
    }
}
```

**Where the work runs.** The executor guarantees serial access to its `ModelContext`; it does not guarantee a background thread. With the generated build settings (mode 1 in `swift-concurrency.md`) the UseCase has already left the main actor when it calls the repository. With `SWIFT_APPROACHABLE_CONCURRENCY = YES` or `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` the call arrives from the main actor, and on macOS the repository's methods have then been observed running on the main thread; this has not been measured on iOS. Measure before assuming background execution. If a fetch or a save is heavy enough to matter, enter the repository from a `@concurrent` function in Data, which kept the work off the main thread in the same measurement.

## Model

```swift
// Data/Article/Models/ArticleSDModel.swift
@Model
final class ArticleSDModel {
    @Attribute(.unique) var id: String
    var name: String
    var summary: String

    init(id: String, name: String, summary: String) {
        self.id = id
        self.name = name
        self.summary = summary
    }

    convenience init(from model: ArticleModel) {
        self.init(id: model.id, name: model.name, summary: model.description)
    }

    func update(from model: ArticleModel) {
        name = model.name
        summary = model.description
    }

    func toDomain() -> ArticleModel {
        ArticleModel(id: id, name: name, description: summary)
    }
}
```

- `final class`, never a `struct`. Relationships are optional and state their delete rule: `@Relationship(deleteRule: .cascade) var comments: [CommentSDModel]?`.
- A stored property of a `@Model` cannot be named `description` (the macro rejects it), which is why the SD model stores `summary` and the mapping translates. Differences like this are the reason the mapping lives in Data.

## Migrations

- **Location.** `Data/Persistence/Migrations/`: one file per schema version (`ArticleSchemaV1.swift`, `ArticleSchemaV2.swift`) and one for the plan (`ArticleMigrationPlan.swift`).
- **Lightweight changes need no plan:** adding a property with a default value, removing a property, renaming one with `@Attribute(originalName:)`. Anything else (a type change, uniqueness added over existing rows, splitting a model) needs a `VersionedSchema` per version and a `SchemaMigrationPlan`.
- **Each `VersionedSchema` lists every model of its version.** An old version nests a frozen copy of its models (`ArticleSchemaV1.ArticleSDModel`); the newest lists the live types. `versionIdentifier` is a `static let`: a `var` there is mutable global state, which Swift 6 language mode rejects.
- **`MigrationStage.custom` takes both closures**, `willMigrate:` and `didMigrate:`; pass `nil` for the one you don't need. `willMigrate` sees only the old schema and `didMigrate` only the new one.
- **Pass the plan to the container**, or it never runs. The generated `ModelContainer.shared` does not pass one: change it to `ModelContainer(for: schema, migrationPlan: ArticleMigrationPlan.self, configurations: [configuration])`.

```swift
// Data/Persistence/Migrations/ArticleSchemaV2.swift
enum ArticleSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [ArticleSDModel.self] }
}

// Data/Persistence/Migrations/ArticleMigrationPlan.swift
enum ArticleMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ArticleSchemaV1.self, ArticleSchemaV2.self] }
    static var stages: [MigrationStage] { [migrateV1toV2] }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: ArticleSchemaV1.self,
        toVersion: ArticleSchemaV2.self,
        willMigrate: { context in
            let articles = try context.fetch(FetchDescriptor<ArticleSchemaV1.ArticleSDModel>())
            var seenIds = Set<String>()
            for article in articles where !seenIds.insert(article.id).inserted {
                context.delete(article)
            }
            try context.save()
        },
        didMigrate: nil
    )
}
```

- **Test every migration.** Create a store at a temporary URL with the old schema (`Schema(versionedSchema: ArticleSchemaV1.self)`), insert rows, reopen it with the plan and assert on the result. Before shipping, also run the upgrade on a real device over data written by the previous release.
- **Keep migration tests from running in parallel with other SwiftData suites.** They load an old schema whose models have the same names as the live ones. On macOS, with an old schema that lacked a property of the live model, repository tests running at the same time silently lost that property's values; this has not been measured on iOS. Nesting the SwiftData suites under one `@Suite(.serialized)` parent removed the problem.

## Tests

- **No `@MainActor` on the repository suite:** the SUT is an `actor`. Build the container and the executor in the suite's `init`, not through `SwiftDataStack` or `PersistenceAssembly`, which are `@MainActor`.
- **A new in-memory container per test.** Swift Testing creates the suite once per test, so `init` gives each test its own empty store. `ModelContainer.preview` is a single shared instance: use it for previews (`PersistenceAssembly.makePreviewSwiftDataStack()`), not for tests.
- **The layers above never see SwiftData.** UseCase and ViewModel tests use `ArticleRepositoryMock`, a `final class ArticleRepositoryMock: ArticleRepository, @unchecked Sendable` like every generated mock.
- Body style (no comments, blank lines between phases), `try #require`, `#expect(throws:)` and the mock rules are in `testing.md`; commands are in `tooling.md`.

```swift
// [Project]Tests/Data/Article/Repositories/ArticleRepositoryTests.swift
@Suite("ArticleRepositoryImpl Tests")
struct ArticleRepositoryImplTests {
    private var sut: ArticleRepositoryImpl

    init() throws {
        let container = try ModelContainer(for: ArticleSDModel.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        sut = ArticleRepositoryImpl(modelExecutor: DefaultSerialModelExecutor(modelContext: ModelContext(container)),
                                    modelContainer: container)
    }

    @Test("Given a saved article, when fetch, then returns it")
    func save_thenFetch_returnsSavedArticle() async throws {
        let article = ArticleModel(id: "1", name: "First", description: "First item")

        try await sut.save(article)
        let fetched = try await sut.fetch()

        #expect(fetched == [article])
    }
}
```

Deeper reference (Axiom plugin, if installed): `axiom-data` (`skills/swiftdata.md` for modeling, relationships, `#Index`, predicates, CloudKit and performance; `skills/swiftdata-migration.md` for custom migration patterns and the testing checklist, whose samples declare `versionIdentifier` as a `var`: write `static let`), and the `swiftdata-auditor` agent.
