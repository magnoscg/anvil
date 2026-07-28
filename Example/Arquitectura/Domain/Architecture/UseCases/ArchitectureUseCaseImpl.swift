import Foundation

// MARK: - ArchitectureUseCaseImpl

/// Implementation of the ArchitectureUseCase
struct ArchitectureUseCaseImpl: ArchitectureUseCase {
    // MARK: - Properties

    private let repository: ArchitectureRepository

    // MARK: - Init

    init(repository: ArchitectureRepository) {
        self.repository = repository
    }

    // MARK: - Public Methods

    func execute() async throws -> [ArchitectureModel] {
        do {
            let features = try await repository.getFeatures()
            return features.sorted { $0.category.rawValue < $1.category.rawValue }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw DomainError.map(error)
        }
    }
}
