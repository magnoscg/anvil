package feature

import (
	"testing"

	"github.com/oscarcanton/anvilcli/internal/config"
)

func TestFeatureLayoutBaseFeature(t *testing.T) {
	cfg := config.FeatureConfig{
		FeatureName:            "Pokemon",
		ProjectRoot:            "/tmp/project",
		ProjectName:            "MyApp",
		IncludeLocalDataSource: false,
		IncludeKeychain:        false,
		IncludeRouteResolver:   false,
	}

	jobs := FeatureLayout(cfg)

	// Base feature: 3 domain + 5 data + 7 features + 5 tests + 6 mocks = 26
	wantCount := 26
	if len(jobs) != wantCount {
		t.Errorf("FeatureLayout base: got %d files, want %d", len(jobs), wantCount)
		for i, j := range jobs {
			t.Logf("  [%d] %s -> %s", i, j.TemplatePath, j.DestPath)
		}
	}

	// Verify no conditional files are included
	for _, job := range jobs {
		if job.Conditional {
			t.Errorf("base feature should have no conditional files, got %s", job.DestPath)
		}
	}
}

func TestFeatureLayoutWithLocalDataSource(t *testing.T) {
	cfg := config.FeatureConfig{
		FeatureName:            "Pokemon",
		ProjectRoot:            "/tmp/project",
		ProjectName:            "MyApp",
		IncludeLocalDataSource: true,
		IncludeKeychain:        false,
		IncludeRouteResolver:   false,
	}

	jobs := FeatureLayout(cfg)
	wantCount := 27 // base(26) + 1 local data source
	if len(jobs) != wantCount {
		t.Errorf("FeatureLayout with LocalDataSource: got %d files, want %d", len(jobs), wantCount)
	}

	assertHasFile(t, jobs, "Data/Pokemon/DataSources/PokemonLocalDataSource.swift")
}

func TestFeatureLayoutWithKeychain(t *testing.T) {
	cfg := config.FeatureConfig{
		FeatureName:            "Pokemon",
		ProjectRoot:            "/tmp/project",
		ProjectName:            "MyApp",
		IncludeLocalDataSource: false,
		IncludeKeychain:        true,
		IncludeRouteResolver:   false,
	}

	jobs := FeatureLayout(cfg)
	wantCount := 27 // base(26) + 1 keychain
	if len(jobs) != wantCount {
		t.Errorf("FeatureLayout with Keychain: got %d files, want %d", len(jobs), wantCount)
	}

	assertHasFile(t, jobs, "Data/Pokemon/DataSources/PokemonKeychainDataSource.swift")
}

func TestFeatureLayoutWithRouteResolver(t *testing.T) {
	cfg := config.FeatureConfig{
		FeatureName:            "Pokemon",
		ProjectRoot:            "/tmp/project",
		ProjectName:            "MyApp",
		IncludeLocalDataSource: false,
		IncludeKeychain:        false,
		IncludeRouteResolver:   true,
	}

	jobs := FeatureLayout(cfg)
	wantCount := 27 // base(26) + 1 route resolver
	if len(jobs) != wantCount {
		t.Errorf("FeatureLayout with RouteResolver: got %d files, want %d", len(jobs), wantCount)
	}

	assertHasFile(t, jobs, "Features/Pokemon/Navigation/PokemonRouteResolver.swift")
}

func TestFeatureLayoutAllOptions(t *testing.T) {
	cfg := config.FeatureConfig{
		FeatureName:            "Pokemon",
		ProjectRoot:            "/tmp/project",
		ProjectName:            "MyApp",
		IncludeLocalDataSource: true,
		IncludeKeychain:        true,
		IncludeRouteResolver:   true,
	}

	jobs := FeatureLayout(cfg)
	wantCount := 29 // base(26) + 3 optional
	if len(jobs) != wantCount {
		t.Errorf("FeatureLayout all options: got %d files, want %d", len(jobs), wantCount)
	}

	// Verify all conditional files present
	assertHasFile(t, jobs, "Data/Pokemon/DataSources/PokemonLocalDataSource.swift")
	assertHasFile(t, jobs, "Data/Pokemon/DataSources/PokemonKeychainDataSource.swift")
	assertHasFile(t, jobs, "Features/Pokemon/Navigation/PokemonRouteResolver.swift")
}

