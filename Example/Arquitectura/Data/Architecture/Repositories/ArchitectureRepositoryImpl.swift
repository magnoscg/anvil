import Foundation

// MARK: - ArchitectureRepositoryImpl

/// Implementation of ArchitectureRepository using static data.
/// Since architecture features are static documentation data (not dynamic API data),
/// we use StaticDataSource which returns domain models directly.
struct ArchitectureRepositoryImpl: ArchitectureRepository {
    // MARK: - Properties

    private let staticDataSource: ArchitectureStaticDataSource

    // MARK: - Init

    init(staticDataSource: ArchitectureStaticDataSource) {
        self.staticDataSource = staticDataSource
    }

    // MARK: - Public Methods

    func getFeatures() async throws -> [ArchitectureModel] {
        staticDataSource.getFeatures()
    }

    func getFeature(id: String) async throws -> ArchitectureModel? {
        staticDataSource.getFeature(id: id)
    }
}
