import SwiftUI

// MARK: - FileListRow

/// List row displaying a single file with icon, name, and chevron
struct FileListRow: View {
    // MARK: - Properties

    let file: FileDecorator

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            iconView
            nameText
            Spacer()
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Private Views

private extension FileListRow {
    var iconView: some View {
        Image(systemName: file.icon)
            .font(.title3)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .foregroundStyle(AppColors.gradientStart)
            .frame(width: 44, height: 44)
    }

    var nameText: some View {
        Text(file.name)
            .font(AppTypography.subheadline.font)
            .foregroundStyle(AppColors.text)
            .lineLimit(1)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        FileListRow(file: FileDecorator(id: "1", name: "Domain.swift", icon: "doc.text.fill"))
        Divider()
        FileListRow(file: FileDecorator(id: "2", name: "ArchitectureRepository.swift", icon: "cylinder.split.1x2.fill"))
        Divider()
        FileListRow(file: FileDecorator(id: "3", name: "FetchArchitectureUseCase.swift", icon: "gearshape.fill"))
    }
    .background(AppColors.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
}
