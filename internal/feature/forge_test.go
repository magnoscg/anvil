package feature

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/oscarcanton/anvilcli/internal/config"
	"github.com/oscarcanton/anvilcli/internal/generator"
)

// stubRenderer is a test double for generator.TemplateRenderer.
type stubRenderer struct {
	renderFunc func(tmplPath string, ctx any, destPath string) error
}

func (s *stubRenderer) Render(tmplPath string, ctx any, destPath string) error {
	if s.renderFunc != nil {
		return s.renderFunc(tmplPath, ctx, destPath)
	}
	// Default: create the file on disk (simulates real rendering)
	w := generator.NewDiskWriter()
	return w.WriteFile(destPath, []byte("// generated"))
}

func (s *stubRenderer) RenderDir(tmplDir string, ctx any, destDir string) ([]string, error) {
	return nil, nil
}

func TestForgeHappyPath(t *testing.T) {
	dir := t.TempDir()

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}

	result, err := forge.Forge(cfg)
	if err != nil {
		t.Fatalf("Forge failed: %v", err)
	}

	// Verify result fields
	if result.FeatureDir != filepath.Join("Features", "Pokemon") {
		t.Errorf("FeatureDir = %q, want %q", result.FeatureDir, filepath.Join("Features", "Pokemon"))
	}

	if len(result.FilesCreated) == 0 {
		t.Error("FilesCreated should not be empty")
	}

	if len(result.WiringInstructions) == 0 {
		t.Error("WiringInstructions should not be empty")
	}

	// Verify files actually exist on disk
	for _, relPath := range result.FilesCreated {
		absPath := filepath.Join(dir, relPath)
		if _, err := os.Stat(absPath); os.IsNotExist(err) {
			t.Errorf("expected file %s to exist, but it does not", relPath)
		}
	}
}

func TestForgeHappyPathFileCount(t *testing.T) {
	dir := t.TempDir()

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}

	result, err := forge.Forge(cfg)
	if err != nil {
		t.Fatalf("Forge failed: %v", err)
	}

	// Base feature: 26 files
	want := 26
	if len(result.FilesCreated) != want {
		t.Errorf("FilesCreated count = %d, want %d", len(result.FilesCreated), want)
	}
}

func TestForgeFeatureAlreadyExists(t *testing.T) {
	dir := t.TempDir()

	// Pre-create the Domain directory to simulate existing feature
	domainDir := filepath.Join(dir, "MyApp", "Domain", "Pokemon")
	if err := os.MkdirAll(domainDir, 0755); err != nil {
		t.Fatalf("setup: %v", err)
	}

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}

	_, err := forge.Forge(cfg)
	if err == nil {
		t.Fatal("expected FeatureExistsError, got nil")
	}

	var target config.FeatureExistsError
	if !errors.As(err, &target) {
		t.Errorf("expected FeatureExistsError, got %T: %v", err, err)
	}
}

func TestForgeFeatureAlreadyExistsViaFeaturesDir(t *testing.T) {
	dir := t.TempDir()

	// Pre-create only the Features directory (no Domain dir) to simulate a partial existing feature.
	featuresDir := filepath.Join(dir, "MyApp", "Features", "Pokemon")
	if err := os.MkdirAll(featuresDir, 0755); err != nil {
		t.Fatalf("setup: %v", err)
	}

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}

	_, err := forge.Forge(cfg)
	if err == nil {
		t.Fatal("expected FeatureExistsError when Features/<Name>/ exists, got nil")
	}

	var target config.FeatureExistsError
	if !errors.As(err, &target) {
		t.Errorf("expected FeatureExistsError, got %T: %v", err, err)
	}
}

func TestForgeFeatureAlreadyExistsViaDataDir(t *testing.T) {
	dir := t.TempDir()

	// Pre-create only the Data directory (no Domain or Features dir).
	dataDir := filepath.Join(dir, "MyApp", "Data", "Pokemon")
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		t.Fatalf("setup: %v", err)
	}

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}

	_, err := forge.Forge(cfg)
	if err == nil {
		t.Fatal("expected FeatureExistsError when Data/<Name>/ exists, got nil")
	}

	var target config.FeatureExistsError
	if !errors.As(err, &target) {
		t.Errorf("expected FeatureExistsError, got %T: %v", err, err)
	}
}

