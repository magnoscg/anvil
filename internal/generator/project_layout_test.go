package generator

import (
	"testing"
	"testing/fstest"

	"github.com/magnoscg/anvil/internal/config"
)

// buildTestFS creates a minimal fstest.MapFS that mirrors the real template structure.
// This avoids depending on the actual embedded FS for unit tests.
func buildTestFS() fstest.MapFS {
	fs := fstest.MapFS{}

	// Base templates
	baseFiles := []string{
		"base/App/Application/AppMain.swift.tmpl",
		"base/App/Config/AppDependencies.swift.tmpl",
		"base/App/Config/AppEnvironment.swift.tmpl",
		"base/App/Config/EnvironmentConfiguration.swift.tmpl",
		"base/App/Config/Xcconfig/Base.xcconfig.tmpl",
		"base/App/Config/Xcconfig/Scheme.xcconfig.tmpl",
		"base/App/Navigation/AppRouter.swift.tmpl",
		"base/App/Navigation/AppRouterImpl.swift.tmpl",
		"base/App/Navigation/AppNavigationCoordinator.swift.tmpl",
		"base/App/Navigation/RootNavigationView.swift.tmpl",
		"base/Core/Common/Extensions/ColorHex.swift.tmpl",
		"base/Core/Common/Extensions/OptionalNil.swift.tmpl",
		"base/Core/Common/Models/ErrorDecorator.swift.tmpl",
		"base/Core/Common/SwiftUI/Builders/ConditionalContent.swift.tmpl",
		"base/Core/Common/SwiftUI/Components/ErrorView.swift.tmpl",
		"base/Core/Common/SwiftUI/Components/LoadingStateView.swift.tmpl",
		"base/Core/Common/SwiftUI/Modifiers/CustomListRow.swift.tmpl",
		"base/Core/Common/SwiftUI/Modifiers/PrimaryButtonStyle.swift.tmpl",
		"base/Core/DesignSystem/Tokens/AppColors.swift.tmpl",
		"base/Core/DesignSystem/Tokens/AppIcons.swift.tmpl",
		"base/Core/DesignSystem/Tokens/AppTypography.swift.tmpl",
		"base/Core/DesignSystem/Tokens/IconSize.swift.tmpl",
		"base/Core/DesignSystem/Tokens/Spacing.swift.tmpl",
		"base/Core/Networking/APIClient.swift.tmpl",
		"base/Core/Networking/APIClientImpl.swift.tmpl",
		"base/Core/Networking/APIEndpoint.swift.tmpl",
		"base/Core/Networking/APIError.swift.tmpl",
		"base/Core/Networking/APIErrorResponse.swift.tmpl",
		"base/Core/Networking/Endpoint.swift.tmpl",
		"base/Core/Networking/NetworkMonitor.swift.tmpl",
		"base/Core/Networking/RequestInterceptor.swift.tmpl",
		"base/Core/Networking/RetryInterceptor.swift.tmpl",
		"base/Core/Networking/RetryPolicy.swift.tmpl",
		"base/Core/Security/KeychainHelper.swift.tmpl",
		"base/Domain/Common/DomainError.swift.tmpl",
		"base/Domain/Common/DomainErrorMapping.swift.tmpl",
		"base/Info.plist.tmpl",
		"base/placeholder.txt.tmpl",
		"base/Resources/Assets.xcassets/Contents.json.tmpl",
		"base/Resources/Assets.xcassets/AccentColor.colorset/Contents.json.tmpl",
		"base/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json.tmpl",
		"base/Resources/Strings/Localizable.xcstrings.tmpl",
		"base/swiftformat.tmpl",
		"base/swiftlint.yml.tmpl",
		"base/.gitignore.tmpl",
	}
	// xcodeproj templates (skipped by walkTemplateDir, rendered by XcodeProjGenerator)
	xcodeprojFiles := []string{
		"base/xcodeproj/project.pbxproj.tmpl",
		"base/xcodeproj/xcscheme.tmpl",
		"base/xcodeproj/contents.xcworkspacedata.tmpl",
	}
	for _, f := range baseFiles {
		fs[f] = &fstest.MapFile{Data: []byte("// template\n")}
	}
	for _, f := range xcodeprojFiles {
		fs[f] = &fstest.MapFile{Data: []byte("// template\n")}
	}

	// SwiftData templates (3 .tmpl files)
	sdFiles := []string{
		"swiftdata/Core/Persistence/ModelContainerShared.swift.tmpl",
		"swiftdata/Core/Persistence/SwiftDataStack.swift.tmpl",
		"swiftdata/App/DI/PersistenceAssembly.swift.tmpl",
	}
	for _, f := range sdFiles {
		fs[f] = &fstest.MapFile{Data: []byte("// template\n")}
	}

	// Claude templates (1 .tmpl + 13 .md = 14 files)
	claudeFiles := []string{
		"ai-packs/ios-architecture/CLAUDE.md.tmpl",
		"ai-packs/ios-architecture/docs/ARCHITECTURE.md",
		"ai-packs/ios-architecture/docs/PROJECT-STRUCTURE.md",
		"ai-packs/ios-architecture/docs/new-feature.md",
		"ai-packs/ios-architecture/docs/swiftui-code-style.md",
		"ai-packs/ios-architecture/docs/design-system.md",
		"ai-packs/ios-architecture/docs/swift-concurrency.md",
		"ai-packs/ios-architecture/docs/swiftdata.md",
		"ai-packs/ios-architecture/docs/networking.md",
		"ai-packs/ios-architecture/docs/security-privacy.md",
		"ai-packs/ios-architecture/docs/diagnostics.md",
		"ai-packs/ios-architecture/docs/testing.md",
		"ai-packs/ios-architecture/docs/create-tests.md",
		"ai-packs/ios-architecture/docs/performance.md",
	}
	for _, f := range claudeFiles {
		fs[f] = &fstest.MapFile{Data: []byte("// content\n")}
	}

	// .gitkeep files (should be skipped)
	fs["base/.gitkeep"] = &fstest.MapFile{Data: []byte("")}
	fs["ai-packs/ios-architecture/.gitkeep"] = &fstest.MapFile{Data: []byte("")}

	return fs
}

