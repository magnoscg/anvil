# UI Testing Rules — XCTest + XCUIAutomation

> Related docs: `testing.md` (unit tests), `create-ui-tests.md` (quick templates)
> Related skills: `axiom:axiom-ui-testing`, `axiom:axiom-xctest-automation`
> WWDC 2025: "Record, replay, and review: UI automation with Xcode" (344)
> Axiom complementa: Network conditioning, multi-factor testing

## Framework

- Use `import XCTest` — UI tests **MUST** use XCTest, NOT Swift Testing.
- `XCUIAutomation` is auto-included when you import XCTest.
- UI tests run in a **separate process** from the app — they cannot access app memory directly.
- Unit tests → Swift Testing (`import Testing`). UI tests → XCTest (`import XCTest`).

## When to Add UI Tests (Optional per Project)

UI tests are **optional**. Not every project needs them.

| Criteria | Add UI Tests? |
|----------|---------------|
| App has > 3 user-facing screens | Consider |
| App has multi-step flows (onboarding, purchase) | YES |
| App has forms with validation | YES |
| App has complex navigation (tabs + nested stacks) | YES |
| App is mostly data display (read-only) | Probably not |
| Solo developer, small app | Start with Screen Tests only |
| Team project, CI/CD pipeline | YES — Screen + Flow Tests |

**Rule of thumb**: If breaking a user flow would lose money or users, add a UI test for it.

---

## Accessibility Identifiers — The Foundation

### Why Identifiers, Not Labels

| Modifier | Purpose | Visible to Users | Localized | Use in Tests |
|----------|---------|-------------------|-----------|--------------|
| `.accessibilityLabel` | VoiceOver reads aloud | YES | YES | NEVER |
| `.accessibilityIdentifier` | Test automation only | NO | NO | ALWAYS |

- `.accessibilityIdentifier` is NOT read by VoiceOver and NOT exposed to users.
- It is stable across languages, app versions, and UI changes.
- **NEVER** use `.accessibilityLabel` for element lookup in UI tests.

### Naming Convention

```
Pattern: [feature].[element].[qualifier?]
```

| Segment | Rule | Example |
|---------|------|---------|
| **feature** | camelCase, matches `[Feature]` from Clean Architecture | `feature`, `pokemonList`, `userProfile` |
| **element** | camelCase, describes the element's role | `favoriteButton`, `title`, `loadingIndicator` |
| **qualifier** | Optional, for dynamic items — use model ID | `feature.row.abc123` |

### Decision Table: When to Add Identifiers

| Element Type | Add Identifier? | Example |
|---|---|---|
| Button, Toggle, Link | **ALWAYS** | `feature.favoriteButton` |
| TextField, SecureField | **ALWAYS** | `profile.emailField` |
| NavigationLink / tappable row | **ALWAYS** | `feature.row.abc123` |
| Title / headline text | YES | `feature.title` |
| Status indicator / badge | YES | `feature.statusBadge` |
| Loading indicator (ProgressView) | YES | `feature.loadingIndicator` |
| Error view container | YES | `feature.errorView` |
| Empty state view | YES | `feature.emptyView` |
| Retry button | YES | `feature.retryButton` |
| Section header | IF TESTABLE | `feature.section.news` |
| Decorative image | NO | — |
| Spacer / Divider | NO | — |

### AccessibilityID Enum (per Feature)

Create one enum per feature in `Features/[Feature]/UI/[Feature]AccessibilityID.swift`:

```swift
// Features/[Feature]/UI/FeatureAccessibilityID.swift
enum FeatureAccessibilityID {

    // MARK: - Screen Containers

    static let loadingIndicator = "feature.loadingIndicator"
    static let errorView = "feature.errorView"
    static let retryButton = "feature.retryButton"
    static let emptyView = "feature.emptyView"

    // MARK: - List

    static let list = "feature.list"
    static func row(id: String) -> String { "feature.row.\(id)" }

    // MARK: - Detail

    static let title = "feature.title"
    static let body = "feature.body"
    static let favoriteButton = "feature.favoriteButton"
    static let shareButton = "feature.shareButton"
}
```

This enum is the **single source of truth** for identifier strings. Used in both Views (app) and Page Objects (tests).

### Applying to Views (Integration with Existing Patterns)

Add `.accessibilityIdentifier()` to the existing View pattern:

