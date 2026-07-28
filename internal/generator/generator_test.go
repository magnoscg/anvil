package generator

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"
	"time"

	"github.com/magnoscg/anvil/internal/config"
	"github.com/magnoscg/anvil/templates"
)

// -- Helpers --

func minimalBaseFS() fstest.MapFS {
	return fstest.MapFS{
		"base/App/Config/AppEnvironment.swift.tmpl": &fstest.MapFile{
			Data: []byte("// Project: {{ .ProjectName }}\n"),
		},
		"base/App/Config/Xcconfig/Scheme.xcconfig.tmpl": &fstest.MapFile{
			Data: []byte("// {{ .SchemeName }}.xcconfig\nBUNDLE_ID = {{ .BundleID }}{{ .BundleIDSuffix }}\n"),
		},
	}
}

func baseCfg(outputDir string) config.ProjectConfig {
	return config.ProjectConfig{
		Name:         "TestApp",
		BundleID:     "com.test.TestApp",
		Organization: "test",
		IOSVersion:   "18.0",
		SwiftVersion: "6.0",
		Schemes:      []string{"Dev", "Stg", "Production"},
		OutputDir:    outputDir,
		Mode:         config.ModeProject,
	}
}

// -- Tests --

func TestGenerateHappyPath(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "generated TestApp.xcodeproj (3 schemes)"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, &mockPackRenderer{})
	cfg := baseCfg(dir)

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	if result.ProjectDir != filepath.Join(dir, "TestApp") {
		t.Errorf("ProjectDir = %q, want %q", result.ProjectDir, filepath.Join(dir, "TestApp"))
	}

	if len(result.FilesCreated) == 0 {
		t.Error("FilesCreated should not be empty")
	}

	if result.XcodeProjectOutput != "generated TestApp.xcodeproj (3 schemes)" {
		t.Errorf("XcodeProjectOutput = %q, want 'generated TestApp.xcodeproj (3 schemes)'", result.XcodeProjectOutput)
	}

	if !strings.Contains(result.GitOutput, "initialized") {
		t.Errorf("GitOutput = %q, should contain 'initialized'", result.GitOutput)
	}

	if result.Duration == 0 {
		t.Error("Duration should be > 0")
	}

	if !xcodeproj.called {
		t.Error("XcodeProjGenerator.Generate should have been called")
	}

	if marker.writeDir != filepath.Join(dir, "TestApp") {
		t.Errorf("marker.Write dir = %q, want %q", marker.writeDir, filepath.Join(dir, "TestApp"))
	}

	if marker.writeCfg.ProjectName != "TestApp" {
		t.Errorf("marker ProjectName = %q, want 'TestApp'", marker.writeCfg.ProjectName)
	}
}

func TestGenerateRollbackOnTemplateRenderFailure(t *testing.T) {
	dir := t.TempDir()

	// Use a template with invalid syntax to trigger a render error
	memFS := fstest.MapFS{
		"base/bad.swift.tmpl": &fstest.MapFile{
			Data: []byte("{{ .NonExistentMethod | bad_func }}\n"),
		},
	}

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, &mockPackRenderer{})
	cfg := baseCfg(dir)

	_, err := gen.Generate(context.Background(), cfg)
	if err == nil {
		t.Fatal("expected error from bad template, got nil")
	}

	projectDir := filepath.Join(dir, "TestApp")
	if _, statErr := os.Stat(projectDir); !os.IsNotExist(statErr) {
		t.Errorf("project directory %s should have been rolled back (removed)", projectDir)
	}
}

func TestGenerateRollbackOnXcodeProjFailure(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{err: config.XcodeProjectError{
		Phase: "render project.pbxproj",
		Cause: errors.New("template error"),
	}}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, &mockPackRenderer{})
	cfg := baseCfg(dir)

	_, err := gen.Generate(context.Background(), cfg)
	if err == nil {
		t.Fatal("expected error from XcodeProj failure, got nil")
	}

	projectDir := filepath.Join(dir, "TestApp")
	if _, statErr := os.Stat(projectDir); !os.IsNotExist(statErr) {
		t.Errorf("project directory should have been rolled back after XcodeProj failure")
	}
}

