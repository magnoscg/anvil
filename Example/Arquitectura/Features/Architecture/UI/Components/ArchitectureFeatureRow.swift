import SwiftUI

// MARK: - ArchitectureFeatureRow

/// Row component displaying a single architecture feature.
///
/// Conforms to `Equatable` to enable SwiftUI to efficiently skip re-renders
/// when the underlying data hasn't changed. Use with `EquatableView` wrapper
/// in ForEach for optimal list performance.
struct ArchitectureFeatureRow: View, Equatable {
    // MARK: - Properties

    let feature: ArchitectureItemDecorator

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            statusIcon

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(feature.name)
                    .font(AppTypography.headline.font)
                    .foregroundStyle(AppColors.text)

                Text(feature.description)
                    .font(AppTypography.subheadline.font)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(AppTypography.caption1.font)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Private Views

private extension ArchitectureFeatureRow {
    var statusIcon: some View {
        feature.icon.image(size: IconSize.md, color: feature.statusColor.uiColor)
    }
}

// MARK: - Preview

#Preview {
    List {
        ArchitectureFeatureRow(feature: ArchitectureItemDecorator(id: "1",
                                                                  name: "Clean Architecture",
                                                                  description: """
                                                                  Layered architecture with Domain, Data, and Presentation separation
                                                                  """,
                                                                  icon: .system("checkmark.circle.fill"),
                                                                  statusColor: .implemented))

        ArchitectureFeatureRow(feature: ArchitectureItemDecorator(id: "2",
                                                                  name: "Swift Testing",
                                                                  description: "Modern testing framework",
                                                                  icon: .system("circle.dashed"),
                                                                  statusColor: .pending))
    }
}
