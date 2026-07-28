package generator

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"

	"github.com/oscarcanton/anvilcli/internal/config"
)

func xcodeprojTemplateFS() fstest.MapFS {
	pbxproj, _ := os.ReadFile("../../templates/base/xcodeproj/project.pbxproj.tmpl")
	xcscheme, _ := os.ReadFile("../../templates/base/xcodeproj/xcscheme.tmpl")
	workspace, _ := os.ReadFile("../../templates/base/xcodeproj/contents.xcworkspacedata.tmpl")

	return fstest.MapFS{
		"base/xcodeproj/project.pbxproj.tmpl":                &fstest.MapFile{Data: pbxproj},
		"base/xcodeproj/xcscheme.tmpl":                       &fstest.MapFile{Data: xcscheme},
		"base/xcodeproj/contents.xcworkspacedata.tmpl":       &fstest.MapFile{Data: workspace},
	}
}

func xcodeprojCfg() config.ProjectConfig {
	return config.ProjectConfig{
		Name:         "TestApp",
		BundleID:     "com.test.TestApp",
		Organization: "test",
		IOSVersion:   "18.0",
		SwiftVersion: "6.0",
		Schemes:      []string{"Dev", "Stg", "Production"},
	}
}

func TestXcodeProjGeneratorHappyPath(t *testing.T) {
	dir := t.TempDir()
	projectDir := filepath.Join(dir, "TestApp")
	if err := os.MkdirAll(projectDir, 0755); err != nil {
		t.Fatal(err)
	}

	memFS := xcodeprojTemplateFS()
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	gen := NewXcodeProjGenerator(renderer, writer, memFS)

	cfg := xcodeprojCfg()
	output, err := gen.Generate(context.Background(), projectDir, cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	if !strings.Contains(output, "TestApp.xcodeproj") {
		t.Errorf("output = %q, should mention TestApp.xcodeproj", output)
	}
	if !strings.Contains(output, "3 schemes") {
		t.Errorf("output = %q, should mention 3 schemes", output)
	}

	xcodeprojDir := filepath.Join(projectDir, "TestApp.xcodeproj")

	pbxprojPath := filepath.Join(xcodeprojDir, "project.pbxproj")
	if _, err := os.Stat(pbxprojPath); os.IsNotExist(err) {
		t.Error("project.pbxproj should exist")
	}

	wsPath := filepath.Join(xcodeprojDir, "project.xcworkspace", "contents.xcworkspacedata")
	if _, err := os.Stat(wsPath); os.IsNotExist(err) {
		t.Error("contents.xcworkspacedata should exist")
	}

	schemesDir := filepath.Join(xcodeprojDir, "xcshareddata", "xcschemes")
	if _, err := os.Stat(schemesDir); os.IsNotExist(err) {
		t.Error("xcschemes directory should exist")
	}
}

func TestXcodeProjGeneratorSchemeFiles(t *testing.T) {
	dir := t.TempDir()
	projectDir := filepath.Join(dir, "TestApp")
	if err := os.MkdirAll(projectDir, 0755); err != nil {
		t.Fatal(err)
	}

	memFS := xcodeprojTemplateFS()
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	gen := NewXcodeProjGenerator(renderer, writer, memFS)

	cfg := xcodeprojCfg()
	_, err := gen.Generate(context.Background(), projectDir, cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	schemesDir := filepath.Join(projectDir, "TestApp.xcodeproj", "xcshareddata", "xcschemes")
	expectedSchemes := []string{"TestApp-Dev.xcscheme", "TestApp-Stg.xcscheme", "TestApp-Production.xcscheme"}

	for _, scheme := range expectedSchemes {
		schemePath := filepath.Join(schemesDir, scheme)
		if _, err := os.Stat(schemePath); os.IsNotExist(err) {
			t.Errorf("scheme file %s should exist", scheme)
		}
	}

	entries, err := os.ReadDir(schemesDir)
	if err != nil {
		t.Fatalf("reading schemes dir: %v", err)
	}

	schemeCount := 0
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".xcscheme") {
			schemeCount++
		}
	}
	if schemeCount != len(cfg.Schemes) {
		t.Errorf("expected %d scheme files, got %d", len(cfg.Schemes), schemeCount)
	}
}

