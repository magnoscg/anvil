import Foundation

// MARK: - ArchitectureDetailState

/// State enum for the Architecture Detail screen
enum ArchitectureDetailState: Equatable {
    case idle
    case loading
    case loaded(ArchitectureDetailDecorator)
    case error(ErrorDecorator)
}