```swift
// Features/[Feature]/UI/FeatureView.swift
struct FeatureView: View {
    @State var viewModel: FeatureViewModel

    var body: some View {
        content
            .task { await viewModel.loadFeatures() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .accessibilityIdentifier(FeatureAccessibilityID.loadingIndicator)
        case .loaded(let sections):
            FeatureListContent(sections: sections, onSelect: viewModel.navigateToDetail)
                .accessibilityIdentifier(FeatureAccessibilityID.list)
        case .error(let error):
            ErrorView(error: error, onRetry: { Task { await viewModel.loadFeatures() } })
                .accessibilityIdentifier(FeatureAccessibilityID.errorView)
        }
    }
}

// In list rows
struct FeatureRow: View {
    let decorator: FeatureItemDecorator
    let onSelect: (String) -> Void

    var body: some View {
        Button {
            onSelect(decorator.id)
        } label: {
            VStack(alignment: .leading) {
                Text(decorator.title)
                    .accessibilityIdentifier(FeatureAccessibilityID.title)
                Text(decorator.formattedDate)
            }
        }
        .accessibilityIdentifier(FeatureAccessibilityID.row(id: decorator.id))
    }
}
```

---

## Test Data Strategy

Since UI tests run in a **separate process**, they cannot inject mocks like unit tests. Data must flow through the app's normal architecture.

### Level 1: Stub DataSources (Default — Use This First)

The Factory already is the composition root. Add a launch argument check:

```swift
// Features/[Feature]/DI/FeatureFactory.swift
@MainActor
enum FeatureFactory {

    // MARK: - UI Test Detection

    static var isUITestMode: Bool {
        CommandLine.arguments.contains("-UITestMode")
    }

    // MARK: - Private Factory Methods

    private static func makeRemoteDataSource() -> FeatureRemoteDataSource {
        if isUITestMode {
            return StubFeatureRemoteDataSource()
        }
        return FeatureRemoteDataSourceImpl(apiClient: makeAPIClient())
    }

    // ... rest of Factory unchanged ...
}
```

Create Stub DataSources in `Features/[Feature]/DataStubs/`, wrapped in `#if DEBUG`:

```swift
// Features/[Feature]/DataStubs/StubFeatureRemoteDataSource.swift
#if DEBUG
import Foundation

struct StubFeatureRemoteDataSource: FeatureRemoteDataSource {

    func fetchFeatures() async throws -> [FeatureDTO] {
        [
            FeatureDTO(
                id: "stub-1",
                title: "UI Test Feature One",
                content: "Content for testing",
                publishedAt: "2026-01-15T10:00:00Z",
                authorId: "author-1"
            ),
            FeatureDTO(
                id: "stub-2",
                title: "UI Test Feature Two",
                content: "More test content",
                publishedAt: "2026-01-16T14:30:00Z",
                authorId: "author-2"
            )
        ]
    }
}
#endif
```

**Zero changes** to ViewModel, UseCase, Repository, or View. Only the Factory conditionally swaps the DataSource.

### Level 2: JSON Fixtures (Complex Scenarios)

For tests needing varied data (empty lists, errors, pagination), use JSON fixture files:

```swift
// Features/[Feature]/DataStubs/FixtureFeatureRemoteDataSource.swift
#if DEBUG
import Foundation

struct FixtureFeatureRemoteDataSource: FeatureRemoteDataSource {
    let fixtureName: String

    func fetchFeatures() async throws -> [FeatureDTO] {
        guard let url = Bundle.main.url(forResource: fixtureName, withExtension: "json") else {
            throw NSError(domain: "Fixture", code: 404, userInfo: [NSLocalizedDescriptionKey: "Fixture \(fixtureName) not found"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([FeatureDTO].self, from: data)
    }
}
#endif
```

JSON fixtures live in `[Project]/Resources/Fixtures/` (only in DEBUG build config):

```json
// Resources/Fixtures/features-list.json
[
  {
    "id": "fix-1",
    "title": "Fixture Feature",
    "content": "Fixture content",
    "publishedAt": "2026-03-01T10:00:00Z",
    "authorId": "author-1"
  }
]

// Resources/Fixtures/features-empty.json
[]
```

The Factory selects fixtures via `launchEnvironment`:

```swift
private static func makeRemoteDataSource() -> FeatureRemoteDataSource {
    if let fixtureName = ProcessInfo.processInfo.environment["FIXTURE_features"] {
        return FixtureFeatureRemoteDataSource(fixtureName: fixtureName)
    }
    if isUITestMode {
        return StubFeatureRemoteDataSource()
    }
    return FeatureRemoteDataSourceImpl(apiClient: makeAPIClient())
}
```