func TestGenerateGitFailureIsNonFatal(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{initErr: errors.New("git not found")}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, &mockPackRenderer{})
	cfg := baseCfg(dir)

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate should succeed even when git fails, got: %v", err)
	}

	if !strings.Contains(result.GitOutput, "failed") {
		t.Errorf("GitOutput = %q, should indicate failure", result.GitOutput)
	}

	projectDir := filepath.Join(dir, "TestApp")
	if _, statErr := os.Stat(projectDir); os.IsNotExist(statErr) {
		t.Error("project directory should NOT be rolled back on git failure")
	}
}

func TestGenerateWithExampleFeature(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	forge := &mockFeatureForge{
		result: config.ForgeResult{
			FeatureDir:   "Features/Example",
			FilesCreated: []string{"Domain/Example/ExampleModel.swift", "Features/Example/UI/ExampleView.swift"},
		},
	}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, forge, &mockPackRenderer{})
	cfg := baseCfg(dir)
	cfg.IncludeExample = true

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	if !forge.called {
		t.Error("FeatureForge.Forge should have been called")
	}

	if forge.cfg.FeatureName != "Example" {
		t.Errorf("forge FeatureName = %q, want 'Example'", forge.cfg.FeatureName)
	}

	found := false
	for _, f := range result.FilesCreated {
		if strings.Contains(f, "Example") {
			found = true
			break
		}
	}
	if !found {
		t.Error("FilesCreated should include Example feature files")
	}
}

func TestGenerateWithSwiftData(t *testing.T) {
	dir := t.TempDir()
	memFS := fstest.MapFS{
		"base/App/Config/AppEnvironment.swift.tmpl": &fstest.MapFile{
			Data: []byte("// {{ .ProjectName }}\n"),
		},
		"base/App/Config/Xcconfig/Scheme.xcconfig.tmpl": &fstest.MapFile{
			Data: []byte("// {{ .SchemeName }}\n"),
		},
		"swiftdata/Core/Persistence/Stack.swift.tmpl": &fstest.MapFile{
			Data: []byte("// SwiftData for {{ .ProjectName }}\n"),
		},
	}

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, &mockPackRenderer{})
	cfg := baseCfg(dir)
	cfg.IncludeSwiftData = true

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	hasSDFile := false
	for _, f := range result.FilesCreated {
		if strings.Contains(f, "Persistence") || strings.Contains(f, "Stack") {
			hasSDFile = true
			break
		}
	}
	if !hasSDFile {
		t.Error("FilesCreated should include SwiftData files when IncludeSwiftData=true")
	}
}

func TestGenerateWithAIPacks(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	packRend := &mockPackRenderer{
		files: []string{"CLAUDE.md", ".claude/docs/ARCHITECTURE.md"},
	}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, packRend)
	cfg := baseCfg(dir)
	cfg.AIPacks = []string{"ios-architecture"}
	cfg.SkillsScope = "project"

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	if !packRend.called {
		t.Error("PackRenderer.RenderPacks should have been called")
	}

	if len(packRend.packs) != 1 || packRend.packs[0] != "ios-architecture" {
		t.Errorf("PackRenderer received packs = %v, want [ios-architecture]", packRend.packs)
	}

	if packRend.scope != "project" {
		t.Errorf("PackRenderer received scope = %q, want 'project'", packRend.scope)
	}

	hasClaudeFile := false
	for _, f := range result.FilesCreated {
		if strings.Contains(f, "CLAUDE") || strings.Contains(f, ".claude") {
			hasClaudeFile = true
			break
		}
	}
	if !hasClaudeFile {
		t.Errorf("FilesCreated should include Claude files when AIPacks contains ios-architecture. Got: %v", result.FilesCreated)
	}
}

