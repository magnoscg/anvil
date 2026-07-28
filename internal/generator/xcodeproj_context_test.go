package generator

import (
	"testing"

	"github.com/oscarcanton/anvilcli/internal/config"
)

// MARK: - Helpers

func testProjectConfig() config.ProjectConfig {
	return config.ProjectConfig{
		Name:             "MyApp",
		BundleID:         "com.company.MyApp",
		Organization:     "company",
		IOSVersion:       "18.0",
		SwiftVersion:     "6.0",
		Schemes:          []string{"Dev", "Stg", "Production"},
		IncludeSwiftData: false,
	}
}

// MARK: - NewPbxprojContext Tests

func TestNewPbxprojContextPopulatesAllUUIDs(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)

	staticUUIDs := map[string]string{
		"RootProject":            ctx.UUIDs.RootProject,
		"MainGroup":              ctx.UUIDs.MainGroup,
		"ProductsGroup":          ctx.UUIDs.ProductsGroup,
		"AppTarget":              ctx.UUIDs.AppTarget,
		"TestTarget":             ctx.UUIDs.TestTarget,
		"AppProduct":             ctx.UUIDs.AppProduct,
		"TestProduct":            ctx.UUIDs.TestProduct,
		"AppSourcesPhase":        ctx.UUIDs.AppSourcesPhase,
		"AppResourcesPhase":      ctx.UUIDs.AppResourcesPhase,
		"AppFrameworksPhase":     ctx.UUIDs.AppFrameworksPhase,
		"TestSourcesPhase":       ctx.UUIDs.TestSourcesPhase,
		"TestFrameworksPhase":    ctx.UUIDs.TestFrameworksPhase,
		"BuildConfigListProject": ctx.UUIDs.BuildConfigListProject,
		"BuildConfigListApp":     ctx.UUIDs.BuildConfigListApp,
		"BuildConfigListTest":    ctx.UUIDs.BuildConfigListTest,
		"AppFileRef":             ctx.UUIDs.AppFileRef,
		"TestFileRef":            ctx.UUIDs.TestFileRef,
		"AppGroup":               ctx.UUIDs.AppGroup,
		"TestGroup":              ctx.UUIDs.TestGroup,
		"DependencyProxy":        ctx.UUIDs.DependencyProxy,
		"TargetDependency":       ctx.UUIDs.TargetDependency,
		"ContainerItemProxy":     ctx.UUIDs.ContainerItemProxy,
	}

	for name, uuid := range staticUUIDs {
		if uuid == "" {
			t.Errorf("UUID %q should not be empty", name)
			continue
		}
		if len(uuid) != 24 {
			t.Errorf("UUID %q should be 24 chars, got %d: %q", name, len(uuid), uuid)
		}
		if !isUpperHex(uuid) {
			t.Errorf("UUID %q should be uppercase hex, got %q", name, uuid)
		}
	}
}

func TestNewPbxprojContextPopulatesPerSchemeConfigUUIDs(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)

	for _, scheme := range cfg.Schemes {
		maps := map[string]map[string]string{
			"DebugConfigsProject":  ctx.UUIDs.DebugConfigsProject,
			"ReleaseConfigsProject": ctx.UUIDs.ReleaseConfigsProject,
			"DebugConfigsApp":      ctx.UUIDs.DebugConfigsApp,
			"ReleaseConfigsApp":    ctx.UUIDs.ReleaseConfigsApp,
			"DebugConfigsTest":     ctx.UUIDs.DebugConfigsTest,
			"ReleaseConfigsTest":   ctx.UUIDs.ReleaseConfigsTest,
		}

		for mapName, m := range maps {
			uuid, ok := m[scheme]
			if !ok || uuid == "" {
				t.Errorf("%s[%q] should be populated", mapName, scheme)
				continue
			}
			if len(uuid) != 24 || !isUpperHex(uuid) {
				t.Errorf("%s[%q] = %q, expected 24-char uppercase hex", mapName, scheme, uuid)
			}
		}
	}
}

