//go:build integration

package anvilcli_test

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestIntegrationOptionsSwiftDataOnly(t *testing.T) {
	dir := t.TempDir()
	gen, _ := newRealGenerator()
	cfg := testProjectConfig(dir)
	cfg.IncludeSwiftData = true
	cfg.AIPacks = nil
	cfg.IncludeExample = false

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	projectDir := result.ProjectDir

	// SwiftData files should exist
	swiftDataFiles := []string{
		filepath.Join(projectDir, "TestApp", "Core", "Persistence", "SwiftDataStack.swift"),
		filepath.Join(projectDir, "TestApp", "Core", "Persistence", "ModelContainerShared.swift"),
		filepath.Join(projectDir, "TestApp", "App", "DI", "PersistenceAssembly.swift"),
	}

	for _, f := range swiftDataFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected SwiftData file %s to exist", f)
		}
	}

	// Claude files should NOT exist
	claudeDir := filepath.Join(projectDir, ".claude")
	if _, err := os.Stat(claudeDir); !os.IsNotExist(err) {
		t.Error(".claude/ directory should NOT exist when AIPacks is nil")
	}

	claudeMd := filepath.Join(projectDir, "CLAUDE.md")
	if _, err := os.Stat(claudeMd); !os.IsNotExist(err) {
		t.Error("CLAUDE.md should NOT exist when AIPacks is nil")
	}

	// Example feature files should NOT exist
	exampleDomain := filepath.Join(projectDir, "Domain", "Example")
	if _, err := os.Stat(exampleDomain); !os.IsNotExist(err) {
		t.Error("Domain/Example/ should NOT exist when IncludeExample=false")
	}
}

func TestIntegrationOptionsClaudeOnly(t *testing.T) {
	dir := t.TempDir()
	gen, _ := newRealGenerator()
	cfg := testProjectConfig(dir)
	cfg.IncludeSwiftData = false
	cfg.AIPacks = []string{"ios-architecture"}
	cfg.IncludeExample = false

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	projectDir := result.ProjectDir

	// Claude files should exist
	claudeDocsDir := filepath.Join(projectDir, ".claude", "docs")
	if _, err := os.Stat(claudeDocsDir); os.IsNotExist(err) {
		t.Error(".claude/docs/ directory should exist when AIPacks contains ios-architecture")
	}

	claudeMd := filepath.Join(projectDir, "CLAUDE.md")
	if _, err := os.Stat(claudeMd); os.IsNotExist(err) {
		t.Error("CLAUDE.md should exist when AIPacks contains ios-architecture")
	}

	// Verify some expected doc files exist
	expectedDocs := []string{
		"ARCHITECTURE.md",
		"PROJECT-STRUCTURE.md",
		"swiftui-code-style.md",
		"swift-concurrency.md",
		"testing.md",
	}

	for _, doc := range expectedDocs {
		docPath := filepath.Join(claudeDocsDir, doc)
		if _, err := os.Stat(docPath); os.IsNotExist(err) {
			t.Errorf("expected Claude doc %s to exist", doc)
		}
	}

	// SwiftData files should NOT exist
	persistenceDir := filepath.Join(projectDir, "TestApp", "Core", "Persistence")
	if _, err := os.Stat(persistenceDir); !os.IsNotExist(err) {
		t.Error("Core/Persistence/ should NOT exist when IncludeSwiftData=false")
	}
}

func TestIntegrationOptionsExampleFeature(t *testing.T) {
	dir := t.TempDir()
	gen, _ := newRealGenerator()
	cfg := testProjectConfig(dir)
	cfg.IncludeSwiftData = false
	cfg.AIPacks = nil
	cfg.IncludeExample = true

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	projectDir := result.ProjectDir

	// Example feature files should exist across all layers
	exampleDirs := []string{
		filepath.Join(projectDir, "Domain", "Example"),
		filepath.Join(projectDir, "Data", "Example"),
		filepath.Join(projectDir, "Features", "Example"),
	}

	for _, d := range exampleDirs {
		if _, err := os.Stat(d); os.IsNotExist(err) {
			t.Errorf("expected Example directory %s to exist", d)
		}
	}

	// Verify specific Example feature files
	exampleFiles := []string{
		filepath.Join(projectDir, "Domain", "Example", "Models", "ExampleModel.swift"),
		filepath.Join(projectDir, "Features", "Example", "UI", "ExampleView.swift"),
		filepath.Join(projectDir, "Features", "Example", "Presentation", "ViewModels", "ExampleViewModel.swift"),
	}

	for _, f := range exampleFiles {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("expected Example file %s to exist", f)
		}
	}
}

func TestIntegrationOptionsAllEnabled(t *testing.T) {
	dir := t.TempDir()
	gen, _ := newRealGenerator()
	cfg := testProjectConfig(dir)
	cfg.IncludeSwiftData = true
	cfg.AIPacks = []string{"ios-architecture"}
	cfg.IncludeExample = true

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	projectDir := result.ProjectDir

	// SwiftData files
	swiftDataStack := filepath.Join(projectDir, "TestApp", "Core", "Persistence", "SwiftDataStack.swift")
	if _, err := os.Stat(swiftDataStack); os.IsNotExist(err) {
		t.Error("SwiftDataStack.swift should exist when all options enabled")
	}

	// Claude files
	claudeDocsDir := filepath.Join(projectDir, ".claude", "docs")
	if _, err := os.Stat(claudeDocsDir); os.IsNotExist(err) {
		t.Error(".claude/docs/ should exist when all options enabled")
	}

	// Example feature
	exampleVM := filepath.Join(projectDir, "Features", "Example", "Presentation", "ViewModels", "ExampleViewModel.swift")
	if _, err := os.Stat(exampleVM); os.IsNotExist(err) {
		t.Error("ExampleViewModel.swift should exist when all options enabled")
	}

	// Total files should be more than base-only
	if len(result.FilesCreated) < 30 {
		t.Errorf("with all options enabled, expected at least 30 files, got %d", len(result.FilesCreated))
	}
}

func TestIntegrationOptionsNoneEnabled(t *testing.T) {
	dir := t.TempDir()
	gen, _ := newRealGenerator()
	cfg := testProjectConfig(dir)
	cfg.IncludeSwiftData = false
	cfg.AIPacks = nil
	cfg.IncludeExample = false

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	projectDir := result.ProjectDir

	// Base files should exist
	baseFile := filepath.Join(projectDir, "TestApp", "App", "Application", "AppMain.swift")
	if _, err := os.Stat(baseFile); os.IsNotExist(err) {
		t.Error("base app file should exist even with no options")
	}

	// SwiftData should NOT exist
	persistenceDir := filepath.Join(projectDir, "TestApp", "Core", "Persistence")
	if _, err := os.Stat(persistenceDir); !os.IsNotExist(err) {
		t.Error("Core/Persistence/ should NOT exist with no options")
	}

	// Claude should NOT exist
	claudeDir := filepath.Join(projectDir, ".claude")
	if _, err := os.Stat(claudeDir); !os.IsNotExist(err) {
		t.Error(".claude/ should NOT exist with no options")
	}

	// Example should NOT exist
	exampleDir := filepath.Join(projectDir, "Domain", "Example")
	if _, err := os.Stat(exampleDir); !os.IsNotExist(err) {
		t.Error("Domain/Example/ should NOT exist with no options")
	}

	// File count should be base-only (roughly 35-45 base files + .anvil.yml)
	if len(result.FilesCreated) < 10 {
		t.Errorf("expected at least 10 base files, got %d", len(result.FilesCreated))
	}
}
