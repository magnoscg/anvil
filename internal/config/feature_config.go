package config

// FeatureConfig holds the configuration for forging a new feature
// within an existing Anvil-generated project.
type FeatureConfig struct {
	// FeatureName is the feature name in PascalCase (e.g. "PokemonList").
	FeatureName string

	// FeatureNameLower is the feature name in camelCase (e.g. "pokemonList").
	FeatureNameLower string

	// ProjectRoot is the absolute path to the project root directory.
	ProjectRoot string

	// ProjectName is the name of the project read from .anvil.yml.
	ProjectName string

	// IncludeLocalDataSource enables a UserDefaults-based local data source.
	IncludeLocalDataSource bool

	// IncludeKeychain enables Keychain storage helpers for the feature.
	IncludeKeychain bool

	// IncludeRouteResolver enables a RouteResolver file for subroute resolution.
	IncludeRouteResolver bool

	// IncludeUITests enables UI test templates (AccessibilityID, Stubs, ScreenTests).
	IncludeUITests bool
}
