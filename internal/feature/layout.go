package feature

import (
	"path/filepath"

	"github.com/magnoscg/anvil/internal/config"
)

// FileJob represents a single template-to-destination file mapping.
type FileJob struct {
	// TemplatePath is the path to the template file within the embedded FS.
	TemplatePath string

	// DestPath is the relative path where the rendered output should be written.
	DestPath string

	// Conditional indicates whether this file is only included when a flag is set.
	Conditional bool
}

// FeatureLayout returns the complete list of template-to-destination file mappings
// for a feature forge. This is a pure function that performs no file I/O.
// The returned paths are relative to the project root.
func FeatureLayout(cfg config.FeatureConfig) []FileJob {
	name := cfg.FeatureName

	var jobs []FileJob

	// Domain layer
	jobs = append(jobs, domainJobs(name)...)

	// Data layer
	jobs = append(jobs, dataJobs(name, cfg)...)

	// Features (presentation) layer
	jobs = append(jobs, featuresJobs(name, cfg)...)

	// Test files
	jobs = append(jobs, testJobs(name)...)

	// Mock files
	jobs = append(jobs, mockJobs(name)...)

	// UI test files (conditional)
	if cfg.IncludeUITests {
		jobs = append(jobs, uiTestJobs(name)...)
	}

	return jobs
}

func domainJobs(name string) []FileJob {
	return []FileJob{
		{
			TemplatePath: "feature/Domain/FeatureModel.swift.tmpl",
			DestPath:     filepath.Join("Domain", name, "Models", name+"Model.swift"),
		},
		{
			TemplatePath: "feature/Domain/FeatureUseCase.swift.tmpl",
			DestPath:     filepath.Join("Domain", name, "UseCases", name+"UseCase.swift"),
		},
		{
			TemplatePath: "feature/Domain/FeatureUseCaseImpl.swift.tmpl",
			DestPath:     filepath.Join("Domain", name, "UseCases", name+"UseCaseImpl.swift"),
		},
	}
}

func dataJobs(name string, cfg config.FeatureConfig) []FileJob {
	jobs := []FileJob{
		{
			TemplatePath: "feature/Data/FeatureDTO.swift.tmpl",
			DestPath:     filepath.Join("Data", name, "DTO", name+"DTO.swift"),
		},
		{
			TemplatePath: "feature/Data/FeatureDTOMapper.swift.tmpl",
			DestPath:     filepath.Join("Data", name, "Mappers", name+"DTOMapper.swift"),
		},
		{
			TemplatePath: "feature/Data/FeatureRemoteDataSource.swift.tmpl",
			DestPath:     filepath.Join("Data", name, "DataSources", name+"RemoteDataSource.swift"),
		},
		{
			TemplatePath: "feature/Data/FeatureRepository.swift.tmpl",
			DestPath:     filepath.Join("Data", name, "Repositories", name+"Repository.swift"),
		},
		{
			TemplatePath: "feature/Data/FeatureRepositoryImpl.swift.tmpl",
			DestPath:     filepath.Join("Data", name, "Repositories", name+"RepositoryImpl.swift"),
		},
	}

	if cfg.IncludeLocalDataSource {
		jobs = append(jobs, FileJob{
			TemplatePath: "feature/Data/FeatureLocalDataSource.swift.tmpl",
			DestPath:     filepath.Join("Data", name, "DataSources", name+"LocalDataSource.swift"),
			Conditional:  true,
		})
	}

	if cfg.IncludeKeychain {
		jobs = append(jobs, FileJob{
			TemplatePath: "feature/Data/FeatureKeychainDataSource.swift.tmpl",
			DestPath:     filepath.Join("Data", name, "DataSources", name+"KeychainDataSource.swift"),
			Conditional:  true,
		})
	}

	return jobs
}