func TestFeatureLayoutDirectoryStructure(t *testing.T) {
	cfg := config.FeatureConfig{
		FeatureName: "Auth",
		ProjectRoot: "/tmp/project",
		ProjectName: "MyApp",
	}

	jobs := FeatureLayout(cfg)

	expectedPaths := []string{
		// Domain
		"Domain/Auth/Models/AuthModel.swift",
		"Domain/Auth/UseCases/AuthUseCase.swift",
		"Domain/Auth/UseCases/AuthUseCaseImpl.swift",
		// Data
		"Data/Auth/DTO/AuthDTO.swift",
		"Data/Auth/Mappers/AuthDTOMapper.swift",
		"Data/Auth/DataSources/AuthRemoteDataSource.swift",
		"Data/Auth/Repositories/AuthRepository.swift",
		"Data/Auth/Repositories/AuthRepositoryImpl.swift",
		// Features
		"Features/Auth/DI/AuthFactory.swift",
		"Features/Auth/UI/AuthView.swift",
		"Features/Auth/UI/AuthState.swift",
		"Features/Auth/UI/AuthDecorator.swift",
		"Features/Auth/Presentation/ViewModels/AuthViewModel.swift",
		"Features/Auth/Presentation/Mappers/AuthDecoratorMapper.swift",
		"Features/Auth/Navigation/AuthRouter.swift",
		// Tests
		"Tests/Domain/Auth/UseCases/AuthUseCaseTests.swift",
		"Tests/Data/Auth/Repositories/AuthRepositoryTests.swift",
		"Tests/Data/Auth/Mappers/AuthDTOMapperTests.swift",
		"Tests/Features/Auth/Presentation/ViewModels/AuthViewModelTests.swift",
		"Tests/Features/Auth/Presentation/Mappers/AuthDecoratorMapperTests.swift",
		// Mocks
		"Tests/Mocks/AuthUseCaseMock.swift",
		"Tests/Mocks/AuthRepositoryMock.swift",
		"Tests/Mocks/AuthRouterMock.swift",
		"Tests/Mocks/AuthRemoteDataSourceMock.swift",
		"Tests/Mocks/AuthDTOMapperMock.swift",
		"Tests/Mocks/AuthDecoratorMapperMock.swift",
	}

	for _, expected := range expectedPaths {
		assertHasFile(t, jobs, expected)
	}
}

func TestFeatureLayoutIsPureFunction(t *testing.T) {
	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: "/tmp/project",
		ProjectName: "MyApp",
	}

	jobs1 := FeatureLayout(cfg)
	jobs2 := FeatureLayout(cfg)

	if len(jobs1) != len(jobs2) {
		t.Fatalf("FeatureLayout is not deterministic: %d vs %d", len(jobs1), len(jobs2))
	}

	for i := range jobs1 {
		if jobs1[i].TemplatePath != jobs2[i].TemplatePath {
			t.Errorf("TemplatePath mismatch at index %d: %q vs %q", i, jobs1[i].TemplatePath, jobs2[i].TemplatePath)
		}
		if jobs1[i].DestPath != jobs2[i].DestPath {
			t.Errorf("DestPath mismatch at index %d: %q vs %q", i, jobs1[i].DestPath, jobs2[i].DestPath)
		}
	}
}

func assertHasFile(t *testing.T, jobs []FileJob, destPath string) {
	t.Helper()
	for _, job := range jobs {
		if job.DestPath == destPath {
			return
		}
	}
	t.Errorf("expected file %q not found in layout", destPath)
}
