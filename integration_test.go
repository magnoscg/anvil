//go:build integration

package anvilcli_test

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/oscarcanton/anvilcli/internal/config"
	"github.com/oscarcanton/anvilcli/internal/feature"
	"github.com/oscarcanton/anvilcli/internal/generator"
)

// testProjectConfig returns a minimal ProjectConfig suitable for integration tests.
func testProjectConfig(outputDir string) config.ProjectConfig {
	return config.ProjectConfig{
		Name:         "TestApp",
		BundleID:     "com.testorg.TestApp",
		Organization: "testorg",
		IOSVersion:   "18.0",
		SwiftVersion: "6.0",
		Schemes:      []string{"Dev", "Stg", "Production"},
		OutputDir:    outputDir,
	}
}

// newRealGenerator creates a ProjectGenerator using the real embedded templates,
// but with a fake TuistRunner and GitRunner (we do not run Tuist/git in these tests).
func newRealGenerator() (*generator.DefaultProjectGenerator, *fakeTuistRunner) {
	writer := generator.NewDiskWriter()
	renderer := generator.NewRenderer(generator.TemplateFS, writer)
	tuist := &fakeTuistRunner{output: "Project generated successfully"}
	git := &fakeGitRunner{}
	marker := config.FileMarkerReadWriter{}
	forge := feature.NewFeatureForge(renderer)
	merger := generator.NewSettingsMerger(writer, generator.TemplateFS)
	packRenderer := generator.NewPackRenderer(generator.TemplateFS, renderer, writer, merger)

	gen := generator.NewProjectGenerator(renderer, writer, tuist, git, marker, generator.TemplateFS, forge, packRenderer)
	return gen, tuist
}

// fakeTuistRunner stubs the TuistRunner to avoid requiring Tuist in CI.
type fakeTuistRunner struct {
	output string
	called bool
}

func (f *fakeTuistRunner) Generate(_ context.Context, _ string) (string, error) {
	f.called = true
	return f.output, nil
}

// fakeGitRunner stubs the GitRunner to avoid requiring git operations.
type fakeGitRunner struct{}

func (f *fakeGitRunner) Init(_ string) error      { return nil }
func (f *fakeGitRunner) AddAll(_ string) error    { return nil }
func (f *fakeGitRunner) Commit(_, _ string) error { return nil }

