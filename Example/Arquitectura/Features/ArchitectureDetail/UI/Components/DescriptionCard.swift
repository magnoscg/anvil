import SwiftUI

// MARK: - DescriptionCard

/// Card component for displaying description text with a section label.
struct DescriptionCard: View {
    // MARK: - Properties

    let title: String
    let description: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppTypography.caption1.font)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(description)
                .font(AppTypography.body.font)
                .foregroundStyle(AppColors.text)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }
}

// MARK: - Private Views

private extension DescriptionCard {
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.divider.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Preview

#Preview {
    DescriptionCard(title: "Description",
                    description: "Layered architecture with Domain, Data, and Presentation separation. This pattern ensures clean separation of concerns and makes the codebase more maintainable and testable.")
        .padding()
        .background(AppColors.background)
}
