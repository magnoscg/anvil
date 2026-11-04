# create-ui-tests.md — Quick UI Test Templates (XCTest)

> Full reference in `ui-testing.md`. This doc is just copy-paste.
> Related skills: `axiom-ui-testing`, `axiom-xctest-automation`

## AccessibilityID Enum

```swift
// Features/[Feature]/UI/[Feature]AccessibilityID.swift
enum [Feature]AccessibilityID {

    // MARK: - Screen Containers

    static let loadingIndicator = "[feature].loadingIndicator"
    static let errorView = "[feature].errorView"
    static let retryButton = "[feature].retryButton"
    static let emptyView = "[feature].emptyView"

    // MARK: - List

    static let list = "[feature].list"
    static func row(id: String) -> String { "[feature].row.\(id)" }

    // MARK: - Detail

    static let title = "[feature].title"
    static let subtitle = "[feature].subtitle"

    // MARK: - Actions

    static let favoriteButton = "[feature].favoriteButton"
    static let deleteButton = "[feature].deleteButton"
    static let shareButton = "[feature].shareButton"
}
```

## Stub DataSource

```swift
// Features/[Feature]/DataStubs/Stub[Feature]RemoteDataSource.swift
#if DEBUG
import Foundation

struct Stub[Feature]RemoteDataSource: [Feature]RemoteDataSource {

    func fetch[Feature]s() async throws -> [[Feature]DTO] {
        [
            [Feature]DTO(
                id: "stub-1",
                title: "UI Test [Feature] One",
                // ... fill with test data matching your DTO
            ),
            [Feature]DTO(
                id: "stub-2",
                title: "UI Test [Feature] Two",
                // ...
            )
        ]
    }
}
#endif
```

## Fixture DataSource

```swift
// Features/[Feature]/DataStubs/Fixture[Feature]RemoteDataSource.swift
#if DEBUG
import Foundation

struct Fixture[Feature]RemoteDataSource: [Feature]RemoteDataSource {
    let fixtureName: String

    func fetch[Feature]s() async throws -> [[Feature]DTO] {
        guard let url = Bundle.main.url(forResource: fixtureName, withExtension: "json") else {
            throw NSError(domain: "Fixture", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Fixture \(fixtureName).json not found"
            ])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([[Feature]DTO].self, from: data)
    }
}
#endif
```

## JSON Fixture Files

```json
// Resources/Fixtures/[feature]-list.json
[
  {
    "id": "fix-1",
    "title": "Fixture [Feature] 1"
  },
  {
    "id": "fix-2",
    "title": "Fixture [Feature] 2"
  }
]
```

```json
// Resources/Fixtures/[feature]-empty.json
[]
```

## Factory Integration

```swift
// In Features/[Feature]/DI/[Feature]Factory.swift — add to existing Factory

// MARK: - UI Test Detection

static var isUITestMode: Bool {
    CommandLine.arguments.contains("-UITestMode")
}

// Modify existing makeRemoteDataSource:

private static func makeRemoteDataSource() -> [Feature]RemoteDataSource {
    #if DEBUG
    if let fixtureName = ProcessInfo.processInfo.environment["FIXTURE_[feature]"] {
        return Fixture[Feature]RemoteDataSource(fixtureName: fixtureName)
    }
    if isUITestMode {
        return Stub[Feature]RemoteDataSource()
    }
    #endif
    return [Feature]RemoteDataSourceImpl(apiClient: makeAPIClient())
}
```

## Page Object (Screen)

```swift
// [Project]UITests/Support/Screens/[Feature]Screen.swift
import XCTest

final class [Feature]Screen {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var loadingIndicator: XCUIElement {
        app.activityIndicators["[feature].loadingIndicator"]
    }

    var errorView: XCUIElement {
        app.otherElements["[feature].errorView"]
    }

    var retryButton: XCUIElement {
        app.buttons["[feature].retryButton"]
    }

    var emptyView: XCUIElement {
        app.otherElements["[feature].emptyView"]
    }

    var list: XCUIElement {
        app.collectionViews["[feature].list"].firstMatch
    }

    func row(id: String) -> XCUIElement {
        app.cells["[feature].row.\(id)"]
    }

    // MARK: - State Queries

    var isLoaded: Bool {
        list.waitForExistence(timeout: 5)
    }

    var isError: Bool {
        errorView.waitForExistence(timeout: 5)
    }

    var isEmpty: Bool {
        emptyView.waitForExistence(timeout: 5)
    }

    var itemCount: Int {
        app.cells.matching(
            NSPredicate(format: "identifier BEGINSWITH '[feature].row.'")
        ).count
    }

    // MARK: - Actions

    func tapRow(id: String) {
        let cell = row(id: id)
        XCTAssertTrue(cell.waitForExistence(timeout: 5), "Row \(id) should exist")
        cell.tap()
    }

    func tapRetry() {
        XCTAssertTrue(retryButton.waitForExistence(timeout: 5))
        retryButton.tap()
    }

    func pullToRefresh() {
        list.swipeDown()
    }
}
```

