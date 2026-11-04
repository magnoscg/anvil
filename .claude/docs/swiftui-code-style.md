# SwiftUI Code Style Rules

> SwiftUI code style conventions and file organization rules.
> Related skills: `axiom-swiftui-architecture`, `axiom-swiftui-performance`
> Axiom complementa: Adaptive layout, animations

## File Organization

Recommended order within a file:

1. `import` (alphabetical)
2. `// MARK: - <TypeName>` (main type)
3. Type properties
4. `init` (if applicable)
5. `body` (if View)
6. Private methods
7. `extension` of main type
8. `// MARK: - Previews` at the end

### Required MARK Comments

**Always** use `// MARK: - <Section>` to organize code:

```swift
// MARK: - FeatureDetailView

struct FeatureDetailView: View {
    // MARK: - Properties

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var viewModel: FeatureDetailViewModel

    @State
    private var retryTrigger = false

    // MARK: - Init

    init(viewModel: FeatureDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        content
            .task(id: retryTrigger) {
                await viewModel.loadFeature()
            }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var content: some View {
        // ...
    }

    // MARK: - Private Methods

    private func handleRetry() {
        retryTrigger.toggle()
    }
}

// MARK: - Previews

#Preview("Loaded") {
    // ...
}
```

## View Organization

### One View per File

Each SwiftUI View should be in its own `.swift` file:

```
✅ [Feature]View.swift         → struct [Feature]View: View
✅ [Feature]FeatureRow.swift   → struct [Feature]FeatureRow: View
✅ [Feature]DetailView.swift   → struct [Feature]DetailView: View

❌ [Feature]Views.swift        → multiple public views
```

**Exception**: Very small private subviews (< 15 lines) can be in the same file:

```swift
// [Feature]View.swift

// MARK: - [Feature]View

struct FeatureView: View {
    var body: some View {
        VStack {
            HeaderSection()
            // ...
        }
    }
}

// MARK: - HeaderSection

// ✅ OK: small private subview in same file
private struct HeaderSection: View {
    var body: some View {
        Text("Header")
            .font(.title)
    }
}
```

### View Locations

| View Type | Location |
|-----------|----------|
| Feature main View | `Features/[Feature]/UI/` |
| Reusable feature component | `Features/[Feature]/UI/Components/` |
| Shared component (all features) | `Core/Common/SwiftUI/Components/` (`ErrorView`, `LoadingStateView`) |
| Design tokens | `Core/DesignSystem/Tokens/` |
| App-level screen (splash) | `App/Application/SplashScreen/` |

### Custom ViewModifiers

**Never** write complex modifiers inline. **All** ViewModifiers go in a single location (current files in `Example/`):

```
Core/
└─ Common/
   └─ SwiftUI/
      └─ Modifiers/
         ├─ CustomListRowModifier.swift
         ├─ GlassmorphismCardModifier.swift
         ├─ PrimaryButtonStyleModifier.swift
         └─ StaggeredAppearModifier.swift
```

The `ShimmerModifier` below is an illustration of the file layout, not an existing file.

File structure:

```swift
// Core/Common/SwiftUI/Modifiers/ShimmerModifier.swift
import SwiftUI

// MARK: - ShimmerModifier

struct ShimmerModifier: ViewModifier {

    // MARK: - Properties

    let isActive: Bool
    @State private var phase: CGFloat = 0

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    shimmerOverlay
                }
            }
    }

    // MARK: - Private Views

    private var shimmerOverlay: some View {
        // ...
    }
}

// MARK: - View Extension

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
```

### @ViewBuilder Helpers

For conditional view building logic, create helpers in:

```
Core/
└─ Common/
   └─ SwiftUI/
      └─ Builders/
         └─ ConditionalContent.swift
```

## State and Observation

### @State for ViewModels from Factory (Navigation Preservation)

**CRITICAL**: When a View receives a ViewModel from a Factory via `navigationDestination`,
you **MUST** use `@State` to preserve the ViewModel identity across navigation.

**Why?** When you navigate back, SwiftUI may recreate the View struct. Without `@State`:
1. View struct recreated → Factory called → NEW ViewModel created
2. All loaded data and state is LOST

**Apple Documentation**: "You can also store observable objects that you create with the
Observable() macro in State" - [State](https://developer.apple.com/documentation/swiftui/state)

Every feature View in `Example/` (`ArchitectureView`, `ArchitectureDetailView`, `PokemonListView`, `PokemonDetailView`, `SplashScreenView`) declares `@State private var viewModel` and an explicit `init` that wraps the injected ViewModel with `State(initialValue:)`:

