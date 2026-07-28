package generator

import (
	"fmt"
	"strings"

	"github.com/magnoscg/anvil/internal/config"
)

// UUIDSet holds all named UUIDs required by the pbxproj template.
type UUIDSet struct {
	RootProject        string
	MainGroup          string
	ProductsGroup      string
	AppTarget          string
	TestTarget         string
	AppProduct         string
	TestProduct        string
	AppSourcesPhase    string
	AppResourcesPhase  string
	AppFrameworksPhase string
	TestSourcesPhase   string
	TestFrameworksPhase string
	BuildConfigListProject string
	BuildConfigListApp     string
	BuildConfigListTest    string
	AppFileRef         string
	TestFileRef        string
	AppGroup           string
	TestGroup          string
	AppExceptionSet    string
	TestResourcesPhase string
	DependencyProxy    string
	TargetDependency   string
	ContainerItemProxy string

	// Per-scheme config UUIDs: map[schemeName]uuid
	DebugConfigsProject  map[string]string
	ReleaseConfigsProject map[string]string
	DebugConfigsApp      map[string]string
	ReleaseConfigsApp    map[string]string
	DebugConfigsTest     map[string]string
	ReleaseConfigsTest   map[string]string

	// SwiftData (optional)
	SwiftDataFramework string
	SwiftDataBuildFile string
}

// BuildConfigEntry represents a single build configuration entry in the pbxproj.
type BuildConfigEntry struct {
	Name        string
	IsDebug     bool
	SchemeName  string
	XcconfigPath string
	UUID        string
}

// PbxprojContext holds all data needed to render the project.pbxproj template.
type PbxprojContext struct {
	ProjectName      string
	BundleID         string
	Organization     string
	IOSVersion       string
	SwiftVersion     string
	Schemes          []string
	IncludeSwiftData bool
	TestTargetName   string
	UUIDs            UUIDSet
	BuildConfigs     []BuildConfigEntry
}

// XcschemeContext holds data needed to render a single .xcscheme template.
type XcschemeContext struct {
	SchemeName        string
	ProjectName       string
	AppTargetName     string
	TestTargetName    string
	BundleID          string
	DebugConfigName   string
	ReleaseConfigName string
	AppTargetUUID     string
	TestTargetUUID    string
}

// WorkspaceContext holds data needed to render the contents.xcworkspacedata template.
type WorkspaceContext struct {
	ProjectName string
}

// NewPbxprojContext builds a PbxprojContext from a ProjectConfig, generating all
// required UUIDs deterministically based on the project name.
func NewPbxprojContext(cfg config.ProjectConfig) PbxprojContext {
	provider := FNV1aUUIDProvider{}
	reg := NewUUIDRegistry(provider, cfg.Name)

	uuids := generateUUIDSet(reg, cfg)
	buildConfigs := generateBuildConfigs(cfg, uuids)
	testTargetName := cfg.Name + "Tests"

	return PbxprojContext{
		ProjectName:      cfg.Name,
		BundleID:         cfg.BundleID,
		Organization:     cfg.Organization,
		IOSVersion:       cfg.IOSVersion,
		SwiftVersion:     cfg.SwiftVersion,
		Schemes:          cfg.Schemes,
		IncludeSwiftData: cfg.IncludeSwiftData,
		TestTargetName:   testTargetName,
		UUIDs:            uuids,
		BuildConfigs:     buildConfigs,
	}
}

// NewXcschemeContexts builds one XcschemeContext per scheme from the config and UUIDs.
func NewXcschemeContexts(cfg config.ProjectConfig, uuids UUIDSet) []XcschemeContext {
	testTargetName := cfg.Name + "Tests"
	contexts := make([]XcschemeContext, 0, len(cfg.Schemes))

	for _, scheme := range cfg.Schemes {
		fullSchemeName := cfg.Name + "-" + scheme
		ctx := XcschemeContext{
			SchemeName:        fullSchemeName,
			ProjectName:       cfg.Name,
			AppTargetName:     cfg.Name,
			TestTargetName:    testTargetName,
			BundleID:          cfg.BundleID,
			DebugConfigName:   debugConfigName(scheme),
			ReleaseConfigName: releaseConfigName(scheme),
			AppTargetUUID:     uuids.AppTarget,
			TestTargetUUID:    uuids.TestTarget,
		}
		contexts = append(contexts, ctx)
	}

	return contexts
}

// NewWorkspaceContext builds a WorkspaceContext from a ProjectConfig.
func NewWorkspaceContext(cfg config.ProjectConfig) WorkspaceContext {
	return WorkspaceContext{
		ProjectName: cfg.Name,
	}
}

