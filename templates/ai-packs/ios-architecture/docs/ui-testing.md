# UI Testing

> Rules for UI tests on this architecture: accessibility identifiers, test data through the Factory, Page Objects and Screen tests, in the shapes that `anvil feature` scaffolds.

## When a UI test is worth it

UI tests are optional per project. They are the slowest and most fragile tests, so they cover only what unit tests cannot: a user-visible journey through real navigation.

- Write one for multi-step flows (onboarding, sign-in, purchase), forms with validation, tabs with nested stacks, and screens whose loaded, empty and error states matter. Skip it for read-only data display; ViewModel tests cover that (`testing.md`).
- Rule of thumb: if breaking the flow would lose money or users, it gets a UI test.

UI tests use XCTest (XCUIAutomation) while the toolchain is Xcode 27.2 or earlier; Swift Testing supports them from Xcode 27.3. Unit tests use Swift Testing (`testing.md`).

## What the generator emits

Answering yes to the UI tests question of `anvil feature Article` adds five files:

| File | Emitted in | Role |
|---|---|---|
| `ArticleAccessibilityID.swift` | `[Project]/Features/Article/UI/` | Identifier strings |
| `StubArticleRemoteDataSource.swift` | `[Project]Tests/DataStubs/Article/` | Data source that answers without network |
| `FixtureArticleRemoteDataSource.swift` | `[Project]Tests/DataStubs/Article/` | Scenarios and sample DTOs |
| `ArticleScreen.swift` | `[Project]Tests/UITests/Support/Screens/` | Page Object |
| `ArticleScreenTests.swift` | `[Project]Tests/UITests/Screens/` | Screen tests |

The generator creates neither a UI test target nor the app-side wiring. Finish it by hand, steps 1 and 2 right after scaffolding (until then `ArticleScreen.swift` sits in the unit-test target, which cannot see `ArticleAccessibilityID`):

1. Add a UI Testing Bundle target, `[Project]UITests`, in Xcode and move the contents of `[Project]Tests/UITests/` into its folder. XCUIAutomation runs from that kind of target; the generated project only has the app and the unit-test target.
2. Give `ArticleAccessibilityID.swift` membership in the UI test target too (File inspector, Target Membership). UI tests run in another process and cannot import the app module.
3. Apply the identifiers in `ArticleView` and wire the stubs into the Factory (next two sections).

## Accessibility identifiers

- Tests find elements by `accessibilityIdentifier`, never by label. Labels are localized and reworded; identifiers are invisible to users and stable.
- Format: `<feature_snake>_<element>[_<qualifier>]`, all snake_case. The qualifier is the model id of a repeated element. A feature named `UserProfile` uses the prefix `user_profile`.
- One enum per feature, `<Feature>AccessibilityID`, is the only place where the strings are written. The View and the Page Object both reference it, so a rename cannot leave them out of sync. New ids go into the enum first, never as literals in a View or a test.

```swift
enum ArticleAccessibilityID {
    static let screen = "article_screen"
    static let navigationTitle = "article_navigation_title"
    static let loadingIndicator = "article_loading"
    static let errorView = "article_error"
    static let retryButton = "article_retry_button"
    static let itemList = "article_item_list"
    static func itemRow(id: String) -> String {
        "article_item_\(id)"
    }
}
```

- Identifier always: buttons, toggles, links, text fields and tappable rows, plus the screen container, its loading, error and empty states and the retry button (Screen tests assert on them).
- Identifier when a test reads them: titles, badges and status text. Never: decorative images, spacers, dividers.

The generated `ArticleView` does not apply the identifiers; add them where the Page Object looks for them:

```swift
Button {
    viewModel.navigateToDetail(id: item.id)
} label: {
    Text(item.displayName)
}
.accessibilityIdentifier(ArticleAccessibilityID.itemRow(id: item.id))
```

The modifier goes on the element the query names: `app.buttons` for rows and retry, `app.scrollViews` for the `ScrollView` (`itemList`), `app.activityIndicators` for the `ProgressView`. A container queried through `app.otherElements` (`screen`, `errorView`) needs `.accessibilityElement(children: .contain)` before the identifier; otherwise SwiftUI hands the identifier down to its children instead of exposing the container.

## Test data through the Factory

A UI test runs in a separate process and cannot inject mocks. Data enters through the normal architecture, and only the Factory (the composition root) decides which data source to build. Zero changes in ViewModel, UseCase, Repository or View: a test hook there ships to production and changes the code under test.

- Launch argument: `--uitesting`, set by the test before `launch()` and read by the app in one place.
- Stub: `StubArticleRemoteDataSource(fixture:)` conforms to `ArticleRemoteDataSource` and answers according to the scenario it receives.
- Fixture: `FixtureArticleRemoteDataSource` is a `String` enum with the scenarios `default`, `empty` and `error`, plus `defaultItems` (three DTOs, ids `stub-1` to `stub-3`). The stub returns them for `default`, `[]` for `empty` and throws for `error`.

