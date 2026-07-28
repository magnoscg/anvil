package generator

import (
	"flag"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"github.com/oscarcanton/anvilcli/internal/config"
	"github.com/oscarcanton/anvilcli/templates"
)

var update = flag.Bool("update", false, "update golden files")

// goldenDir returns the absolute path to the testdata/golden/ directory.
func goldenDir() string {
	_, filename, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(filename), "..", "..", "testdata", "golden")
}

func TestGoldenBaseAppMain(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())

	ctx := ProjectTemplateContext{
		ProjectName:      "MyApp",
		ProjectNameLower: "myapp",
		BundleID:         "com.testorg.MyApp",
		Organization:     "testorg",
		IOSVersion:       "18.0",
		SwiftVersion:     "6.0",
		Schemes:          []string{"Dev", "Stg", "Production"},
		IncludeSwiftData: false,
		AIPacks:          nil,
		SkillsScope:      "project",
		IncludeExample:   false,
	}

	dir := t.TempDir()
	dest := filepath.Join(dir, "AppMain.swift")

	if err := renderer.Render("base/App/Application/AppMain.swift.tmpl", ctx, dest); err != nil {
		t.Fatalf("Render failed: %v", err)
	}

	got, err := os.ReadFile(dest)
	if err != nil {
		t.Fatalf("reading rendered output: %v", err)
	}

	goldenPath := filepath.Join(goldenDir(), "base_AppMain.swift")

	if *update {
		if err := os.WriteFile(goldenPath, got, 0644); err != nil {
			t.Fatalf("updating golden file: %v", err)
		}
		t.Log("updated golden file:", goldenPath)
		return
	}

	want, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("reading golden file (run with -update to create): %v", err)
	}

	if string(got) != string(want) {
		t.Errorf("golden file mismatch for base_AppMain.swift\n--- got ---\n%s\n--- want ---\n%s", string(got), string(want))
	}
}

func TestGoldenBaseAppEnvironment(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())

	ctx := ProjectTemplateContext{
		ProjectName:      "MyApp",
		ProjectNameLower: "myapp",
		BundleID:         "com.testorg.MyApp",
		Organization:     "testorg",
		IOSVersion:       "18.0",
		SwiftVersion:     "6.0",
		Schemes:          []string{"Dev", "Stg", "Production"},
	}

	dir := t.TempDir()
	dest := filepath.Join(dir, "AppEnvironment.swift")

	if err := renderer.Render("base/App/Config/AppEnvironment.swift.tmpl", ctx, dest); err != nil {
		t.Fatalf("Render failed: %v", err)
	}

	got, err := os.ReadFile(dest)
	if err != nil {
		t.Fatalf("reading rendered output: %v", err)
	}

	goldenPath := filepath.Join(goldenDir(), "base_AppEnvironment.swift")

	if *update {
		if err := os.WriteFile(goldenPath, got, 0644); err != nil {
			t.Fatalf("updating golden file: %v", err)
		}
		t.Log("updated golden file:", goldenPath)
		return
	}

	want, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("reading golden file (run with -update to create): %v", err)
	}

	if string(got) != string(want) {
		t.Errorf("golden file mismatch for base_AppEnvironment.swift\n--- got ---\n%s\n--- want ---\n%s", string(got), string(want))
	}
}

func TestGoldenFeatureViewModel(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())

	cfg := config.FeatureConfig{
		FeatureName: "Article",
		ProjectName: "MyApp",
	}
	ctx := NewFeatureContext(cfg)

	dir := t.TempDir()
	dest := filepath.Join(dir, "ArticleViewModel.swift")

	if err := renderer.Render("feature/Features/FeatureViewModel.swift.tmpl", ctx, dest); err != nil {
		t.Fatalf("Render failed: %v", err)
	}

	got, err := os.ReadFile(dest)
	if err != nil {
		t.Fatalf("reading rendered output: %v", err)
	}

	goldenPath := filepath.Join(goldenDir(), "feature_ViewModel.swift")

	if *update {
		if err := os.WriteFile(goldenPath, got, 0644); err != nil {
			t.Fatalf("updating golden file: %v", err)
		}
		t.Log("updated golden file:", goldenPath)
		return
	}

	want, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("reading golden file (run with -update to create): %v", err)
	}

	if string(got) != string(want) {
		t.Errorf("golden file mismatch for feature_ViewModel.swift\n--- got ---\n%s\n--- want ---\n%s", string(got), string(want))
	}
}

