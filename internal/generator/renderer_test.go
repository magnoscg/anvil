package generator

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"
)

func TestRenderSingleTemplate(t *testing.T) {
	memFS := fstest.MapFS{
		"test/hello.swift.tmpl": &fstest.MapFile{
			Data: []byte("// Project: {{ .ProjectName }}\nimport Foundation\n"),
		},
	}

	dir := t.TempDir()
	dest := filepath.Join(dir, "hello.swift")

	renderer := NewRenderer(memFS, NewDiskWriter())
	ctx := ProjectTemplateContext{ProjectName: "MyApp"}

	if err := renderer.Render("test/hello.swift.tmpl", ctx, dest); err != nil {
		t.Fatalf("Render failed: %v", err)
	}

	got, err := os.ReadFile(dest)
	if err != nil {
		t.Fatalf("reading output: %v", err)
	}

	want := "// Project: MyApp\nimport Foundation\n"
	if string(got) != want {
		t.Errorf("output = %q, want %q", string(got), want)
	}
}

func TestRenderWithConditionalBlocks(t *testing.T) {
	memFS := fstest.MapFS{
		"test/app.swift.tmpl": &fstest.MapFile{
			Data: []byte("import SwiftUI\n{{ if .IncludeSwiftData }}import SwiftData\n{{ end }}struct App {}\n"),
		},
	}

	tests := []struct {
		name string
		ctx  ProjectTemplateContext
		want string
	}{
		{
			name: "with SwiftData",
			ctx:  ProjectTemplateContext{IncludeSwiftData: true},
			want: "import SwiftUI\nimport SwiftData\nstruct App {}\n",
		},
		{
			name: "without SwiftData",
			ctx:  ProjectTemplateContext{IncludeSwiftData: false},
			want: "import SwiftUI\nstruct App {}\n",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			dir := t.TempDir()
			dest := filepath.Join(dir, "app.swift")

			renderer := NewRenderer(memFS, NewDiskWriter())
			if err := renderer.Render("test/app.swift.tmpl", tt.ctx, dest); err != nil {
				t.Fatalf("Render failed: %v", err)
			}

			got, err := os.ReadFile(dest)
			if err != nil {
				t.Fatalf("reading output: %v", err)
			}

			if string(got) != tt.want {
				t.Errorf("output = %q, want %q", string(got), tt.want)
			}
		})
	}
}

func TestRenderWithCustomFunctions(t *testing.T) {
	memFS := fstest.MapFS{
		"test/funcs.swift.tmpl": &fstest.MapFile{
			Data: []byte("struct {{ pascal .FeatureName }}View {}\nlet name = \"{{ lower .FeatureName }}\"\nlet camelName = \"{{ camel .FeatureName }}\"\n"),
		},
	}

	dir := t.TempDir()
	dest := filepath.Join(dir, "funcs.swift")

	renderer := NewRenderer(memFS, NewDiskWriter())
	ctx := FeatureTemplateContext{FeatureName: "pokemon-list"}

	if err := renderer.Render("test/funcs.swift.tmpl", ctx, dest); err != nil {
		t.Fatalf("Render failed: %v", err)
	}

	got, err := os.ReadFile(dest)
	if err != nil {
		t.Fatalf("reading output: %v", err)
	}

	want := "struct PokemonListView {}\nlet name = \"pokemon-list\"\nlet camelName = \"pokemonList\"\n"
	if string(got) != want {
		t.Errorf("output = %q, want %q", string(got), want)
	}
}

