//go:build integration

package anvilcli_test

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/magnoscg/anvil/internal/config"
	"github.com/magnoscg/anvil/internal/feature"
	"github.com/magnoscg/anvil/internal/generator"
)

func TestIntegrationAnvilFeature(t *testing.T) {
	dir := t.TempDir()

	// Step 1: Generate a base project first
	gen, _ := newRealGenerator()
	cfg := testProjectConfig(dir)

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("project generation failed: %v", err)
	}
	projectDir := result.ProjectDir

	// Step 2: Forge a "TestFeature" using the real renderer and embedded templates
	writer := generator.NewDiskWriter()
	renderer := generator.NewRenderer(generator.TemplateFS, writer)
	forge := feature.NewFeatureForge(renderer)

	featureCfg := config.FeatureConfig{
		FeatureName: "TestFeature",
		ProjectRoot: projectDir,
		ProjectName: "TestApp",
	}

	forgeResult, err := forge.Forge(featureCfg)
	if err != nil {
		t.Fatalf("feature forge failed: %v", err)
	}

	// Step 3: Verify all source feature files exist in correct directories
	expectedSourceFiles := []string{
		// Domain
		filepath.Join(projectDir, "Domain", "TestFeature", "Models", "TestFeatureModel.swift"),
		filepath.Join(projectDir, "Domain", "TestFeature", "UseCases", "TestFeatureUseCase.swift"),
		filepath.Join(projectDir, "Domain", "TestFeature", "UseCases", "TestFeatureUseCaseImpl.swift"),
		// Data
		filepath.Join(projectDir, "Data", "TestFeature", "DTO", "TestFeatureDTO.swift"),
		filepath.Join(projectDir, "Data", "TestFeature", "Mappers", "TestFeatureDTOMapper.swift"),
		filepath.Join(projectDir, "Data", "TestFeature", "DataSources", "TestFeatureRemoteDataSource.swift"),
		filepath.Join(projectDir, "Data", "TestFeature", "Repositories", "TestFeatureRepository.swift"),
		filepath.Join(projectDir, "Data", "TestFeature", "Repositories", "TestFeatureRepositoryImpl.swift"),
		// Features
		filepath.Join(projectDir, "Features", "TestFeature", "DI", "TestFeatureFactory.swift"),
		filepath.Join(projectDir, "Features", "TestFeature", "UI", "TestFeatureView.swift"),
		filepath.Join(projectDir, "Features", "TestFeature", "UI", "TestFeatureState.swift"),
		filepath.Join(projectDir, "Features", "TestFeature", "UI", "TestFeatureDecorator.swift"),
		filepath.Join(projectDir, "Features", "TestFeature", "Presentation", "ViewModels", "TestFeatureViewModel.swift"),
		filepath.Join(projectDir, "Features", "TestFeature", "Presentation", "Mappers", "TestFeatureDecoratorMapper.swift"),
		filepath.Join(projectDir, "Features", "TestFeature", "Navigation", "TestFeatureRouter.swift"),
	}

	for _, f := range expectedSourceFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected source file %s to exist", f)
		}
	}

	// Step 4: Verify all test files exist with correct mock types
	expectedTestFiles := []string{
		filepath.Join(projectDir, "Tests", "Domain", "TestFeature", "UseCases", "TestFeatureUseCaseTests.swift"),
		filepath.Join(projectDir, "Tests", "Data", "TestFeature", "Repositories", "TestFeatureRepositoryTests.swift"),
		filepath.Join(projectDir, "Tests", "Data", "TestFeature", "Mappers", "TestFeatureDTOMapperTests.swift"),
		filepath.Join(projectDir, "Tests", "Features", "TestFeature", "Presentation", "ViewModels", "TestFeatureViewModelTests.swift"),
		filepath.Join(projectDir, "Tests", "Features", "TestFeature", "Presentation", "Mappers", "TestFeatureDecoratorMapperTests.swift"),
	}

	for _, f := range expectedTestFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected test file %s to exist", f)
		}
	}

	expectedMockFiles := []string{
		filepath.Join(projectDir, "Tests", "Mocks", "TestFeatureUseCaseMock.swift"),
		filepath.Join(projectDir, "Tests", "Mocks", "TestFeatureRepositoryMock.swift"),
		filepath.Join(projectDir, "Tests", "Mocks", "TestFeatureRouterMock.swift"),
		filepath.Join(projectDir, "Tests", "Mocks", "TestFeatureRemoteDataSourceMock.swift"),
		filepath.Join(projectDir, "Tests", "Mocks", "TestFeatureDTOMapperMock.swift"),
		filepath.Join(projectDir, "Tests", "Mocks", "TestFeatureDecoratorMapperMock.swift"),
	}

	for _, f := range expectedMockFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected mock file %s to exist", f)
		}
	}

	// Verify total file count
	wantFiles := 27
	if len(forgeResult.FilesCreated) != wantFiles {
		t.Errorf("FilesCreated count = %d, want %d", len(forgeResult.FilesCreated), wantFiles)
	}

	// Verify wiring instructions are present
	if len(forgeResult.WiringInstructions) == 0 {
		t.Error("WiringInstructions should not be empty")
	}

	// Step 5: Forge again - expect FeatureExistsError
	_, dupErr := forge.Forge(featureCfg)
	if dupErr == nil {
		t.Fatal("expected FeatureExistsError on duplicate forge, got nil")
	}

	var featureExistsErr config.FeatureExistsError
	if !errors.As(dupErr, &featureExistsErr) {
		t.Errorf("expected FeatureExistsError, got %T: %v", dupErr, dupErr)
	}

	// Step 6-7: xcodebuild compilation tests are skipped here (require Tuist-generated
	// Xcode project). Steps 6-7 need a real Tuist + Xcode environment.
}

