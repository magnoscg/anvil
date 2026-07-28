import SwiftUI

// MARK: - CodeBlockView

/// View displaying syntax-highlighted code with a copy button
struct CodeBlockView: View {
    // MARK: - Properties

    let codeExample: CodeExampleDecorator

    @State
    private var showCopiedFeedback = false

    @State
    private var copyCount = 0

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            headerRow
            codeContent
        }
        .task(id: copyCount) {
            guard copyCount > 0 else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

// MARK: - Private Views

private extension CodeBlockView {
    var headerRow: some View {
        HStack {
            languageLabel
            Spacer()
            copyButton
        }
    }

    var languageLabel: some View {
        Text(codeExample.language.uppercased() + " EXAMPLE")
            .font(AppTypography.caption2.font)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.textSecondary)
    }

    var copyButton: some View {
        Button(action: copyCode) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                    .font(.caption2)
                Text(showCopiedFeedback
                    ? String(localized: "detail.code.copied")
                    : String(localized: "detail.code.copy"))
                    .font(AppTypography.caption2.font)
                    .fontWeight(.medium)
            }
            .foregroundStyle(AppColors.gradientStart)
        }
        .buttonStyle(.plain)
    }

    var codeContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                lineNumbersView
                codeTextView
            }
            .padding(Spacing.md)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var lineNumbersView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(codeExample.code.components(separatedBy: "\n").enumerated()), id: \.offset) { index, _ in
                Text("\(index + 1)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(minWidth: 20, alignment: .trailing)
            }
        }
    }

    var codeTextView: some View {
        Text(codeExample.highlightedCode)
            .font(.system(.footnote, design: .monospaced))
            .textSelection(.enabled)
    }
}

// MARK: - Private Methods

private extension CodeBlockView {
    func copyCode() {
        UIPasteboard.general.string = codeExample.code
        withAnimation {
            showCopiedFeedback = true
        }
        copyCount += 1
    }
}

// MARK: - Preview

#Preview {
    CodeBlockView(codeExample: CodeExampleDecorator(language: "swift",
                                                    code: "protocol FetchUserUseCase {\n    func execute() async throws -> User\n}"))
        .padding()
}
