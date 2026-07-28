import Foundation

// MARK: - ArchitectureDetailDTOMapperImpl

/// Implementation for mapping ArchitectureDetailDTO to ArchitectureDetailModel
struct ArchitectureDetailDTOMapperImpl: ArchitectureDetailDTOMapper {
    // MARK: - ArchitectureDetailDTOMapper

    func mapToDomain(_ dto: ArchitectureDetailDTO) -> ArchitectureDetailModel {
        ArchitectureDetailModel(id: dto.id,
                                name: dto.name,
                                icon: dto.icon,
                                version: dto.version,
                                category: mapCategory(dto.category),
                                subtitle: dto.subtitle,
                                isImplemented: dto.isImplemented,
                                filesInvolved: dto.filesInvolved.map(mapFileInfo),
                                implementationDetails: dto.implementationDetails,
                                codeExample: dto.codeExample.map(mapCodeExample),
                                bestPractices: dto.bestPractices.map(mapBestPractice))
    }
}

// MARK: - Private Methods

private extension ArchitectureDetailDTOMapperImpl {
    func mapCategory(_ categoryString: String) -> ArchitectureDetailModel.Category {
        ArchitectureDetailModel.Category(rawValue: categoryString) ?? .architecture
    }

    func mapFileInfo(_ dto: FileInfoDTO) -> ArchitectureDetailModel.FileInfo {
        ArchitectureDetailModel.FileInfo(name: dto.name,
                                         icon: dto.icon)
    }

    func mapCodeExample(_ dto: CodeExampleDTO) -> ArchitectureDetailModel.CodeExample {
        ArchitectureDetailModel.CodeExample(language: dto.language,
                                            code: dto.code)
    }

    func mapBestPractice(_ dto: BestPracticeDTO) -> ArchitectureDetailModel.BestPractice {
        ArchitectureDetailModel.BestPractice(id: dto.id,
                                             title: dto.title,
                                             description: dto.description)
    }
}
