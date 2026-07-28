# UI Design System Documentation Template

Use this template when the user asks to document: design system, UI components, theming, colors, typography, reusable views, SwiftUI component library, or "how to style views".

---

## Template Structure

```markdown
# [Project Name] - UI Design System

{toc}

## 1. Overview

Description of the design system, its purpose, and how it relates to the Figma design files.

> ℹ️ **Figma:** [Link to Figma project]
> **Design System module:** `DesignSystem` SPM package (or `Presentation/Components/`)

## 2. Theme & Tokens

### 2.1 Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `primary` | #007AFF | #0A84FF | CTAs, links, active elements |
| `secondary` | #5856D6 | #5E5CE6 | Secondary actions |
| `background` | #FFFFFF | #000000 | Screen backgrounds |
| `surface` | #F2F2F7 | #1C1C1E | Card backgrounds, grouped sections |
| `textPrimary` | #000000 | #FFFFFF | Main text |
| `textSecondary` | #8E8E93 | #8E8E93 | Captions, hints |
| `error` | #FF3B30 | #FF453A | Error states |
| `success` | #34C759 | #30D158 | Success states |
| `warning` | #FF9500 | #FF9F0A | Warning states |

```swift
// Theme/Colors.swift
extension Color {
    static let appPrimary = Color("Primary", bundle: .designSystem)
    static let appSecondary = Color("Secondary", bundle: .designSystem)
    static let appBackground = Color("Background", bundle: .designSystem)
    // ...
}
```

### 2.2 Typography

| Style | Font | Size | Weight | Line Height | Usage |
|-------|------|------|--------|-------------|-------|
| `largeTitle` | System | 34pt | Bold | 41pt | Screen titles |
| `title` | System | 28pt | Bold | 34pt | Section headers |
| `headline` | System | 17pt | Semibold | 22pt | Card titles |
| `body` | System | 17pt | Regular | 22pt | Body text |
| `callout` | System | 16pt | Regular | 21pt | Secondary text |
| `caption` | System | 12pt | Regular | 16pt | Labels, timestamps |

```swift
// Theme/Typography.swift
extension Font {
    static let appLargeTitle = Font.system(size: 34, weight: .bold)
    static let appTitle = Font.system(size: 28, weight: .bold)
    static let appHeadline = Font.system(size: 17, weight: .semibold)
    static let appBody = Font.system(size: 17, weight: .regular)
    static let appCaption = Font.system(size: 12, weight: .regular)
}
```

### 2.3 Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 2pt | Inline icon padding |
| `xs` | 4pt | Tight spacing |
| `sm` | 8pt | Compact elements |
| `md` | 16pt | Standard spacing (default) |
| `lg` | 24pt | Section spacing |
| `xl` | 32pt | Major sections |
| `xxl` | 48pt | Screen padding top/bottom |

### 2.4 Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `small` | 8pt | Buttons, inputs |
| `medium` | 12pt | Cards |
| `large` | 16pt | Bottom sheets, modals |
| `full` | 999pt | Circular elements (avatars) |

## 3. Component Library

### 3.1 Component Index

| Component | File | Preview | Description |
|-----------|------|---------|-------------|
| PrimaryButton | `Components/Buttons/PrimaryButton.swift` | ✅ | Main CTA button |
| SecondaryButton | `Components/Buttons/SecondaryButton.swift` | ✅ | Secondary actions |
| InputField | `Components/Inputs/InputField.swift` | ✅ | Text input with label & error |
| Card | `Components/Cards/Card.swift` | ✅ | Content card container |
| LoadingView | `Components/Feedback/LoadingView.swift` | ✅ | Loading indicator |
| ErrorBanner | `Components/Feedback/ErrorBanner.swift` | ✅ | Error notification |
| EmptyState | `Components/Feedback/EmptyState.swift` | ✅ | Empty content placeholder |
| Avatar | `Components/Media/Avatar.swift` | ✅ | User avatar image |

### 3.2 Component Documentation Pattern

For each component, document:

```swift
/// A primary action button with loading state support.
///
/// Usage:
/// ```swift
/// PrimaryButton("Save Changes") {
///     await viewModel.save()
/// }
/// .disabled(viewModel.isSaveDisabled)
/// ```
///
/// States: default, pressed, disabled, loading
struct PrimaryButton: View {
    let title: String
    let action: () async -> Void
    var isLoading: Bool = false

