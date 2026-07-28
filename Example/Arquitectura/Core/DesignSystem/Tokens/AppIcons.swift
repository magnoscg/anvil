import SwiftUI

// MARK: - AppIcons

/// Type-safe SF Symbols for consistent icon usage across the app
enum AppIcons {
    // MARK: - Status

    static let checkmarkCircleFill = Image(systemName: "checkmark.circle.fill")
    static let circle = Image(systemName: "circle")
    static let exclamationTriangle = Image(systemName: "exclamationmark.triangle")
    static let infoCircle = Image(systemName: "info.circle")

    // MARK: - Navigation

    static let chevronRight = Image(systemName: "chevron.right")
    static let chevronLeft = Image(systemName: "chevron.left")
}

// MARK: - IconType

/// Type-safe icon representation supporting both SF Symbols and custom assets
enum IconType: Equatable {
    case system(String)
    case asset(String)

    // MARK: - View Builder

    @MainActor @ViewBuilder
    func image(size: CGFloat = IconSize.md, color: Color? = nil) -> some View {
        switch self {
        case let .system(name):
            ScaledSystemIcon(name: name, baseSize: size, color: color)
        case let .asset(name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}

// MARK: - ScaledSystemIcon

/// Helper view that scales SF Symbol icons with Dynamic Type using @ScaledMetric
private struct ScaledSystemIcon: View {
    // MARK: - Properties

    let name: String
    let color: Color?

    @ScaledMetric
    private var scaledSize: CGFloat

    // MARK: - Init

    init(name: String, baseSize: CGFloat, color: Color?) {
        self.name = name
        self.color = color
        self._scaledSize = ScaledMetric(wrappedValue: baseSize, relativeTo: .body)
    }

    // MARK: - Body

    var body: some View {
        Image(systemName: name)
            .font(.system(size: scaledSize))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .foregroundStyle(color ?? AppColors.text)
    }
}

// MARK: - StatusIcon

/// Type-safe status icons with semantic meaning
enum StatusIcon: Equatable {
    case implemented
    case pending
    case error
    case info

    var image: Image {
        switch self {
        case .implemented: AppIcons.checkmarkCircleFill
        case .pending: AppIcons.circle
        case .error: AppIcons.exclamationTriangle
        case .info: AppIcons.infoCircle
        }
    }
}
