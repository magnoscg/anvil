import SwiftUI

// MARK: - BestPracticeRow

/// Row displaying a single best practice with checkmark
struct BestPracticeRow: View {
    // MARK: - Properties

    let practice: BestPracticeDecorator

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            checkmarkIcon
            contentStack
            Spacer()
        }
    }
}

// MARK: - Private Views

private extension BestPracticeRow {
    var checkmarkIcon: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title3)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .foregroundStyle(AppColors.success)
    }

    var contentStack: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(practice.title)
                .font(AppTypography.subheadline.font)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.text)

            Text(practice.description)
                .font(AppTypography.caption1.font)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        BestPracticeRow(practice: BestPracticeDecorator(id: "1",
                                                        title: "Dependency Inversion",
                                                        description: "High-level modules should not depend on low-level modules. Both should depend on abstractions."))
        BestPracticeRow(practice: BestPracticeDecorator(id: "2",
                                                        title: "Single Responsibility",
                                                        description: "Each file and class should have one reason to change, ensuring focused code."))
    }
    .padding()
}