func TestIntegrationAnvilInit(t *testing.T) {
	dir := t.TempDir()
	gen, tuist := newRealGenerator()
	cfg := testProjectConfig(dir)

	// Step 1-2: Generate project with real templates
	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	projectDir := result.ProjectDir
	if projectDir != filepath.Join(dir, "TestApp") {
		t.Errorf("ProjectDir = %q, want %q", projectDir, filepath.Join(dir, "TestApp"))
	}

	// Step 3: Verify directory tree matches expected structure
	expectedDirs := []string{
		filepath.Join(projectDir, "TestApp", "App", "Application"),
		filepath.Join(projectDir, "TestApp", "App", "Config"),
		filepath.Join(projectDir, "TestApp", "App", "Config", "Xcconfig"),
		filepath.Join(projectDir, "TestApp", "App", "Navigation"),
		filepath.Join(projectDir, "TestApp", "Core", "Common", "Extensions"),
		filepath.Join(projectDir, "TestApp", "Core", "Common", "Models"),
		filepath.Join(projectDir, "TestApp", "Core", "Common", "SwiftUI", "Builders"),
		filepath.Join(projectDir, "TestApp", "Core", "Common", "SwiftUI", "Components"),
		filepath.Join(projectDir, "TestApp", "Core", "Common", "SwiftUI", "Modifiers"),
		filepath.Join(projectDir, "TestApp", "Core", "DesignSystem", "Tokens"),
		filepath.Join(projectDir, "TestApp", "Core", "Networking"),
		filepath.Join(projectDir, "TestApp", "Core", "Security"),
		filepath.Join(projectDir, "TestApp", "Domain", "Common"),
	}

	for _, d := range expectedDirs {
		if _, err := os.Stat(d); os.IsNotExist(err) {
			t.Errorf("expected directory %s to exist", d)
		}
	}

	// Step 4: Verify zero "Arquitectura" or "magnos" references in generated files
	err = filepath.Walk(projectDir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}
		data, readErr := os.ReadFile(path)
		if readErr != nil {
			return readErr
		}
		content := string(data)
		if strings.Contains(content, "Arquitectura") {
			t.Errorf("file %s contains 'Arquitectura' reference", path)
		}
		if strings.Contains(content, "magnos") {
			t.Errorf("file %s contains 'magnos' reference", path)
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walking project directory: %v", err)
	}

	// Step 5: Verify .anvil.yml marker exists with correct content
	markerRW := config.FileMarkerReadWriter{}
	anvilMarker, err := markerRW.Read(projectDir)
	if err != nil {
		t.Fatalf("reading .anvil.yml: %v", err)
	}
	if anvilMarker.ProjectName != "TestApp" {
		t.Errorf("marker ProjectName = %q, want 'TestApp'", anvilMarker.ProjectName)
	}
	if anvilMarker.BundleID != "com.testorg.TestApp" {
		t.Errorf("marker BundleID = %q, want 'com.testorg.TestApp'", anvilMarker.BundleID)
	}
	if anvilMarker.IOSVersion != "18.0" {
		t.Errorf("marker IOSVersion = %q, want '18.0'", anvilMarker.IOSVersion)
	}
	if anvilMarker.SwiftVersion != "6.0" {
		t.Errorf("marker SwiftVersion = %q, want '6.0'", anvilMarker.SwiftVersion)
	}

	// Verify Tuist runner was called
	if !tuist.called {
		t.Error("TuistRunner.Generate should have been called")
	}

	// Verify files were created
	if len(result.FilesCreated) == 0 {
		t.Error("no files were created")
	}

	// Verify key files exist
	keyFiles := []string{
		filepath.Join(projectDir, "TestApp", "App", "Application", "AppMain.swift"),
		filepath.Join(projectDir, "TestApp", "App", "Config", "AppEnvironment.swift"),
		filepath.Join(projectDir, "TestApp", "App", "Config", "EnvironmentConfiguration.swift"),
		filepath.Join(projectDir, "TestApp", "App", "Config", "AppDependencies.swift"),
		filepath.Join(projectDir, "TestApp", "App", "Navigation", "AppRouter.swift"),
		filepath.Join(projectDir, "TestApp", "App", "Navigation", "AppRouterImpl.swift"),
		filepath.Join(projectDir, "TestApp", "Core", "Networking", "APIClient.swift"),
		filepath.Join(projectDir, "TestApp", "Domain", "Common", "DomainError.swift"),
	}

	for _, f := range keyFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected key file %s to exist", f)
		}
	}

	// Step 6: Skipped (xcodebuild requires real Xcode + Tuist generated project)
	// The real xcodebuild test is in TestIntegrationAnvilInitXcodeBuild which
	// requires the "xcodebuild" build tag.

	// Step 7: Cleanup is automatic via t.TempDir()
}

func TestIntegrationAnvilInitRenderedContent(t *testing.T) {
	dir := t.TempDir()
	gen, _ := newRealGenerator()
	cfg := testProjectConfig(dir)

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	// Verify the main app file contains correct project name
	appFile := filepath.Join(result.ProjectDir, "TestApp", "App", "Application", "AppMain.swift")
	data, err := os.ReadFile(appFile)
	if err != nil {
		t.Fatalf("reading app file: %v", err)
	}
	content := string(data)

	if !strings.Contains(content, "TestAppApp") {
		t.Error("app file should contain 'TestAppApp' struct")
	}
	if !strings.Contains(content, "@main") {
		t.Error("app file should contain @main attribute")
	}

	// Verify Environment.swift contains correct scheme names
	envFile := filepath.Join(result.ProjectDir, "TestApp", "App", "Config", "AppEnvironment.swift")
	envData, err := os.ReadFile(envFile)
	if err != nil {
		t.Fatalf("reading environment file: %v", err)
	}
	envContent := string(envData)

	if !strings.Contains(envContent, "case dev") {
		t.Error("Environment.swift should contain 'case dev'")
	}
	if !strings.Contains(envContent, "case stg") {
		t.Error("Environment.swift should contain 'case stg'")
	}
	if !strings.Contains(envContent, "case production") {
		t.Error("Environment.swift should contain 'case production'")
	}
}
