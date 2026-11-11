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
		projectPath(projectDir, "Domain", "TestFeature", "Models", "TestFeatureModel.swift"),
		projectPath(projectDir, "Domain", "TestFeature", "UseCases", "TestFeatureUseCase.swift"),
		projectPath(projectDir, "Domain", "TestFeature", "UseCases", "TestFeatureUseCaseImpl.swift"),
		projectPath(projectDir, "Domain", "TestFeature", "Repositories", "TestFeatureRepository.swift"),
		// Data
		projectPath(projectDir, "Data", "TestFeature", "DTO", "TestFeatureDTO.swift"),
		projectPath(projectDir, "Data", "TestFeature", "Mappers", "TestFeatureDTOMapper.swift"),
		projectPath(projectDir, "Data", "TestFeature", "DataSources", "TestFeatureRemoteDataSource.swift"),
		projectPath(projectDir, "Data", "TestFeature", "Repositories", "TestFeatureRepositoryImpl.swift"),
		// Features
		projectPath(projectDir, "Features", "TestFeature", "DI", "TestFeatureFactory.swift"),
		projectPath(projectDir, "Features", "TestFeature", "UI", "TestFeatureView.swift"),
		projectPath(projectDir, "Features", "TestFeature", "UI", "TestFeatureState.swift"),
		projectPath(projectDir, "Features", "TestFeature", "UI", "TestFeatureDecorator.swift"),
		projectPath(projectDir, "Features", "TestFeature", "Presentation", "ViewModels", "TestFeatureViewModel.swift"),
		projectPath(projectDir, "Features", "TestFeature", "Presentation", "Mappers", "TestFeatureDecoratorMapper.swift"),
		projectPath(projectDir, "Features", "TestFeature", "Navigation", "TestFeatureRouter.swift"),
	}

	for _, f := range expectedSourceFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected source file %s to exist", f)
		}
	}

	// Step 4: Verify all test files exist with correct mock types
	expectedTestFiles := []string{
		projectPath(projectDir, "Tests", "Domain", "TestFeature", "UseCases", "TestFeatureUseCaseTests.swift"),
		projectPath(projectDir, "Tests", "Data", "TestFeature", "Repositories", "TestFeatureRepositoryTests.swift"),
		projectPath(projectDir, "Tests", "Data", "TestFeature", "Mappers", "TestFeatureDTOMapperTests.swift"),
		projectPath(projectDir, "Tests", "Features", "TestFeature", "Presentation", "ViewModels", "TestFeatureViewModelTests.swift"),
		projectPath(projectDir, "Tests", "Features", "TestFeature", "Presentation", "Mappers", "TestFeatureDecoratorMapperTests.swift"),
	}

	for _, f := range expectedTestFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected test file %s to exist", f)
		}
	}

	expectedMockFiles := []string{
		projectPath(projectDir, "Tests", "Mocks", "TestFeatureUseCaseMock.swift"),
		projectPath(projectDir, "Tests", "Mocks", "TestFeatureRepositoryMock.swift"),
		projectPath(projectDir, "Tests", "Mocks", "TestFeatureRouterMock.swift"),
		projectPath(projectDir, "Tests", "Mocks", "TestFeatureRemoteDataSourceMock.swift"),
		projectPath(projectDir, "Tests", "Mocks", "TestFeatureDTOMapperMock.swift"),
		projectPath(projectDir, "Tests", "Mocks", "TestFeatureDecoratorMapperMock.swift"),
	}

	for _, f := range expectedMockFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected mock file %s to exist", f)
		}
	}

	// Verify that nothing beyond the expected files was created
	wantFiles := len(expectedSourceFiles) + len(expectedTestFiles) + len(expectedMockFiles)
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

	// Step 6-7: Building the feature with xcodebuild is not covered here.
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
	vmFile := projectPath(projectDir, "Features", "Article", "Presentation", "ViewModels", "ArticleViewModel.swift")
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
	routerFile := projectPath(projectDir, "Features", "Article", "Navigation", "ArticleRouter.swift")
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
	err = filepath.Walk(projectPath(projectDir, "Features", "Article"), func(path string, info os.FileInfo, err error) error {
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

func TestIntegrationFeatureWithUITests(t *testing.T) {
	dir := t.TempDir()

	gen, _ := newRealGenerator()
	result, err := gen.Generate(context.Background(), testProjectConfig(dir))
	if err != nil {
		t.Fatalf("project generation failed: %v", err)
	}
	projectDir := result.ProjectDir

	renderer := generator.NewRenderer(generator.TemplateFS, generator.NewDiskWriter())
	_, err = feature.NewFeatureForge(renderer).Forge(config.FeatureConfig{
		FeatureName:    "Article",
		ProjectRoot:    projectDir,
		ProjectName:    "TestApp",
		IncludeUITests: true,
	})
	if err != nil {
		t.Fatalf("forge failed: %v", err)
	}

	read := func(parts ...string) string {
		t.Helper()
		data, err := os.ReadFile(filepath.Join(append([]string{projectDir}, parts...)...))
		if err != nil {
			t.Fatalf("reading %s: %v", filepath.Join(parts...), err)
		}
		return string(data)
	}

	checks := []struct {
		file     []string
		contains string
	}{
		{[]string{"Shared", "UITestLaunch.swift"}, `static let argument = "--uitesting"`},
		{[]string{"Shared", "AccessibilityIDs", "ArticleAccessibilityID.swift"}, `static let retryButton = "article_retry_button"`},
		{[]string{"TestAppUITests", "Support", "XCUIApplication+UITesting.swift"}, "static func launchForUITesting"},
		{[]string{"TestAppUITests", "Support", "Screens", "ArticleScreen.swift"}, "@MainActor\nstruct ArticleScreen"},
		{[]string{"TestAppUITests", "Screens", "ArticleScreenTests.swift"}, `ArticleScreen.launch(fixture: "error")`},
		{[]string{"TestApp", "Data", "Article", "DataStubs", "StubArticleRemoteDataSource.swift"}, "throw APIError.httpError(statusCode: 500, data: nil)"},
		{[]string{"TestApp", "Data", "Article", "DataStubs", "FixtureArticleRemoteDataSource.swift"}, "#if DEBUG"},
		{[]string{"TestApp", "Features", "Article", "DI", "ArticleFactory.swift"}, `ProcessInfo.uiTestFixture(screen: "Article")`},
		{[]string{"TestApp", "Features", "Article", "UI", "ArticleView.swift"}, "retryButtonID: ArticleAccessibilityID.retryButton"},
		{[]string{"TestApp", "App", "Navigation", "UITestScreenRegistry.swift"}, `UITestScreen(name: "Article") { AnyView(ArticleFactory.makeView(appRouter: $0, dependencies: $1)) },
        // anvil:ui-test-screens`},
	}
	for _, c := range checks {
		if content := read(c.file...); !strings.Contains(content, c.contains) {
			t.Errorf("%s should contain %q", filepath.Join(c.file...), c.contains)
		}
	}

	for _, file := range [][]string{
		{"TestApp", "Data", "Article", "DataStubs", "StubArticleRemoteDataSource.swift"},
		{"TestApp", "Data", "Article", "DataStubs", "FixtureArticleRemoteDataSource.swift"},
	} {
		if strings.Contains(read(file...), "@testable") {
			t.Errorf("%s is compiled into the app and must not use @testable import", filepath.Join(file...))
		}
	}
}
