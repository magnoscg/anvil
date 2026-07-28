import SwiftUI

// MARK: - FilesInvolvedSection

/// Horizontal scrollable section showing files involved in a feature
struct FilesInvolvedSection: View {
    // MARK: - Properties

    let files: [FileDecorator]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader
            filesList
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Private Views

private extension FilesInvolvedSection {
    var sectionHeader: some View {
        Text(String(localized: "detail.files.title"))
            .font(AppTypography.caption1.font)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
    }

    var filesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                FileListRow(file: file)

                if index < files.count - 1 {
                    Divider()
                        .padding(.leading, Spacing.md + 28 + Spacing.md)
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
    FilesInvolvedSection(files: [FileDecorator(id: "1", name: "ArchitectureDomainModel.swift", icon: "doc.text.fill"),
                                 FileDecorator(id: "2", name: "ArchitectureRepository.swift",
                                               icon: "cylinder.split.1x2.fill"),
                                 FileDecorator(id: "3", name: "FetchArchitectureUseCase.swift",
                                               icon: "gearshape.fill")])
        .background(AppColors.background)
}
