import Foundation

// MARK: - ArchitectureDTOMapperImpl

/// Implementation of ArchitectureDTOMapper
struct ArchitectureDTOMapperImpl: ArchitectureDTOMapper {
    // MARK: - Public Methods

    func map(_ dto: ArchitectureDTO) -> ArchitectureModel {
        ArchitectureModel(id: dto.id,
                          name: dto.name,
                          description: dto.description,
                          category: mapCategory(dto.category),
                          isImplemented: dto.isImplemented,
                          customIcon: nil)
    }

    func map(_ dtos: [ArchitectureDTO]) -> [ArchitectureModel] {
        dtos.map { map($0) }
    }

    // MARK: - Private Methods

    private func mapCategory(_ categoryString: String) -> ArchitectureModel.Category {
        ArchitectureModel.Category.allCases.first {
            $0.rawValue.caseInsensitiveCompare(categoryString) == .orderedSame
        } ?? .architecture
    }
}