func TestGenerateAnvilMarkerContainsAIPacks(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, &mockPackRenderer{})
	cfg := baseCfg(dir)
	cfg.AIPacks = []string{"ios-architecture", "gitflow"}
	cfg.SkillsScope = "global"

	_, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	m := marker.writeCfg
	if len(m.AIPacks) != 2 {
		t.Fatalf("marker AIPacks length = %d, want 2", len(m.AIPacks))
	}
	if m.AIPacks[0] != "ios-architecture" || m.AIPacks[1] != "gitflow" {
		t.Errorf("marker AIPacks = %v, want [ios-architecture gitflow]", m.AIPacks)
	}
	if m.SkillsScope != "global" {
		t.Errorf("marker SkillsScope = %q, want 'global'", m.SkillsScope)
	}
}

func TestGenerateRollbackOnMarkerWriteFailure(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{writeErr: errors.New("disk full")}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, &mockPackRenderer{})
	cfg := baseCfg(dir)

	_, err := gen.Generate(context.Background(), cfg)
	if err == nil {
		t.Fatal("expected error from marker write failure, got nil")
	}

	projectDir := filepath.Join(dir, "TestApp")
	if _, statErr := os.Stat(projectDir); !os.IsNotExist(statErr) {
		t.Error("project directory should have been rolled back after marker write failure")
	}
}

func TestGenerateWithNoPacks(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	packRend := &mockPackRenderer{}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, packRend)
	cfg := baseCfg(dir)
	cfg.AIPacks = nil

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	if packRend.called {
		t.Error("PackRenderer.RenderPacks should NOT have been called when AIPacks is nil")
	}

	for _, f := range result.FilesCreated {
		if strings.Contains(f, "CLAUDE") || strings.Contains(f, ".claude") {
			t.Errorf("no Claude files should be created when AIPacks is nil, found: %s", f)
		}
	}
}

func TestGenerateWithMultiplePacks(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	packRend := &mockPackRenderer{
		files: []string{
			"CLAUDE.md",
			".claude/docs/ARCHITECTURE.md",
			".claude/commands/dev-build.md",
			".dev/arch-index.md",
			"plan/INDEX.md",
		},
	}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, packRend)
	cfg := baseCfg(dir)
	cfg.AIPacks = []string{"ios-architecture", "prd-planner"}
	cfg.SkillsScope = "project"

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	if !packRend.called {
		t.Error("PackRenderer.RenderPacks should have been called")
	}

	// ResolveDependencies should have been called, ios-architecture comes first
	if len(packRend.packs) < 2 {
		t.Fatalf("PackRenderer received %d packs, want at least 2", len(packRend.packs))
	}

	hasClaude := false
	hasCommands := false
	hasDev := false
	hasPlan := false
	for _, f := range result.FilesCreated {
		if f == "CLAUDE.md" {
			hasClaude = true
		}
		if strings.Contains(f, "commands") {
			hasCommands = true
		}
		if strings.Contains(f, ".dev") {
			hasDev = true
		}
		if strings.Contains(f, "plan") {
			hasPlan = true
		}
	}
	if !hasClaude {
		t.Error("CLAUDE.md should be in FilesCreated")
	}
	if !hasCommands {
		t.Error("commands should be in FilesCreated")
	}
	if !hasDev {
		t.Error(".dev files should be in FilesCreated")
	}
	if !hasPlan {
		t.Error("plan files should be in FilesCreated")
	}
}

func TestGenerateWithAllPacks(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	allSlugs := make([]string, 0)
	for _, p := range config.AllPacks() {
		allSlugs = append(allSlugs, p.Slug)
	}

	expectedFiles := []string{
		"CLAUDE.md",
		".claude/docs/ARCHITECTURE.md",
		".claude/commands/dev-build.md",
		".claude/settings.json",
		".claude/skills/my-skill/SKILL.md",
		".github/workflows/ci.yml",
	}

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	packRend := &mockPackRenderer{files: expectedFiles}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, packRend)
	cfg := baseCfg(dir)
	cfg.AIPacks = allSlugs
	cfg.SkillsScope = "project"

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	if !packRend.called {
		t.Error("PackRenderer should have been called")
	}

	if len(packRend.packs) != 7 {
		t.Errorf("PackRenderer received %d packs, want 7", len(packRend.packs))
	}

	for _, expected := range expectedFiles {
		found := false
		for _, f := range result.FilesCreated {
			if f == expected {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("expected file %q not found in FilesCreated", expected)
		}
	}
}