    var body: some View { ... }
}

// MARK: - Previews
#Preview("Default") { PrimaryButton("Save") {} }
#Preview("Loading") { PrimaryButton("Save", isLoading: true) {} }
#Preview("Disabled") { PrimaryButton("Save") {}.disabled(true) }
```

## 4. SwiftUI Patterns

### 4.1 View Composition Hierarchy

```
App
├── MainTabView
│   ├── HomeTab
│   │   ├── HomeView (screen)
│   │   │   ├── HeaderSection (section)
│   │   │   │   └── Avatar (component)
│   │   │   ├── ContentList (section)
│   │   │   │   └── Card (component)
│   │   │   └── LoadingView (component)
│   │   └── ItemDetailView (screen)
│   └── ProfileTab
│       └── ProfileView (screen)
└── LoginFlow (full screen cover)
    └── LoginView (screen)
        ├── InputField (component)
        └── PrimaryButton (component)
```

### 4.2 View Modifier Patterns

```swift
// Custom view modifiers for consistent styling
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.md)
            .background(Color.appSurface)
            .cornerRadius(.medium)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
```

### 4.3 Preview Conventions

```swift
// Always group previews by state:
#Preview("Default") { ComponentName() }
#Preview("Loading") { ComponentName(isLoading: true) }
#Preview("Error") { ComponentName(error: .mock) }
#Preview("Empty") { ComponentName(items: []) }
#Preview("Dark Mode") { ComponentName().preferredColorScheme(.dark) }
#Preview("Large Text") { ComponentName().dynamicTypeSize(.xxxLarge) }
```

## 5. Accessibility

### 5.1 Requirements

- All interactive elements have accessibility labels
- Dynamic Type supported on all text
- VoiceOver navigation order is logical
- Color contrast meets WCAG AA (4.5:1 for text)
- No information conveyed by color alone

### 5.2 Patterns

```swift
Button(action: { ... }) {
    Image(systemName: "heart.fill")
}
.accessibilityLabel("Add to favorites")
.accessibilityHint("Double-tap to add this item to your favorites list")
```

## 6. Dark Mode & Appearance

### Color System Rules

| Rule | Implementation |
|------|----------------|
| Always use semantic colors | `Color.appPrimary` not `Color.blue` |
| Test both appearances | Every PR must verify light + dark mode |
| Custom colors need both variants | Asset catalog with "Any Appearance" + "Dark" |
| System materials for overlays | `.ultraThinMaterial` adapts automatically |

### Edge Cases

| Scenario | Handling |
|----------|----------|
| High Contrast mode | Use `accessibilityContrast` environment value; provide stronger borders |
| Elevated appearance (sheets on iPad) | Use `colorScheme` + `UITraitCollection.userInterfaceLevel` |
| Custom dark mode toggle (in-app) | `@AppStorage("appearance")` + `.preferredColorScheme()` |
| Screenshots for App Store | Capture both modes; use marketing-approved colors |

## 7. Icon System

### SF Symbols

| Usage | Weight | Size | Example |
|-------|--------|------|---------|
| Tab bar | Regular | 24pt | `Image(systemName: "house")` |
| Navigation bar | Regular | 17pt | `Image(systemName: "gear")` |
| Inline with text | Matching text | Text size | `Label("Settings", systemImage: "gear")` |
| Large display | Thin/Ultralight | 48pt+ | Hero icons |

### Custom Icons

| Convention | Example |
|------------|---------|
| Asset naming | `icon-[name]-[size]` → `icon-camera-24` |
| Rendering mode | `.template` for tintable, `.original` for branded |
| PDF vs SVG | PDF for Xcode assets, SVG for dynamic rendering |

## 8. Animation & Motion

### Timing Constants

| Token | Duration | Curve | Usage |
|-------|----------|-------|-------|
| `instant` | 0.1s | `.easeOut` | Micro-interactions (tap feedback) |
| `fast` | 0.2s | `.easeInOut` | State changes (toggle, selection) |
| `normal` | 0.35s | `.spring(response: 0.35)` | Navigation transitions |
| `slow` | 0.5s | `.easeInOut` | Complex animations, page transitions |

### Reduce Motion Support

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    content
        .animation(reduceMotion ? nil : .spring(response: 0.35), value: isExpanded)
}
```