func featuresJobs(name string, cfg config.FeatureConfig) []FileJob {
	jobs := []FileJob{
		{
			TemplatePath: "feature/Features/FeatureFactory.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "DI", name+"Factory.swift"),
		},
		{
			TemplatePath: "feature/Features/FeatureView.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "UI", name+"View.swift"),
		},
		{
			TemplatePath: "feature/Features/FeatureState.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "UI", name+"State.swift"),
		},
		{
			TemplatePath: "feature/Features/FeatureDecorator.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "UI", name+"Decorator.swift"),
		},
		{
			TemplatePath: "feature/Features/FeatureViewModel.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "Presentation", "ViewModels", name+"ViewModel.swift"),
		},
		{
			TemplatePath: "feature/Features/FeatureDecoratorMapper.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "Presentation", "Mappers", name+"DecoratorMapper.swift"),
		},
		{
			TemplatePath: "feature/Features/FeatureRouter.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "Navigation", name+"Router.swift"),
		},
	}

	if cfg.IncludeRouteResolver {
		jobs = append(jobs, FileJob{
			TemplatePath: "feature/Features/FeatureRouteResolver.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "Navigation", name+"RouteResolver.swift"),
			Conditional:  true,
		})
	}

	return jobs
}

func testJobs(name string) []FileJob {
	return []FileJob{
		{
			TemplatePath: "feature/Tests/Domain/FeatureUseCaseTests.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Domain", name, "UseCases", name+"UseCaseTests.swift"),
		},
		{
			TemplatePath: "feature/Tests/Data/FeatureRepositoryTests.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Data", name, "Repositories", name+"RepositoryTests.swift"),
		},
		{
			TemplatePath: "feature/Tests/Data/FeatureDTOMapperTests.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Data", name, "Mappers", name+"DTOMapperTests.swift"),
		},
		{
			TemplatePath: "feature/Tests/Features/FeatureViewModelTests.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Features", name, "Presentation", "ViewModels", name+"ViewModelTests.swift"),
		},
		{
			TemplatePath: "feature/Tests/Features/FeatureDecoratorMapperTests.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Features", name, "Presentation", "Mappers", name+"DecoratorMapperTests.swift"),
		},
	}
}

func mockJobs(name string) []FileJob {
	return []FileJob{
		{
			TemplatePath: "feature/Tests/Mocks/FeatureUseCaseMock.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Mocks", name+"UseCaseMock.swift"),
		},
		{
			TemplatePath: "feature/Tests/Mocks/FeatureRepositoryMock.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Mocks", name+"RepositoryMock.swift"),
		},
		{
			TemplatePath: "feature/Tests/Mocks/FeatureRouterMock.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Mocks", name+"RouterMock.swift"),
		},
		{
			TemplatePath: "feature/Tests/Mocks/FeatureRemoteDataSourceMock.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Mocks", name+"RemoteDataSourceMock.swift"),
		},
		{
			TemplatePath: "feature/Tests/Mocks/FeatureDTOMapperMock.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Mocks", name+"DTOMapperMock.swift"),
		},
		{
			TemplatePath: "feature/Tests/Mocks/FeatureDecoratorMapperMock.swift.tmpl",
			DestPath:     filepath.Join("Tests", "Mocks", name+"DecoratorMapperMock.swift"),
		},
	}
}

func uiTestJobs(name string) []FileJob {
	return []FileJob{
		{
			TemplatePath: "feature/Features/FeatureAccessibilityID.swift.tmpl",
			DestPath:     filepath.Join("Features", name, "UI", name+"AccessibilityID.swift"),
			Conditional:  true,
		},
		{
			TemplatePath: "feature/Tests/DataStubs/StubFeatureRemoteDataSource.swift.tmpl",
			DestPath:     filepath.Join("Tests", "DataStubs", name, "Stub"+name+"RemoteDataSource.swift"),
			Conditional:  true,
		},
		{
			TemplatePath: "feature/Tests/DataStubs/FixtureFeatureRemoteDataSource.swift.tmpl",
			DestPath:     filepath.Join("Tests", "DataStubs", name, "Fixture"+name+"RemoteDataSource.swift"),
			Conditional:  true,
		},
		{
			TemplatePath: "feature/Tests/UITests/FeatureScreenTests.swift.tmpl",
			DestPath:     filepath.Join("Tests", "UITests", "Screens", name+"ScreenTests.swift"),
			Conditional:  true,
		},
		{
			TemplatePath: "feature/Tests/UITests/FeatureScreen.swift.tmpl",
			DestPath:     filepath.Join("Tests", "UITests", "Support", "Screens", name+"Screen.swift"),
			Conditional:  true,
		},
	}
}
