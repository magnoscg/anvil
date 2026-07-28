import Foundation
@testable import Arquitectura

// MARK: - MockArchitectureDetailDecoratorMapper

/// Mock implementation of ArchitectureDetailDecoratorMapper for testing
struct MockArchitectureDetailDecoratorMapper: ArchitectureDetailDecoratorMapper {
    // MARK: - Properties

    var mapResult: ArchitectureDetailDecorator?

    // MARK: - Init

    init(mapResult: ArchitectureDetailDecorator? = nil) {
        self.mapResult = mapResult
    }

    // MARK: - ArchitectureDetailDecoratorMapper

    func map(_ model: ArchitectureDetailModel) -> ArchitectureDetailDecorator {
        if let result = mapResult {
            return result
        }

        return ArchitectureDetailDecorator(id: model.id,
                                           icon: model.icon,
                                           name: model.name,
                                           version: model.version,
                                           subtitle: model.subtitle,
                                           statusBadge: StatusBadgeDecorator(text: model
                                               .isImplemented ? "Implemented" : "Pending",
                                               icon: model
                                                   .isImplemented ? .implemented : .pending,
                                               color: model
                                                   .isImplemented ? .implemented : .pending),
                                           filesInvolved: model.filesInvolved.map { fileInfo in
                                               FileDecorator(id: fileInfo.id, name: fileInfo.name, icon: fileInfo.icon)
                                           },
                                           implementationDetails: model.implementationDetails,
                                           codeExample: model.codeExample.map { codeExample in
                                               CodeExampleDecorator(language: codeExample.language,
                                                                    code: codeExample.code)
                                           },
                                           bestPractices: model.bestPractices.map { bestPractice in
                                               BestPracticeDecorator(id: bestPractice.id,
                                                                     title: bestPractice.title,
                                                                     description: bestPractice.description)
                                           },
                                           showsTryItButton: model.id == "pokemon-api")
    }
}