func TestNewPbxprojContextUUIDsAreUnique(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)

	allUUIDs := make(map[string]string)
	collectUUID := func(name, uuid string) {
		if prev, exists := allUUIDs[uuid]; exists {
			t.Errorf("UUID collision: %q and %q both have UUID %q", prev, name, uuid)
		}
		allUUIDs[uuid] = name
	}

	collectUUID("RootProject", ctx.UUIDs.RootProject)
	collectUUID("MainGroup", ctx.UUIDs.MainGroup)
	collectUUID("ProductsGroup", ctx.UUIDs.ProductsGroup)
	collectUUID("AppTarget", ctx.UUIDs.AppTarget)
	collectUUID("TestTarget", ctx.UUIDs.TestTarget)
	collectUUID("AppProduct", ctx.UUIDs.AppProduct)
	collectUUID("TestProduct", ctx.UUIDs.TestProduct)
	collectUUID("AppSourcesPhase", ctx.UUIDs.AppSourcesPhase)
	collectUUID("AppResourcesPhase", ctx.UUIDs.AppResourcesPhase)
	collectUUID("AppFrameworksPhase", ctx.UUIDs.AppFrameworksPhase)
	collectUUID("TestSourcesPhase", ctx.UUIDs.TestSourcesPhase)
	collectUUID("TestFrameworksPhase", ctx.UUIDs.TestFrameworksPhase)

	for scheme, uuid := range ctx.UUIDs.DebugConfigsProject {
		collectUUID("DebugConfigsProject:"+scheme, uuid)
	}
	for scheme, uuid := range ctx.UUIDs.ReleaseConfigsProject {
		collectUUID("ReleaseConfigsProject:"+scheme, uuid)
	}
	for scheme, uuid := range ctx.UUIDs.DebugConfigsApp {
		collectUUID("DebugConfigsApp:"+scheme, uuid)
	}
	for scheme, uuid := range ctx.UUIDs.ReleaseConfigsApp {
		collectUUID("ReleaseConfigsApp:"+scheme, uuid)
	}
	for scheme, uuid := range ctx.UUIDs.DebugConfigsTest {
		collectUUID("DebugConfigsTest:"+scheme, uuid)
	}
	for scheme, uuid := range ctx.UUIDs.ReleaseConfigsTest {
		collectUUID("ReleaseConfigsTest:"+scheme, uuid)
	}
}

func TestNewPbxprojContextDeterminism(t *testing.T) {
	cfg := testProjectConfig()
	ctx1 := NewPbxprojContext(cfg)
	ctx2 := NewPbxprojContext(cfg)

	if ctx1.UUIDs.RootProject != ctx2.UUIDs.RootProject {
		t.Errorf("RootProject UUID should be deterministic: %q != %q", ctx1.UUIDs.RootProject, ctx2.UUIDs.RootProject)
	}
	if ctx1.UUIDs.AppTarget != ctx2.UUIDs.AppTarget {
		t.Errorf("AppTarget UUID should be deterministic: %q != %q", ctx1.UUIDs.AppTarget, ctx2.UUIDs.AppTarget)
	}
}

func TestNewPbxprojContextFieldValues(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)

	if ctx.ProjectName != "MyApp" {
		t.Errorf("ProjectName = %q, want 'MyApp'", ctx.ProjectName)
	}
	if ctx.BundleID != "com.company.MyApp" {
		t.Errorf("BundleID = %q, want 'com.company.MyApp'", ctx.BundleID)
	}
	if ctx.Organization != "company" {
		t.Errorf("Organization = %q, want 'company'", ctx.Organization)
	}
	if ctx.TestTargetName != "MyAppTests" {
		t.Errorf("TestTargetName = %q, want 'MyAppTests'", ctx.TestTargetName)
	}
}

func TestNewPbxprojContextSwiftDataUUIDs(t *testing.T) {
	cfg := testProjectConfig()
	cfg.IncludeSwiftData = true
	ctx := NewPbxprojContext(cfg)

	if ctx.UUIDs.SwiftDataFramework == "" {
		t.Error("SwiftDataFramework UUID should be populated when IncludeSwiftData=true")
	}
	if ctx.UUIDs.SwiftDataBuildFile == "" {
		t.Error("SwiftDataBuildFile UUID should be populated when IncludeSwiftData=true")
	}
	if len(ctx.UUIDs.SwiftDataFramework) != 24 || !isUpperHex(ctx.UUIDs.SwiftDataFramework) {
		t.Errorf("SwiftDataFramework UUID invalid: %q", ctx.UUIDs.SwiftDataFramework)
	}
}

func TestNewPbxprojContextNoSwiftDataUUIDs(t *testing.T) {
	cfg := testProjectConfig()
	cfg.IncludeSwiftData = false
	ctx := NewPbxprojContext(cfg)

	if ctx.UUIDs.SwiftDataFramework != "" {
		t.Errorf("SwiftDataFramework UUID should be empty when IncludeSwiftData=false, got %q", ctx.UUIDs.SwiftDataFramework)
	}
	if ctx.UUIDs.SwiftDataBuildFile != "" {
		t.Errorf("SwiftDataBuildFile UUID should be empty when IncludeSwiftData=false, got %q", ctx.UUIDs.SwiftDataBuildFile)
	}
}

// MARK: - NewXcschemeContexts Tests

