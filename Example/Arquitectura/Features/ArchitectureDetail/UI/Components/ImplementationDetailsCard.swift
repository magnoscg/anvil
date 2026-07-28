import SwiftUI

// MARK: - ImplementationDetailsCard

/// Card displaying implementation details and code example
struct ImplementationDetailsCard: View {
    // MARK: - Properties

    let details: String
    let codeExample: CodeExampleDecorator?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader
            detailsText

            if let codeExample {
                Divider()
                    .background(AppColors.cardBorder)
                CodeBlockView(codeExample: codeExample)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        }
    }
}

// MARK: - Private Views

private extension ImplementationDetailsCard {
    var sectionHeader: some View {
        Text(String(localized: "detail.implementation.title"))
            .font(AppTypography.caption1.font)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
    }

    var detailsText: some View {
        Text(details)
            .font(AppTypography.body.font)
            .foregroundStyle(AppColors.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Preview

#Preview {
    ImplementationDetailsCard(details: "Separation of concerns using the Repository pattern and Use Cases. The domain layer remains independent of UI and Frameworks.",
                              codeExample: CodeExampleDecorator(language: "swift",
                                                                code: "protocol FetchUserUseCase {\n    func execute() async throws -> User\n}"))
        .padding()
}
