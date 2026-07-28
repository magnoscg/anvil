# PROJECT-STRUCTURE.md — Folder Structure

> Operational guide: where to create each file in the project.

## Complete Structure

```text
MyApp/
+- App/
|  +- Application/                    # AppDelegate, SceneDelegate, @main
|  +- Navigation/                     # Generic AppRouter (protocol + impl)
|  |  +- AppRouter.swift              # Protocol only
|  |  +- AppRouterImpl.swift          # Implementation
|  +- Config/                         # Configuration, feature flags
|
+- Core/
|  +- DesignSystem/                   # Reusable UI (Buttons, Tokens)
|  +- Networking/                     # APIClient shared
|  +- Persistence/                    # SwiftDataStack shared
|  +- Common/                         # Extensions, Formatters
|
+- Domain/                            # GLOBAL DOMAIN LAYER
|  +- <Feature>/                      # Example: Article
|     +- Models/                      # Domain models
|     |  +- <Feature>Model.swift      # e.g., ArticleModel.swift
|     +- UseCases/                    # Business logic
|        +- <Feature>UseCase.swift    # Protocol
|        +- <Feature>UseCaseImpl.swift # Implementation
|
+- Data/                              # GLOBAL DATA LAYER
|  +- <Feature>/                      # Example: Article
|     +- Repositories/                # Protocol + Implementation together
|     |  +- <Feature>Repository.swift # Protocol
|     |  +- <Feature>RepositoryImpl.swift
|     +- DataSources/                 # Remote and Local sources
|     |  +- <Feature>RemoteDataSource.swift
|     |  +- <Feature>RemoteDataSourceImpl.swift
|     |  +- <Feature>LocalDataSource.swift
|     |  +- <Feature>LocalDataSourceImpl.swift
|     +- DTO/                         # Data Transfer Objects
|     |  +- <Feature>DTO.swift
|     +- Mappers/                     # DTO <-> Model transformations
|        +- <Feature>DTOMapper.swift  # Protocol
|        +- <Feature>DTOMapperImpl.swift
|
+- Features/                          # PRESENTATION LAYER ONLY
|  +- <Feature>/                      # Example: Article
|     +- DI/                          # Dependency Injection / Factory
|     |  +- <Feature>Factory.swift
|     |
|     +- UI/                          # UI (SwiftUI Views ONLY)
|     |  +- <Feature>View.swift       # Main view
|     |  +- <Feature>State.swift      # State enum only
|     |  +- <Feature>Decorator.swift  # UI decorators (section, item, error)
|     |  +- Components/               # Feature-specific subviews
|     |     +- <Feature>FeatureRow.swift
|     |     +- <Feature>DetailView.swift
|     |
|     +- Presentation/                # PRESENTATION LOGIC
|     |  +- ViewModels/
|     |  |  +- <Feature>ViewModel.swift
|     |  +- Mappers/                  # Domain -> UI decorator mapping
|     |     +- <Feature>DecoratorMapper.swift  # Protocol
|     |     +- <Feature>DecoratorMapperImpl.swift
|     |
|     +- Navigation/                  # NAVIGATION (2 files only)
|        +- <Feature>Router.swift     # Route enum + Protocol + Impl
|        +- <Feature>RouteResolver.swift
|
+- Resources/                         # Assets, Strings
|
+- [Project]Tests/
   +- Domain/                         # Domain layer tests
   |  +- <Feature>/
   |     +- UseCases/
   |        +- <Feature>UseCaseTests.swift
   +- Data/                           # Data layer tests
   |  +- <Feature>/
   |     +- Repositories/
   |        +- <Feature>RepositoryTests.swift
   +- Features/                       # Presentation tests
   |  +- <Feature>/
   |     +- Presentation/
   |        +- ViewModels/
   |        |  +- <Feature>ViewModelTests.swift
   |        +- Mappers/
   |           +- <Feature>DecoratorMapperTests.swift
   +- Mocks/                          # Shared mocks
      +- Mock<Feature>UseCase.swift
      +- Mock<Feature>Repository.swift
      +- Mock<Feature>Router.swift
```

## Quick Guide: Where Does Each Thing Go?

### Domain Layer (Global)

