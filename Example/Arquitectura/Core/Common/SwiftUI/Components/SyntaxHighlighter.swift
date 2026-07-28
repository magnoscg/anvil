import SwiftUI

// MARK: - SyntaxHighlighter

/// Utility for creating syntax-highlighted AttributedStrings for Swift code
enum SyntaxHighlighter {
    // MARK: - Colors

    enum Colors {
        static let keyword = Color(red: 0.98, green: 0.26, blue: 0.63) // Pink/Magenta for keywords
        static let type = Color(red: 0.40, green: 0.85, blue: 0.95) // Cyan for types
        static let string = Color(red: 0.98, green: 0.41, blue: 0.36) // Red for strings
        static let comment = Color(red: 0.55, green: 0.55, blue: 0.55) // Gray for comments
        static let number = Color(red: 0.85, green: 0.67, blue: 0.28) // Orange for numbers
        static let function = Color(red: 0.80, green: 0.90, blue: 0.45) // Yellow-green for functions
        static let property = Color(red: 0.40, green: 0.75, blue: 0.68) // Teal for properties
        static let text = Color.white // White text for dark background
    }

    // MARK: - Keywords

    private static let keywords: Set<String> = ["protocol", "struct", "class", "enum", "extension", "typealias",
                                                "func", "var", "let", "static", "private", "fileprivate", "internal",
                                                "public", "open",
                                                "init", "deinit", "subscript", "operator", "precedencegroup",
                                                "if", "else", "guard", "switch", "case", "default", "where",
                                                "fallthrough",
                                                "for", "while", "repeat", "in", "return", "break", "continue", "defer",
                                                "do", "try", "catch", "throw", "throws", "rethrows", "async", "await",
                                                "import", "as", "is", "nil", "true", "false", "self", "Self", "super",
                                                "get", "set", "willSet", "didSet", "inout", "mutating", "nonmutating",
                                                "final", "required", "convenience", "override", "lazy", "weak",
                                                "unowned",
                                                "some", "any", "associatedtype", "typealias"]

    private static let typeKeywords: Set<String> = ["String", "Int", "Double", "Float", "Bool", "Character",
                                                    "Array", "Dictionary", "Set", "Optional", "Result",
                                                    "Error", "Codable", "Sendable", "Equatable", "Hashable",
                                                    "Identifiable",
                                                    "View", "some", "any", "Never", "Void", "Date", "Data", "URL",
                                                    "Task", "Actor", "MainActor"]

    private static let attributes: Set<String> = ["@State", "@Binding", "@Observable", "@MainActor", "@Model",
                                                  "@Published", "@Environment", "@EnvironmentObject", "@StateObject",
                                                  "@ObservedObject", "@AppStorage", "@SceneStorage", "@FocusState",
                                                  "@ViewBuilder", "@escaping", "@autoclosure", "@discardableResult",
                                                  "@available", "@objc", "@frozen", "@inlinable", "@usableFromInline",
                                                  "@Attribute", "@Query", "@Relationship", "@Test", "@Suite"]

    // MARK: - Public Methods

    /// Highlights Swift code and returns an AttributedString
    /// - Parameter code: The Swift code to highlight
    /// - Returns: An AttributedString with syntax highlighting applied
    static func highlight(_ code: String) -> AttributedString {
        var result = AttributedString()
        let lines = code.components(separatedBy: "\n")

        for (lineIndex, line) in lines.enumerated() {
            let highlightedLine = highlightLine(line)
            result.append(highlightedLine)

            if lineIndex < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }

        return result
    }
}

// MARK: - Private Methods

private extension SyntaxHighlighter {
    static func highlightLine(_ line: String) -> AttributedString {
        // Check for comment first
        if let commentRange = line.range(of: "//") {
            let beforeComment = String(line[..<commentRange.lowerBound])
            let comment = String(line[commentRange.lowerBound...])

            var result = highlightTokens(in: beforeComment)
            var commentAttr = AttributedString(comment)
            commentAttr.foregroundColor = Colors.comment
            result.append(commentAttr)
            return result
        }

        return highlightTokens(in: line)
    }