// generateUUIDSet creates all static UUIDs for the project.
func generateUUIDSet(reg *UUIDRegistry, cfg config.ProjectConfig) UUIDSet {
	set := UUIDSet{
		RootProject:            reg.Generate("PBXProject"),
		MainGroup:              reg.Generate("MainGroup"),
		ProductsGroup:          reg.Generate("ProductsGroup"),
		AppTarget:              reg.Generate("AppTarget"),
		TestTarget:             reg.Generate("TestTarget"),
		AppProduct:             reg.Generate("AppProduct"),
		TestProduct:            reg.Generate("TestProduct"),
		AppSourcesPhase:        reg.Generate("AppSourcesPhase"),
		AppResourcesPhase:      reg.Generate("AppResourcesPhase"),
		AppFrameworksPhase:     reg.Generate("AppFrameworksPhase"),
		TestSourcesPhase:       reg.Generate("TestSourcesPhase"),
		TestFrameworksPhase:    reg.Generate("TestFrameworksPhase"),
		TestResourcesPhase:    reg.Generate("TestResourcesPhase"),
		AppExceptionSet:       reg.Generate("AppExceptionSet"),
		BuildConfigListProject: reg.Generate("BuildConfigListProject"),
		BuildConfigListApp:     reg.Generate("BuildConfigListApp"),
		BuildConfigListTest:    reg.Generate("BuildConfigListTest"),
		AppFileRef:             reg.Generate("AppFileRef"),
		TestFileRef:            reg.Generate("TestFileRef"),
		AppGroup:               reg.Generate("AppGroup"),
		TestGroup:              reg.Generate("TestGroup"),
		DependencyProxy:        reg.Generate("DependencyProxy"),
		TargetDependency:       reg.Generate("TargetDependency"),
		ContainerItemProxy:     reg.Generate("ContainerItemProxy"),

		DebugConfigsProject:  make(map[string]string, len(cfg.Schemes)),
		ReleaseConfigsProject: make(map[string]string, len(cfg.Schemes)),
		DebugConfigsApp:      make(map[string]string, len(cfg.Schemes)),
		ReleaseConfigsApp:    make(map[string]string, len(cfg.Schemes)),
		DebugConfigsTest:     make(map[string]string, len(cfg.Schemes)),
		ReleaseConfigsTest:   make(map[string]string, len(cfg.Schemes)),
	}

	for _, scheme := range cfg.Schemes {
		set.DebugConfigsProject[scheme] = reg.Generate(seedForConfig("ProjectConfig", scheme, true))
		set.ReleaseConfigsProject[scheme] = reg.Generate(seedForConfig("ProjectConfig", scheme, false))
		set.DebugConfigsApp[scheme] = reg.Generate(seedForConfig("AppConfig", scheme, true))
		set.ReleaseConfigsApp[scheme] = reg.Generate(seedForConfig("AppConfig", scheme, false))
		set.DebugConfigsTest[scheme] = reg.Generate(seedForConfig("TestConfig", scheme, true))
		set.ReleaseConfigsTest[scheme] = reg.Generate(seedForConfig("TestConfig", scheme, false))
	}

	if cfg.IncludeSwiftData {
		set.SwiftDataFramework = reg.Generate("SwiftDataFramework")
		set.SwiftDataBuildFile = reg.Generate("SwiftDataBuildFile")
	}

	return set
}

// generateBuildConfigs creates BuildConfigEntry slices for all schemes.
// Each scheme produces two entries: Debug and Release.
func generateBuildConfigs(cfg config.ProjectConfig, uuids UUIDSet) []BuildConfigEntry {
	entries := make([]BuildConfigEntry, 0, 2*len(cfg.Schemes))

	for _, scheme := range cfg.Schemes {
		debugName := debugConfigName(scheme)
		releaseName := releaseConfigName(scheme)
		xcconfigPath := fmt.Sprintf("%s/App/Config/Xcconfig/%s.xcconfig", cfg.Name, scheme)

		entries = append(entries, BuildConfigEntry{
			Name:         debugName,
			IsDebug:      true,
			SchemeName:   scheme,
			XcconfigPath: xcconfigPath,
			UUID:         uuids.DebugConfigsApp[scheme],
		})
		entries = append(entries, BuildConfigEntry{
			Name:         releaseName,
			IsDebug:      false,
			SchemeName:   scheme,
			XcconfigPath: xcconfigPath,
			UUID:         uuids.ReleaseConfigsApp[scheme],
		})
	}

	return entries
}

// debugConfigName returns the debug build configuration name for a scheme.
func debugConfigName(scheme string) string {
	return "Debug-" + strings.ToLower(scheme)
}

// releaseConfigName returns the release build configuration name for a scheme.
func releaseConfigName(scheme string) string {
	return "Release-" + strings.ToLower(scheme)
}