func TestRenderFilenameTemplating(t *testing.T) {
	tests := []struct {
		name     string
		filename string
		ctx      any
		want     string
	}{
		{
			name:     "feature name in filename",
			filename: "{{.FeatureName}}View.swift.tmpl",
			ctx:      FeatureTemplateContext{FeatureName: "Pokemon"},
			want:     "PokemonView.swift",
		},
		{
			name:     "no template in filename",
			filename: "AppDelegate.swift.tmpl",
			ctx:      ProjectTemplateContext{ProjectName: "MyApp"},
			want:     "AppDelegate.swift",
		},
		{
			name:     "nested path with template",
			filename: "UI/{{.FeatureName}}View.swift.tmpl",
			ctx:      FeatureTemplateContext{FeatureName: "Auth"},
			want:     "UI/AuthView.swift",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := renderFilename(tt.filename, tt.ctx)
			if err != nil {
				t.Fatalf("renderFilename failed: %v", err)
			}
			if got != tt.want {
				t.Errorf("renderFilename(%q) = %q, want %q", tt.filename, got, tt.want)
			}
		})
	}
}

func TestRenderDirCreatesFiles(t *testing.T) {
	memFS := fstest.MapFS{
		"feature/Model.swift.tmpl": &fstest.MapFile{
			Data: []byte("struct {{ .FeatureName }}Model {}\n"),
		},
		"feature/View.swift.tmpl": &fstest.MapFile{
			Data: []byte("struct {{ .FeatureName }}View: View {}\n"),
		},
	}

	dir := t.TempDir()
	renderer := NewRenderer(memFS, NewDiskWriter())
	ctx := FeatureTemplateContext{FeatureName: "Pokemon"}

	created, err := renderer.RenderDir("feature", ctx, dir)
	if err != nil {
		t.Fatalf("RenderDir failed: %v", err)
	}

	if len(created) != 2 {
		t.Fatalf("created %d files, want 2", len(created))
	}

	modelContent, err := os.ReadFile(filepath.Join(dir, "Model.swift"))
	if err != nil {
		t.Fatalf("reading Model.swift: %v", err)
	}
	if string(modelContent) != "struct PokemonModel {}\n" {
		t.Errorf("Model.swift = %q, want %q", string(modelContent), "struct PokemonModel {}\n")
	}

	viewContent, err := os.ReadFile(filepath.Join(dir, "View.swift"))
	if err != nil {
		t.Fatalf("reading View.swift: %v", err)
	}
	if string(viewContent) != "struct PokemonView: View {}\n" {
		t.Errorf("View.swift = %q, want %q", string(viewContent), "struct PokemonView: View {}\n")
	}
}

func TestRenderDirWithSubdirectories(t *testing.T) {
	memFS := fstest.MapFS{
		"feature/UI/View.swift.tmpl": &fstest.MapFile{
			Data: []byte("struct {{ .FeatureName }}View {}\n"),
		},
		"feature/DI/Factory.swift.tmpl": &fstest.MapFile{
			Data: []byte("struct {{ .FeatureName }}Factory {}\n"),
		},
	}

	dir := t.TempDir()
	renderer := NewRenderer(memFS, NewDiskWriter())
	ctx := FeatureTemplateContext{FeatureName: "Auth"}

	created, err := renderer.RenderDir("feature", ctx, dir)
	if err != nil {
		t.Fatalf("RenderDir failed: %v", err)
	}

	if len(created) != 2 {
		t.Fatalf("created %d files, want 2", len(created))
	}

	uiContent, err := os.ReadFile(filepath.Join(dir, "UI", "View.swift"))
	if err != nil {
		t.Fatalf("reading UI/View.swift: %v", err)
	}
	if string(uiContent) != "struct AuthView {}\n" {
		t.Errorf("UI/View.swift = %q, want %q", string(uiContent), "struct AuthView {}\n")
	}
}

func TestRenderMissingTemplateReturnsError(t *testing.T) {
	memFS := fstest.MapFS{}

	dir := t.TempDir()
	dest := filepath.Join(dir, "output.swift")

	renderer := NewRenderer(memFS, NewDiskWriter())
	ctx := ProjectTemplateContext{ProjectName: "Test"}

	err := renderer.Render("nonexistent/file.swift.tmpl", ctx, dest)
	if err == nil {
		t.Fatal("expected error for missing template, got nil")
	}

	if !strings.Contains(err.Error(), "nonexistent/file.swift.tmpl") {
		t.Errorf("error should mention template name, got: %v", err)
	}
}

