import SwiftUI

// MARK: - ArchitectureView

struct ArchitectureView: View {
    // MARK: - Properties

    @State
    private var viewModel: ArchitectureViewModel

    @State
    private var retryTrigger = false

    // MARK: - Init

    init(viewModel: ArchitectureViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear

            case .loading:
                loadingView

            case let .loaded(sections):
                loadedView(sections: sections)

            case let .error(error):
                errorView(error: error)
            }
        }
        .navigationTitle(String(localized: "home.title"))
        .navigationBarTitleDisplayMode(.large)
        .background(AppColors.surface)
        .task(id: retryTrigger) {
            await viewModel.loadFeatures()
        }
    }
}

// MARK: - Private Views

private extension ArchitectureView {
    var loadingView: some View {
        LoadingStateView()
    }

    func loadedView(sections: [ArchitectureSectionDecorator]) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.features) { feature in
                            Button {
                                viewModel.navigateToDetail(featureId: feature.id)
                            } label: {
                                ArchitectureCardRow(feature: feature)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Spacing.md)
                            .accessibilityHint(String(localized: "accessibility.navigatesToDetail \(feature.name)"))
                        }
                    } header: {
                        ArchitectureSectionHeaderView(title: section.title,
                                                      icon: section.icon)
                    }
                }
            }
        }
        .background(AppColors.background)
    }

    func errorView(error: ErrorDecorator) -> some View {
        ErrorView(error: error) {
            retryTrigger.toggle()
        }
    }
}

// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        ArchitectureView(viewModel: ArchitectureViewModel(useCase: PreviewArchitectureUseCase(),
                                                          router: PreviewArchitectureRouter(),
                                                          decoratorMapper: ArchitectureDecoratorMapperImpl()))
    }
}

#Preview("Loading") {
    NavigationStack {
        ArchitectureView(viewModel: ArchitectureViewModel(useCase: PreviewLoadingUseCase(),
                                                          router: PreviewArchitectureRouter(),
                                                          decoratorMapper: ArchitectureDecoratorMapperImpl()))
    }
}

#Preview("Error") {
    NavigationStack {
        ArchitectureView(viewModel: ArchitectureViewModel(useCase: PreviewErrorUseCase(),
                                                          router: PreviewArchitectureRouter(),
                                                          decoratorMapper: ArchitectureDecoratorMapperImpl()))
    }
}

#Preview("Empty") {
    NavigationStack {
        ArchitectureView(viewModel: ArchitectureViewModel(useCase: PreviewEmptyUseCase(),
                                                          router: PreviewArchitectureRouter(),
                                                          decoratorMapper: ArchitectureDecoratorMapperImpl()))
    }
}

// MARK: - Preview Helpers

private struct PreviewArchitectureUseCase: ArchitectureUseCase {
    func execute() async throws -> [ArchitectureModel] {
        [ArchitectureModel(id: "1",
                           name: "Clean Architecture",
                           description: "Layered architecture with Domain, Data, and Presentation separation",
                           category: .architecture,
                           isImplemented: true,
                           customIcon: nil),
         ArchitectureModel(id: "2",
                           name: "MVVM + Router",
                           description: "ViewModel pattern with type-erased navigation",
                           category: .architecture,
                           isImplemented: true,
                           customIcon: nil),
         ArchitectureModel(id: "3",
                           name: "SwiftUI",
                           description: "Declarative UI framework",
                           category: .ui,
                           isImplemented: true,
                           customIcon: nil),
         ArchitectureModel(id: "4",
                           name: "SwiftData",
                           description: "Modern persistence framework",
                           category: .persistence,
                           isImplemented: false,
                           customIcon: nil)]
    }
}

private struct PreviewLoadingUseCase: ArchitectureUseCase {
    func execute() async throws -> [ArchitectureModel] {
        try await Task.sleep(for: .seconds(60))
        return []
    }
}

private struct PreviewErrorUseCase: ArchitectureUseCase {
    func execute() async throws -> [ArchitectureModel] {
        throw NSError(domain: "Preview", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
    }
}

private struct PreviewEmptyUseCase: ArchitectureUseCase {
    func execute() async throws -> [ArchitectureModel] {
        []
    }
}

@MainActor
private struct PreviewArchitectureRouter: ArchitectureRouter {
    func navigateToDetail(featureId: String) {}
    func goBack() {}
}
