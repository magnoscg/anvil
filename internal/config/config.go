// Package config defines all data models and configuration types for AnvilCLI.
package config

import "strings"

// ProjectMode determines the generation path: full project or tools-only.
type ProjectMode string

const (
	// ModeProject generates a full iOS project with all forging.
	ModeProject ProjectMode = "project"

	// ModeTools installs only AI coding tools (packs) in the current directory.
	ModeTools ProjectMode = "tools"
)

// ProjectConfig holds the full configuration for a new iOS project forge.
type ProjectConfig struct {
	// Name is the project name (PascalCase, e.g. "MyApp").
	Name string

	// BundleID is the iOS bundle identifier (e.g. "com.company.MyApp").
	BundleID string

	// Organization is the organization name derived from the BundleID.
	Organization string

	// IOSVersion is the minimum iOS deployment target (e.g. "18.0").
	IOSVersion string

	// SwiftVersion is the Swift language version (e.g. "6.0").
	SwiftVersion string

	// Schemes lists the build scheme names (e.g. ["Dev", "Stg", "Production"]).
	Schemes []string

	// OutputDir is the directory where the project will be created.
	OutputDir string

	// IncludeSwiftData enables the SwiftData persistence stack.
	IncludeSwiftData bool

	// AIPacks holds the slugs of AI coding packs selected by the user.
	AIPacks []string

	// SkillsScope controls where skills are installed: "project" (.claude/skills/)
	// or "global" (~/.claude/skills/).
	SkillsScope string

	// IncludeExample enables the example feature demonstrating all layers.
	IncludeExample bool

	// Mode selects the generation path: ModeProject (full forge) or ModeTools (packs only).
	Mode ProjectMode
}

// IsToolsMode reports whether the config targets tools-only installation.
func (c *ProjectConfig) IsToolsMode() bool {
	return c.Mode == ModeTools
}

// HasPack reports whether the given pack slug is present in AIPacks.
func (c *ProjectConfig) HasPack(slug string) bool {
	for _, s := range c.AIPacks {
		if s == slug {
			return true
		}
	}
	return false
}

// HasAnyPacks reports whether any AI packs are selected.
func (c *ProjectConfig) HasAnyPacks() bool {
	return len(c.AIPacks) > 0
}

// Normalize ensures version strings have a minor component (e.g. "17" → "17.0").
// Xcode requires deployment targets in X.Y format.
func (c *ProjectConfig) Normalize() {
	if c.IOSVersion != "" && !strings.Contains(c.IOSVersion, ".") {
		c.IOSVersion += ".0"
	}
	if c.SwiftVersion != "" && !strings.Contains(c.SwiftVersion, ".") {
		c.SwiftVersion += ".0"
	}
}
