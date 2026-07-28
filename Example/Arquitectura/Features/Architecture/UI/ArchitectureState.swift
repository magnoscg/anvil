import Foundation

// MARK: - ArchitectureState

/// State enum for the Architecture feature screen
enum ArchitectureState: Equatable {
    case idle
    case loading
    case loaded([ArchitectureSectionDecorator])
    case error(ErrorDecorator)
}
