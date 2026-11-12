# UI Testing

> Rules for UI tests on this architecture: accessibility identifiers, test data through the Factory, Page Objects and Screen tests, in the shapes that `anvil init` and `anvil feature` generate.

## When a UI test is worth it

UI tests are optional per project and off by default. They are the slowest and most fragile tests, so a screen gets one only when unit tests cannot protect it.

- Write one only when (1) the flow costs money or data if it breaks (purchase or subscription, sign-in, first launch, account deletion), (2) the screen already had a regression that a unit test would not have caught, or (3) the developer asks for it. Keep at most one smoke flow per app beyond those.
- Everything else is covered by unit tests: ViewModel states and actions, navigation through `RouterMock` in the ViewModel tests, and deep links as a URL → route test (`testing.md`). Forms with validation and loaded, empty and error states belong there, not in Screen tests.
- Layout is checked by eye: one `#Preview` per state, captured in light, dark, Dynamic Type `accessibility3` and the smallest supported iPhone (plus iPad and the longest language when the app supports them).
- Existing UI tests run with `-only-testing` for the screen that changed, with stub data through launch arguments and without `sleep`. The full suite and `performAccessibilityAudit()` run on `release/*` branches.
- `anvil feature` asks about UI tests: answer no unless the screen meets one of the conditions above.

UI tests use XCTest (XCUIAutomation) while the toolchain is Xcode 27.2 or earlier; Swift Testing supports them from Xcode 27.3. Unit tests use Swift Testing (`testing.md`).

## What the generator emits

`anvil init` sets up UI testing once per project:

| File | Role |
|---|---|
| `[Project]UITests/` target | UI Testing Bundle, a testable in every scheme |
| `[Project]UITests/Support/XCUIApplication+UITesting.swift` | `launchForUITesting(screen:fixture:)` |
| `Shared/UITestLaunch.swift` | Launch contract: `--uitesting`, `UITEST_SCREEN`, `UITEST_FIXTURE_<Screen>` |
| `[Project]/Core/Common/Extensions/ProcessInfo+UITesting.swift` | Debug only: `isUITestMode`, `uiTestScreen`, `uiTestFixture(screen:)` |
| `[Project]/App/Navigation/UITestScreenRegistry.swift` | Debug only: the screens a UI test can open as the root view |

`Shared/` is a synchronized folder in both the app and the UI test target: whatever lives there compiles in both, so it imports only Foundation.

Answering yes to the UI tests question of `anvil feature Article` adds five files and wires them:

| File | Role |
|---|---|
| `Shared/AccessibilityIDs/ArticleAccessibilityID.swift` | Identifier strings, read by the View and the Page Object |
| `[Project]/Data/Article/DataStubs/StubArticleRemoteDataSource.swift` | Debug only: data source that answers without network |
| `[Project]/Data/Article/DataStubs/FixtureArticleRemoteDataSource.swift` | Debug only: scenarios and sample DTOs |
| `[Project]UITests/Support/Screens/ArticleScreen.swift` | Page Object |
| `[Project]UITests/Screens/ArticleScreenTests.swift` | Screen tests: loads, shows items, error with retry |

It also applies the identifiers in `ArticleView`, adds the stub branch to `ArticleFactory` and inserts `UITestScreen(name: "Article")` above the `// anvil:ui-test-screens` marker of the registry. The tests pass as generated. A project without that marker (generated before `anvil init` created the UI test target) makes `anvil feature` stop before writing anything.

## Accessibility identifiers

- Tests find elements by `accessibilityIdentifier`, never by label. Labels are localized and reworded; identifiers are invisible to users and stable.
- Format: `<feature_snake>_<element>[_<qualifier>]`, all snake_case. The qualifier is the model id of a repeated element. A feature named `UserProfile` uses the prefix `user_profile`.
- One enum per feature, `<Feature>AccessibilityID` in `Shared/AccessibilityIDs/`, is the only place where the strings are written. New ids go into the enum first, never as literals in a View or a test.

```swift
enum ArticleAccessibilityID {
    static let loadingIndicator = "article_loading"
    static let errorView = "article_error"
    static let retryButton = "article_retry_button"
    static let itemList = "article_item_list"
    static func itemRow(id: String) -> String {
        "article_item_\(id)"
    }
}
```

- Identifier always: buttons, toggles, links, text fields and tappable rows, plus the loading, loaded, empty and error states and the retry button (Screen tests assert on them).
- Identifier when a test reads them: titles, badges and status text. Never: decorative images, spacers, dividers.
- No screen-wide id. SwiftUI hands a container's identifier to its only child and overrides the child's own one, so an id on the view that wraps the `switch` erases the state ids. The Page Object detects the screen through its state elements.

The modifier goes on the element the query names, as the generated `ArticleView` does: rows and retry are `app.buttons`, the `ScrollView` (`itemList`) is `app.scrollViews`, `LoadingStateView` hands its id to the `ProgressView` (`app.activityIndicators`). `ErrorView(error:retryButtonID:)` sets the retry id, and the error container needs `.accessibilityElement(children: .contain)` before its id to be exposed as `app.otherElements`.

