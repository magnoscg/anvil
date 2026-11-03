# PROJECT-STRUCTURE.md — Folder Structure

> Operational guide: where to create each file in the project.

## Complete Structure

Sources live in `[Project]/` (one app target); tests live in `[Project]Tests/`. Layers are folders, not modules.

```text
[Project]/
+- App/
|  +- Application/
|  |  +- AppMain.swift                # @main: creates AppDependencies, AppRouterImpl (+ SwiftDataStack)
|  +- Config/
|  |  +- AppDependencies.swift        # App-lifetime dependencies (APIClient, SwiftDataStack)
|  |  +- AppEnvironment.swift
|  |  +- EnvironmentConfiguration.swift
|  |  +- Xcconfig/                    # Base.xcconfig + one xcconfig per scheme
|  +- Navigation/
|  |  +- AppRouter.swift              # @MainActor protocol: push / pop / popToRoot
|  |  +- AppRouterImpl.swift          # Owns the NavigationPath (`path`)
|  |  +- AppNavigationCoordinator.swift # Deep links, state restoration, debounced save
|  |  +- RootNavigationView.swift     # NavigationStack, .onOpenURL, @SceneStorage, resolvers
|  +- DI/
|     +- PersistenceAssembly.swift    # Only when SwiftData is enabled
|
+- Core/
|  +- Common/
|  |  +- Extensions/
|  |  +- Models/ErrorDecorator.swift  # Shared presentation error model
|  |  +- SwiftUI/
|  |     +- Builders/                 # @ViewBuilder helpers
|  |     +- Components/               # Shared views (ErrorView, LoadingStateView)
|  |     +- Modifiers/                # All custom ViewModifiers
|  +- DesignSystem/Tokens/            # AppColors, AppTypography, Spacing, AppIcons, IconSize
|  +- Networking/                     # APIClient + Impl, Endpoint, APIEndpoint, APIError, interceptors
|  |  +- Security/                    # URLSessionFactory, SSLPinningDelegate
|  +- Persistence/                    # Only when SwiftData is enabled
|  |  +- SwiftDataStack.swift
|  |  +- ModelContainerShared.swift   # ModelContainer.shared / .preview
|  +- Security/KeychainHelper.swift
|
+- Domain/                            # GLOBAL, organized by domain concept
|  +- Common/DomainError.swift
|  +- <Feature>/                      # Example: Article
|     +- Models/
|     |  +- <Feature>Model.swift      # e.g., ArticleModel.swift
|     +- UseCases/
|     |  +- <Feature>UseCase.swift    # Protocol
|     |  +- <Feature>UseCaseImpl.swift # Implementation
|     +- Repositories/
|        +- <Feature>Repository.swift # Protocol (owned by Domain)
|
+- Data/                              # GLOBAL, mirrors Domain
|  +- Common/DomainErrorMapping.swift # DomainError.map + DomainError.catching
|  +- <Feature>/                      # Example: Article
|     +- Repositories/
|     |  +- <Feature>RepositoryImpl.swift  # Impl only
|     +- DataSources/                 # Protocol + Impl in one file
|     |  +- <Feature>RemoteDataSource.swift
|     |  +- <Feature>LocalDataSource.swift     # Optional (UserDefaults)
|     |  +- <Feature>KeychainDataSource.swift  # Optional
|     +- DTO/
|     |  +- <Feature>DTO.swift
|     +- Mappers/
|        +- <Feature>DTOMapper.swift  # Protocol + Impl in one file
|
+- Features/                          # PRESENTATION ONLY, one folder per screen
|  +- <Feature>/                      # Example: Article
|     +- DI/
|     |  +- <Feature>Factory.swift
|     +- UI/
|     |  +- <Feature>View.swift       # Main view
|     |  +- <Feature>State.swift      # State enum only
|     |  +- <Feature>Decorator.swift  # UI decorators
|     |  +- <Feature>AccessibilityID.swift # Optional (UI tests)
|     |  +- Components/               # Feature-specific subviews (add when needed)
|     +- Presentation/
|     |  +- ViewModels/
|     |  |  +- <Feature>ViewModel.swift
|     |  +- Mappers/
|     |     +- <Feature>DecoratorMapper.swift  # Protocol + Impl in one file
|     +- Navigation/
|        +- <Feature>Router.swift     # Route enum + Protocol + Impl
|        +- <Feature>RouteResolver.swift # Optional
|
+- Resources/                         # Assets.xcassets, Strings/Localizable.xcstrings
+- Info.plist

[Project]Tests/
+- Domain/<Feature>/UseCases/<Feature>UseCaseTests.swift
+- Data/<Feature>/
|  +- Repositories/<Feature>RepositoryTests.swift
|  +- Mappers/<Feature>DTOMapperTests.swift
+- Features/<Feature>/Presentation/
|  +- ViewModels/<Feature>ViewModelTests.swift
|  +- Mappers/<Feature>DecoratorMapperTests.swift
+- Mocks/                             # Shared mocks: <Feature><Type>Mock.swift
|  +- <Feature>UseCaseMock.swift
|  +- <Feature>RepositoryMock.swift
|  +- <Feature>RouterMock.swift
|  +- <Feature>RemoteDataSourceMock.swift
|  +- <Feature>DTOMapperMock.swift
|  +- <Feature>DecoratorMapperMock.swift
+- DataStubs/<Feature>/               # Optional (UI tests)
+- UITests/                           # Optional (UI tests): Screens/, Support/Screens/
```

