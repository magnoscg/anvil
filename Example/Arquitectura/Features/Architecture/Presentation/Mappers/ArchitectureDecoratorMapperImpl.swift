import Foundation

// MARK: - ArchitectureDecoratorMapperImpl

/// Implementation of ArchitectureDecoratorMapper
/// Pure data transformation — no actor isolation needed
struct ArchitectureDecoratorMapperImpl: ArchitectureDecoratorMapper {
    // MARK: - Public Methods

    func map(_ model: ArchitectureModel) -> ArchitectureItemDecorator {
        ArchitectureItemDecorator(id: model.id,
                                  name: model.name,
                                  description: model.description,
                                  icon: icon(for: model),
                                  statusColor: model.isImplemented ? .implemented : .pending)
    }

    func mapToSections(_ models: [ArchitectureModel]) -> [ArchitectureSectionDecorator] {
        let grouped = Dictionary(grouping: models) { $0.category }
        return ArchitectureModel.Category.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return ArchitectureSectionDecorator(id: category.rawValue,
                                                title: category.rawValue,
                                                icon: categoryIcon(for: category),
                                                features: items.map { map($0) })
        }
    }
}

// MARK: - Private

private extension ArchitectureDecoratorMapperImpl {
    func icon(for model: ArchitectureModel) -> IconType {
        guard let customIcon = model.customIcon else {
            return model.isImplemented ? .system("checkmark.circle.fill") : .system("circle.dashed")
        }

        return .asset(customIcon)
    }

    func categoryIcon(for category: ArchitectureModel.Category) -> String {
        switch category {
        case .architecture:
            "building.2"
        case .ui:
            "paintpalette"
        case .testing:
            "checkmark.seal"
        case .persistence:
            "cylinder.split.1x2"
        case .networking:
            "network"
        case .security:
            "lock.shield"
        }
    }
}