## Test data through the Factory

A UI test runs in a separate process and cannot inject mocks. Data enters through the normal architecture, and only the composition root decides what to build: `RootNavigationView` and the Factories. ViewModel, UseCase, Repository and View have no test hook.

1. The test launches with `UITestLaunch.argument` (`--uitesting`), the screen name in `UITEST_SCREEN` and, optionally, a scenario in `UITEST_FIXTURE_<Screen>`. `launchForUITesting(screen:fixture:)` sets all three.
2. In Debug, `RootNavigationView` asks `UITestScreenRegistry` for that screen and shows it as the root view, and skips restoring the saved navigation, so every test starts clean.
3. The Factory builds the stub instead of the Impl:

```swift
static func makeRemoteDataSource(apiClient: APIClient) -> ArticleRemoteDataSource {
    #if DEBUG
    if ProcessInfo.isUITestMode {
        let scenario = ProcessInfo.uiTestFixture(screen: "Article") ?? ""
        return StubArticleRemoteDataSource(fixture: FixtureArticleRemoteDataSource(rawValue: scenario) ?? .default)
    }
    #endif
    return ArticleRemoteDataSourceImpl(apiClient: apiClient)
}
```

- `FixtureArticleRemoteDataSource` is a `String` enum with `default`, `empty` and `error`, plus `defaultItems` (three DTOs, ids `stub-1` to `stub-3`). The stub returns them for `default`, `[]` for `empty` and throws `APIError.httpError(statusCode: 500, data: nil)` for `error`, so the error travels the normal `APIError` → `DomainError` → `ErrorDecorator` path.
- Stubs, fixtures, the registry and `ProcessInfo+UITesting` are wrapped in `#if DEBUG`, and so is the Factory branch: none of them ships in Release.
- Every feature generated with UI tests uses its stub in UI test mode, so a test never hits the network. A new scenario is a new fixture case plus its branch in the stub.

## Target layout and test levels

- Screen tests live in `[Project]UITests/Screens/` and Page Objects in `[Project]UITests/Support/Screens/`. A Screen test exercises one screen on stub data. Add the empty state and the main interaction to the scaffolded ones.
- Flow tests are not scaffolded. Add them by hand as `[Project]UITests/Flows/<Journey>FlowTests.swift`: one user journey across screens, composed from several Page Objects, each step wrapped in `XCTContext.runActivity(named:)` so the report names the step that failed.
- Every test launches its own app instance and depends on no other test.

## Page Object

One `<Feature>Screen` struct per screen, `@MainActor` because XCUI types are main-actor isolated. Tests never write `XCUIApplication` queries themselves, so a UI change is fixed in one file. Sections: Launch, Elements (built from the enum), Queries (`Bool` state) and Actions (waits and taps).

```swift
@MainActor
struct ArticleScreen {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Launch

    static func launch(fixture: String? = nil) -> ArticleScreen {
        ArticleScreen(app: .launchForUITesting(screen: "Article", fixture: fixture))
    }

    // MARK: - Elements

    var retryButton: XCUIElement {
        app.buttons[ArticleAccessibilityID.retryButton]
    }
}
```

The generated file also has `screenElement` (whichever of loading, item list or error is on screen), `loadingIndicator`, `errorView`, `itemList`, `item(id:)`, the queries `isLoaded`, `hasItems` and `isShowingError`, and the actions `waitForScreen(timeout:)` (5 s), `waitForItems(timeout:)` and `waitForError(timeout:)` (10 s), `tapItem(id:)` and `tapRetry()`. `fixture` takes a raw value of the fixture enum, which the UI test target cannot see.

## Screen test

```swift
import XCTest

final class ArticleScreenTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testErrorScenarioShowsRetryButton() {
        let screen = ArticleScreen.launch(fixture: "error")

        screen.waitForError()

        XCTAssertTrue(screen.retryButton.exists, "Retry button should be displayed")
    }
}
```

- `setUpWithError` and `tearDownWithError` are nonisolated overrides. Launch the app from a `@MainActor` test through the Page Object, never from `setUp`.
- If the UI test target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (the generated one does not), declare the class `nonisolated final class`; otherwise its inherited initializers conflict with `XCTestCase` (build-setting modes: `swift-concurrency.md`).
- No comments inside test bodies: blank lines separate the phases.

## Stability rules

- Never `sleep()`. Wait for a condition (`waitForExistence(timeout:)`, or a predicate expectation for disappearance) and assert after the wait; a fixed delay is slower and flakier.
- Appearance, Dynamic Type and network conditions are simulator or host state. Do not drive them from launch arguments or test plan configurations: UIKit ignores `-UIUserInterfaceStyle`, a test plan has no appearance or network option, and no argument selects a network profile. Set them on the simulator and verify visually with `xcui` and `devicectl` (`tooling.md`), which also holds the commands to build and run the tests.

Deeper reference (Axiom plugin, if installed): `axiom-testing` (`skills/ui-testing.md`, `skills/xctest-automation.md`, `skills/ui-recording.md`) for waiting patterns, recording, test plans, network conditioning and CI.