func TestProjectLayoutBaseOnly(t *testing.T) {
	testFS := buildTestFS()
	cfg := config.ProjectConfig{
		Name: "MyApp",
	}

	jobs, err := ProjectLayout(cfg, testFS)
	if err != nil {
		t.Fatalf("ProjectLayout failed: %v", err)
	}

	// base has 45 files in list, minus 1 skipped (Scheme.xcconfig.tmpl) = 44
	// .gitkeep (non-tmpl) is skipped, xcodeproj/ dir is skipped entirely
	if len(jobs) != 44 {
		t.Errorf("base-only: got %d jobs, want 44", len(jobs))
		for _, j := range jobs {
			t.Logf("  %s -> %s (tmpl=%v)", j.TemplatePath, j.DestinationPath, j.IsTemplate)
		}
	}

	for _, j := range jobs {
		if j.Conditional {
			t.Errorf("base-only job should not be conditional: %s", j.TemplatePath)
		}
	}
}

func TestProjectLayoutBaseWithSwiftData(t *testing.T) {
	testFS := buildTestFS()
	cfg := config.ProjectConfig{
		Name:             "MyApp",
		IncludeSwiftData: true,
	}

	jobs, err := ProjectLayout(cfg, testFS)
	if err != nil {
		t.Fatalf("ProjectLayout failed: %v", err)
	}

	// 44 base + 3 swiftdata = 47
	if len(jobs) != 47 {
		t.Errorf("base+swiftdata: got %d jobs, want 47", len(jobs))
	}

	sdCount := 0
	for _, j := range jobs {
		if j.Condition == "SwiftData" {
			sdCount++
		}
	}
	if sdCount != 3 {
		t.Errorf("SwiftData conditional jobs: got %d, want 3", sdCount)
	}
}

func TestProjectLayoutBaseWithClaude(t *testing.T) {
	testFS := buildTestFS()
	cfg := config.ProjectConfig{
		Name:    "MyApp",
		AIPacks: []string{"ios-architecture"},
	}

	jobs, err := ProjectLayout(cfg, testFS)
	if err != nil {
		t.Fatalf("ProjectLayout failed: %v", err)
	}

	// 44 base + 14 claude = 58
	if len(jobs) != 58 {
		t.Errorf("base+claude: got %d jobs, want 58", len(jobs))
		for _, j := range jobs {
			if j.Condition == "AIPack:ios-architecture" {
				t.Logf("  claude: %s -> %s (tmpl=%v)", j.TemplatePath, j.DestinationPath, j.IsTemplate)
			}
		}
	}

	claudeCount := 0
	for _, j := range jobs {
		if j.Condition == "AIPack:ios-architecture" {
			claudeCount++
		}
	}
	if claudeCount != 14 {
		t.Errorf("Claude conditional jobs: got %d, want 14", claudeCount)
	}

	// Verify mix of template and non-template files
	tmplCount := 0
	copyCount := 0
	for _, j := range jobs {
		if j.Condition == "AIPack:ios-architecture" {
			if j.IsTemplate {
				tmplCount++
			} else {
				copyCount++
			}
		}
	}
	if tmplCount != 1 {
		t.Errorf("Claude .tmpl files: got %d, want 1", tmplCount)
	}
	if copyCount != 13 {
		t.Errorf("Claude .md files (copy): got %d, want 13", copyCount)
	}
}