UI test controls which fixture:

```swift
app.launchEnvironment["FIXTURE_features"] = "features-empty"
```

### Level 3: In-Memory SwiftData (Persistence Tests)

For features using local persistence. Only applies when the project includes the optional SwiftData stack (see `swiftdata.md`); `Example/` has no SwiftData.

```swift
// Launch arg: -UseInMemoryStore
// In SwiftDataStack or App init:
if CommandLine.arguments.contains("-UseInMemoryStore") {
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    container = try ModelContainer(for: schema, configurations: [config])
}
```

### Complete Data Flow Diagram

```
UI Test (separate process)
  ├─ launchArguments: ["-UITestMode"]
  ├─ launchEnvironment: ["FIXTURE_features": "features-list"]
  │
  ▼
App launches
  ▼
Factory.isUITestMode == true
  ├─ makeRemoteDataSource() → StubDataSource or FixtureDataSource
  ├─ makeRepository() → RepositoryImpl (with stub DataSource)
  ├─ makeUseCase() → UseCaseImpl (unchanged)
  └─ makeViewModel() → ViewModel (unchanged)
  │
  ▼
ViewModel.load() → deterministic data
  ▼
View renders → UI test asserts via accessibilityIdentifier
```

### App-Side Launch Arguments Handler

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
```

Handle in App init:

```swift
@main
struct MyApp: App {
    init() {
        #if DEBUG
        handleUITestArguments()
        #endif
    }

    #if DEBUG
    private func handleUITestArguments() {
        if CommandLine.arguments.contains(UITestLaunchArguments.clearDataOnLaunch) {
            // Clear UserDefaults, keychain, etc.
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
        if CommandLine.arguments.contains(UITestLaunchArguments.disableAnimations) {
            UIView.setAnimationsEnabled(false)
        }
    }
    #endif
}
```

---

## Test File Structure

```
[Project]UITests/
├─ Screens/                              # Screen-level tests (1 screen, all states)
│  └─ [Feature]/
│     └─ [Feature]ScreenTests.swift
├─ Flows/                                # E2E journey tests (multi-screen)
│  └─ [FlowName]FlowTests.swift
├─ Support/
│  ├─ Screens/                           # Page Objects
│  │  └─ [Feature]Screen.swift
│  ├─ Helpers/
│  │  ├─ UITestLaunchArguments.swift     # Launch args enum (test-side)
│  │  ├─ XCUIApplication+Launch.swift    # Launch convenience
│  │  └─ XCUIElement+Wait.swift          # Wait extensions
│  └─ Data/
│     └─ TestConstants.swift             # Expected strings/values
└─ Resources/
   └─ [Project]UITests.xctestplan        # Multi-config test plan

App-side (main target, #if DEBUG):
Features/[Feature]/DataStubs/
  Stub[Feature]RemoteDataSource.swift
[Project]/Resources/Fixtures/
  [feature]-list.json
  [feature]-empty.json

```

---

## Two Test Levels

### Screen Tests

Verify **one screen** renders correctly in **all its states**.

```swift
// [Project]UITests/Screens/[Feature]/FeatureScreenTests.swift
import XCTest

final class FeatureScreenTests: XCTestCase {

    private var app: XCUIApplication!
    private var screen: FeatureScreen!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        screen = FeatureScreen(app: app)
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

        XCTAssertTrue(screen.isLoaded, "Feature list should be visible")
        XCTAssertGreaterThan(screen.itemCount, 0, "List should have items")
    }

    // MARK: - Empty State

    func testEmptyState() {
        app.launchArguments = ["-UITestMode"]
        app.launchEnvironment["FIXTURE_features"] = "features-empty"
        app.launch()

        XCTAssertTrue(screen.isEmpty, "Empty view should be visible")
    }

    // MARK: - Error State

    func testErrorState() {
        app.launchArguments = ["-UITestMode"]
        app.launchEnvironment["FIXTURE_features"] = "features-error"
        app.launch()

        XCTAssertTrue(screen.isError, "Error view should be visible")
        XCTAssertTrue(screen.retryButton.exists, "Retry button should be visible")
    }

    // MARK: - Interaction

    func testTapFeatureNavigatesToDetail() {
        app.launchArguments = ["-UITestMode"]
        app.launch()

        XCTAssertTrue(screen.isLoaded)
        screen.tapRow(id: "stub-1")

        let detailTitle = app.staticTexts["feature.title"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 5), "Detail screen should appear")
    }

