# SwiftUI Code Style

Conventions for SwiftUI files in this architecture: file layout, where views live, how a View holds its ViewModel, and how previews are built.

## File Layout

Order inside a file, as the generator emits it:

1. `import` statements, alphabetical.
2. `// MARK: - <TypeName>` and the main type, split into `// MARK: - Properties`, `// MARK: - Init` and `// MARK: - Body`.
3. `// MARK: - Private Views`: a `private extension` of the type with its subviews and helpers.
4. `// MARK: - Preview` and `// MARK: - Preview Helpers`, always last.

- Every section opens with `// MARK: - <Section>`, and the first one sits directly under the opening brace. The marks are what keeps a long View navigable.
- Attributes go on the line before the declaration (`@State`, `@Bindable`, `@ViewBuilder`, `@MainActor`, `@Observable`). The generated `.swiftformat` sets `--varattributes`, `--funcattributes` and `--typeattributes` to `prev-line`, so any other spelling only produces a reformat diff.
- `body` only composes named subviews. Move a branch into the private extension well before the type reaches the limits in `.swiftlint.yml` (`type_body_length` 250, `function_body_length` 40).
- One View per file, named after the type (`ArticleView.swift` holds `struct ArticleView: View`), so a view is found by name and files stay small. The only exception is a `private` subview of about 15 lines or fewer, which may stay below the view that uses it, under its own `// MARK: -`.

## Where Things Live

| What | Location |
|---|---|
| Feature screen, its `State` and its `Decorator` | `Features/<Feature>/UI/` (ViewModels, mappers and the rest of the tree: `PROJECT-STRUCTURE.md`) |
| Component used by a single feature | `Features/<Feature>/UI/Components/` |
| Component shared by features | `Core/Common/SwiftUI/Components/` (generated: `ErrorView`, `LoadingStateView`) |
| `ViewModifier` plus its `View` extension | `Core/Common/SwiftUI/Modifiers/` (generated: `CustomListRow.swift`, `PrimaryButtonStyle.swift`) |
| `@ViewBuilder` helpers | `Core/Common/SwiftUI/Builders/` (generated: `ConditionalContent.swift`) |
| Design tokens | `Core/DesignSystem/Tokens/` (`AppColors`, `AppTypography`, `Spacing`, `AppIcons`, `IconSize`) |

## Modifiers and Builders

- A modifier chain that is reused, or that carries logic, becomes a `ViewModifier` in `Core/Common/SwiftUI/Modifiers/`; it is never repeated inline. One place to change a style is one place to get it wrong.
- The file holds the `<Name>Modifier` struct and the `View` extension that exposes it. Call sites use the extension (`.primaryButtonStyle()`, `.customListRow()`), never `.modifier(...)`.
- Conditional view-building helpers go in `Core/Common/SwiftUI/Builders/` (generated: `.if(_:transform:)`).

## View and ViewModel

The Factory builds the ViewModel and hands it to the View, which keeps it in `@State`. Every feature screen has this shape:

```swift
// Features/Article/UI/ArticleView.swift
import SwiftUI

// MARK: - ArticleView

struct ArticleView: View {
    // MARK: - Properties

    @State
    private var viewModel: ArticleViewModel

    // MARK: - Init

    init(viewModel: ArticleViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear
            case .loading:
                loadingView
            case .loaded:
                loadedView
            case let .error(error):
                errorView(error: error)
            }
        }
        .navigationTitle(String(localized: "article.title"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - Private Views

private extension ArticleView {
    var loadingView: some View {
        LoadingStateView()
    }

    var loadedView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.items) { item in
                    Button {
                        viewModel.navigateToDetail(id: item.id)
                    } label: {
                        Text(item.displayName)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }

    func errorView(error: ErrorDecorator) -> some View {
        let retryError = ErrorDecorator(
            title: error.title,
            message: error.message,
            retryAction: { [viewModel] in Task { await viewModel.load() } }
        )
        return ErrorView(error: retryError)
    }
}
```

Why it is written this way:

- `@State private var viewModel` keeps the first ViewModel for as long as the view keeps its identity, so loaded data survives navigating back. It is `private` because the View owns it.
- `init` assigns the property itself (`self.viewModel = viewModel`) as its last statement, after every other stored property. Never write to the underscored storage (`_viewModel = ...`), and never add an inline default to a `@State` that `init` assigns: the inline value wins silently.
- The Factory runs every time SwiftUI rebuilds the View value, not once per screen; `@State` keeps the first ViewModel and discards the rest. Every `init` reached from the Factory (ViewModel, UseCase, Repository, mappers) must therefore be cheap: no I/O, no decoding, no work started.
- The first load uses `.task { }`, which SwiftUI cancels when the view goes away. Use `.task(id:)` only when the id drives the work (loading the detail of the selected item); a flag flipped just to restart a task is not an id.
- Retry launches `Task { await viewModel.load() }` from the action. The ViewModel emits an `ErrorDecorator` without `retryAction`; the View adds it, and `ErrorView` shows the retry button only when it is set. The capture list `[viewModel]` makes the `@Sendable` closure hold the ViewModel itself instead of a copy of the whole View.
- `.idle` renders `Color.clear`: nothing has been requested yet, so the screen shows nothing rather than a spinner.

The part of the ViewModel the View relies on (the whole file is in `new-feature.md`, layers and error mapping in `ARCHITECTURE.md`, isolation and cancellation rules in `swift-concurrency.md`):