    static func highlightTokens(in text: String) -> AttributedString {
        var result = AttributedString()
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            let char = text[currentIndex]

            if char == "\"" || char == "'" {
                let (stringAttr, newIndex) = highlightString(in: text, from: currentIndex, delimiter: char)
                result.append(stringAttr)
                currentIndex = newIndex
                continue
            }

            if char.isLetter || char == "_" || char == "@" {
                let (wordAttr, newIndex) = highlightWord(in: text, from: currentIndex)
                result.append(wordAttr)
                currentIndex = newIndex
                continue
            }

            if char.isNumber {
                let (numberAttr, newIndex) = highlightNumber(in: text, from: currentIndex)
                result.append(numberAttr)
                currentIndex = newIndex
                continue
            }

            var charAttr = AttributedString(String(char))
            charAttr.foregroundColor = Colors.text
            result.append(charAttr)
            currentIndex = text.index(after: currentIndex)
        }

        return result
    }

    static func highlightString(in text: String, from startIndex: String.Index,
                                delimiter: Character) -> (AttributedString, String.Index) {
        var currentIndex = text.index(after: startIndex)

        while currentIndex < text.endIndex {
            let char = text[currentIndex]
            if char == delimiter, text[text.index(before: currentIndex)] != "\\" {
                currentIndex = text.index(after: currentIndex)
                break
            }
            currentIndex = text.index(after: currentIndex)
        }

        let stringContent = String(text[startIndex ..< currentIndex])
        var stringAttr = AttributedString(stringContent)
        stringAttr.foregroundColor = Colors.string
        return (stringAttr, currentIndex)
    }

    static func highlightWord(in text: String, from startIndex: String.Index) -> (AttributedString, String.Index) {
        var currentIndex = startIndex

        // Handle @ prefix for attributes (e.g., @MainActor, @Observable)
        if currentIndex < text.endIndex, text[currentIndex] == "@" {
            currentIndex = text.index(after: currentIndex)
        }

        while currentIndex < text.endIndex,
              text[currentIndex].isLetter || text[currentIndex].isNumber || text[currentIndex] == "_" {
            currentIndex = text.index(after: currentIndex)
        }

        let word = String(text[startIndex ..< currentIndex])
        var wordAttr = AttributedString(word)

        let isFunctionCall = isFunctionName(word: word, at: currentIndex, in: text)
        wordAttr.foregroundColor = colorForWord(word, isFunctionCall: isFunctionCall)

        return (wordAttr, currentIndex)
    }

    static func highlightNumber(in text: String, from startIndex: String.Index) -> (AttributedString, String.Index) {
        var currentIndex = startIndex
        while currentIndex < text.endIndex, text[currentIndex].isNumber || text[currentIndex] == "." {
            currentIndex = text.index(after: currentIndex)
        }

        let number = String(text[startIndex ..< currentIndex])
        var numberAttr = AttributedString(number)
        numberAttr.foregroundColor = Colors.number
        return (numberAttr, currentIndex)
    }

    static func isFunctionName(word: String, at index: String.Index, in text: String) -> Bool {
        guard index < text.endIndex,
              let nextNonWhitespace = text[index...].firstIndex(where: { !$0.isWhitespace }) else {
            return false
        }
        return text[nextNonWhitespace] == "("
    }

    static func colorForWord(_ word: String, isFunctionCall: Bool) -> Color {
        if word.hasPrefix("@") && attributes.contains(word) {
            Colors.keyword
        } else if keywords.contains(word) {
            Colors.keyword
        } else if typeKeywords.contains(word) || (word.first?.isUppercase == true && !isFunctionCall) {
            Colors.type
        } else if isFunctionCall {
            Colors.function
        } else {
            Colors.text
        }
    }
}