```swift
// ✅ CORRECT: @State preserves ViewModel across navigation
struct FeatureDetailView: View {
    // MARK: - Properties

    @State
    private var viewModel: FeatureDetailViewModel

    @State
    private var retryTrigger = false

    // MARK: - Init

    init(viewModel: FeatureDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        content
            .task(id: retryTrigger) {
                await viewModel.loadFeature()
            }
    }
}

// Factory - creates ViewModel and returns View
static func makeView(featureId: String, appRouter: AppRouter) -> FeatureDetailView {
    let viewModel = FeatureDetailViewModel(...)
    return FeatureDetailView(viewModel: viewModel)
}

// RouteResolver - calls Factory
@ViewBuilder
private func destination(for route: FeatureRoute) -> some View {
    switch route {
    case let .detail(featureId):
        FeatureDetailFactory.makeView(featureId: featureId, appRouter: appRouter)
    }
}
```

**Cost of the pattern**: SwiftUI can call the destination closure, and therefore the Factory, many times. `@State` keeps only the first ViewModel; the rest are built and thrown away. Factories and every `init` they reach (ViewModel, UseCase, Repository, DataSource) must stay cheap: no file I/O, decoding or network work. Load lazily inside an `async` method called from `.task(id:)`.

### When to Use Each Wrapper

| Wrapper | When to Use | Example |
|---------|-------------|---------|
| `@State private var viewModel` + `State(initialValue:)` in `init` | View receives from Factory | Main feature views |
| `@Bindable var viewModel` | Need `$viewModel.property` bindings | Forms with TextField/Toggle |
| `var viewModel` | Parent owns @State, passes down | Child components |
| `@State private var localState` | UI-only state (not ViewModel) | `isShowingSheet`, `selectedTab` |

### @Bindable for Two-way Bindings

When you need to create bindings (`$`) to properties of an `@Observable` class, use `@Bindable`:

```swift
// Features/Profile/UI/EditProfileView.swift
import SwiftUI

// MARK: - EditProfileView

struct EditProfileView: View {

    // MARK: - Properties

    @Bindable var viewModel: EditProfileViewModel  // For two-way bindings

    // MARK: - Body

    var body: some View {
        Form {
            TextField("profile.name", text: $viewModel.name)
            TextField("profile.bio", text: $viewModel.bio)
            Toggle("profile.notifications", isOn: $viewModel.notificationsEnabled)
        }
    }
}
```

### Separate State and Decorators

State enum and Decorators in **separate files** in `UI/` folder:

```swift
// Features/[Feature]/UI/[Feature]State.swift

// MARK: - [Feature]State

enum FeatureState: Equatable {
    case idle
    case loading
    case loaded([FeatureSectionDecorator])
    case error(ErrorDecorator)
}
```

```swift
// Features/[Feature]/UI/[Feature]Decorator.swift

// MARK: - [Feature]SectionDecorator

struct FeatureSectionDecorator: Identifiable, Equatable {
    let id: String
    let title: String
    let features: [FeatureItemDecorator]
}

// MARK: - [Feature]ItemDecorator

struct FeatureItemDecorator: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let statusIcon: String
    let statusColor: StatusColor
}
```

### ViewModel with @Observable

**Note**: Actions are direct methods, no Action/Event enums. **No default values** — everything is injected by the Factory.

```swift
// Features/[Feature]/Presentation/ViewModels/[Feature]ViewModel.swift
import Foundation

// MARK: - [Feature]ViewModel

@MainActor
@Observable
final class FeatureViewModel {

    // MARK: - Properties

    private(set) var state: FeatureState = .idle

    private let useCase: FeatureUseCase
    private let router: FeatureRouter
    private let decoratorMapper: FeatureDecoratorMapper

    // MARK: - Init

    init(
        useCase: FeatureUseCase,
        router: FeatureRouter,
        decoratorMapper: FeatureDecoratorMapper
    ) {
        self.useCase = useCase
        self.router = router
        self.decoratorMapper = decoratorMapper
    }

    // MARK: - Public Methods

    func loadFeatures() async {
        guard state != .loading else { return }

        let previousState = state
        state = .loading

        do {
            let models = try await useCase.execute()
            let sections = decoratorMapper.mapToSections(models)
            state = .loaded(sections)
        } catch is CancellationError {
            state = previousState
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }

    func navigateToDetail(featureId: String) {
        router.navigateToDetail(featureId: featureId)
    }
}
```

### View with ViewModel Injection

