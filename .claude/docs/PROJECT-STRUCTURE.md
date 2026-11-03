# PROJECT-STRUCTURE.md — Folder Structure

> Operational guide: where to create each file in the project.
> Matches `Example/Arquitectura/` (paths below are relative to it) and `Example/ArquitecturaTests/`.
> Related skills: —

## Complete Structure

```text
Arquitectura/
├─ ArquitecturaApp.swift              # @main: AppDependencies + AppLaunchState only
├─ App/
│  ├─ Application/
│  │  ├─ AppRootView.swift            # Per window: AppRouterImpl + AppNavigationCoordinator,
│  │  │                               # splash or RootNavigationView, .onOpenURL
│  │  └─ SplashScreen/                # App-level screen (Factory, View, ViewModel, State, Components/)
│  ├─ Config/
│  │  ├─ AppDependencies.swift        # App-lifetime dependencies (shared APIClient)
│  │  ├─ AppEnvironment.swift
│  │  ├─ EnvironmentConfiguration.swift
│  │  └─ Xcconfig/                    # Base, Development, Staging, Production
│  └─ Navigation/
│     ├─ AppRouter.swift              # Protocol: push / pop / popToRoot
│     ├─ AppRouterImpl.swift          # Owns the window's NavigationPath
│     ├─ RootNavigationView.swift     # NavigationStack + resolver registration
│     └─ AppNavigationCoordinator.swift # Deep links + @SceneStorage persistence
│
├─ Core/
│  ├─ Common/
│  │  ├─ Extensions/                  # Color+Hex, Optional+Nil
│  │  ├─ Models/ErrorDecorator.swift  # Shared UI error model
│  │  └─ SwiftUI/
│  │     ├─ Builders/                 # @ViewBuilder helpers
│  │     ├─ Components/               # ErrorView, LoadingStateView, ...
│  │     └─ Modifiers/                # All custom ViewModifiers
│  ├─ DesignSystem/Tokens/            # AppColors, AppTypography, Spacing, AppIcons, IconSize
│  ├─ Networking/                     # APIClient(+Impl), Endpoint, APIEndpoint, APIError,
│  │  │                               # interceptors, RetryPolicy, NetworkMonitor
│  │  ├─ PokeAPI/                     # External API endpoints
│  │  └─ Security/                    # SSLPinningDelegate, URLSessionFactory
│  └─ Security/KeychainHelper.swift
│
├─ Domain/                            # GLOBAL DOMAIN LAYER, by business concept
│  ├─ Common/DomainError.swift        # The only domain error type
│  └─ <Concept>/                      # e.g. Pokemon (serves PokemonList + PokemonDetail)
│     ├─ Models/
│     │  └─ <Feature>Model.swift      # e.g. PokemonSummaryModel, PokemonDetailModel
│     ├─ Repositories/
│     │  └─ <Feature>Repository.swift # Protocol only (owned by Domain)
│     └─ UseCases/
│        ├─ <Feature>UseCase.swift    # Protocol
│        └─ <Feature>UseCaseImpl.swift
│
├─ Data/                              # GLOBAL DATA LAYER, mirrors Domain
│  ├─ Common/DomainError+Mapping.swift # DomainError.map + DomainError.catching
│  └─ <Concept>/
│     ├─ DTO/
│     │  └─ <Feature>DTO.swift
│     ├─ DataSources/                 # Protocol + Impl in separate files
│     │  ├─ <Feature>RemoteDataSource.swift      # API (APIClient)
│     │  ├─ <Feature>RemoteDataSourceImpl.swift
│     │  ├─ <Feature>StaticDataSource.swift      # In-code data (e.g. Architecture)
│     │  ├─ <Feature>JSONDataSource.swift        # Bundled JSON (e.g. ArchitectureDetail)
│     │  └─ ...Impl.swift
│     ├─ Mappers/                     # DTO → Model
│     │  ├─ <Feature>DTOMapper.swift  # Protocol
│     │  └─ <Feature>DTOMapperImpl.swift
│     └─ Repositories/
│        └─ <Feature>RepositoryImpl.swift # Impl only, conforms to the Domain protocol
│
├─ Features/                          # PRESENTATION LAYER ONLY, per screen
│  └─ <Screen>/                       # e.g. PokemonList, PokemonDetail
│     ├─ DI/
│     │  └─ <Feature>Factory.swift
│     ├─ UI/
│     │  ├─ <Feature>View.swift       # Main view
│     │  ├─ <Feature>State.swift      # State enum only
│     │  ├─ <Feature>Decorator.swift  # UI decorators (section, item)
│     │  └─ Components/               # Feature-specific subviews
│     ├─ Presentation/
│     │  ├─ ViewModels/
│     │  │  └─ <Feature>ViewModel.swift
│     │  └─ Mappers/                  # Domain → UI decorator mapping
│     │     ├─ <Feature>DecoratorMapper.swift  # Protocol
│     │     └─ <Feature>DecoratorMapperImpl.swift
│     └─ Navigation/
│        ├─ <Feature>Router.swift         # Route enum + Protocol + Impl (always)
│        └─ <Feature>RouteResolver.swift  # Only when the feature resolves its own routes
│
└─ Resources/
   └─ Strings/Localizable.xcstrings   # String Catalog

ArquitecturaTests/                    # Mirrors the source tree
├─ App/                               # e.g. Navigation/AppNavigationCoordinatorTests.swift
├─ Core/                              # e.g. Networking/, Common/Models/
├─ Data/
│  ├─ Common/DomainErrorMappingTests.swift
│  └─ <Concept>/{DataSources,Mappers,Repositories}/
├─ Domain/
│  └─ <Concept>/UseCases/<Feature>UseCaseTests.swift
├─ Features/
│  └─ <Screen>/Presentation/{ViewModels,Mappers}/
├─ Mocks/                             # Shared Mock<Feature><Type>.swift
└─ ArquitecturaTests.xctestplan
```