func TestProjectLayoutAllOptions(t *testing.T) {
	testFS := buildTestFS()
	cfg := config.ProjectConfig{
		Name:             "MyApp",
		IncludeSwiftData: true,
		AIPacks:          []string{"ios-architecture"},
		// Note: IncludeExample is handled by the generator via FeatureForge,
		// not by ProjectLayout (it doesn't walk feature templates).
	}

	jobs, err := ProjectLayout(cfg, testFS)
	if err != nil {
		t.Fatalf("ProjectLayout failed: %v", err)
	}

	// 44 base + 3 swiftdata + 14 claude = 61
	if len(jobs) != 61 {
		t.Errorf("all options: got %d jobs, want 61", len(jobs))
	}
}

func TestProjectLayoutConditionalExcluded(t *testing.T) {
	testFS := buildTestFS()
	cfg := config.ProjectConfig{
		Name:             "MyApp",
		IncludeSwiftData: false,
	}

	jobs, err := ProjectLayout(cfg, testFS)
	if err != nil {
		t.Fatalf("ProjectLayout failed: %v", err)
	}

	for _, j := range jobs {
		if j.Condition == "SwiftData" || j.Condition == "AIPack:ios-architecture" {
			t.Errorf("conditional job should not be present when disabled: %s (condition=%s)", j.TemplatePath, j.Condition)
		}
	}
}

func TestProjectLayoutDestinationPaths(t *testing.T) {
	testFS := buildTestFS()
	cfg := config.ProjectConfig{
		Name: "MyApp",
	}

	jobs, err := ProjectLayout(cfg, testFS)
	if err != nil {
		t.Fatalf("ProjectLayout failed: %v", err)
	}

	destMap := make(map[string]string)
	for _, j := range jobs {
		destMap[j.TemplatePath] = j.DestinationPath
	}

	// Check key path mappings
	tests := []struct {
		tmpl string
		dest string
	}{
		{"base/.gitignore.tmpl", ".gitignore"},
		{"base/swiftlint.yml.tmpl", ".swiftlint.yml"},
		{"base/swiftformat.tmpl", ".swiftformat"},
		{"base/Info.plist.tmpl", "MyApp/Info.plist"},
		{"base/App/Config/AppEnvironment.swift.tmpl", "MyApp/App/Config/AppEnvironment.swift"},
		{"base/Core/Networking/APIClient.swift.tmpl", "MyApp/Core/Networking/APIClient.swift"},
		{"base/Domain/Common/DomainError.swift.tmpl", "MyApp/Domain/Common/DomainError.swift"},
	}

	for _, tt := range tests {
		t.Run(tt.tmpl, func(t *testing.T) {
			got, ok := destMap[tt.tmpl]
			if !ok {
				t.Fatalf("template %q not found in jobs", tt.tmpl)
			}
			if got != tt.dest {
				t.Errorf("dest for %q = %q, want %q", tt.tmpl, got, tt.dest)
			}
		})
	}
}

func TestMapToProjectPath(t *testing.T) {
	tests := []struct {
		relPath     string
		projectName string
		want        string
	}{
		{".gitignore", "MyApp", ".gitignore"},
		{"swiftlint.yml", "MyApp", ".swiftlint.yml"},
		{"swiftformat", "MyApp", ".swiftformat"},
		{"Info.plist", "MyApp", "MyApp/Info.plist"},
		{"App/Config/AppEnvironment.swift", "MyApp", "MyApp/App/Config/AppEnvironment.swift"},
		{"Core/Networking/APIClient.swift", "MyApp", "MyApp/Core/Networking/APIClient.swift"},
		{"Domain/Common/DomainError.swift", "MyApp", "MyApp/Domain/Common/DomainError.swift"},
		// Claude paths (empty projectName passed for claude)
		{"CLAUDE.md", "", "CLAUDE.md"},
		{"docs/ARCHITECTURE.md", "", ".claude/docs/ARCHITECTURE.md"},
		// AI Pack output paths
		{"commands/review.md", "", ".claude/commands/review.md"},
		{"workflows/ci.yml", "", ".github/workflows/ci.yml"},
		{"dev/arch-index.md", "", ".dev/arch-index.md"},
		{"plan/INDEX.md", "", "plan/INDEX.md"},
		{"skills/my-skill/prompt.md", "", ".claude/skills/my-skill/prompt.md"},
		{"settings-merge.json", "", ""},
	}

	for _, tt := range tests {
		t.Run(tt.relPath, func(t *testing.T) {
			got := mapToProjectPath(tt.relPath, tt.projectName)
			if got != tt.want {
				t.Errorf("mapToProjectPath(%q, %q) = %q, want %q", tt.relPath, tt.projectName, got, tt.want)
			}
		})
	}
}
