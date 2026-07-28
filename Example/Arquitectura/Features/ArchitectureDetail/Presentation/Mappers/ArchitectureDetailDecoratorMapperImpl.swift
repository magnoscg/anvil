import Foundation

// MARK: - ArchitectureDetailDecoratorMapperImpl

/// Implementation of ArchitectureDetailDecoratorMapper
struct ArchitectureDetailDecoratorMapperImpl: ArchitectureDetailDecoratorMapper {
    // MARK: - Public Methods

    func map(_ model: ArchitectureDetailModel) -> ArchitectureDetailDecorator {
        ArchitectureDetailDecorator(id: model.id,
                                    icon: model.icon,
                                    name: model.name,
                                    version: model.version,
                                    subtitle: model.subtitle,
                                    statusBadge: mapStatusBadge(isImplemented: model.isImplemented),
                                    filesInvolved: model.filesInvolved.map(mapFileInfo),
                                    implementationDetails: model.implementationDetails,
                                    codeExample: model.codeExample.map(mapCodeExample),
                                    bestPractices: model.bestPractices.map(mapBestPractice),
                                    showsTryItButton: model.id == "pokemon-api")
    }
}

// MARK: - Private Methods

private extension ArchitectureDetailDecoratorMapperImpl {
    func mapStatusBadge(isImplemented: Bool) -> StatusBadgeDecorator {
        StatusBadgeDecorator(text: isImplemented
            ? String(localized: "detail.status.implemented")
            : String(localized: "detail.status.pending"),
            icon: isImplemented ? .implemented : .pending,
            color: isImplemented ? .implemented : .pending)
    }

    func mapFileInfo(_ fileInfo: ArchitectureDetailModel.FileInfo) -> FileDecorator {
        FileDecorator(id: fileInfo.id,
                      name: fileInfo.name,
                      icon: fileInfo.icon)
    }

    func mapCodeExample(_ codeExample: ArchitectureDetailModel.CodeExample) -> CodeExampleDecorator {
        CodeExampleDecorator(language: codeExample.language,
                             code: codeExample.code)
    }

    func mapBestPractice(_ bestPractice: ArchitectureDetailModel.BestPractice) -> BestPracticeDecorator {
        BestPracticeDecorator(id: bestPractice.id,
                              title: bestPractice.title,
                              description: bestPractice.description)
    }
}
