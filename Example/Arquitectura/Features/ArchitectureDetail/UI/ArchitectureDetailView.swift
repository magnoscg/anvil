import SwiftUI

// MARK: - ArchitectureDetailView

/// Detail view for displaying feature information
struct ArchitectureDetailView: View {
    // MARK: - Properties

    @State
    private var viewModel: ArchitectureDetailViewModel

    @State
    private var retryTrigger = false

    // MARK: - Init

    init(viewModel: ArchitectureDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingView

            case let .loaded(decorator):
                loadedView(decorator: decorator)

            case let .error(error):
                errorView(error: error)
            }
        }
        .navigationTitle(String(localized: "detail.navigation.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .task(id: retryTrigger) {
            await viewModel.loadFeature()
        }
    }
}

// MARK: - Private Views

private extension ArchitectureDetailView {
    var loadingView: some View {
        LoadingStateView()
    }

    func loadedView(decorator: ArchitectureDetailDecorator) -> some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                DetailHeroHeader(decorator: decorator)

                if !decorator.filesInvolved.isEmpty {
                    FilesInvolvedSection(files: decorator.filesInvolved)
                }

                ImplementationDetailsCard(details: decorator.implementationDetails,
                                          codeExample: decorator.codeExample)
                    .padding(.horizontal, Spacing.md)

                if !decorator.bestPractices.isEmpty {
                    BestPracticesSection(bestPractices: decorator.bestPractices)
                        .padding(.horizontal, Spacing.md)
                }

                if decorator.showsTryItButton {
                    tryItButton
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(AppColors.background)
    }

    var tryItButton: some View {
        Button {
            viewModel.navigateToPokemonList()
        } label: {
            Label(String(localized: "detail.tryIt.button"), systemImage: "play.circle.fill")
                .font(AppTypography.headline.font)
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(AppColors.accent)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, Spacing.md)
    }

    func errorView(error: ErrorDecorator) -> some View {
        ErrorView(error: error) {
            retryTrigger.toggle()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArchitectureDetailView(viewModel: ArchitectureDetailViewModel(featureId: "clean-architecture",
                                                                      useCase: PreviewDetailUseCase(),
                                                                      router: PreviewArchitectureDetailRouter(),
                                                                      decoratorMapper: ArchitectureDetailDecoratorMapperImpl()))
    }
}

// MARK: - Preview Helpers

private struct PreviewDetailUseCase: ArchitectureDetailUseCase {
    func execute(id: String) async throws -> ArchitectureDetailModel? {
        ArchitectureDetailModel(id: id,
                                name: "Clean Architecture",
                                icon: "building.2.crop.circle.fill",
                                version: "v1.2.0",
                                category: .architecture,
                                subtitle: "Architecture & Structure",
                                isImplemented: true,
                                filesInvolved: [.init(name: "Domain.swift", icon: "doc.text.fill"),
                                                .init(name: "Repository.swift", icon: "cylinder.split.1x2.fill"),
                                                .init(name: "UseCase.swift", icon: "gearshape.fill")],
                                implementationDetails: "Separation of concerns using the Repository pattern and Use Cases. The domain layer remains independent of UI and Frameworks.",
                                codeExample: .init(language: "swift",
                                                   code: "protocol FetchUserUseCase {\n    func execute() async throws -> User\n}"),
                                bestPractices: [.init(id: "1", title: "Dependency Inversion",
                                                      description: "High-level modules should not depend on low-level modules."),
                                                .init(id: "2", title: "Single Responsibility",
                                                      description: "Each file and class should have one reason to change.")])
    }
}

@MainActor
private struct PreviewArchitectureDetailRouter: ArchitectureDetailRouter {
    func navigateToPokemonList() {}
    func goBack() {}
}
