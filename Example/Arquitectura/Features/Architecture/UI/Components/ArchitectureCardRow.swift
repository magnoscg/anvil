import SwiftUI

// MARK: - ArchitectureCardRow

/// Card-style row component displaying a single architecture feature.
///
/// Conforms to `Equatable` to enable SwiftUI to efficiently skip re-renders
/// when the underlying data hasn't changed.
struct ArchitectureCardRow: View, Equatable {
    // MARK: - Properties

    let feature: ArchitectureItemDecorator

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            statusIcon

            content

            Spacer(minLength: 0)

            chevron
        }
        .padding(Spacing.md)
        .background(cardBackground)
    }
}

// MARK: - Private Views

private extension ArchitectureCardRow {
    var statusIcon: some View {
        feature.icon.image(size: IconSize.md, color: feature.statusColor.uiColor)
    }

    var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(feature.name)
                .font(AppTypography.headline.font)
                .foregroundStyle(AppColors.text)

            Text(feature.description)
                .font(AppTypography.subheadline.font)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
        }
    }

    var chevron: some View {
        Image(systemName: "chevron.right")
            .font(AppTypography.caption1.font)
            .foregroundStyle(AppColors.textTertiary)
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.divider.opacity(0.3), lineWidth: 1))
            .shadow(color: AppColors.shadowColor.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        ArchitectureCardRow(feature: ArchitectureItemDecorator(id: "1",
                                                               name: "Clean Architecture",
                                                               description: "Layered architecture with Domain, Data, and Presentation separation",
                                                               icon: .system("checkmark.circle.fill"),
                                                               statusColor: .implemented))

        ArchitectureCardRow(feature: ArchitectureItemDecorator(id: "2",
                                                               name: "Swift Testing",
                                                               description: "Modern testing framework",
                                                               icon: .system("circle.dashed"),
                                                               statusColor: .pending))
    }
    .padding()
    .background(AppColors.background)
}
