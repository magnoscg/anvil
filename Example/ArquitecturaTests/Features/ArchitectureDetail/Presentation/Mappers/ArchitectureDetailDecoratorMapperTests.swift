import Foundation
import Testing
@testable import Arquitectura

// MARK: - ArchitectureDetailDecoratorMapperTests

@Suite
@MainActor
struct ArchitectureDetailDecoratorMapperTests {
    // MARK: - Helper Methods

    private func makeModel(id: String = "test-id",
                           name: String = "Test Feature",
                           icon: String = "building.2",
                           version: String? = "1.0",
                           category: ArchitectureDetailModel.Category = .architecture,
                           subtitle: String = "Test subtitle",
                           isImplemented: Bool = true,
                           filesInvolved: [ArchitectureDetailModel.FileInfo] = [],
                           implementationDetails: String = "Implementation details",
                           codeExample: ArchitectureDetailModel.CodeExample? = nil,
                           bestPractices: [ArchitectureDetailModel.BestPractice] = []) -> ArchitectureDetailModel {
        ArchitectureDetailModel(id: id,
                                name: name,
                                icon: icon,
                                version: version,
                                category: category,
                                subtitle: subtitle,
                                isImplemented: isImplemented,
                                filesInvolved: filesInvolved,
                                implementationDetails: implementationDetails,
                                codeExample: codeExample,
                                bestPractices: bestPractices)
    }

    // MARK: - Tests

    @Test("Map implemented model to decorator correctly")
    func mapImplementedModelToDecorator() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let model = makeModel(id: "test-id",
                              name: "Clean Architecture",
                              icon: "building.2",
                              subtitle: "Layered architecture pattern",
                              isImplemented: true)

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.id == "test-id")
        #expect(decorator.name == "Clean Architecture")
        #expect(decorator.icon == "building.2")
        #expect(decorator.subtitle == "Layered architecture pattern")
        #expect(decorator.statusBadge.icon == .implemented)
        #expect(decorator.statusBadge.color == .implemented)
    }

    @Test("Map pending model to decorator correctly")
    func mapPendingModelToDecorator() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let model = makeModel(id: "pending-id",
                              name: "Pending Feature",
                              subtitle: "Not implemented yet",
                              isImplemented: false)

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.id == "pending-id")
        #expect(decorator.name == "Pending Feature")
        #expect(decorator.statusBadge.icon == .pending)
        #expect(decorator.statusBadge.color == .pending)
    }

    @Test("Map model with files involved")
    func mapModelWithFilesInvolved() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let files = [ArchitectureDetailModel.FileInfo(id: "1", name: "ViewModel.swift", icon: "doc.text"),
                     ArchitectureDetailModel.FileInfo(id: "2", name: "View.swift", icon: "doc.text")]
        let model = makeModel(filesInvolved: files)

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.filesInvolved.count == 2)
        #expect(decorator.filesInvolved[0].name == "ViewModel.swift")
        #expect(decorator.filesInvolved[1].name == "View.swift")
    }

    @Test("Map model with code example")
    func mapModelWithCodeExample() throws {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let codeExample = ArchitectureDetailModel.CodeExample(language: "swift",
                                                              code: "let example = true")
        let model = makeModel(codeExample: codeExample)

        // When
        let decorator = mapper.map(model)

        // Then
        let result = try #require(decorator.codeExample)
        #expect(result.language == "swift")
        #expect(result.code == "let example = true")
    }

    @Test("Map model without code example")
    func mapModelWithoutCodeExample() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let model = makeModel(codeExample: nil)

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.codeExample.isNil)
    }

    @Test("Map model with best practices")
    func mapModelWithBestPractices() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let bestPractices = [ArchitectureDetailModel.BestPractice(id: "1",
                                                                  title: "Use protocols",
                                                                  description: "Always depend on abstractions"),
                             ArchitectureDetailModel.BestPractice(id: "2",
                                                                  title: "Single responsibility",
                                                                  description: "Each class should have one reason to change")]
        let model = makeModel(bestPractices: bestPractices)

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.bestPractices.count == 2)
        #expect(decorator.bestPractices[0].title == "Use protocols")
        #expect(decorator.bestPractices[1].title == "Single responsibility")
    }

    @Test("Decorator statusBadge text is localized for implemented")
    func decoratorStatusTextLocalizedImplemented() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let model = makeModel(isImplemented: true)

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(!decorator.statusBadge.text.isEmpty)
    }

    @Test("Decorator statusBadge text is localized for pending")
    func decoratorStatusTextLocalizedPending() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let model = makeModel(isImplemented: false)

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(!decorator.statusBadge.text.isEmpty)
    }

    @Test("Map preserves version when present")
    func mapPreservesVersion() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let model = makeModel(version: "2.0.1")

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.version == "2.0.1")
    }

    @Test("Map preserves nil version")
    func mapPreservesNilVersion() {
        // Given
        let mapper = ArchitectureDetailDecoratorMapperImpl()
        let model = makeModel(version: nil)

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.version.isNil)
    }
}
