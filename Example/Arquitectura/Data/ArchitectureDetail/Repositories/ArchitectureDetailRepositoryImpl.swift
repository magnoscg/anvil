import Foundation

// MARK: - ArchitectureDetailRepositoryImpl

/// Implementation of ArchitectureDetailRepository using JSON data source
struct ArchitectureDetailRepositoryImpl: ArchitectureDetailRepository {
    // MARK: - Properties

    private let dataSource: ArchitectureDetailJSONDataSource
    private let mapper: ArchitectureDetailDTOMapper

    // MARK: - Init

    init(dataSource: ArchitectureDetailJSONDataSource,
         mapper: ArchitectureDetailDTOMapper) {
        self.dataSource = dataSource
        self.mapper = mapper
    }

    // MARK: - ArchitectureDetailRepository

    func getFeatureDetail(id: String) async throws -> ArchitectureDetailModel? {
        guard let dto = try dataSource.loadFeatureDetail(id: id) else {
            return nil
        }
        return mapper.mapToDomain(dto)
    }
}