> **Important**: Use `@State private var viewModel` with an explicit `init` (`State(initialValue:)`) when the View receives the ViewModel from a Factory.
> This preserves the ViewModel identity across navigation events.

```swift
// Features/[Feature]/UI/[Feature]View.swift
import SwiftUI

// MARK: - [Feature]View

struct FeatureView: View {
    // MARK: - Properties

    @State
    private var viewModel: FeatureViewModel

    @State
    private var retryTrigger = false

    // MARK: - Init

    init(viewModel: FeatureViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        content
            .task(id: retryTrigger) {
                await viewModel.loadFeatures()
            }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView()
        case let .loaded(sections):
            FeatureLoadedView(sections: sections,
                              onSelectFeature: viewModel.navigateToDetail)
        case let .error(error):
            ErrorView(error: error) {
                retryTrigger.toggle()
            }
        }
    }
}

// MARK: - Previews

#Preview("Loaded") {
    // ...
}
```

### UI-only State

For state that only affects UI (not business logic), use `@State private`:

```swift
struct FeatureView: View {

    // MARK: - Properties

    @State
    private var viewModel: FeatureViewModel

    @State
    private var isShowingFilter = false

    // MARK: - Body

    var body: some View {
        // ...
    }
}
```

## Environment and Dependencies

### Use @Environment for System APIs

```swift
@Environment(\.dismiss) private var dismiss
@Environment(\.openURL) private var openURL
@Environment(\.colorScheme) private var colorScheme
```

### Do NOT use @Environment for Custom Dependencies

```swift
// ❌ Avoid
@Environment(\.featureRepository) private var repository

// ✅ Inject via ViewModel
let viewModel = FeatureViewModel(useCase: useCase)
```

### Avoid

- `@EnvironmentObject` — prefer Observation with explicit injection
- `@StateObject` — it's from the Combine paradigm
- `@ObservedObject` — it's from the Combine paradigm

## Errors and Optionals

- Don't use `try?` or empty `catch {}` without a clear reason
- Prefer returning `Result` or throwing typed errors
- Map errors between layers (see `ARCHITECTURE.md`)

```swift
// ❌ Avoid
let data = try? await fetch()

// ✅ Handle the error
do {
    let data = try await fetch()
} catch {
    state = .error(ErrorDecorator.generic)
}
```

## Memory Management (Closures)

### When to Use `[weak self]`

Only in **escaping closures** that capture a **class** and can outlive the scope:

- Network callbacks
- Timers
- NotificationCenter observers
- Combine sinks
- Retained delegates
- `Task` stored in properties

```swift
// ✅ Necessary: escaping closure that can outlive
client.fetch { [weak self] result in
    guard let self else { return }
    self.handle(result)
}

// ✅ NOT necessary: non-escaping closure
let mapped = items.map { $0.name }
```

## Concurrency

### In Views: Use `.task(id:)`

```swift
.task(id: featureId) {
    await viewModel.loadFeature(featureId: featureId)
}
```

### Do NOT Use Loose `Task { }`

To trigger async work from a button (e.g. retry), change a `@State` value that a `.task(id:)` observes. SwiftUI cancels the previous run and ties the work to the view's lifetime (`ArchitectureView`, `PokemonListView`):

```swift
// ❌ Avoid
Button("Load") {
    Task {
        await viewModel.loadFeatures()
    }
}

// ✅ Drive the work with .task(id:)
@State
private var retryTrigger = false

var body: some View {
    content
        .task(id: retryTrigger) {
            await viewModel.loadFeatures()
        }
}

private var retryButton: some View {
    Button(String(localized: "error.button.retry")) {
        retryTrigger.toggle()
    }
}
```

### Cancellation Handling in ViewModel

On cancellation, restore the previous state so the view never stays stuck in `.loading`:

```swift
func loadFeatures() async {
    guard state != .loading else { return }

    let previousState = state
    state = .loading

    do {
        let data = try await useCase.execute()
        let sections = decoratorMapper.mapToSections(data)
        state = .loaded(sections)
    } catch is CancellationError {
        state = previousState
    } catch let error as DomainError {
        state = .error(ErrorDecorator.from(error))
    } catch {
        state = .error(.generic)
    }
}
```

## Localization

### In Views: String Catalog

Don't use hardcoded literals:

```swift
// ❌ Avoid
Text("Welcome back!")

// ✅ Use String Catalog
Text("home.welcome.title")
```

### In Code: String(localized:)

```swift
let message = String(localized: "error.network.message")
```

## Accessibility

### Basic Rules

All interactive Views must be accessible for VoiceOver and other assistive technologies.