## Screen Test

```swift
// [Project]UITests/Screens/[Feature]/[Feature]ScreenTests.swift
import XCTest

final class [Feature]ScreenTests: XCTestCase {

    private var app: XCUIApplication!
    private var screen: [Feature]Screen!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        screen = [Feature]Screen(app: app)
    }

    override func tearDownWithError() throws {
        if testRun?.failureCount ?? 0 > 0 {
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Failure-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        app.terminate()
    }

    // MARK: - Loaded State

    func testLoadedState() {
        app.launchArguments = ["-UITestMode"]
        app.launch()

        XCTAssertTrue(screen.isLoaded, "[Feature] list should be visible")
        XCTAssertGreaterThan(screen.itemCount, 0, "List should have items")
    }

    // MARK: - Empty State

    func testEmptyState() {
        app.launchArguments = ["-UITestMode"]
        app.launchEnvironment["FIXTURE_[feature]"] = "[feature]-empty"
        app.launch()

        XCTAssertTrue(screen.isEmpty, "Empty view should be visible")
    }

    // MARK: - Error State

    func testErrorState() {
        app.launchArguments = ["-UITestMode"]
        app.launchEnvironment["FIXTURE_[feature]"] = "[feature]-error"
        app.launch()

        XCTAssertTrue(screen.isError, "Error view should be visible")
        XCTAssertTrue(screen.retryButton.exists, "Retry button should be visible")
    }

    // MARK: - Interaction

    func testTapItemNavigatesToDetail() {
        app.launchArguments = ["-UITestMode"]
        app.launch()

        XCTAssertTrue(screen.isLoaded)
        screen.tapRow(id: "stub-1")

        let detailTitle = app.staticTexts["[feature].title"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 5), "Detail should appear")
    }

    // MARK: - Accessibility

    func testAccessibilityAudit() throws {
        app.launchArguments = ["-UITestMode"]
        app.launch()

        XCTAssertTrue(screen.isLoaded)
        try app.performAccessibilityAudit()
    }
}
```

## Flow Test (E2E)

```swift
// [Project]UITests/Flows/[FlowName]FlowTests.swift
import XCTest

final class [FlowName]FlowTests: XCTestCase {

    private var app: XCUIApplication!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-ClearDataOnLaunch"]
        app.launch()
    }

    override func tearDownWithError() throws {
        if testRun?.failureCount ?? 0 > 0 {
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Failure-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        app.terminate()
    }

    // MARK: - Flow

    func test[FlowName]CompletesSuccessfully() {
        // Step 1: First screen
        XCTContext.runActivity(named: "Verify initial screen") { _ in
            let firstScreen = [Feature1]Screen(app: app)
            XCTAssertTrue(firstScreen.isLoaded, "First screen should load")
        }

        // Step 2: Navigate forward
        XCTContext.runActivity(named: "Navigate to second screen") { _ in
            let firstScreen = [Feature1]Screen(app: app)
            firstScreen.tapRow(id: "stub-1")

            let secondScreen = [Feature2]Screen(app: app)
            XCTAssertTrue(secondScreen.isLoaded, "Second screen should appear")
        }

        // Step 3: Perform action
        XCTContext.runActivity(named: "Perform action on second screen") { _ in
            let secondScreen = [Feature2]Screen(app: app)
            secondScreen.tapAction()
        }

        // Step 4: Verify result
        XCTContext.runActivity(named: "Verify result") { _ in
            let resultElement = app.staticTexts["expected.result.identifier"]
            XCTAssertTrue(resultElement.waitForExistence(timeout: 5))
        }
    }
}
```

## XCUIApplication+Launch Extension

```swift
// [Project]UITests/Support/Helpers/XCUIApplication+Launch.swift
import XCTest

extension XCUIApplication {

    /// Launch app configured for UI testing with deterministic data
    func launchForTesting(
        clearData: Bool = true,
        disableAnimations: Bool = true,
        fixture: (feature: String, name: String)? = nil
    ) {
        launchArguments = ["-UITestMode"]

        if clearData {
            launchArguments.append("-ClearDataOnLaunch")
        }
        if disableAnimations {
            launchArguments.append("-DisableAnimations")
        }
        if let fixture {
            launchEnvironment["FIXTURE_\(fixture.feature)"] = fixture.name
        }

        launch()
    }
}
```