func TestGenerateToolsOnlyHappyPath(t *testing.T) {
	dir := t.TempDir()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(minimalBaseFS(), writer)
	packRend := &mockPackRenderer{
		files: []string{"CLAUDE.md", ".claude/docs/ARCHITECTURE.md"},
	}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, minimalBaseFS(), nil, packRend)
	cfg := config.ProjectConfig{
		Mode:        config.ModeTools,
		AIPacks:     []string{"ios-architecture"},
		SkillsScope: "project",
		OutputDir:   dir,
	}

	result, err := gen.GenerateToolsOnly(context.Background(), cfg)
	if err != nil {
		t.Fatalf("GenerateToolsOnly failed: %v", err)
	}

	if result.ProjectDir != dir {
		t.Errorf("ProjectDir = %q, want %q (should use OutputDir directly)", result.ProjectDir, dir)
	}

	if len(result.FilesCreated) != 2 {
		t.Errorf("FilesCreated length = %d, want 2", len(result.FilesCreated))
	}

	if !packRend.called {
		t.Error("PackRenderer.RenderPacks should have been called")
	}

	if xcodeproj.called {
		t.Error("XcodeProjGenerator should NOT have been called in tools mode")
	}

	if git.initDir != "" {
		t.Error("git init should NOT have been called in tools mode")
	}

	if marker.writeDir != "" {
		t.Error("marker Write should NOT have been called in tools mode")
	}

	if result.Duration == 0 {
		t.Error("Duration should be > 0")
	}
}

func TestGenerateToolsOnlyNoPacks(t *testing.T) {
	dir := t.TempDir()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(minimalBaseFS(), writer)
	packRend := &mockPackRenderer{}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, minimalBaseFS(), nil, packRend)
	cfg := config.ProjectConfig{
		Mode:      config.ModeTools,
		OutputDir: dir,
	}

	result, err := gen.GenerateToolsOnly(context.Background(), cfg)
	if err != nil {
		t.Fatalf("GenerateToolsOnly with no packs failed: %v", err)
	}

	if len(result.FilesCreated) != 0 {
		t.Errorf("FilesCreated should be empty when no packs, got %v", result.FilesCreated)
	}

	if packRend.called {
		t.Error("PackRenderer should NOT have been called when no packs")
	}

	if result.ProjectDir != dir {
		t.Errorf("ProjectDir = %q, want %q", result.ProjectDir, dir)
	}
}

func TestGenerateToolsOnly_WithRealPacks(t *testing.T) {
	dir := t.TempDir()

	writer := NewDiskWriter()
	renderer := NewRenderer(templates.FS, writer)
	merger := NewSettingsMerger(writer, templates.FS)
	packRend := NewPackRenderer(templates.FS, renderer, writer, merger)

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, templates.FS, nil, packRend)
	cfg := config.ProjectConfig{
		Mode:        config.ModeTools,
		AIPacks:     []string{"ios-architecture"},
		SkillsScope: "project",
		OutputDir:   dir,
	}

	result, err := gen.GenerateToolsOnly(context.Background(), cfg)
	if err != nil {
		t.Fatalf("GenerateToolsOnly with real packs failed: %v", err)
	}

	// CLAUDE.md must exist
	claudePath := filepath.Join(dir, "CLAUDE.md")
	if _, err := os.Stat(claudePath); os.IsNotExist(err) {
		t.Error("CLAUDE.md should exist in tools mode output")
	}

	// .claude/docs/ must exist with at least one doc
	docsDir := filepath.Join(dir, ".claude", "docs")
	entries, err := os.ReadDir(docsDir)
	if err != nil {
		t.Fatalf("reading .claude/docs/: %v", err)
	}
	if len(entries) == 0 {
		t.Error(".claude/docs/ should contain doc files")
	}

	// No .xcodeproj directory
	xcodeprojDir := filepath.Join(dir, "*.xcodeproj")
	matches, _ := filepath.Glob(xcodeprojDir)
	if len(matches) > 0 {
		t.Errorf(".xcodeproj should NOT exist in tools mode, found: %v", matches)
	}

	// No .anvil.yml
	anvilPath := filepath.Join(dir, ".anvil.yml")
	if _, err := os.Stat(anvilPath); !os.IsNotExist(err) {
		t.Error(".anvil.yml should NOT exist in tools mode")
	}

	// No App/ directory
	appDir := filepath.Join(dir, "App")
	if _, err := os.Stat(appDir); !os.IsNotExist(err) {
		t.Error("App/ directory should NOT exist in tools mode")
	}

	// Xcodeproj generator should NOT have been called
	if xcodeproj.called {
		t.Error("XcodeProjGenerator should NOT have been called in tools mode")
	}

	// Git should NOT have been called
	if git.initDir != "" {
		t.Error("git init should NOT have been called in tools mode")
	}

	// Marker should NOT have been called
	if marker.writeDir != "" {
		t.Error("marker Write should NOT have been called in tools mode")
	}

	if len(result.FilesCreated) == 0 {
		t.Error("FilesCreated should not be empty with ios-architecture pack")
	}
}