The app cannot load types from a test bundle. Move both files from `[Project]Tests/DataStubs/Article/` to `[Project]/Data/Article/DataStubs/`, delete their `@testable import` line and wrap each file in `#if DEBUG` so they never ship in Release. Then add the accessor (`Core/Common/Extensions/`) and the branch in `ArticleFactory`:

```swift
#if DEBUG
extension ProcessInfo {
    static var isUITestMode: Bool {
        processInfo.arguments.contains("--uitesting")
    }
}
#endif

static func makeRemoteDataSource(apiClient: APIClient) -> ArticleRemoteDataSource {
    #if DEBUG
    if ProcessInfo.isUITestMode {
        let scenario = ProcessInfo.processInfo.environment["FIXTURE_ARTICLE"] ?? ""
        return StubArticleRemoteDataSource(fixture: FixtureArticleRemoteDataSource(rawValue: scenario) ?? .default)
    }
    #endif
    return ArticleRemoteDataSourceImpl(apiClient: apiClient)
}
```

The branch needs its own `#if DEBUG`: the stub types do not exist in Release. The generator emits the scenarios but no selector; `FIXTURE_<FEATURE>` in the launch environment, carrying the case raw value, is the convention to add by hand. A test selects a scenario with `app.launchEnvironment["FIXTURE_ARTICLE"] = "error"` before `launch()`.

## Target layout and test levels

- Screen tests live in `[Project]UITests/Screens/` and Page Objects in `[Project]UITests/Support/Screens/`. A Screen test exercises one screen on stub data. The scaffold covers "loads" and "shows items"; add empty, error with retry and the main interaction.
- Flow tests are not scaffolded. Add them by hand as `[Project]UITests/Flows/<Journey>FlowTests.swift`: one user journey across screens, composed from several Page Objects, each step wrapped in `XCTContext.runActivity(named:)` so the report names the step that failed.
- Every test launches its own app instance and depends on no other test.

## Page Object

One `<Feature>Screen` struct per screen. Tests never write `XCUIApplication` queries themselves, so a UI change is fixed in one file. Three sections: Elements (built from the enum), Queries (`Bool` state) and Actions (waits and taps).

```swift
@MainActor
struct ArticleScreen {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var screenElement: XCUIElement {
        app.otherElements[ArticleAccessibilityID.screen]
    }

    // MARK: - Queries

    var isLoaded: Bool {
        screenElement.exists
    }

    // MARK: - Actions

    func waitForScreen(timeout: TimeInterval = 5) {
        _ = screenElement.waitForExistence(timeout: timeout)
    }
}
```

The scaffolded file follows the same pattern for `loadingIndicator`, `errorView`, `retryButton`, `itemList`, `hasItems`, `waitForItems(timeout:)` (10 s), `tapItem(id:)` and `tapRetry()`. `@MainActor` is required: XCUI types are main-actor isolated and every query is a Swift 6 diagnostic without it. Add it if the scaffolded file lacks it.

## Screen test

```swift
import XCTest

final class ArticleScreenTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testScreenLoadsSuccessfully() {
        let screen = launchScreen()

        screen.waitForScreen()

        XCTAssertTrue(screen.isLoaded, "Article screen should be loaded")
    }

    @MainActor
    private func launchScreen() -> ArticleScreen {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        return ArticleScreen(app: app)
    }
}
```

- `setUpWithError` and `tearDownWithError` are nonisolated overrides. Create and launch `XCUIApplication` from a `@MainActor` test or helper, not from `setUp`, and keep the test methods `@MainActor`.
- If the UI test target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, declare the class `nonisolated final class`; otherwise its inherited initializers conflict with `XCTestCase` (build-setting modes: `swift-concurrency.md`).
- No comments inside test bodies: blank lines separate the phases.

## Stability rules

- Never `sleep()`. Wait for a condition (`waitForExistence(timeout:)`, or a predicate expectation for disappearance) and assert after the wait; a fixed delay is slower and flakier.
- Appearance, Dynamic Type and network conditions are simulator or host state. Do not drive them from launch arguments or test plan configurations: UIKit ignores `-UIUserInterfaceStyle`, a test plan has no appearance or network option, and no argument selects a network profile. Set them on the simulator and verify visually with `xcui` and `devicectl` (`tooling.md`), which also holds the commands to build and run the UI test target.

Deeper reference (Axiom plugin, if installed): `axiom-testing` (`skills/ui-testing.md`, `skills/xctest-automation.md`, `skills/ui-recording.md`) for waiting patterns, recording, test plans, network conditioning and CI.