func TestXcodeProjGeneratorSwiftData(t *testing.T) {
	dir := t.TempDir()
	projectDir := filepath.Join(dir, "TestApp")
	if err := os.MkdirAll(projectDir, 0755); err != nil {
		t.Fatal(err)
	}

	memFS := xcodeprojTemplateFS()
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	gen := NewXcodeProjGenerator(renderer, writer, memFS)

	cfg := xcodeprojCfg()
	cfg.IncludeSwiftData = true

	_, err := gen.Generate(context.Background(), projectDir, cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	pbxprojPath := filepath.Join(projectDir, "TestApp.xcodeproj", "project.pbxproj")
	data, err := os.ReadFile(pbxprojPath)
	if err != nil {
		t.Fatalf("reading pbxproj: %v", err)
	}

	content := string(data)
	if !strings.Contains(content, "SwiftData.framework") {
		t.Error("pbxproj should contain SwiftData.framework when IncludeSwiftData is true")
	}
}

func TestXcodeProjGeneratorNoSwiftData(t *testing.T) {
	dir := t.TempDir()
	projectDir := filepath.Join(dir, "TestApp")
	if err := os.MkdirAll(projectDir, 0755); err != nil {
		t.Fatal(err)
	}

	memFS := xcodeprojTemplateFS()
	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	gen := NewXcodeProjGenerator(renderer, writer, memFS)

	cfg := xcodeprojCfg()
	cfg.IncludeSwiftData = false

	_, err := gen.Generate(context.Background(), projectDir, cfg)
	if err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	pbxprojPath := filepath.Join(projectDir, "TestApp.xcodeproj", "project.pbxproj")
	data, err := os.ReadFile(pbxprojPath)
	if err != nil {
		t.Fatalf("reading pbxproj: %v", err)
	}

	content := string(data)
	if strings.Contains(content, "SwiftData.framework") {
		t.Error("pbxproj should NOT contain SwiftData.framework when IncludeSwiftData is false")
	}
}

func TestXcodeProjGeneratorDeterministic(t *testing.T) {
	cfg := xcodeprojCfg()
	memFS := xcodeprojTemplateFS()

	var outputs [2]string

	for i := range 2 {
		dir := t.TempDir()
		projectDir := filepath.Join(dir, "TestApp")
		if err := os.MkdirAll(projectDir, 0755); err != nil {
			t.Fatal(err)
		}

		writer := NewDiskWriter()
		renderer := NewRenderer(memFS, writer)
		gen := NewXcodeProjGenerator(renderer, writer, memFS)

		_, err := gen.Generate(context.Background(), projectDir, cfg)
		if err != nil {
			t.Fatalf("run %d: Generate failed: %v", i, err)
		}

		pbxprojPath := filepath.Join(projectDir, "TestApp.xcodeproj", "project.pbxproj")
		data, err := os.ReadFile(pbxprojPath)
		if err != nil {
			t.Fatalf("run %d: reading pbxproj: %v", i, err)
		}
		outputs[i] = string(data)
	}

	if outputs[0] != outputs[1] {
		t.Error("same config should produce identical pbxproj output across runs")
	}
}

func TestXcodeProjGeneratorErrorWrapping(t *testing.T) {
	dir := t.TempDir()
	projectDir := filepath.Join(dir, "TestApp")
	if err := os.MkdirAll(projectDir, 0755); err != nil {
		t.Fatal(err)
	}

	memFS := fstest.MapFS{
		"base/xcodeproj/project.pbxproj.tmpl": &fstest.MapFile{
			Data: []byte("{{ .NonExistent | bad_func }}"),
		},
	}

	writer := NewDiskWriter()
	renderer := NewRenderer(memFS, writer)
	gen := NewXcodeProjGenerator(renderer, writer, memFS)

	cfg := xcodeprojCfg()
	_, err := gen.Generate(context.Background(), projectDir, cfg)
	if err == nil {
		t.Fatal("expected error from bad template, got nil")
	}

	var xcErr config.XcodeProjectError
	if !isXcodeProjectError(err, &xcErr) {
		t.Errorf("expected XcodeProjectError, got %T: %v", err, err)
	}
}

func isXcodeProjectError(err error, target *config.XcodeProjectError) bool {
	for err != nil {
		if xe, ok := err.(config.XcodeProjectError); ok {
			*target = xe
			return true
		}
		if u, ok := err.(interface{ Unwrap() error }); ok {
			err = u.Unwrap()
		} else {
			return false
		}
	}
	return false
}