func TestGenerateToolsOnly_CLAUDEMDContent(t *testing.T) {
	dir := t.TempDir()

	writer := NewDiskWriter()
	renderer := NewRenderer(templates.FS, writer)
	merger := NewSettingsMerger(writer, templates.FS)
	packRend := NewPackRenderer(templates.FS, renderer, writer, merger)

	gen := NewProjectGenerator(renderer, writer, &mockXcodeProjGenerator{}, &mockGitRunner{}, &mockMarkerReadWriter{}, templates.FS, nil, packRend)
	cfg := config.ProjectConfig{
		Mode:        config.ModeTools,
		AIPacks:     []string{"ios-architecture"},
		SkillsScope: "project",
		OutputDir:   dir,
	}

	_, err := gen.GenerateToolsOnly(context.Background(), cfg)
	if err != nil {
		t.Fatalf("GenerateToolsOnly failed: %v", err)
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
		t.Error("tools mode CLAUDE.md SHOULD contain '## Non-negotiable Rules'")
	}
	if !strings.Contains(text, "## Anti-patterns to Avoid") {
		t.Error("tools mode CLAUDE.md SHOULD contain '## Anti-patterns to Avoid'")
	}
}

func TestGenerate_ProjectMode_Unchanged(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "generated TestApp.xcodeproj (3 schemes)"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	packRend := &mockPackRenderer{
		files: []string{"CLAUDE.md", ".claude/docs/ARCHITECTURE.md"},
	}

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, packRend)
	cfg := baseCfg(dir)
	cfg.AIPacks = []string{"ios-architecture"}
	cfg.SkillsScope = "project"

	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate in project mode failed: %v", err)
	}

	// Full project structure must exist
	projectDir := filepath.Join(dir, "TestApp")
	if result.ProjectDir != projectDir {
		t.Errorf("ProjectDir = %q, want %q", result.ProjectDir, projectDir)
	}

	// xcodeproj must have been called
	if !xcodeproj.called {
		t.Error("XcodeProjGenerator should have been called in project mode")
	}

	// git must have been called
	if git.initDir == "" {
		t.Error("git init should have been called in project mode")
	}

	// marker must have been called
	if marker.writeDir == "" {
		t.Error("marker Write should have been called in project mode")
	}

	// .anvil.yml must be in FilesCreated
	hasAnvil := false
	for _, f := range result.FilesCreated {
		if f == ".anvil.yml" {
			hasAnvil = true
			break
		}
	}
	if !hasAnvil {
		t.Error("project mode should include .anvil.yml in FilesCreated")
	}

	// XcodeProjectOutput must be set
	if result.XcodeProjectOutput == "" {
		t.Error("XcodeProjectOutput should not be empty in project mode")
	}

	// GitOutput must contain initialized
	if !strings.Contains(result.GitOutput, "initialized") {
		t.Errorf("GitOutput = %q, should contain 'initialized'", result.GitOutput)
	}

	// Pack renderer must have been called
	if !packRend.called {
		t.Error("PackRenderer should have been called in project mode")
	}

	// Claude files must be in FilesCreated
	hasClaude := false
	for _, f := range result.FilesCreated {
		if strings.Contains(f, "CLAUDE") {
			hasClaude = true
			break
		}
	}
	if !hasClaude {
		t.Error("project mode should include CLAUDE.md in FilesCreated")
	}
}

