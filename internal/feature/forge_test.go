package feature

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/magnoscg/anvil/internal/config"
	"github.com/magnoscg/anvil/internal/generator"
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
	if err := w.EnsureDir(filepath.Dir(destPath)); err != nil {
		return err
	}
	return w.CreateFile(destPath, []byte("// generated"), 0644)
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

func TestForgeRejectsUnsafeProjectNameBeforeWriting(t *testing.T) {
	for _, projectName := range []string{"../outside", "App/Child", "/tmp/App", ""} {
		t.Run(projectName, func(t *testing.T) {
			dir := t.TempDir()
			projectRoot := filepath.Join(dir, "project")
			if err := os.Mkdir(projectRoot, 0o755); err != nil {
				t.Fatalf("create project root: %v", err)
			}
			forge := NewFeatureForge(&stubRenderer{})

			_, err := forge.Forge(config.FeatureConfig{
				FeatureName: "Pokemon",
				ProjectRoot: projectRoot,
				ProjectName: projectName,
			})

			var invalidName config.InvalidProjectNameError
			if !errors.As(err, &invalidName) {
				t.Fatalf("error = %v, want InvalidProjectNameError", err)
			}
			entries, readErr := os.ReadDir(dir)
			if readErr != nil {
				t.Fatalf("read temp directory: %v", readErr)
			}
			if len(entries) != 1 || entries[0].Name() != "project" {
				t.Fatalf("unsafe project name wrote outside the project: %v", entries)
			}
			projectEntries, readErr := os.ReadDir(projectRoot)
			if readErr != nil {
				t.Fatalf("read project root: %v", readErr)
			}
			if len(projectEntries) != 0 {
				t.Fatalf("unsafe project name wrote into the project: %v", projectEntries)
			}
		})
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
			return renderLikeTheRealRenderer(destPath)
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
		absPath := filepath.Join(dir, generator.MapToProjectPath(jobs[i].DestPath, cfg.ProjectName))
		if _, statErr := os.Stat(absPath); !os.IsNotExist(statErr) {
			t.Errorf("rolled-back file %s should not exist", jobs[i].DestPath)
		}
	}
	assertEmptyDir(t, dir)
}

func TestForgeFailureRemovesCreatedDirectoriesSoARetrySucceeds(t *testing.T) {
	dir := t.TempDir()
	existingDomain := filepath.Join(dir, "MyApp", "Domain")
	if err := os.MkdirAll(existingDomain, 0o755); err != nil {
		t.Fatalf("create existing directory: %v", err)
	}
	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}
	jobs := FeatureLayout(cfg)
	failingTemplate := jobs[len(jobs)-1].TemplatePath
	failing := &stubRenderer{
		renderFunc: func(tmplPath string, ctx any, destPath string) error {
			if tmplPath == failingTemplate {
				return fmt.Errorf("simulated render failure")
			}
			return renderLikeTheRealRenderer(destPath)
		},
	}

	if _, err := NewFeatureForge(failing).Forge(cfg); err == nil {
		t.Fatal("expected the failing render to fail the forge")
	}

	assertEmptyDir(t, existingDomain)
	for _, sub := range []string{"Data", "Features"} {
		if _, err := os.Lstat(filepath.Join(dir, "MyApp", sub)); !os.IsNotExist(err) {
			t.Errorf("directory MyApp/%s created by the failed forge should be removed, stat err = %v", sub, err)
		}
	}
	if _, err := os.Lstat(filepath.Join(dir, "MyAppTests")); !os.IsNotExist(err) {
		t.Errorf("directory MyAppTests created by the failed forge should be removed, stat err = %v", err)
	}

	result, err := NewFeatureForge(&stubRenderer{}).Forge(cfg)
	if err != nil {
		t.Fatalf("retry after a failed forge: %v", err)
	}
	if len(result.FilesCreated) != len(jobs) {
		t.Fatalf("retry created %d files, want %d", len(result.FilesCreated), len(jobs))
	}
}

func TestForgeRefusesAnExistingDestinationBeforeWriting(t *testing.T) {
	dir := t.TempDir()
	cfg := config.FeatureConfig{
		FeatureName: "Pokemon",
		ProjectRoot: dir,
		ProjectName: "MyApp",
	}
	jobs := FeatureLayout(cfg)
	collision := filepath.Join(dir, generator.MapToProjectPath(jobs[len(jobs)-1].DestPath, cfg.ProjectName))
	if err := os.MkdirAll(filepath.Dir(collision), 0o755); err != nil {
		t.Fatalf("create collision directory: %v", err)
	}
	if err := os.WriteFile(collision, []byte("// user code"), 0o644); err != nil {
		t.Fatalf("create colliding file: %v", err)
	}
	renders := 0
	renderer := &stubRenderer{
		renderFunc: func(string, any, string) error {
			renders++
			return nil
		},
	}

	_, err := NewFeatureForge(renderer).Forge(cfg)

	var exists config.FeatureExistsError
	if !errors.As(err, &exists) || exists.ExistingDir != collision {
		t.Fatalf("error = %v, want FeatureExistsError for %s", err, collision)
	}
	if renders != 0 {
		t.Fatalf("rendered %d files before detecting the collision", renders)
	}
	if _, err := os.Lstat(filepath.Join(dir, "MyApp")); !os.IsNotExist(err) {
		t.Fatalf("a refused forge must not create source directories, stat err = %v", err)
	}
	data, err := os.ReadFile(collision)
	if err != nil || string(data) != "// user code" {
		t.Fatalf("existing file changed: %q, %v", data, err)
	}
}

// renderLikeTheRealRenderer creates missing parent directories before the
// file, as generator.DefaultRenderer does.
func renderLikeTheRealRenderer(destPath string) error {
	w := generator.NewDiskWriter()
	if err := w.EnsureDir(filepath.Dir(destPath)); err != nil {
		return err
	}
	return w.CreateFile(destPath, []byte("// generated"), 0644)
}

func assertEmptyDir(t *testing.T, dir string) {
	t.Helper()
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatalf("read %s: %v", dir, err)
	}
	if len(entries) != 0 {
		names := make([]string, 0, len(entries))
		for _, entry := range entries {
			names = append(names, entry.Name())
		}
		t.Fatalf("%s should be empty after rollback, found %v", dir, names)
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

	// All options: base 26 + local(3) + keychain(2) + route resolver(1) = 32
	want := 32
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

	// All options: 32 (base+optional) + 5 UI test files = 37
	want := 37
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