func TestGoldenCLAUDEmdSinglePack(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())
	merger := NewSettingsMerger(NewDiskWriter(), templates.FS)
	pr := NewPackRenderer(templates.FS, renderer, NewDiskWriter(), merger)

	ctx := ProjectTemplateContext{
		ProjectName:      "MyApp",
		ProjectNameLower: "myapp",
		BundleID:         "com.testorg.MyApp",
		Organization:     "testorg",
		IOSVersion:       "18.0",
		SwiftVersion:     "6.0",
		Schemes:          []string{"Dev", "Stg", "Production"},
	}

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"ios-architecture"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	got, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}

	goldenPath := filepath.Join(goldenDir(), "claude_ios_architecture.md")

	if *update {
		if err := os.MkdirAll(filepath.Dir(goldenPath), 0755); err != nil {
			t.Fatalf("creating golden dir: %v", err)
		}
		if err := os.WriteFile(goldenPath, got, 0644); err != nil {
			t.Fatalf("updating golden file: %v", err)
		}
		t.Log("updated golden file:", goldenPath)
		return
	}

	want, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("reading golden file (run with -update to create): %v", err)
	}

	if string(got) != string(want) {
		t.Errorf("golden file mismatch for claude_ios_architecture.md\n--- got (first 200) ---\n%s\n--- want (first 200) ---\n%s",
			truncate(string(got), 200), truncate(string(want), 200))
	}
}

func TestGoldenCLAUDEmdComposed(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())
	merger := NewSettingsMerger(NewDiskWriter(), templates.FS)
	pr := NewPackRenderer(templates.FS, renderer, NewDiskWriter(), merger)

	ctx := ProjectTemplateContext{
		ProjectName:      "MyApp",
		ProjectNameLower: "myapp",
		BundleID:         "com.testorg.MyApp",
		Organization:     "testorg",
		IOSVersion:       "18.0",
		SwiftVersion:     "6.0",
		Schemes:          []string{"Dev", "Stg", "Production"},
	}

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"ios-architecture", "prd-planner"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	got, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}

	goldenPath := filepath.Join(goldenDir(), "claude_composed.md")

	if *update {
		if err := os.MkdirAll(filepath.Dir(goldenPath), 0755); err != nil {
			t.Fatalf("creating golden dir: %v", err)
		}
		if err := os.WriteFile(goldenPath, got, 0644); err != nil {
			t.Fatalf("updating golden file: %v", err)
		}
		t.Log("updated golden file:", goldenPath)
		return
	}

	want, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("reading golden file (run with -update to create): %v", err)
	}

	if string(got) != string(want) {
		t.Errorf("golden file mismatch for claude_composed.md\n--- got (first 200) ---\n%s\n--- want (first 200) ---\n%s",
			truncate(string(got), 200), truncate(string(want), 200))
	}
}

func TestGoldenCLAUDEmdToolsMode(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())
	merger := NewSettingsMerger(NewDiskWriter(), templates.FS)
	pr := NewPackRenderer(templates.FS, renderer, NewDiskWriter(), merger)

	ctx := ProjectTemplateContext{
		ProjectName: "",
		Schemes:     nil,
		BundleID:    "",
		IsToolsMode: true,
	}

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"ios-architecture"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks in tools mode should not panic or error, got: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}

	text := string(content)

	if strings.Contains(text, "## Project Summary") {
		t.Error("tools mode CLAUDE.md should NOT contain '## Project Summary'")
	}
	if strings.Contains(text, "## Build & Test") {
		t.Error("tools mode CLAUDE.md should NOT contain '## Build & Test'")
	}
	if !strings.Contains(text, "## Non-negotiable Rules") {
		t.Error("tools mode CLAUDE.md should contain '## Non-negotiable Rules'")
	}
	if !strings.Contains(text, "## Anti-patterns to Avoid") {
		t.Error("tools mode CLAUDE.md should contain '## Anti-patterns to Avoid'")
	}
	if !strings.Contains(text, "## How to Work") {
		t.Error("tools mode CLAUDE.md should contain '## How to Work'")
	}
}