## XCUIElement+Wait Extensions

```swift
// [Project]UITests/Support/Helpers/XCUIElement+Wait.swift
import XCTest

extension XCUIElement {

    /// Wait for element to disappear
    @discardableResult
    func waitForDisappearance(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Wait for element to be hittable (visible AND enabled)
    @discardableResult
    func waitForHittable(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Clear text from a text field
    func clearText() {
        guard let stringValue = value as? String, !stringValue.isEmpty else { return }
        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }

    /// Clear text and type new text
    func clearAndType(_ text: String) {
        clearText()
        typeText(text)
    }
}
```

## UITestLaunchArguments Enum (Test-Side)

```swift
// [Project]UITests/Support/Helpers/UITestLaunchArguments.swift
import Foundation

enum UITestLaunchArguments {
    static let uiTestMode = "-UITestMode"
    static let clearData = "-ClearDataOnLaunch"
    static let disableAnimations = "-DisableAnimations"
    static let useInMemoryStore = "-UseInMemoryStore"
}
```

## App-Side Launch Argument Handler

```swift
// App/Config/UITestLaunchArguments.swift (in main target)
#if DEBUG
enum UITestLaunchArguments {
    static let uiTestMode = "-UITestMode"
    static let clearDataOnLaunch = "-ClearDataOnLaunch"
    static let disableAnimations = "-DisableAnimations"
    static let useInMemoryStore = "-UseInMemoryStore"

    static var isUITestMode: Bool {
        CommandLine.arguments.contains(uiTestMode)
    }

    static func fixture(for feature: String) -> String? {
        ProcessInfo.processInfo.environment["FIXTURE_\(feature)"]
    }
}
#endif

// In @main App struct init:
#if DEBUG
private func handleUITestArguments() {
    if CommandLine.arguments.contains(UITestLaunchArguments.clearDataOnLaunch) {
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!
        )
    }
    if CommandLine.arguments.contains(UITestLaunchArguments.disableAnimations) {
        UIView.setAnimationsEnabled(false)
    }
}
#endif
```

## Test Plan JSON Template

```json
{
  "configurations": [
    {
      "id": "default",
      "name": "Default",
      "options": {
        "language": "en",
        "region": "US",
        "uiTestingScreenshotsLifetime": "keepAlways",
        "testExecutionOrdering": "random"
      }
    },
    {
      "id": "dark-mode",
      "name": "Dark Mode",
      "options": {
        "language": "en",
        "region": "US",
        "userInterfaceStyle": "dark",
        "uiTestingScreenshotsLifetime": "keepAlways"
      }
    },
    {
      "id": "large-text",
      "name": "Large Text",
      "options": {
        "language": "en",
        "region": "US",
        "preferredContentSizeCategory": "XXXL",
        "uiTestingScreenshotsLifetime": "keepAlways"
      }
    },
    {
      "id": "spanish",
      "name": "Spanish",
      "options": {
        "language": "es",
        "region": "ES",
        "uiTestingScreenshotsLifetime": "keepAlways"
      }
    }
  ],
  "defaultOptions": {
    "codeCoverage": false,
    "targetForVariableExpansion": {
      "containerPath": "container:[Project].xcodeproj",
      "identifier": "[Project]UITests"
    }
  },
  "testTargets": [
    {
      "target": {
        "containerPath": "container:[Project].xcodeproj",
        "identifier": "[Project]UITests",
        "name": "[Project]UITests"
      }
    }
  ],
  "version": 1
}
```

## File Structure Summary

```
App-side (main target, #if DEBUG):
Features/[Feature]/
  UI/
    [Feature]AccessibilityID.swift
  DataStubs/
    Stub[Feature]RemoteDataSource.swift
    Fixture[Feature]RemoteDataSource.swift
App/Config/
  UITestLaunchArguments.swift
Resources/Fixtures/
  [feature]-list.json
  [feature]-empty.json

Test target:
[Project]UITests/
├─ Screens/[Feature]/
│  └─ [Feature]ScreenTests.swift
├─ Flows/
│  └─ [FlowName]FlowTests.swift
├─ Support/
│  ├─ Screens/
│  │  └─ [Feature]Screen.swift
│  ├─ Helpers/
│  │  ├─ UITestLaunchArguments.swift
│  │  ├─ XCUIApplication+Launch.swift
│  │  └─ XCUIElement+Wait.swift
│  └─ Data/
│     └─ TestConstants.swift
└─ Resources/
   └─ [Project]UITests.xctestplan
```
