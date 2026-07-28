import SwiftUI

// MARK: - ArchitectureSectionHeaderView

/// Header view for displaying section title with an icon.
/// When `isPinned` is true, the header becomes invisible (shown in toolbar instead).
struct ArchitectureSectionHeaderView: View {
    // MARK: - Properties

    let title: String
    let icon: String

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.primary)

            Text(title)
                .font(AppTypography.subheadline.font.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Preview

#Preview("Scroll") {
    ScrollView {
        LazyVStack(spacing: Spacing.sm, pinnedViews: [.sectionHeaders]) {
            Section {
                ForEach(0 ..< 5, id: \.self) { index in
                    Text("Item \(index)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.cardBackground)
                        .padding(.horizontal, Spacing.md)
                }
            } header: {
                ArchitectureSectionHeaderView(title: "Architecture", icon: "building.2")
            }

            Section {
                ForEach(0 ..< 5, id: \.self) { index in
                    Text("Item \(index)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.cardBackground)
                        .padding(.horizontal, Spacing.md)
                }
            } header: {
                ArchitectureSectionHeaderView(title: "UI Components", icon: "paintpalette")
            }
        }
    }
//    .background(AppColors.background)
}

#Preview("Solo header") {
    ArchitectureSectionHeaderView(title: "Solo Header", icon: "star.fill")
        .background(.clear)
}