    // MARK: - Accessibility Audit

    func testAccessibilityAudit() throws {
        app.launchArguments = ["-UITestMode"]
        app.launch()

        XCTAssertTrue(screen.isLoaded)
        try app.performAccessibilityAudit()
    }
}
```

### Flow Tests (E2E)

Verify **complete user journeys** spanning multiple screens.

```swift
// [Project]UITests/Flows/FeatureBrowsingFlowTests.swift
import XCTest

final class FeatureBrowsingFlowTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestMode"]
        app.launch()
    }

    func testBrowseFeatureAndFavorite() {
        // Step 1: Feature list loads
        let featureScreen = FeatureScreen(app: app)
        XCTAssertTrue(featureScreen.isLoaded, "Feature list should load")

        // Step 2: Tap first feature
        featureScreen.tapRow(id: "stub-1")

        // Step 3: Detail screen appears
        let detailTitle = app.staticTexts["feature.title"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 5))

        // Step 4: Tap favorite
        let favoriteButton = app.buttons["feature.favoriteButton"]
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        favoriteButton.tap()

        // Step 5: Navigate back
        app.navigationBars.buttons.firstMatch.tap()

        // Step 6: List still visible
        XCTAssertTrue(featureScreen.isLoaded)
    }
}
```

---

## Page Object Pattern

One `Screen` class per feature screen. Encapsulates element queries and actions.

```swift
// [Project]UITests/Support/Screens/FeatureScreen.swift
import XCTest

final class FeatureScreen {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var loadingIndicator: XCUIElement {
        app.activityIndicators["feature.loadingIndicator"]
    }

    var errorView: XCUIElement {
        app.otherElements["feature.errorView"]
    }

    var retryButton: XCUIElement {
        app.buttons["feature.retryButton"]
    }

    var emptyView: XCUIElement {
        app.otherElements["feature.emptyView"]
    }

    var list: XCUIElement {
        app.collectionViews["feature.list"].firstMatch
    }