### Required Labels

```swift
// ✅ Icons without text need label
Button(action: deleteItem) {
    Image(systemName: "trash")
}
.accessibilityLabel("feature.delete.button")

// ✅ Decorative images are hidden
Image("decorative-banner")
    .accessibilityHidden(true)

// ✅ Informative images need description
Image("product-photo")
    .accessibilityLabel("product.image.description")
```

## Previews

### Always Deterministic

- No network
- No persistence
- With stubs

Test mocks live in `ArquitecturaTests/Mocks/` and are not visible to the app target, so previews use small `private` stubs declared at the bottom of the View file (see `PokemonListView.swift`):

```swift
// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        FeatureView(viewModel: FeatureViewModel(useCase: PreviewFeatureUseCase(),
                                                router: PreviewFeatureRouter(),
                                                decoratorMapper: FeatureDecoratorMapperImpl()))
    }
}

#Preview("Loading") {
    NavigationStack {
        FeatureView(viewModel: FeatureViewModel(useCase: PreviewFeatureLoadingUseCase(),
                                                router: PreviewFeatureRouter(),
                                                decoratorMapper: FeatureDecoratorMapperImpl()))
    }
}

#Preview("Error") {
    NavigationStack {
        FeatureView(viewModel: FeatureViewModel(useCase: PreviewFeatureErrorUseCase(),
                                                router: PreviewFeatureRouter(),
                                                decoratorMapper: FeatureDecoratorMapperImpl()))
    }
}

// MARK: - Preview Helpers

private struct PreviewFeatureUseCase: FeatureUseCase {
    func execute() async throws -> [FeatureModel] {
        [FeatureModel(id: "1", name: "Clean Architecture", category: .architecture)]
    }
}

private struct PreviewFeatureLoadingUseCase: FeatureUseCase {
    func execute() async throws -> [FeatureModel] {
        try await Task.sleep(for: .seconds(60))
        return []
    }
}

private struct PreviewFeatureErrorUseCase: FeatureUseCase {
    func execute() async throws -> [FeatureModel] {
        throw DomainError.network
    }
}

@MainActor
private struct PreviewFeatureRouter: FeatureRouter {
    func navigateToDetail(featureId: String) {}
    func goBack() {}
}
```

### Cover Main States

At minimum:
- `loaded` with data
- `loading`
- `error`
- `empty` (if applicable)

---

## Performance Patterns

### LazyVStack for Long Lists

```swift
// ❌ WRONG: VStack loads all items immediately
ScrollView {
    VStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// ✅ CORRECT: LazyVStack loads items on demand
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### Avoid Expensive Computations in Body

```swift
// ❌ WRONG: Expensive computation on every render
var body: some View {
    let sortedItems = items.sorted { $0.date > $1.date }
    let filteredItems = sortedItems.filter { $0.isActive }

    List(filteredItems) { item in
        ItemRow(item: item)
    }
}

// ✅ CORRECT: Move computation to ViewModel
var body: some View {
    List(viewModel.processedItems) { item in
        ItemRow(item: item)
    }
}
```

### Use equatable() for Heavy Views

```swift
// For views with expensive rendering, prevent unnecessary updates
struct HeavyChartView: View {
    let data: ChartData

    var body: some View {
        // Complex chart rendering
    }
}

// Usage
HeavyChartView(data: chartData)
    .equatable()
```

### @Previewable for Efficient Previews (iOS 18+)

```swift
#Preview {
    @Previewable @State var isPresented = false

    Button("Show Sheet") {
        isPresented.toggle()
    }
    .sheet(isPresented: $isPresented) {
        Text("Sheet Content")
    }
}
```

### Image Loading Optimization

```swift
// ❌ WRONG: Large images loaded at full resolution
Image("large-photo")
    .resizable()
    .frame(width: 100, height: 100)

// ✅ CORRECT: Thumbnail with proper sizing
AsyncImage(url: imageURL) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}
.frame(width: 100, height: 100)
.clipped()
```

### Minimize State Changes in Body

```swift
// ❌ WRONG: Creating new objects on every render
var body: some View {
    let formatter = DateFormatter()  // Created every render!
    formatter.dateStyle = .medium
    Text(formatter.string(from: date))
}

// ✅ CORRECT: Use static or computed property
private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

var body: some View {
    Text(Self.dateFormatter.string(from: date))
}
```

### Use drawingGroup() for Complex Graphics

```swift
// For views with many layers/effects
ZStack {
    // Many overlapping shapes with effects
}
.drawingGroup()  // Flattens to single layer for GPU rendering
```