func TestNewXcschemeContextsCreatesOnePerScheme(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)
	schemes := NewXcschemeContexts(cfg, ctx.UUIDs)

	if len(schemes) != len(cfg.Schemes) {
		t.Fatalf("expected %d scheme contexts, got %d", len(cfg.Schemes), len(schemes))
	}

	for i, scheme := range cfg.Schemes {
		sc := schemes[i]
		expectedName := cfg.Name + "-" + scheme
		if sc.SchemeName != expectedName {
			t.Errorf("scheme[%d].SchemeName = %q, want %q", i, sc.SchemeName, expectedName)
		}
		if sc.ProjectName != cfg.Name {
			t.Errorf("scheme[%d].ProjectName = %q, want %q", i, sc.ProjectName, cfg.Name)
		}
		if sc.AppTargetName != cfg.Name {
			t.Errorf("scheme[%d].AppTargetName = %q, want %q", i, sc.AppTargetName, cfg.Name)
		}
		if sc.TestTargetName != cfg.Name+"Tests" {
			t.Errorf("scheme[%d].TestTargetName = %q, want %q", i, sc.TestTargetName, cfg.Name+"Tests")
		}
		if sc.AppTargetUUID != ctx.UUIDs.AppTarget {
			t.Errorf("scheme[%d].AppTargetUUID mismatch", i)
		}
		if sc.TestTargetUUID != ctx.UUIDs.TestTarget {
			t.Errorf("scheme[%d].TestTargetUUID mismatch", i)
		}
	}
}

func TestNewXcschemeContextsConfigNames(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)
	schemes := NewXcschemeContexts(cfg, ctx.UUIDs)

	expected := map[string][2]string{
		"Dev":        {"Debug-dev", "Release-dev"},
		"Stg":        {"Debug-stg", "Release-stg"},
		"Production": {"Debug-production", "Release-production"},
	}

	for i, scheme := range cfg.Schemes {
		sc := schemes[i]
		exp := expected[scheme]
		if sc.DebugConfigName != exp[0] {
			t.Errorf("scheme %q: DebugConfigName = %q, want %q", scheme, sc.DebugConfigName, exp[0])
		}
		if sc.ReleaseConfigName != exp[1] {
			t.Errorf("scheme %q: ReleaseConfigName = %q, want %q", scheme, sc.ReleaseConfigName, exp[1])
		}
	}
}

// MARK: - NewWorkspaceContext Tests

func TestNewWorkspaceContextPopulatesProjectName(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewWorkspaceContext(cfg)

	if ctx.ProjectName != "MyApp" {
		t.Errorf("ProjectName = %q, want 'MyApp'", ctx.ProjectName)
	}
}

// MARK: - BuildConfigEntry Tests

func TestBuildConfigEntriesCount(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)

	expectedCount := 2 * len(cfg.Schemes)
	if len(ctx.BuildConfigs) != expectedCount {
		t.Errorf("expected %d build config entries, got %d", expectedCount, len(ctx.BuildConfigs))
	}
}

func TestBuildConfigEntriesDebugReleaseAlternate(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)

	for i := 0; i < len(ctx.BuildConfigs); i += 2 {
		debug := ctx.BuildConfigs[i]
		release := ctx.BuildConfigs[i+1]

		if !debug.IsDebug {
			t.Errorf("entry %d should be debug, got release", i)
		}
		if release.IsDebug {
			t.Errorf("entry %d should be release, got debug", i+1)
		}
		if debug.SchemeName != release.SchemeName {
			t.Errorf("entries %d/%d should have same scheme: %q != %q", i, i+1, debug.SchemeName, release.SchemeName)
		}
	}
}

func TestBuildConfigEntriesHaveUUIDs(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)

	for i, entry := range ctx.BuildConfigs {
		if entry.UUID == "" {
			t.Errorf("BuildConfig[%d] (%s) should have a UUID", i, entry.Name)
		}
		if len(entry.UUID) != 24 || !isUpperHex(entry.UUID) {
			t.Errorf("BuildConfig[%d] UUID invalid: %q", i, entry.UUID)
		}
	}
}

func TestBuildConfigEntriesXcconfigPath(t *testing.T) {
	cfg := testProjectConfig()
	ctx := NewPbxprojContext(cfg)

	for i, entry := range ctx.BuildConfigs {
		expectedPath := "MyApp/App/Config/Xcconfig/" + entry.SchemeName + ".xcconfig"
		if entry.XcconfigPath != expectedPath {
			t.Errorf("BuildConfig[%d] XcconfigPath = %q, want %q", i, entry.XcconfigPath, expectedPath)
		}
	}
}
