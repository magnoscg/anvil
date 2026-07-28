package config

// OptionalFeature describes an optional capability that can be included
// during project or feature forging.
type OptionalFeature struct {
	// Name is the identifier for this optional feature.
	Name string

	// Description is a human-readable explanation shown in the TUI.
	Description string

	// Default indicates whether this feature is selected by default.
	Default bool
}

// AllOptionalFeatures returns every optional feature available during
// project forging via `anvil init`.
func AllOptionalFeatures() []OptionalFeature {
	return []OptionalFeature{
		{
			Name:        "SwiftData",
			Description: "SwiftData persistence stack (ModelContainer, SwiftDataStack, executor pattern)",
			Default:     false,
		},
		{
			Name:        "ExampleFeature",
			Description: "Example feature demonstrating all architecture layers",
			Default:     false,
		},
	}
}

// AllFeatureOptions returns optional capabilities available when forging
// a new feature via `anvil feature`.
func AllFeatureOptions() []OptionalFeature {
	return []OptionalFeature{
		{
			Name:        "LocalDataSource",
			Description: "UserDefaults-based local data source",
			Default:     false,
		},
		{
			Name:        "Keychain",
			Description: "Keychain storage helpers",
			Default:     false,
		},
		{
			Name:        "RouteResolver",
			Description: "RouteResolver for subroute resolution into views",
			Default:     false,
		},
	}
}