func TestGoldenCLAUDEmdToolsModeComposed(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())
	merger := NewSettingsMerger(NewDiskWriter(), templates.FS)
	pr := NewPackRenderer(templates.FS, renderer, NewDiskWriter(), merger)

	ctx := ProjectTemplateContext{
		ProjectName: "",
		Schemes:     nil,
		BundleID:    "",
		IsToolsMode: true,
	}

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"ios-architecture", "prd-planner", "gitflow"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks composed in tools mode should not panic or error, got: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}

	text := string(content)

	if strings.Contains(text, "## Project Summary") {
		t.Error("tools mode CLAUDE.md should NOT contain '## Project Summary'")
	}
	if !strings.Contains(text, "## Regla de oro") && !strings.Contains(text, "## Workflow de desarrollo") {
		t.Error("tools mode CLAUDE.md should contain prd-planner section")
	}
	if !strings.Contains(text, "## Git") {
		t.Error("tools mode CLAUDE.md should contain gitflow section '## Git'")
	}
}

func TestGoldenWorkflowsToolsMode(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())
	merger := NewSettingsMerger(NewDiskWriter(), templates.FS)
	pr := NewPackRenderer(templates.FS, renderer, NewDiskWriter(), merger)

	ctx := ProjectTemplateContext{
		ProjectName: "",
		Schemes:     nil,
		BundleID:    "",
		IsToolsMode: true,
	}

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"github-actions"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks github-actions in tools mode should not panic or error, got: %v", err)
	}

	ciContent, err := os.ReadFile(filepath.Join(dir, ".github", "workflows", "ci.yml"))
	if err != nil {
		t.Fatalf("reading ci.yml: %v", err)
	}

	ciText := string(ciContent)

	if strings.Contains(ciText, "build-go") {
		t.Error("ci.yml should NOT contain 'build-go' job (iOS projects only)")
	}
	if !strings.Contains(ciText, "build-and-test") {
		t.Error("ci.yml should contain 'build-and-test' job")
	}

	releaseContent, err := os.ReadFile(filepath.Join(dir, ".github", "workflows", "release.yml"))
	if err != nil {
		t.Fatalf("reading release.yml: %v", err)
	}

	releaseText := string(releaseContent)

	if strings.Contains(releaseText, "goreleaser") {
		t.Error("release.yml should NOT contain goreleaser (iOS projects only)")
	}
	if !strings.Contains(releaseText, "name: Release") {
		t.Error("release.yml should contain 'name: Release'")
	}
	if !strings.Contains(releaseText, "create-release") {
		t.Error("release.yml should contain 'create-release' job")
	}
}

func TestGoldenNoPacks(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())
	merger := NewSettingsMerger(NewDiskWriter(), templates.FS)
	pr := NewPackRenderer(templates.FS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	created, err := pr.RenderPacks(nil, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	if len(created) != 0 {
		t.Errorf("no-packs should create 0 files, got %d", len(created))
	}

	claudePath := filepath.Join(dir, "CLAUDE.md")
	if _, err := os.Stat(claudePath); !os.IsNotExist(err) {
		t.Error("CLAUDE.md should not exist when no packs are selected")
	}
}

// truncate returns at most maxLen characters from s.
func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

func TestGoldenFeatureRouter(t *testing.T) {
	renderer := NewRenderer(templates.FS, NewDiskWriter())

	cfg := config.FeatureConfig{
		FeatureName: "Article",
		ProjectName: "MyApp",
	}
	ctx := NewFeatureContext(cfg)

	dir := t.TempDir()
	dest := filepath.Join(dir, "ArticleRouter.swift")

	if err := renderer.Render("feature/Features/FeatureRouter.swift.tmpl", ctx, dest); err != nil {
		t.Fatalf("Render failed: %v", err)
	}

	got, err := os.ReadFile(dest)
	if err != nil {
		t.Fatalf("reading rendered output: %v", err)
	}

	goldenPath := filepath.Join(goldenDir(), "feature_Router.swift")

	if *update {
		if err := os.WriteFile(goldenPath, got, 0644); err != nil {
			t.Fatalf("updating golden file: %v", err)
		}
		t.Log("updated golden file:", goldenPath)
		return
	}

	want, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("reading golden file (run with -update to create): %v", err)
	}

	if string(got) != string(want) {
		t.Errorf("golden file mismatch for feature_Router.swift\n--- got ---\n%s\n--- want ---\n%s", string(got), string(want))
	}
}
