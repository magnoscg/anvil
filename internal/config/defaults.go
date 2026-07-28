package config

import "strings"

const (
	// DefaultIOSVersion is the default minimum iOS deployment target.
	DefaultIOSVersion = "18.0"

	// DefaultSwiftVersion is the default Swift language version.
	DefaultSwiftVersion = "6.0"
)

// DefaultSchemes returns the default build scheme names.
func DefaultSchemes() []string {
	return []string{"Dev", "Stg", "Production"}
}

// OrganizationFromBundleID extracts the organization component from a bundle ID.
// For "com.company.MyApp" it returns "company".
// If the bundle ID has fewer than 3 parts, it returns the first part.
func OrganizationFromBundleID(bundleID string) string {
	parts := strings.Split(bundleID, ".")
	if len(parts) >= 3 {
		return parts[1]
	}
	if len(parts) > 0 {
		return parts[0]
	}
	return ""
}

// NewProjectConfigWithDefaults creates a ProjectConfig with sensible defaults.
// Only the project Name is required; all other fields receive default values.
func NewProjectConfigWithDefaults(name string) ProjectConfig {
	bundleID := "com." + strings.ToLower(name) + "." + name
	return ProjectConfig{
		Name:             name,
		BundleID:         bundleID,
		Organization:     OrganizationFromBundleID(bundleID),
		IOSVersion:       DefaultIOSVersion,
		SwiftVersion:     DefaultSwiftVersion,
		Schemes:          DefaultSchemes(),
		OutputDir:        ".",
		IncludeSwiftData: false,
		AIPacks:          nil,
		SkillsScope:      "project",
		IncludeExample:   false,
	}
}
