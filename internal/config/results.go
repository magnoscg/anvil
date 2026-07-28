package config

import "time"

// GenerationResult holds the outcome of a full project generation via `anvil init`.
type GenerationResult struct {
	// ProjectDir is the absolute path to the generated project directory.
	ProjectDir string

	// FilesCreated lists relative paths of all files created during generation.
	FilesCreated []string

	// XcodeProjectOutput captures the summary from native .xcodeproj generation.
	XcodeProjectOutput string

	// GitOutput captures stdout/stderr from git initialization.
	GitOutput string

	// Duration is how long the entire generation took.
	Duration time.Duration
}

// ForgeResult holds the outcome of a feature forge via `anvil feature`.
type ForgeResult struct {
	// FeatureDir is the relative path to the feature's root directory.
	FeatureDir string

	// FilesCreated lists relative paths of all files created during forging.
	FilesCreated []string

	// WiringInstructions lists human-readable steps the developer must follow
	// to integrate the new feature into the project's navigation and DI.
	WiringInstructions []string
}

// Dependency represents a single system dependency with its detection status.
type Dependency struct {
	// Name is the dependency identifier (e.g. "Xcode", "git").
	Name string

	// Required indicates whether this dependency must be present to proceed.
	Required bool

	// Installed indicates whether the dependency was detected on the system.
	Installed bool

	// Version is the detected version string, empty if not installed.
	Version string

	// InstallHint provides installation instructions shown when missing.
	InstallHint string
}

// DependencyReport aggregates the status of all system dependencies.
type DependencyReport struct {
	// Dependencies lists all checked dependencies and their status.
	Dependencies []Dependency
}

// Ready returns true when all required dependencies are installed.
func (r DependencyReport) Ready() bool {
	for _, d := range r.Dependencies {
		if d.Required && !d.Installed {
			return false
		}
	}
	return true
}
