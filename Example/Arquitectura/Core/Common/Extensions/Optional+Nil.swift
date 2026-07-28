import Foundation

// MARK: - Optional+Nil

extension Optional {
    // MARK: - Properties

    var isNil: Bool {
        self == nil
    }

    var isNotNil: Bool {
        self != nil
    }
}
