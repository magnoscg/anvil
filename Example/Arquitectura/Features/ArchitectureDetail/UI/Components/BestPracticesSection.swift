import SwiftUI

// MARK: - BestPracticesSection

/// Section displaying architecture best practices with checkmarks
struct BestPracticesSection: View {
    // MARK: - Properties

    let bestPractices: [BestPracticeDecorator]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader
            practicesCard
        }
    }
}

// MARK: - Private Views

private extension BestPracticesSection {
    var sectionHeader: some View {
        Text(String(localized: "detail.bestPractices.title"))
            .font(AppTypography.caption1.font)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
    }

    var practicesCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(bestPractices.enumerated()), id: \.element.id) { index, practice in
                BestPracticeRow(practice: practice)
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.md)

                if index < bestPractices.count - 1 {
                    Divider()
                        .padding(.leading, Spacing.md + 20 + Spacing.sm)
                }
            }
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        }
    }
}

// MARK: - Preview

#Preview {
    BestPracticesSection(bestPractices: [BestPracticeDecorator(id: "1",
                                                               title: "Dependency Inversion",
                                                               description: "High-level modules should not depend on low-level modules."),
                                         BestPracticeDecorator(id: "2",
                                                               title: "Single Responsibility",
                                                               description: "Each file and class should have one reason to change.")])
        .padding()
}
