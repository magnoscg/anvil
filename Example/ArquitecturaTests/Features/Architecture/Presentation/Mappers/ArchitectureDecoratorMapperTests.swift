import Foundation
import SwiftUI
import Testing
@testable import Arquitectura

// MARK: - ArchitectureDecoratorMapperTests

@Suite
@MainActor
struct ArchitectureDecoratorMapperTests {
    // MARK: - Tests

    @Test("Map single model to decorator correctly")
    func mapSingleModelToDecorator() {
        // Given
        let mapper = ArchitectureDecoratorMapperImpl()
        let implementedModel = ArchitectureModel(id: "1",
                                                 name: "Clean Architecture",
                                                 description: "Description",
                                                 category: .architecture,
                                                 isImplemented: true,
                                                 customIcon: nil)

        let pendingModel = ArchitectureModel(id: "2",
                                             name: "SwiftData",
                                             description: "Description",
                                             category: .persistence,
                                             isImplemented: false,
                                             customIcon: nil)

        // When
        let implementedDecorator = mapper.map(implementedModel)
        let pendingDecorator = mapper.map(pendingModel)

        // Then
        #expect(implementedDecorator.id == "1")
        #expect(implementedDecorator.name == "Clean Architecture")
        #expect(implementedDecorator.icon == .system("checkmark.circle.fill"))
        #expect(implementedDecorator.statusColor == .implemented)

        #expect(pendingDecorator.id == "2")
        #expect(pendingDecorator.icon == .system("circle.dashed"))
        #expect(pendingDecorator.statusColor == .pending)
    }

    @Test("MapToSections groups models by category")
    func mapToSectionsGroupsByCategory() {
        // Given
        let mapper = ArchitectureDecoratorMapperImpl()
        let models = [ArchitectureModel(id: "1",
                                        name: "Clean Architecture",
                                        description: "Description",
                                        category: .architecture,
                                        isImplemented: true,
                                        customIcon: nil),
                      ArchitectureModel(id: "2",
                                        name: "SwiftUI",
                                        description: "Description",
                                        category: .ui,
                                        isImplemented: true,
                                        customIcon: nil),
                      ArchitectureModel(id: "3",
                                        name: "MVVM",
                                        description: "Description",
                                        category: .architecture,
                                        isImplemented: true,
                                        customIcon: nil)]

        // When
        let sections = mapper.mapToSections(models)

        // Then
        #expect(sections.count == 2)

        let architectureSection = sections.first { $0.title == "Architecture" }
        #expect(architectureSection?.features.count == 2)

        let uiSection = sections.first { $0.title == "UI" }
        #expect(uiSection?.features.count == 1)
    }

    @Test("MapToSections returns empty array for empty input")
    func mapToSectionsReturnsEmptyForEmptyInput() {
        // Given
        let mapper = ArchitectureDecoratorMapperImpl()

        // When
        let sections = mapper.mapToSections([])

        // Then
        #expect(sections.isEmpty)
    }

    @Test("Map model with customIcon uses asset icon type")
    func mapModelWithCustomIconUsesAssetType() {
        // Given
        let mapper = ArchitectureDecoratorMapperImpl()
        let modelWithCustomIcon = ArchitectureModel(id: "pokemon",
                                                    name: "Pokemon API",
                                                    description: "API Example",
                                                    category: .networking,
                                                    isImplemented: false,
                                                    customIcon: "pokeball")

        // When
        let decorator = mapper.map(modelWithCustomIcon)

        // Then
        #expect(decorator.icon == .asset("pokeball"))
        #expect(decorator.statusColor == .pending)
    }
}