| Folder | Content | Example |
| --- | --- | --- |
| **Domain/\<Feature\>/Models/** | Domain models (Sendable) | `ArticleModel.swift` |
| **Domain/\<Feature\>/UseCases/** | Protocol + Implementation | `ArticleUseCase.swift`, `ArticleUseCaseImpl.swift` |

### Data Layer (Global)

| Folder | Content | Example |
| --- | --- | --- |
| **Data/\<Feature\>/Repositories/** | Protocol + Implementation | `ArticleRepository.swift`, `ArticleRepositoryImpl.swift` |
| **Data/\<Feature\>/DataSources/** | Remote (API) and/or Local (Database) | `ArticleRemoteDataSource.swift` (API), `ArticleLocalDataSource.swift` (DB) |
| **Data/\<Feature\>/DTO/** | Data Transfer Objects (only if API) | `ArticleDTO.swift` |
| **Data/\<Feature\>/Mappers/** | DTO -> Model mappers (only if API) | `ArticleDTOMapper.swift`, `ArticleDTOMapperImpl.swift` |

### Features (Presentation Only)

| Folder | Content | Example |
| --- | --- | --- |
| **DI/** | Factory / Assembly. Returns `some View`. | `ArticleFactory.swift` |
| **UI/** | SwiftUI Views, State enum, Decorators. | `ArticleView.swift`, `ArticleState.swift`, `ArticleDecorator.swift` |
| **UI/Components/** | Feature-specific subviews. | `ArticleFeatureRow.swift`, `ArticleDetailView.swift` |
| **Presentation/ViewModels/** | `@Observable` classes. | `ArticleViewModel.swift` |
| **Presentation/Mappers/** | Domain -> Decorator mappers. | `ArticleDecoratorMapper.swift`, `ArticleDecoratorMapperImpl.swift` |
| **Navigation/** | Route enum (inside Router) + RouteResolver. | `ArticleRouter.swift`, `ArticleRouteResolver.swift` |

### Navigation Structure (2 Files Pattern)

Each feature defines 2 navigation files:

| File | Purpose | Example |
| --- | --- | --- |
| `<Feature>Router.swift` | Route enum + Protocol + Implementation | `ArticleRouter.swift` |
| `<Feature>RouteResolver.swift` | ViewModifier resolving routes to views | `ArticleRouteResolver.swift` |

**Note**: The Route enum lives inside the Router file, not in a separate file.

### Tests Structure

| Folder | What to test |
| --- | --- |
| `[Project]Tests/Domain/<Feature>/UseCases/` | UseCase tests with mocked repositories |
| `[Project]Tests/Data/<Feature>/Repositories/` | Repository tests with mocked data sources |
| `[Project]Tests/Features/<Feature>/Presentation/ViewModels/` | ViewModel tests with mocked use cases |
| `[Project]Tests/Features/<Feature>/Presentation/Mappers/` | DecoratorMapper tests |
| `[Project]Tests/Mocks/` | Shared mocks |

## Layer Separation Rules

### Domain Layer
- **NO** imports of SwiftUI, SwiftData, URLSession
- **ONLY** pure Swift, Foundation for basic types
- Contains: Models, UseCases (protocol + impl)
- **Does NOT contain**: Repository protocols (moved to Data)

### Data Layer
- **CAN** import: Foundation, SwiftData (for persistence), networking
- **CANNOT** import: SwiftUI
- Contains: Repository protocols + implementations, DataSources, DTOs, Mappers

### Features (Presentation)
- **CAN** import: SwiftUI, Domain layer protocols
- **CANNOT** import: Data layer directly (only through DI)
- Contains: Views, ViewModels, State, Decorators, DecoratorMappers, Routers, Factories

## File Naming Conventions

**IMPORTANT**: All files related to a feature must start with the feature name.

| Type | Pattern | Example |
| --- | --- | --- |
| Domain Model | `<Feature>Model.swift` | `ArticleModel.swift` |
| UseCase Protocol | `<Feature>UseCase.swift` | `ArticleUseCase.swift` |
| UseCase Impl | `<Feature>UseCaseImpl.swift` | `ArticleUseCaseImpl.swift` |
| Repository Protocol | `<Feature>Repository.swift` | `ArticleRepository.swift` |
| Repository Impl | `<Feature>RepositoryImpl.swift` | `ArticleRepositoryImpl.swift` |
| Remote DataSource | `<Feature>RemoteDataSource.swift` | `ArticleRemoteDataSource.swift` |
| Remote DataSource Impl | `<Feature>RemoteDataSourceImpl.swift` | `ArticleRemoteDataSourceImpl.swift` |
| Local DataSource | `<Feature>LocalDataSource.swift` | `ArticleLocalDataSource.swift` |
| DTO | `<Feature>DTO.swift` | `ArticleDTO.swift` |
| DTO Mapper | `<Feature>DTOMapper.swift` | `ArticleDTOMapper.swift` |
| View | `<Feature>View.swift` | `ArticleView.swift` |
| State | `<Feature>State.swift` | `ArticleState.swift` |
| Decorator | `<Feature>Decorator.swift` | `ArticleDecorator.swift` |
| ViewModel | `<Feature>ViewModel.swift` | `ArticleViewModel.swift` |
| DecoratorMapper | `<Feature>DecoratorMapper.swift` | `ArticleDecoratorMapper.swift` |
| Factory | `<Feature>Factory.swift` | `ArticleFactory.swift` |
| Router | `<Feature>Router.swift` | `ArticleRouter.swift` |
| RouteResolver | `<Feature>RouteResolver.swift` | `ArticleRouteResolver.swift` |

### Tests & Mocks

| Type | Pattern | Example |
| --- | --- | --- |
| Test File | `<ComponentName>Tests.swift` | `ArticleUseCaseTests.swift` |
| Mock | `Mock<ProtocolName>.swift` | `MockArticleRepository.swift` |
