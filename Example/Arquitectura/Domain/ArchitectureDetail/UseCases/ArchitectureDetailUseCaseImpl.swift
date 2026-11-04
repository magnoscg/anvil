import Foundation

// MARK: - ArchitectureDetailUseCaseImpl

/// Implementation of ArchitectureDetailUseCase
struct ArchitectureDetailUseCaseImpl: ArchitectureDetailUseCase {
    // MARK: - Properties

    private let repository: ArchitectureDetailRepository

    // MARK: - Init

    init(repository: ArchitectureDetailRepository) {
        self.repository = repository
    }

    // MARK: - Public Methods

    func execute(id: String) async throws -> ArchitectureDetailModel? {
        try await repository.getFeatureDetail(id: id)
    }
}
