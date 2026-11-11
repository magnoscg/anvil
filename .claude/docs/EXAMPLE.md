# Example/ — deviations from the architecture docs

The architecture rules live in one place: `templates/ai-packs/ios-architecture/docs/`. They describe what
`anvil init` and `anvil feature` generate. `Example/` is an older, hand-written app that follows the same
layers but differs in the points below. When you work in `Example/`, read the pack doc first and then apply
these differences. When you change the pack docs, do not copy them here.

## Build settings

| Setting | Generated project | `Example/` |
|---|---|---|
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | not set | `MainActor` |
| `SWIFT_APPROACHABLE_CONCURRENCY` | not set | `YES` |
| Swift language mode / deployment target | chosen at `anvil init` | Swift 6.0 / iOS 18.0 |

Consequences in `Example/` (see the isolation table in `swift-concurrency.md`):

- Every unannotated type is `@MainActor`, UseCases, Repositories and DataSources included.
- DTOs, DTO mappers and decoding helpers are declared `nonisolated`.
- A `nonisolated async` function stays on the caller's actor. Work that must leave the main actor is marked
  `@concurrent` and lives in a DataSource.
- Test suites are main-actor isolated by default, so an unannotated suite is not evidence of anything.

## Code shape

| Topic | Generated project | `Example/` |
|---|---|---|
| Router lifetime | one `AppRouterImpl` created in `@main` | one per window, owned by `App/Application/AppRootView.swift` |
| Data sources | Remote, Local (UserDefaults), Keychain | Remote, Static, JSON |
| Protocol and `Impl` of DataSources and mappers | one file | separate files |
| DTO mapper method | `map(_:)` | `mapToDomain(_:)` |
| `ErrorDecorator` | `Sendable`, carries `retryAction` | `Equatable`, carries `isRetryable`; `ErrorView(error:onRetry:)` |
| `DomainError` | includes `.unauthorized` | no `.unauthorized`; mapping file is `DomainError+Mapping.swift` |
| `KeychainHelper` | `struct`, injected | static `enum`, `WhenUnlockedThisDeviceOnly` |
| Networking extras | `RetryInterceptor` only | also `LoggingInterceptor`, per-request `decoderFactory` |
| Persistence | optional SwiftData stack | none (only the navigation path, in `@SceneStorage`) |
| Domain folders | one per feature until merged | by concept (`Domain/Pokemon` serves two screens) |

## Known gaps to close in `Example/`

These contradict the pack docs and are not intentional. Fix them here, not in the docs.

- Views store the ViewModel with `self._viewModel = State(initialValue:)` and retry through
  `.task(id:)` plus a toggled flag. The docs and the generator assign `self.viewModel = viewModel` last in
  `init`, load with `.task { }` and retry with a `Task` from the button action.
- Test mocks are named `Mock<Feature><Type>` and most are `actor`s. The docs and the generator use
  `<Feature><Type>Mock`, `final class ... @unchecked Sendable`.
- Test bodies carry `// Given`, `// When`, `// Then` comments, and use `guard case` with `Issue.record`
  where `#expect` and `try #require` apply.
- There is no UI test target and no `accessibilityIdentifier` in the app, so `ui-testing.md` is not
  exercised here.
