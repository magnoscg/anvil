import Foundation

// MARK: - ArchitectureDetailDecorator

/// Decorator for displaying architecture feature details
struct ArchitectureDetailDecorator: Equatable {
    // MARK: - Properties

    let id: String
    let icon: String
    let name: String
    let version: String?
    let subtitle: String
    let statusBadge: StatusBadgeDecorator
    let filesInvolved: [FileDecorator]
    let implementationDetails: String
    let codeExample: CodeExampleDecorator?
    let bestPractices: [BestPracticeDecorator]
    let showsTryItButton: Bool
}

// MARK: - StatusBadgeDecorator

/// Decorator for the status badge in hero header
struct StatusBadgeDecorator: Equatable {
    let text: String
    let icon: StatusIcon
    let color: ArchitectureItemDecorator.StatusColor
}

// MARK: - FileDecorator

/// Decorator for a file card in the files involved section
struct FileDecorator: Equatable, Identifiable {
    let id: String
    let name: String
    let icon: String
}

// MARK: - CodeExampleDecorator

/// Decorator for the code example section
struct CodeExampleDecorator {
    // MARK: - Properties

    let language: String
    let code: String
    let highlightedCode: AttributedString

    // MARK: - Init

    /// Initializes the decorator and computes syntax highlighting once.
    /// - Parameters:
    ///   - language: The programming language of the code snippet.
    ///   - code: The raw code string to display.
    init(language: String, code: String) {
        self.language = language
        self.code = code
        self.highlightedCode = SyntaxHighlighter.highlight(code)
    }
}

// MARK: - CodeExampleDecorator + Equatable

extension CodeExampleDecorator: Equatable {
    /// Manual Equatable implementation excluding highlightedCode (AttributedString is not Equatable).
    /// Since highlightedCode is derived from code, comparing code is sufficient.
    static func == (lhs: CodeExampleDecorator, rhs: CodeExampleDecorator) -> Bool {
        lhs.language == rhs.language && lhs.code == rhs.code
    }
}

// MARK: - BestPracticeDecorator

/// Decorator for a single best practice item
struct BestPracticeDecorator: Equatable, Identifiable {
    let id: String
    let title: String
    let description: String
}