> `Domain/` and `Data/` are organized by **concept**. `anvil feature` starts with one folder per feature; merge them (for example `Domain/Article/`) when several screens share a concept. `Features/` stays one folder per screen.

## Quick Guide: Where Does Each Thing Go?

### Domain Layer (Global)

| Folder | Content | Example |
| --- | --- | --- |
| **Domain/Common/** | `DomainError` (shared by every feature) | `DomainError.swift` |
| **Domain/\<Feature\>/Models/** | Domain models (Sendable) | `ArticleModel.swift` |
| **Domain/\<Feature\>/UseCases/** | Protocol + Implementation (separate files) | `ArticleUseCase.swift`, `ArticleUseCaseImpl.swift` |
| **Domain/\<Feature\>/Repositories/** | Repository protocol | `ArticleRepository.swift` |

### Data Layer (Global)

| Folder | Content | Example |
| --- | --- | --- |
| **Data/Common/** | `DomainError.map` / `DomainError.catching` | `DomainErrorMapping.swift` |
| **Data/\<Feature\>/Repositories/** | Repository Impl only (conforms to the Domain protocol) | `ArticleRepositoryImpl.swift` |
| **Data/\<Feature\>/DataSources/** | Remote (API), optional Local (UserDefaults) / Keychain; protocol + Impl in one file | `ArticleRemoteDataSource.swift`, `ArticleLocalDataSource.swift` |
| **Data/\<Feature\>/DTO/** | Data Transfer Objects (only if API) | `ArticleDTO.swift` |
| **Data/\<Feature\>/Mappers/** | DTO -> Model mappers; protocol + Impl in one file | `ArticleDTOMapper.swift` |

### Features (Presentation Only)

| Folder | Content | Example |
| --- | --- | --- |
| **DI/** | Factory / Assembly. Returns `some View`. | `ArticleFactory.swift` |
| **UI/** | SwiftUI Views, State enum, Decorators. | `ArticleView.swift`, `ArticleState.swift`, `ArticleDecorator.swift` |
| **UI/Components/** | Feature-specific subviews. | `ArticleRow.swift`, `ArticleDetailView.swift` |
| **Presentation/ViewModels/** | `@MainActor @Observable` classes. | `ArticleViewModel.swift` |
| **Presentation/Mappers/** | Domain -> Decorator mappers; protocol + Impl in one file. | `ArticleDecoratorMapper.swift` |
| **Navigation/** | Route enum (inside Router) + optional RouteResolver. | `ArticleRouter.swift`, `ArticleRouteResolver.swift` |

### Navigation Structure

| File | Purpose | Example |
| --- | --- | --- |
| `<Feature>Router.swift` | **Always**. Route enum + `@MainActor` protocol + `struct` Impl | `ArticleRouter.swift` |
| `<Feature>RouteResolver.swift` | **Optional**. `ViewModifier` + `View.with<Feature>Routes(appRouter:dependencies:)` | `ArticleRouteResolver.swift` |

**Note**: The Route enum lives inside the Router file, not in a separate file. Add a resolver only when the feature owns destinations, and register it in `App/Navigation/RootNavigationView.swift`.

### Tests Structure

| Folder | What to test |
| --- | --- |
| `[Project]Tests/Domain/<Feature>/UseCases/` | UseCase tests with mocked repositories |
| `[Project]Tests/Data/<Feature>/Repositories/` | Repository tests with mocked data sources and mappers (incl. error mapping) |
| `[Project]Tests/Data/<Feature>/Mappers/` | DTOMapper tests |
| `[Project]Tests/Features/<Feature>/Presentation/ViewModels/` | ViewModel tests with mocked use cases |
| `[Project]Tests/Features/<Feature>/Presentation/Mappers/` | DecoratorMapper tests |
| `[Project]Tests/Mocks/` | Shared mocks |

## Layer Separation Rules

### Domain Layer
- **NO** imports of SwiftUI, SwiftData, URLSession
- **ONLY** pure Swift, Foundation for basic types
- Contains: Models, UseCases (protocol + impl), Repository **protocols**, `DomainError`
- **Does NOT reference**: `APIError`, DTOs or any other infrastructure type

### Data Layer
- **CAN** import: Foundation, SwiftData (for persistence), networking
- **CANNOT** import: SwiftUI
- Contains: Repository **implementations**, DataSources, DTOs, DTOMappers, `DomainErrorMapping`

### Features (Presentation)
- **CAN** import: SwiftUI, Domain layer protocols
- **CANNOT** import: Data layer directly (only through DI)
- Contains: Views, ViewModels, State, Decorators, DecoratorMappers, Routers, Factories

## File Naming Conventions

**IMPORTANT**: All files related to a feature must start with the feature name. UseCase and Repository protocols and their `Impl` go in **separate files**; DataSources, DTOMappers, DecoratorMappers and the Router keep protocol and `Impl` in **one file**.

| Type | Pattern | Example |
| --- | --- | --- |
| Domain Model | `<Feature>Model.swift` | `ArticleModel.swift` |
| UseCase Protocol | `<Feature>UseCase.swift` | `ArticleUseCase.swift` |
| UseCase Impl | `<Feature>UseCaseImpl.swift` | `ArticleUseCaseImpl.swift` |
| Repository Protocol (Domain) | `<Feature>Repository.swift` | `ArticleRepository.swift` |
| Repository Impl (Data) | `<Feature>RepositoryImpl.swift` | `ArticleRepositoryImpl.swift` |
| Remote DataSource (protocol + Impl) | `<Feature>RemoteDataSource.swift` | `ArticleRemoteDataSource.swift` |
| Local DataSource (protocol + Impl) | `<Feature>LocalDataSource.swift` | `ArticleLocalDataSource.swift` |
| Keychain DataSource (protocol + Impl) | `<Feature>KeychainDataSource.swift` | `ArticleKeychainDataSource.swift` |
| DTO | `<Feature>DTO.swift` | `ArticleDTO.swift` |
| DTOMapper (protocol + Impl) | `<Feature>DTOMapper.swift` | `ArticleDTOMapper.swift` |
| View | `<Feature>View.swift` | `ArticleView.swift` |
| State | `<Feature>State.swift` | `ArticleState.swift` |
| Decorator | `<Feature>Decorator.swift` | `ArticleDecorator.swift` |
| ViewModel | `<Feature>ViewModel.swift` | `ArticleViewModel.swift` |
| DecoratorMapper (protocol + Impl) | `<Feature>DecoratorMapper.swift` | `ArticleDecoratorMapper.swift` |
| Factory | `<Feature>Factory.swift` | `ArticleFactory.swift` |
| Router | `<Feature>Router.swift` | `ArticleRouter.swift` |
| RouteResolver (optional) | `<Feature>RouteResolver.swift` | `ArticleRouteResolver.swift` |
| Accessibility IDs (optional) | `<Feature>AccessibilityID.swift` | `ArticleAccessibilityID.swift` |

### Tests & Mocks

| Type | Pattern | Example |
| --- | --- | --- |
| Test File | `<ComponentName>Tests.swift` | `ArticleUseCaseTests.swift` |
| Mock | `[Project]Tests/Mocks/<Feature><Type>Mock.swift` | `ArticleRepositoryMock.swift` |