    func row(id: String) -> XCUIElement {
        app.cells["feature.row.\(id)"]
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
            NSPredicate(format: "identifier BEGINSWITH 'feature.row.'")
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

---

## Async Waiting — NEVER sleep()

### Wait for Element to Appear

```swift
let element = app.buttons["feature.favoriteButton"]
XCTAssertTrue(element.waitForExistence(timeout: 5))
```

### Wait for Element to Disappear

```swift
func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    return result == .completed
}

// Usage
let loadingIndicator = app.activityIndicators["feature.loadingIndicator"]
XCTAssertTrue(waitForDisappearance(loadingIndicator))
```

### Wait for Element to Be Hittable

```swift
func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    let predicate = NSPredicate(format: "isHittable == true")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    return result == .completed
}
```

### Wait for Property Change (Xcode 26+)

```swift
let favoriteButton = app.buttons["feature.favoriteButton"]
XCTAssertTrue(
    favoriteButton.wait(for: \.isEnabled, toEqual: true, timeout: 5)
)
```

### Recommended Timeouts

| Scenario | Timeout |
|----------|---------|
| UI animations / transitions | 2-3s |
| Data loads from stub | 5s |
| Data loads from network | 10s |
| Complex operations | 30s max |

---

## Device Configuration

### Setup in setUp

```swift
override func setUpWithError() throws {
    continueAfterFailure = false

    XCUIDevice.shared.orientation = .portrait

    let app = XCUIApplication()
    app.launchArguments = ["-UITestMode"]
    app.launch()
}
```

### Dark Mode

```swift
app.launchArguments += ["-UIUserInterfaceStyle", "dark"]
```

### Location Simulation

```swift
let simulatedLocation = CLLocation(latitude: 28.3114, longitude: -81.5535)
XCUIDevice.shared.location = XCUILocation(location: simulatedLocation)
```

### Accessibility Audit

```swift
func testAccessibilityCompliance() throws {
    app.launchArguments = ["-UITestMode"]
    app.launch()

    try app.performAccessibilityAudit()
}
```

---

## Recording UI Automation (Xcode 26 — WWDC 2025)

### How It Works

1. **Record**: Xcode captures your interactions (taps, swipes, text entry) and generates Swift code
2. **Replay**: Run the generated tests across multiple devices/languages/configs via Test Plans
3. **Review**: Watch video recordings with interaction overlays and failure analysis

### Recording Workflow

1. Open UI test source file in Xcode
2. Click **"Start Recording"** button in editor gutter
3. Interact with app naturally in Simulator
4. Code appears in source editor in real-time
5. Click **"Stop Run"** to finish

### Enhancing Recorded Code

After recording, review and improve:

```swift
// RECORDED (may use labels — fragile)
app.buttons["Login"].tap()

// ENHANCED (uses identifier — stable)
let loginButton = app.buttons["loginButton"]
XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
loginButton.tap()
```

Each recorded line has a **dropdown** showing alternative queries. Choose:
- **Accessibility identifier** for localized strings
- **Shortest query** for deeply nested views
- **Generic query** (`.firstMatch`) for dynamic content

### Video Review at Failure

When a test fails, the test report shows:
- Video recording with interaction dots on timeline
- **Failure diamonds** to jump to exact failure moment
- **UI element overlay** showing all elements present at failure
- Click any element → get code recommendation → copy/paste to fix test

---

## Test Plans (.xctestplan)

### When to Use

Test Plans let you run the same tests with multiple configurations (language, appearance, orientation) in a single run.

### Default Configurations

Create `[Project]UITests.xctestplan` with these configs:

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

### Running with Test Plan

```bash
xcodebuild test \
  -scheme "[Scheme]" \
  -testPlan "[Project]UITests" \
  -destination "platform=iOS Simulator,id=[UDID]" \
  -resultBundlePath /tmp/results.xcresult
```

### Video/Screenshot Capture Options

| Setting | Default | "Keep All" Use Case |
|---------|---------|---------------------|
| `uiTestingScreenshotsLifetime` | `keepNever` (only failures) | Documentation, marketing |
| Video capture | Failures only | Tutorials, review |

---

## Network Conditioning (Multi-Factor Testing)

For apps with heavy network usage (images, uploads, streaming):

### Network Link Conditioner Profiles

| Profile | Latency | Use Case |
|---------|---------|----------|
| 3G | ~100ms, low bandwidth | Worst case mobile |
| LTE | ~50ms, medium bandwidth | Typical mobile |
| WiFi | ~1ms, high bandwidth | Best case |

### Adaptive Timeouts in Tests

```swift
func timeout(for scenario: String) -> TimeInterval {
    // In Test Plan configurations, set environment vars per config
    let isSlowNetwork = ProcessInfo.processInfo.environment["NETWORK_PROFILE"] == "3G"
    switch scenario {
    case "data_load": return isSlowNetwork ? 30 : 10
    case "image_load": return isSlowNetwork ? 20 : 5
    default: return isSlowNetwork ? 15 : 5
    }
}
```

---

## Verification with ast-grep

Use ast-grep patterns to detect UI testing anti-patterns:

```bash
# Detect sleep() in UI test files
ast-grep --lang swift -p 'sleep($DURATION)' [Project]UITests/

# Detect Thread.sleep in UI test files
ast-grep --lang swift -p 'Thread.sleep($$$)' [Project]UITests/

# Detect .accessibilityLabel usage in UI tests (should use .accessibilityIdentifier)
grep -rn '\.accessibilityLabel' [Project]UITests/

# Detect interactive elements without identifiers in app code
ast-grep --lang swift -p 'Button($$$) { $$$BODY }' Features/
```

---

## Tips

- **Keep UI tests fast**: Target < 30 seconds per test.
- **Reset state between tests**: Use launch arguments (`-ClearDataOnLaunch`).
- **Stop on first failure**: `continueAfterFailure = false` in setUp.
- **Screenshot on failure**: Capture and attach in tearDown.
- **Debug element hierarchy**: `print(app.debugDescription)`.
- **Tests must be independent**: Each test must work in any order.
- **Use launch arguments, not network mocking**: The Factory handles data isolation.
- **Don't test implementation details**: Test what the user sees, not internal structure.
- **Use XCTContext.runActivity for test steps**: Groups actions for better failure reporting.

```swift
func testPurchaseFlow() {
    XCTContext.runActivity(named: "Navigate to product") { _ in
        // ...
    }
    XCTContext.runActivity(named: "Add to cart") { _ in
        // ...
    }
    XCTContext.runActivity(named: "Complete checkout") { _ in
        // ...
    }
}
```
