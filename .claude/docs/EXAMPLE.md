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
- A mock of an unannotated protocol is `@MainActor` like its caller, so `await mock.execute()` never
  suspends. A test that needs a call in flight (a second `load()` while `.loading`) sets the mock's one-shot
  `onExecute` hook and re-enters the ViewModel from it, instead of racing two calls with `async let`.

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
| Test mocks of UseCases, Repositories and DataSources | `final class ..., @unchecked Sendable` | `final class`, main-actor isolated by default, no `@unchecked Sendable` |

## Known gap to close in `Example/`

This contradicts the pack docs and is not intentional. Fix it here, not in the docs.

- There is no UI test code, no `Shared/` group, no `UITestScreenRegistry` and no `accessibilityIdentifier`
  in the app, so `ui-testing.md` is not exercised here.
