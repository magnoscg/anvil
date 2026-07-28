package generator

import (
	"strings"

	"github.com/magnoscg/anvil/internal/config"
)

// ProjectTemplateContext holds ALL variables available to project templates.
// This struct is passed as the context to Go text/template when rendering
// project-level templates via `anvil init`.
type ProjectTemplateContext struct {
	// ProjectName is the PascalCase project name (e.g. "MyApp").
	ProjectName string

	// ProjectNameLower is the lowercase project name (e.g. "myapp").
	ProjectNameLower string

	// BundleID is the full iOS bundle identifier (e.g. "com.company.MyApp").
	BundleID string

	// Organization is the organization component from the bundle ID (e.g. "company").
	Organization string

	// IOSVersion is the minimum iOS deployment target (e.g. "18.0").
	IOSVersion string

	// SwiftVersion is the Swift language version (e.g. "6.0").
	SwiftVersion string

	// Schemes lists the build scheme names (e.g. ["Dev", "Stg", "Production"]).
	Schemes []string

	// IncludeSwiftData enables the SwiftData persistence stack in templates.
	IncludeSwiftData bool

	// AIPacks holds the slugs of AI coding packs selected by the user.
	AIPacks []string

	// SkillsScope controls where skills are installed: "project" or "global".
	SkillsScope string

	// IncludeExample enables the example feature in templates.
	IncludeExample bool

	// IsToolsMode is true when generating tools-only (no project forge).
	IsToolsMode bool
}

// FeatureTemplateContext holds ALL variables available to feature templates.
// This struct is passed as the context to Go text/template when rendering
// feature-level templates via `anvil feature`.
type FeatureTemplateContext struct {
	// FeatureName is the PascalCase feature name (e.g. "PokemonList").
	FeatureName string

	// FeatureNameLower is the camelCase feature name (e.g. "pokemonList").
	FeatureNameLower string

	// FeatureNameSnake is the snake_case feature name (e.g. "pokemon_list").
	FeatureNameSnake string

	// ProjectName is the PascalCase project name (e.g. "MyApp").
	ProjectName string

	// IncludeLocalDataSource enables a UserDefaults-based local data source.
	IncludeLocalDataSource bool

	// IncludeKeychain enables Keychain storage helpers.
	IncludeKeychain bool

	// IncludeRouteResolver enables a RouteResolver file for subroute resolution.
	IncludeRouteResolver bool

	// IncludeUITests enables UI test templates (AccessibilityID, Stubs, ScreenTests).
	IncludeUITests bool
}

// NewProjectContext creates a ProjectTemplateContext from a ProjectConfig.
func NewProjectContext(cfg config.ProjectConfig) ProjectTemplateContext {
	return ProjectTemplateContext{
		ProjectName:      cfg.Name,
		ProjectNameLower: strings.ToLower(cfg.Name),
		BundleID:         cfg.BundleID,
		Organization:     cfg.Organization,
		IOSVersion:       cfg.IOSVersion,
		SwiftVersion:     cfg.SwiftVersion,
		Schemes:          cfg.Schemes,
		IncludeSwiftData: cfg.IncludeSwiftData,
		AIPacks:          cfg.AIPacks,
		SkillsScope:      cfg.SkillsScope,
		IncludeExample:   cfg.IncludeExample,
		IsToolsMode:      cfg.IsToolsMode(),
	}
}

// NewFeatureContext creates a FeatureTemplateContext from a FeatureConfig.
func NewFeatureContext(cfg config.FeatureConfig) FeatureTemplateContext {
	return FeatureTemplateContext{
		FeatureName:            cfg.FeatureName,
		FeatureNameLower:       config.ToCamelCase(cfg.FeatureName),
		FeatureNameSnake:       config.ToSnakeCase(cfg.FeatureName),
		ProjectName:            cfg.ProjectName,
		IncludeLocalDataSource: cfg.IncludeLocalDataSource,
		IncludeKeychain:        cfg.IncludeKeychain,
		IncludeRouteResolver:   cfg.IncludeRouteResolver,
		IncludeUITests:         cfg.IncludeUITests,
	}
}