func TestRenderInvalidTemplateSyntaxReturnsError(t *testing.T) {
	memFS := fstest.MapFS{
		"test/bad.swift.tmpl": &fstest.MapFile{
			Data: []byte("struct {{ .ProjectName }{}\n"),
		},
	}

	dir := t.TempDir()
	dest := filepath.Join(dir, "bad.swift")

	renderer := NewRenderer(memFS, NewDiskWriter())
	ctx := ProjectTemplateContext{ProjectName: "Test"}

	err := renderer.Render("test/bad.swift.tmpl", ctx, dest)
	if err == nil {
		t.Fatal("expected error for invalid template syntax, got nil")
	}

	if !strings.Contains(err.Error(), "bad.swift.tmpl") {
		t.Errorf("error should mention template name, got: %v", err)
	}
}

func TestRenderGoldenFileComparison(t *testing.T) {
	templateContent := `// Generated by AnvilCLI
// Project: {{ .ProjectName }}
// Bundle: {{ .BundleID }}
// iOS: {{ .IOSVersion }}
// Swift: {{ .SwiftVersion }}
{{ if .IncludeSwiftData }}
import SwiftData
{{ end }}
import SwiftUI

struct {{ .ProjectName }}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
`

	expectedOutput := `// Generated by AnvilCLI
// Project: TestApp
// Bundle: com.test.TestApp
// iOS: 18.0
// Swift: 6.0

import SwiftData

import SwiftUI

struct TestAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
`

	memFS := fstest.MapFS{
		"base/App.swift.tmpl": &fstest.MapFile{
			Data: []byte(templateContent),
		},
	}

	dir := t.TempDir()
	dest := filepath.Join(dir, "App.swift")

	renderer := NewRenderer(memFS, NewDiskWriter())
	ctx := ProjectTemplateContext{
		ProjectName:      "TestApp",
		BundleID:         "com.test.TestApp",
		IOSVersion:       "18.0",
		SwiftVersion:     "6.0",
		IncludeSwiftData: true,
	}

	if err := renderer.Render("base/App.swift.tmpl", ctx, dest); err != nil {
		t.Fatalf("Render failed: %v", err)
	}

	got, err := os.ReadFile(dest)
	if err != nil {
		t.Fatalf("reading output: %v", err)
	}

	if string(got) != expectedOutput {
		t.Errorf("golden file mismatch.\ngot:\n%s\nwant:\n%s", string(got), expectedOutput)
	}
}

func TestRenderDirSkipsNonTmplFiles(t *testing.T) {
	memFS := fstest.MapFS{
		"feature/Model.swift.tmpl": &fstest.MapFile{
			Data: []byte("struct {{ .FeatureName }}Model {}\n"),
		},
		"feature/.gitkeep": &fstest.MapFile{
			Data: []byte(""),
		},
		"feature/README.md": &fstest.MapFile{
			Data: []byte("# Feature docs"),
		},
	}

	dir := t.TempDir()
	renderer := NewRenderer(memFS, NewDiskWriter())
	ctx := FeatureTemplateContext{FeatureName: "Pokemon"}

	created, err := renderer.RenderDir("feature", ctx, dir)
	if err != nil {
		t.Fatalf("RenderDir failed: %v", err)
	}

	if len(created) != 1 {
		t.Errorf("created %d files, want 1 (only .tmpl files)", len(created))
	}

	if _, err := os.Stat(filepath.Join(dir, "README.md")); !os.IsNotExist(err) {
		t.Error("README.md should not have been rendered")
	}
}

func TestSimplePlural(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"Pokemon", "Pokemons"},
		{"bus", "buses"},
		{"box", "boxes"},
		{"buzz", "buzzes"},
		{"dish", "dishes"},
		{"match", "matches"},
		{"party", "parties"},
		{"key", "keys"},
		{"toy", "toys"},
		{"", ""},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := simplePlural(tt.input)
			if got != tt.want {
				t.Errorf("simplePlural(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}