func TestIntegrationFeatureRenderedContent(t *testing.T) {
	dir := t.TempDir()

	// Generate base project
	gen, _ := newRealGenerator()
	cfg := testProjectConfig(dir)

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("project generation failed: %v", err)
	}
	projectDir := result.ProjectDir

	// Forge feature
	writer := generator.NewDiskWriter()
	renderer := generator.NewRenderer(generator.TemplateFS, writer)
	forge := feature.NewFeatureForge(renderer)

	featureCfg := config.FeatureConfig{
		FeatureName: "Article",
		ProjectRoot: projectDir,
		ProjectName: "TestApp",
	}

	_, err = forge.Forge(featureCfg)
	if err != nil {
		t.Fatalf("forge failed: %v", err)
	}

	// Verify ViewModel content
	vmFile := filepath.Join(projectDir, "Features", "Article", "Presentation", "ViewModels", "ArticleViewModel.swift")
	vmData, err := os.ReadFile(vmFile)
	if err != nil {
		t.Fatalf("reading ViewModel: %v", err)
	}
	vmContent := string(vmData)

	checks := []struct {
		label    string
		contains string
	}{
		{"class declaration", "class ArticleViewModel"},
		{"@MainActor", "@MainActor"},
		{"@Observable", "@Observable"},
		{"use case property", "ArticleUseCase"},
		{"decorator mapper property", "ArticleDecoratorMapper"},
		{"router property", "ArticleRouter"},
		{"state property", "ArticleState"},
		{"decorator type", "ArticleDecorator"},
	}

	for _, c := range checks {
		if !strings.Contains(vmContent, c.contains) {
			t.Errorf("ViewModel should contain %s (%q)", c.label, c.contains)
		}
	}

	// Verify Router content
	routerFile := filepath.Join(projectDir, "Features", "Article", "Navigation", "ArticleRouter.swift")
	routerData, err := os.ReadFile(routerFile)
	if err != nil {
		t.Fatalf("reading Router: %v", err)
	}
	routerContent := string(routerData)

	routerChecks := []struct {
		label    string
		contains string
	}{
		{"route enum", "ArticleRoute"},
		{"router protocol", "protocol ArticleRouter"},
		{"router impl", "ArticleRouterImpl"},
		{"Hashable conformance", "Hashable"},
		{"Codable conformance", "Codable"},
	}

	for _, c := range routerChecks {
		if !strings.Contains(routerContent, c.contains) {
			t.Errorf("Router should contain %s (%q)", c.label, c.contains)
		}
	}

	// Verify no hardcoded references leaked
	err = filepath.Walk(filepath.Join(projectDir, "Features", "Article"), func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}
		data, readErr := os.ReadFile(path)
		if readErr != nil {
			return readErr
		}
		content := string(data)
		if strings.Contains(content, "Arquitectura") {
			t.Errorf("feature file %s contains 'Arquitectura' reference", path)
		}
		if strings.Contains(content, "magnos") {
			t.Errorf("feature file %s contains 'magnos' reference", path)
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walking feature directory: %v", err)
	}
}