```swift
// Features/Article/Presentation/ViewModels/ArticleViewModel.swift
@MainActor
@Observable
final class ArticleViewModel {
    // MARK: - Properties

    private(set) var state: ArticleState = .idle
    private(set) var items: [ArticleDecorator] = []

    // MARK: - Public Methods

    func load() async {
        guard state != .loading else { return }

        let previousState = state
        state = .loading

        do {
            let models = try await useCase.execute()
            let decorators = models.map { decoratorMapper.map($0) }
            items = decorators
            state = .loaded
        } catch is CancellationError {
            state = previousState
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }
}
```

- `@MainActor`, `@Observable`, `final class`. Observable state is `private(set)`: the View reads it and calls plain methods (`load()`, `navigateToDetail(id:)`); there are no Action or Event enums.
- Cancellation is not an error. When `.task` is cancelled the ViewModel restores `previousState`, so coming back to the screen reloads instead of showing a stuck spinner.

## Property Wrappers

| Declaration | Use it when |
|---|---|
| `@State private var viewModel: ArticleViewModel` plus `init` | The View receives its ViewModel from the Factory (every feature screen). |
| `@Bindable var viewModel: ArticleViewModel` | A child view needs `$viewModel.property` bindings (`TextField`, `Toggle`) to a ViewModel owned elsewhere. |
| `let viewModel: ArticleViewModel`, `let item: ArticleDecorator` | A child view only reads; the parent owns the state. |
| `@Binding var isPresented: Bool` | A child view writes a value type owned by its parent. |
| `@State private var isShowingFilter = false` | UI-only state that no other layer needs. |
| `@Environment(\.dismiss)`, `\.openURL`, `\.colorScheme` | System-provided values only. |

App dependencies never travel through `@Environment`: the Factory injects them into the ViewModel. Do not use `@StateObject`, `@ObservedObject`, `@EnvironmentObject` or `ObservableObject`; the project uses Observation.

## State and Decorator

```swift
enum ArticleState: Equatable {
    case idle
    case loading
    case loaded
    case error(ErrorDecorator)

    static func == (lhs: ArticleState, rhs: ArticleState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            true
        case let (.error(l), .error(r)):
            l.title == r.title && l.message == r.message
        default:
            false
        }
    }
}
```

- `State` and `Decorator` each get their own file in `UI/`, never inside the View or ViewModel file.
- `State` says which screen to draw. The data lives in the ViewModel (`items`), so `.loaded` carries no payload.
- `==` is written by hand because `ErrorDecorator` holds a closure (`retryAction`) and is `Sendable` but not `Equatable`: two errors are equal when title and message match. `guard state != .loading` depends on it.
- A Decorator (`ArticleDecorator`) is display-ready data: `Sendable`, `Identifiable`, `Equatable`, with strings already formatted by the `DecoratorMapper`. A View never receives a domain `Model`.

## Previews

Previews are deterministic: no network, no persistence, fixed data. Test mocks belong to the test target and are not visible to the app target, so each View file declares small `private` stubs at the bottom, under `// MARK: - Preview Helpers`.

```swift
// MARK: - Preview

#Preview("Loaded") {
    NavigationStack {
        ArticleView(viewModel: ArticleViewModel(useCase: PreviewArticleUseCase(),
                                                decoratorMapper: ArticleDecoratorMapperImpl(),
                                                router: PreviewArticleRouter()))
    }
}

// MARK: - Preview Helpers

private struct PreviewArticleUseCase: ArticleUseCase {
    var error: DomainError?

    func execute() async throws -> [ArticleModel] {
        if let error { throw error }
        return [ArticleModel(id: "1", name: "First article", description: "Preview data")]
    }
}

@MainActor
private struct PreviewArticleRouter: ArticleRouter {
    func navigateToDetail(id: String) {}
    func goBack() {}
}
```

Add one `#Preview` per case of the State enum that draws something different: loaded, error (`PreviewArticleUseCase(error: .network)`), loading (a stub that never returns) and empty when the screen has one. Previews use the real `DecoratorMapperImpl`, so they show what the mapper actually produces.

## Tokens, Accessibility and Localization

```swift
Text(item.subtitle)
    .font(AppTypography.footnote.font)
    .foregroundStyle(AppColors.textSecondary)
    .padding(.horizontal, Spacing.md)
```

- Typography, color, spacing and icons come from tokens, never from `.font(.title)`, a literal `Color` or a numeric padding. `AppTypography` maps to Dynamic Type text styles, so there are no fixed font sizes.
- Localization: user-facing text is a String Catalog key shaped `<feature>.<element>` (`article.title`, `error.button.retry`) read with `String(localized:)`; no hardcoded literals in Views.
- Accessibility: a control without visible text gets an `accessibilityLabel` (a localized key), decorative images are hidden with `accessibilityHidden(true)`, and identifiers come from the feature's `AccessibilityID` enum (`ui-testing.md`). The token catalog and the full rules are in `design-system.md`.

## Performance

- Sorting, filtering and formatting happen in the ViewModel or the `DecoratorMapper`, never in `body`, which runs on every state change.
- Long or unbounded lists use a lazy container (`List`, or `LazyVStack` inside a `ScrollView`).
- Format values with `.formatted()` or `Text(value, format:)`; never store a formatter in a View.

Deeper reference (Axiom plugin, if installed): `axiom-swiftui` (`skills/architecture.md`, `skills/swiftui-performance.md`, `skills/previews-ref.md`).