func TestForgeInvalidFeatureName(t *testing.T) {
	dir := t.TempDir()

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	tests := []struct {
		name        string
		featureName string
	}{
		{"empty", ""},
		{"starts with digit", "123feature"},
		{"swift keyword", "class"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg := config.FeatureConfig{
				FeatureName: tt.featureName,
				ProjectRoot: dir,
				ProjectName: "MyApp",
			}

			_, err := forge.Forge(cfg)
			if err == nil {
				t.Errorf("expected error for feature name %q, got nil", tt.featureName)
			}
		})
	}
}

func TestForgePartialFailureTriggersRollback(t *testing.T) {
	dir := t.TempDir()

	renderCount := 0
	renderer := &stubRenderer{
		renderFunc: func(tmplPath string, ctx any, destPath string) error {
			renderCount++
			// Fail on the 5th file
			if renderCount == 5 {
				return fmt.Errorf("simulated render failure")
			}
			w := generator.NewDiskWriter()
			return w.WriteFile(destPath, []byte("// generated"))
		},
	}

	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}

	_, err := forge.Forge(cfg)
	if err == nil {
		t.Fatal("expected error from partial failure, got nil")
	}

	// Verify that the first 4 created files were rolled back
	jobs := FeatureLayout(cfg)
	for i := 0; i < 4 && i < len(jobs); i++ {
		absPath := filepath.Join(dir, jobs[i].DestPath)
		if _, statErr := os.Stat(absPath); !os.IsNotExist(statErr) {
			t.Errorf("rolled-back file %s should not exist", jobs[i].DestPath)
		}
	}
}

func TestForgeWithOptionalFlags(t *testing.T) {
	dir := t.TempDir()

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName:            "Pokemon",
		ProjectRoot:            dir,
		ProjectName:            "MyApp",
		IncludeLocalDataSource: true,
		IncludeKeychain:        true,
		IncludeRouteResolver:   true,
	}

	result, err := forge.Forge(cfg)
	if err != nil {
		t.Fatalf("Forge failed: %v", err)
	}

	// All options: 29 files
	want := 29
	if len(result.FilesCreated) != want {
		t.Errorf("FilesCreated count = %d, want %d", len(result.FilesCreated), want)
	}

	// Check optional files are included
	hasLocalDS := false
	hasKeychain := false
	hasRouteResolver := false

	for _, f := range result.FilesCreated {
		switch filepath.Base(f) {
		case "PokemonLocalDataSource.swift":
			hasLocalDS = true
		case "PokemonKeychainDataSource.swift":
			hasKeychain = true
		case "PokemonRouteResolver.swift":
			hasRouteResolver = true
		}
	}

	if !hasLocalDS {
		t.Error("expected PokemonLocalDataSource.swift in created files")
	}
	if !hasKeychain {
		t.Error("expected PokemonKeychainDataSource.swift in created files")
	}
	if !hasRouteResolver {
		t.Error("expected PokemonRouteResolver.swift in created files")
	}
}

func TestForgeResultRelativePaths(t *testing.T) {
	dir := t.TempDir()

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}

	result, err := forge.Forge(cfg)
	if err != nil {
		t.Fatalf("Forge failed: %v", err)
	}

	// All paths should be relative (not starting with /)
	for _, f := range result.FilesCreated {
		if filepath.IsAbs(f) {
			t.Errorf("expected relative path, got absolute: %s", f)
		}
	}
}

