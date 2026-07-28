# SwiftUI Code Style Rules

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
// MARK: - ArticleDetailView

struct ArticleDetailView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    private let viewModel: ArticleViewModel

    // MARK: - Init

    init(viewModel: ArticleViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        content
            .task { await viewModel.loadArticles() }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var content: some View {
        // ...
    }

    // MARK: - Private Methods

    private func handleRetry() {
        Task { await viewModel.loadArticles() }
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
ArticleView.swift         -> struct ArticleView: View
ArticleFeatureRow.swift   -> struct ArticleFeatureRow: View
ArticleDetailView.swift   -> struct ArticleDetailView: View
```

**Exception**: Very small private subviews (< 15 lines) can be in the same file:

```swift
// ArticleView.swift

// MARK: - ArticleView

struct ArticleView: View {
    var body: some View {
        VStack {
            HeaderSection()
            // ...
        }
    }
}

// MARK: - HeaderSection

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
| Feature main View | `Features/<Feature>/UI/` |
| Reusable feature component | `Features/<Feature>/UI/Components/` |
| Design System component | `Core/DesignSystem/Components/` |

### Custom ViewModifiers

**Never** write complex modifiers inline. **All** ViewModifiers go in a single location:

```
Core/
+- Common/
   +- SwiftUI/
      +- Modifiers/
         +- ShimmerModifier.swift
         +- LoadingOverlayModifier.swift
         +- CardStyleModifier.swift
         +- PrimaryButtonStyleModifier.swift
         +- ConditionalModifier.swift
```

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
+- Common/
   +- SwiftUI/
      +- Builders/
         +- ConditionalContent.swift
```

## State and Observation

### @State for ViewModels from Factory (Navigation Preservation)

**CRITICAL**: When a View receives a ViewModel from a Factory via `navigationDestination`,
you **MUST** use `@State` to preserve the ViewModel identity across navigation.

**Why?** When you navigate back, SwiftUI may recreate the View struct. Without `@State`:
1. View struct recreated -> Factory called -> NEW ViewModel created
2. All loaded data and state is LOST

```swift
// CORRECT: @State preserves ViewModel across navigation
struct ArticleDetailView: View {

    // MARK: - Properties

    @State var viewModel: ArticleDetailViewModel

    // MARK: - Body

    var body: some View {
        content
            .task { await viewModel.load() }
    }
}

// Factory stays the same - creates ViewModel and returns View
static func makeView(articleId: String, ...) -> ArticleDetailView {
    let viewModel = ArticleDetailViewModel(...)
    return ArticleDetailView(viewModel: viewModel)
}
```

**Note**: Don't write explicit init with `_viewModel = State(initialValue:)`.
Swift's memberwise initializer handles @State correctly.

### When to Use Each Wrapper

| Wrapper | When to Use | Example |
|---------|-------------|---------|
| `@State var viewModel` | View receives from Factory | Main feature views |
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

    @Bindable var viewModel: EditProfileViewModel

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
// Features/Article/UI/ArticleState.swift

// MARK: - ArticleState

enum ArticleState: Equatable {
    case idle
    case loading
    case loaded([ArticleSectionDecorator])
    case error(ErrorDecorator)
}
```

```swift
// Features/Article/UI/ArticleDecorator.swift

// MARK: - ArticleSectionDecorator

struct ArticleSectionDecorator: Identifiable, Equatable {
    let id: String
    let title: String
    let items: [ArticleItemDecorator]
}

// MARK: - ArticleItemDecorator

struct ArticleItemDecorator: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
}
```

### ViewModel with @Observable

**Note**: Actions are direct methods, no Action/Event enums. **No default values** — everything is injected by the Factory.

```swift
// Features/Article/Presentation/ViewModels/ArticleViewModel.swift
import Foundation

// MARK: - ArticleViewModel

@MainActor
@Observable
final class ArticleViewModel {

    // MARK: - Properties

    private(set) var state: ArticleState = .idle

    private let useCase: ArticleUseCase
    private let router: ArticleRouter
    private let decoratorMapper: ArticleDecoratorMapper

    // MARK: - Init

    init(
        useCase: ArticleUseCase,
        router: ArticleRouter,
        decoratorMapper: ArticleDecoratorMapper
    ) {
        self.useCase = useCase
        self.router = router
        self.decoratorMapper = decoratorMapper
    }

    // MARK: - Public Methods

    func loadArticles() async {
        guard state != .loading else { return }
        state = .loading

        do {
            let models = try await useCase.execute()
            let sections = decoratorMapper.mapToSections(models)
            state = .loaded(sections)
        } catch is CancellationError {
            return
        } catch {
            state = .error(ErrorDecorator.generic)
        }
    }

    func navigateToDetail(articleId: String) {
        router.navigateToDetail(articleId: articleId)
    }
}
```

### View with ViewModel Injection

> **Important**: Use `@State var viewModel` when the View receives the ViewModel from a Factory.
> This preserves the ViewModel identity across navigation events.

```swift
// Features/Article/UI/ArticleView.swift
import SwiftUI

// MARK: - ArticleView

struct ArticleView: View {

    // MARK: - Properties

    @State var viewModel: ArticleViewModel

    // MARK: - Body

    var body: some View {
        content
            .task {
                await viewModel.loadArticles()
            }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let sections):
            ArticleListContent(
                sections: sections,
                onSelectArticle: viewModel.navigateToDetail
            )
        case .error(let error):
            ErrorView(error: error, onRetry: {
                Task { await viewModel.loadArticles() }
            })
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
struct ArticleView: View {

    // MARK: - Properties

    @State var viewModel: ArticleViewModel
    @State private var isShowingFilter = false

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
// Avoid
@Environment(\.articleRepository) private var repository

// Inject via ViewModel
let viewModel = ArticleViewModel(useCase: useCase)
```

### Avoid

- `@EnvironmentObject` — prefer Observation with explicit injection
- `@StateObject` — it's from the Combine paradigm
- `@ObservedObject` — it's from the Combine paradigm

## Errors and Optionals

- Don't use `try?` or empty `catch {}` without a clear reason
- Prefer returning `Result` or throwing typed errors
- Map errors between layers (see `ARCHITECTURE.md`)

## Memory Management (Closures)

### When to Use `[weak self]`

Only in **escaping closures** that capture a **class** and can outlive the scope:

- Network callbacks
- Timers
- NotificationCenter observers
- Combine sinks
- Retained delegates
- `Task` stored in properties

## Concurrency

### In Views: Use `.task(id:)`

```swift
.task(id: articleId) {
    await viewModel.loadArticle(articleId: articleId)
}
```

### Do NOT Use Loose `Task { }`

```swift
// Avoid in onAppear or Button
Button("Load") {
    Task {
        await viewModel.loadArticles()
    }
}

// Better to move logic to ViewModel
```

### Cancellation Handling in ViewModel

```swift
func loadArticles() async {
    guard state != .loading else { return }
    state = .loading

    do {
        let data = try await useCase.execute()
        let sections = decoratorMapper.mapToSections(data)
        state = .loaded(sections)
    } catch is CancellationError {
        return
    } catch {
        state = .error(ErrorDecorator.generic)
    }
}
```

## Localization

### In Views: String Catalog

Don't use hardcoded literals:

```swift
// Avoid
Text("Welcome back!")

// Use String Catalog
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
// Icons without text need label
Button(action: deleteItem) {
    Image(systemName: "trash")
}
.accessibilityLabel("article.delete.button")

// Decorative images are hidden
Image("decorative-banner")
    .accessibilityHidden(true)

// Informative images need description
Image("product-photo")
    .accessibilityLabel("product.image.description")
```

## Previews

### Always Deterministic

- No network
- No real SwiftData
- With mocks/stubs

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
// WRONG: VStack loads all items immediately
ScrollView {
    VStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// CORRECT: LazyVStack loads items on demand
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
// WRONG: Expensive computation on every render
var body: some View {
    let sortedItems = items.sorted { $0.date > $1.date }
    List(sortedItems) { item in
        ItemRow(item: item)
    }
}

// CORRECT: Move computation to ViewModel
var body: some View {
    List(viewModel.processedItems) { item in
        ItemRow(item: item)
    }
}
```

### Use drawingGroup() for Complex Graphics

```swift
ZStack {
    // Many overlapping shapes with effects
}
.drawingGroup()
```