> No `Core/Persistence/` or `App/DI/` in `Example/`: there is no SwiftData. Projects generated by `anvil init` with the optional SwiftData stack get `Core/Persistence/` and `App/DI/PersistenceAssembly.swift` (see `swiftdata.md`).

## Quick Guide: Where Does Each Thing Go?

### Domain Layer (Global, by concept)

| Folder | Content | Example |
| --- | --- | --- |
| **Domain/Common/** | `DomainError` | `DomainError.swift` |
| **Domain/\<Concept\>/Models/** | Domain models | `PokemonSummaryModel.swift`, `[Feature]Model.swift` |
| **Domain/\<Concept\>/UseCases/** | Protocol + Implementation (separate files) | `[Feature]UseCase.swift`, `[Feature]UseCaseImpl.swift` |
| **Domain/\<Concept\>/Repositories/** | Repository **protocol** | `[Feature]Repository.swift` |

### Data Layer (Global, mirrors Domain)

| Folder | Content | Example |
| --- | --- | --- |
| **Data/Common/** | `DomainError` mapping | `DomainError+Mapping.swift` |
| **Data/\<Concept\>/Repositories/** | Repository **Impl** only | `[Feature]RepositoryImpl.swift` |
| **Data/\<Concept\>/DataSources/** | Remote (API), Static, or bundled JSON | `[Feature]RemoteDataSource.swift`, `[Feature]StaticDataSource.swift`, `[Feature]JSONDataSource.swift` |
| **Data/\<Concept\>/DTO/** | Data Transfer Objects | `[Feature]DTO.swift` |
| **Data/\<Concept\>/Mappers/** | DTO → Model mappers | `[Feature]DTOMapper.swift`, `[Feature]DTOMapperImpl.swift` |

### Features (Presentation Only)

| Folder | Content | Example |
| --- | --- | --- |
| **DI/** | `@MainActor enum <Feature>Factory` with `static func makeView(...)` returning the concrete View (e.g. `-> PokemonListView`). | `[Feature]Factory.swift` |
| **UI/** | SwiftUI Views, State enum, Decorators. | `[Feature]View.swift`, `[Feature]State.swift`, `[Feature]Decorator.swift` |
| **UI/Components/** | Feature-specific subviews. | `PokemonListCardView.swift`, `ArchitectureFeatureRow.swift` |
| **Presentation/ViewModels/** | `@MainActor @Observable final class`. | `[Feature]ViewModel.swift` |
| **Presentation/Mappers/** | Domain → Decorator mappers. | `[Feature]DecoratorMapper.swift`, `[Feature]DecoratorMapperImpl.swift` |
| **Navigation/** | Router (with Route enum inside), plus an optional RouteResolver. | `[Feature]Router.swift`, `[Feature]RouteResolver.swift` |

### Navigation Structure

| File | When | Purpose |
| --- | --- | --- |
| `[Feature]Router.swift` | Always | Route enum (`Hashable, Codable`) + `@MainActor` protocol + `struct ...RouterImpl` delegating to `AppRouter` |
| `[Feature]RouteResolver.swift` | Only when the feature owns routes that must be resolved into views | `ViewModifier` + `View.with<Feature>Routes(...)`, registered in `App/Navigation/RootNavigationView.swift` |

In `Example/`, `Architecture` and `PokemonList` have a resolver; `ArchitectureDetail` and `PokemonDetail` only have a Router. A feature that only pushes an already registered route (`ArchitectureDetailRouterImpl` pushes `PokemonListRoute.list`) needs no resolver.

**Note**: The Route enum lives inside the Router file, not in a separate file.

### Tests Structure

> Tests live in `Example/ArquitecturaTests/` and mirror the source tree.

| Folder | What to test |
| --- | --- |
| `ArquitecturaTests/App/` | App-layer logic (e.g. `AppNavigationCoordinatorTests`, `SplashScreenViewModelTests`) |
| `ArquitecturaTests/Core/` | Networking (endpoints, `APIError`, interceptors), `ErrorDecorator` mapping |
| `ArquitecturaTests/Domain/<Concept>/UseCases/` | UseCase tests with mocked repositories |
| `ArquitecturaTests/Data/Common/` | `DomainError.map` / `DomainError.catching` |
| `ArquitecturaTests/Data/<Concept>/` | Repository, DataSource and DTOMapper tests |
| `ArquitecturaTests/Features/<Screen>/Presentation/` | ViewModel and DecoratorMapper tests |
| `ArquitecturaTests/Mocks/` | Shared mocks |

## Layer Separation Rules

Layers are folders in one app target, so these rules are enforced by review, not by the compiler.

### App Layer
- Composition root only: `@main` creates `AppDependencies` and `AppLaunchState`; `AppRootView` creates the per-window router and coordinator.
- Owns `AppRouterImpl.path`, deep-link parsing and navigation persistence.

### Domain Layer
- **NO** imports of SwiftUI, SwiftData, URLSession
- **ONLY** pure Swift, Foundation for basic types
- **NO** references to `APIError` or any other infrastructure type
- Contains: Models, UseCases (protocol + impl), Repository **protocols**, `Common/DomainError`

### Data Layer
- **CAN** import: Foundation, networking (`Core/Networking`)
- **CANNOT** import: SwiftUI
- Contains: Repository **implementations** (no protocols), DataSources, DTOs, Mappers, `Common/DomainError+Mapping`

### Features (Presentation)
- **CAN** import: SwiftUI, Domain types
- **CANNOT** use Data types directly (only the Factory in `DI/` builds them)
- Contains: Views, ViewModels, State, Decorators, DecoratorMappers, Routers, Factories

## File Naming Conventions

**IMPORTANT**: All files related to a feature must start with the feature name. Protocols and their `Impl` go in **separate files**, except the Router (Route enum + protocol + Impl in one file).

| Type | Pattern | Example |
| --- | --- | --- |
| Domain Model | `Domain/<Concept>/Models/[Feature]Model.swift` | `PokemonSummaryModel.swift` |
| UseCase Protocol | `[Feature]UseCase.swift` | `PokemonListUseCase.swift` |
| UseCase Impl | `[Feature]UseCaseImpl.swift` | `PokemonListUseCaseImpl.swift` |
| Repository Protocol (Domain) | `Domain/<Concept>/Repositories/[Feature]Repository.swift` | `PokemonListRepository.swift` |
| Repository Impl (Data) | `Data/<Concept>/Repositories/[Feature]RepositoryImpl.swift` | `PokemonListRepositoryImpl.swift` |
| DataSource Protocol | `[Feature]<Kind>DataSource.swift` (`Remote`, `Static`, `JSON`) | `ArchitectureStaticDataSource.swift` |
| DataSource Impl | `[Feature]<Kind>DataSourceImpl.swift` | `ArchitectureDetailJSONDataSourceImpl.swift` |
| DTO | `[Feature]DTO.swift` | `PokemonListDTO.swift` |
| DTOMapper Protocol | `[Feature]DTOMapper.swift` | `PokemonListDTOMapper.swift` |
| DTOMapper Impl | `[Feature]DTOMapperImpl.swift` | `PokemonListDTOMapperImpl.swift` |
| View | `[Feature]View.swift` | `PokemonListView.swift` |
| State | `[Feature]State.swift` | `PokemonListState.swift` |
| Decorator | `[Feature]Decorator.swift` | `PokemonListDecorator.swift` |
| ViewModel | `[Feature]ViewModel.swift` | `PokemonListViewModel.swift` |
| DecoratorMapper Protocol | `[Feature]DecoratorMapper.swift` | `PokemonListDecoratorMapper.swift` |
| DecoratorMapper Impl | `[Feature]DecoratorMapperImpl.swift` | `PokemonListDecoratorMapperImpl.swift` |
| Factory | `[Feature]Factory.swift` | `PokemonListFactory.swift` |
| Router | `[Feature]Router.swift` | `PokemonListRouter.swift` |
| RouteResolver (optional) | `[Feature]RouteResolver.swift` | `PokemonListRouteResolver.swift` |

### Tests & Mocks

| Type | Pattern | Example |
| --- | --- | --- |
| Test File | `<ComponentName>Tests.swift` | `PokemonListRepositoryTests.swift` |
| Mock | `ArquitecturaTests/Mocks/Mock<Feature><Type>.swift` | `MockPokemonListRemoteDataSource.swift` |

## Key Differences from Old Structure

| Old | New |
| --- | --- |
| `Domain/[Feature]/[Entity].swift` | `Domain/<Concept>/Models/[Feature]Model.swift` |
| One Domain folder per screen | One Domain folder per business concept (`Domain/Pokemon`) |
| `Data/[Feature]/Repositories/[Feature]Repository.swift` (protocol in Data) | `Domain/<Concept>/Repositories/[Feature]Repository.swift` (protocol in Domain, Impl stays in Data) |
| Per-feature `[Feature]Error` | Shared `Domain/Common/DomainError.swift` + `Data/Common/DomainError+Mapping.swift` |
| `PokemonListModel` | `PokemonSummaryModel` |
| `Features/[Feature]/View/` | `Features/[Feature]/UI/` |
| `Features/[Feature]/ViewModel/` | `Features/[Feature]/Presentation/ViewModels/` |
| `Features/[Feature]/State/` | Split into `UI/[Feature]State.swift` + `UI/[Feature]Decorator.swift` |
| `Features/[Feature]/Router/` (3 files) | `Features/[Feature]/Navigation/` (Router always, RouteResolver only when needed) |
| `<Action>.swift`, `<Event>.swift` | **REMOVED** - Actions are direct methods in ViewModel |