### Haptic Feedback Patterns

| Action | Haptic | Implementation |
|--------|--------|----------------|
| Button tap | Light impact | `UIImpactFeedbackGenerator(style: .light)` |
| Toggle change | Medium impact | `UIImpactFeedbackGenerator(style: .medium)` |
| Success | Notification success | `UINotificationFeedbackGenerator().notificationOccurred(.success)` |
| Error | Notification error | `UINotificationFeedbackGenerator().notificationOccurred(.error)` |
| Selection change | Selection changed | `UISelectionFeedbackGenerator().selectionChanged()` |

## 9. State Indicator Patterns

### Standard States

| State | Visual | Component |
|-------|--------|-----------|
| Loading | Skeleton shimmer or `ProgressView` | `LoadingView` |
| Empty | Illustration + message + CTA | `EmptyStateView` |
| Error | Message + retry button | `ErrorView` |
| Success | Check animation + message | `SuccessView` |
| Offline | Banner + cached data indicator | `OfflineBanner` |

```swift
// ViewState-driven rendering
@ViewBuilder
func contentView<T>(state: ViewState<T>, @ViewBuilder content: (T) -> some View) -> some View {
    switch state {
    case .idle: EmptyView()
    case .loading: LoadingView()
    case .loaded(let data): content(data)
    case .empty: EmptyStateView(message: "No items found")
    case .error(let error): ErrorView(error: error) { /* retry action */ }
    }
}
```

## 10. Form UI Patterns

### Validation Display

| Pattern | When to Use |
|---------|------------|
| Inline error (below field) | Field-specific validation errors |
| Shake animation | Invalid submission attempt |
| Red border | Field with error |
| Helper text (gray) | Always-visible input hints |
| Character counter | Text fields with limits |

```swift
struct ValidatedTextField: View {
    let label: String
    @Binding var text: String
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.appCaption).foregroundStyle(.secondary)
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(error != nil ? Color.appError : .clear))
            if let error {
                Text(error).font(.caption2).foregroundStyle(.appError)
            }
        }
    }
}
```

## 11. Dynamic Type & Layout

### Supported Sizes

| Category | Supported | Testing Priority |
|----------|-----------|-----------------|
| xSmall → xxxLarge | ✅ Required | High |
| AX1 → AX5 | ✅ Required (accessibility sizes) | Medium |

### Layout Breakpoints

| Context | Breakpoint | Behavior |
|---------|------------|----------|
| iPhone portrait | <390pt width | Single column, compact |
| iPhone landscape | <844pt width | Two columns or adapted |
| iPad portrait | <1024pt width | Two columns, sidebar |
| iPad landscape / Split View | ≥1024pt width | Three columns, full layout |

```swift
@Environment(\.horizontalSizeClass) var sizeClass

var body: some View {
    if sizeClass == .compact {
        VStack { content }  // Stack vertically on iPhone
    } else {
        HStack { content }  // Side by side on iPad
    }
}
```

## 12. Component Versioning

### When to Version a Component

| Situation | Action |
|-----------|--------|
| Breaking API change | Create `PrimaryButtonV2`, deprecate `PrimaryButton` |
| Visual refresh only | Update in-place, no version bump |
| New variant | Add as parameter (`.style(.outlined)`) |
| Complete redesign | New component, deprecate old with migration guide |

### Deprecation Process

```swift
@available(*, deprecated, renamed: "PrimaryButton", message: "Use PrimaryButton with .style(.outlined) instead")
struct OutlinedButton: View { ... }
```

## 13. Related Documentation

- [Architecture Overview](./01-Architecture-Overview.md)
- [Project Structure](./02-Project-Structure.md) — Component file locations
- [Coding Conventions](./10-Coding-Conventions.md) — Naming conventions for views

---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Owner | [Name/Team] |
| Created | [Date] |
| Last Updated | [Date] |
| Last Verified | [Date] |
| Review Schedule | [Quarterly/Monthly/Bi-annual] |
| Status | Draft |
| Labels | `ios`, `swift`, `design-system`, `ui`, `swiftui`, `[project-name]` |
```

## Writing Guidelines

- Include actual hex color values and map them to semantic token names
- Document components with previews showing ALL states (default, loading, error, disabled)
- Always show usage code, not just implementation
- Include accessibility requirements for every component
- Update the component index when adding new components