func TestRollbackRemovesOnlyCreatedFiles(t *testing.T) {
	dir := t.TempDir()

	// Create some pre-existing files that should NOT be touched
	existing := filepath.Join(dir, "existing.swift")
	if err := os.WriteFile(existing, []byte("keep me"), 0644); err != nil {
		t.Fatalf("setup: %v", err)
	}

	// Create some files to roll back
	toRemove := filepath.Join(dir, "generated.swift")
	if err := os.WriteFile(toRemove, []byte("// generated"), 0644); err != nil {
		t.Fatalf("setup: %v", err)
	}

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	if err := forge.Rollback([]string{toRemove}); err != nil {
		t.Fatalf("Rollback failed: %v", err)
	}

	// generated.swift should be gone
	if _, err := os.Stat(toRemove); !os.IsNotExist(err) {
		t.Error("generated.swift should have been removed")
	}

	// existing.swift should still exist
	if _, err := os.Stat(existing); os.IsNotExist(err) {
		t.Error("existing.swift should NOT have been removed")
	}
}

func TestForgeWithUITests(t *testing.T) {
	dir := t.TempDir()

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName:    "Pokemon",
		ProjectRoot:    dir,
		ProjectName:    "MyApp",
		IncludeUITests: true,
	}

	result, err := forge.Forge(cfg)
	if err != nil {
		t.Fatalf("Forge failed: %v", err)
	}

	// Base 26 + 5 UI test files = 31
	want := 31
	if len(result.FilesCreated) != want {
		t.Errorf("FilesCreated count = %d, want %d", len(result.FilesCreated), want)
	}

	hasAccessibilityID := false
	hasStub := false
	hasFixture := false
	hasScreenTests := false
	hasScreen := false

	for _, f := range result.FilesCreated {
		switch filepath.Base(f) {
		case "PokemonAccessibilityID.swift":
			hasAccessibilityID = true
		case "StubPokemonRemoteDataSource.swift":
			hasStub = true
		case "FixturePokemonRemoteDataSource.swift":
			hasFixture = true
		case "PokemonScreenTests.swift":
			hasScreenTests = true
		case "PokemonScreen.swift":
			hasScreen = true
		}
	}

	if !hasAccessibilityID {
		t.Error("expected PokemonAccessibilityID.swift in created files")
	}
	if !hasStub {
		t.Error("expected StubPokemonRemoteDataSource.swift in created files")
	}
	if !hasFixture {
		t.Error("expected FixturePokemonRemoteDataSource.swift in created files")
	}
	if !hasScreenTests {
		t.Error("expected PokemonScreenTests.swift in created files")
	}
	if !hasScreen {
		t.Error("expected PokemonScreen.swift in created files")
	}
}

func TestForgeWithAllOptionsIncludingUITests(t *testing.T) {
	dir := t.TempDir()

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName:            "Pokemon",
		ProjectRoot:            dir,
		ProjectName:            "MyApp",
		IncludeLocalDataSource: true,
		IncludeKeychain:        true,
		IncludeRouteResolver:   true,
		IncludeUITests:         true,
	}

	result, err := forge.Forge(cfg)
	if err != nil {
		t.Fatalf("Forge failed: %v", err)
	}

	// All options: 29 (base+optional) + 5 UI test files = 34
	want := 34
	if len(result.FilesCreated) != want {
		t.Errorf("FilesCreated count = %d, want %d", len(result.FilesCreated), want)
	}
}

func TestForgeWiringInstructionsWithRouteResolver(t *testing.T) {
	dir := t.TempDir()

	renderer := &stubRenderer{}
	forge := NewFeatureForge(renderer)

	cfg := config.FeatureConfig{
		FeatureName:          "Pokemon",
		ProjectRoot:          dir,
		ProjectName:          "MyApp",
		IncludeRouteResolver: true,
	}

	result, err := forge.Forge(cfg)
	if err != nil {
		t.Fatalf("Forge failed: %v", err)
	}

	// Should have at least 3 instructions (factory, routes modifier, route resolver)
	if len(result.WiringInstructions) < 3 {
		t.Errorf("expected at least 3 wiring instructions with RouteResolver, got %d", len(result.WiringInstructions))
	}
}
