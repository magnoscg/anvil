import SwiftUI

// MARK: - DetailHeroHeader

/// Hero header view with gradient background for feature details
struct DetailHeroHeader: View {
    // MARK: - Properties

    let decorator: ArchitectureDetailDecorator

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            iconView

            VStack(alignment: .leading, spacing: Spacing.md) {
                statusRow
                titleText
                subtitleText
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradientBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }
}

// MARK: - Private Views

private extension DetailHeroHeader {
    var iconView: some View {
        Image(systemName: decorator.icon)
            .font(.title.weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .foregroundStyle(AppColors.gradientStart)
            .frame(width: 56, height: 56)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var statusRow: some View {
        HStack(spacing: Spacing.sm) {
            statusBadge
            if let version = decorator.version {
                versionBadge(version)
            }
        }
    }

    var statusBadge: some View {
        HStack(spacing: Spacing.xs) {
            decorator.statusBadge.icon.image
                .font(.caption2)
                .foregroundStyle(decorator.statusBadge.color.uiColor)

            Text(decorator.statusBadge.text)
                .font(AppTypography.caption2.font)
                .fontWeight(.semibold)
                .foregroundStyle(decorator.statusBadge.color.uiColor)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(decorator.statusBadge.color.uiColor.opacity(0.15))
        .clipShape(Capsule())
    }

    func versionBadge(_ version: String) -> some View {
        Text(version)
            .font(AppTypography.caption2.font)
            .foregroundStyle(.white.opacity(0.8))
    }

    var titleText: some View {
        Text(decorator.name)
            .font(AppTypography.largeTitle.font)
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    var subtitleText: some View {
        Text(decorator.subtitle)
            .font(AppTypography.subheadline.font)
            .foregroundStyle(.white.opacity(0.8))
    }

    var gradientBackground: some View {
        LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }
}

// MARK: - Preview

#Preview {
    DetailHeroHeader(decorator: ArchitectureDetailDecorator(id: "1",
                                                            icon: "building.2.crop.circle.fill",
                                                            name: "Clean Architecture",
                                                            version: "v1.2.0",
                                                            subtitle: "Architecture & Structure",
                                                            statusBadge: StatusBadgeDecorator(text: "IMPLEMENTED",
                                                                                              icon: .implemented,
                                                                                              color: .implemented),
                                                            filesInvolved: [],
                                                            implementationDetails: "",
                                                            codeExample: nil,
                                                            bestPractices: [],
                                                            showsTryItButton: false))
}