func TestGenerateToolsOnly_EmptyPacksEdgeCase(t *testing.T) {
	dir := t.TempDir()

	writer := NewDiskWriter()
	renderer := NewRenderer(templates.FS, writer)
	merger := NewSettingsMerger(writer, templates.FS)
	packRend := NewPackRenderer(templates.FS, renderer, writer, merger)

	gen := NewProjectGenerator(renderer, writer, &mockXcodeProjGenerator{}, &mockGitRunner{}, &mockMarkerReadWriter{}, templates.FS, nil, packRend)
	cfg := config.ProjectConfig{
		Mode:      config.ModeTools,
		AIPacks:   nil,
		OutputDir: dir,
	}

	result, err := gen.GenerateToolsOnly(context.Background(), cfg)
	if err != nil {
		t.Fatalf("GenerateToolsOnly with empty packs should not error: %v", err)
	}

	if len(result.FilesCreated) != 0 {
		t.Errorf("FilesCreated should be empty with no packs, got %d files", len(result.FilesCreated))
	}

	if result.ProjectDir != dir {
		t.Errorf("ProjectDir = %q, want %q", result.ProjectDir, dir)
	}
}

func TestGenerateToolsOnly_EmptyProjectNameNoPanic(t *testing.T) {
	dir := t.TempDir()

	writer := NewDiskWriter()
	renderer := NewRenderer(templates.FS, writer)
	merger := NewSettingsMerger(writer, templates.FS)
	packRend := NewPackRenderer(templates.FS, renderer, writer, merger)

	gen := NewProjectGenerator(renderer, writer, &mockXcodeProjGenerator{}, &mockGitRunner{}, &mockMarkerReadWriter{}, templates.FS, nil, packRend)
	cfg := config.ProjectConfig{
		Mode:        config.ModeTools,
		Name:        "",
		Schemes:     nil,
		BundleID:    "",
		AIPacks:     []string{"ios-architecture"},
		SkillsScope: "project",
		OutputDir:   dir,
	}

	result, err := gen.GenerateToolsOnly(context.Background(), cfg)
	if err != nil {
		t.Fatalf("GenerateToolsOnly with empty ProjectName should not panic or error: %v", err)
	}

	if len(result.FilesCreated) == 0 {
		t.Error("should still produce files even with empty ProjectName")
	}
}

func TestGenerateAnvilMarkerHasCorrectMetadata(t *testing.T) {
	dir := t.TempDir()
	memFS := minimalBaseFS()

	xcodeproj := &mockXcodeProjGenerator{output: "ok"}
	git := &mockGitRunner{}
	marker := &mockMarkerReadWriter{}
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)

	gen := NewProjectGenerator(renderer, writer, xcodeproj, git, marker, memFS, nil, &mockPackRenderer{})
	cfg := baseCfg(dir)

	before := time.Now()
	_, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	m := marker.writeCfg
	if m.ProjectName != "TestApp" {
		t.Errorf("marker ProjectName = %q, want 'TestApp'", m.ProjectName)
	}
	if m.BundleID != "com.test.TestApp" {
		t.Errorf("marker BundleID = %q, want 'com.test.TestApp'", m.BundleID)
	}
	if m.IOSVersion != "18.0" {
		t.Errorf("marker IOSVersion = %q, want '18.0'", m.IOSVersion)
	}
	if m.SwiftVersion != "6.0" {
		t.Errorf("marker SwiftVersion = %q, want '6.0'", m.SwiftVersion)
	}
	if m.CreatedAt.Before(before) {
		t.Error("marker CreatedAt should be after test start time")
	}
}
