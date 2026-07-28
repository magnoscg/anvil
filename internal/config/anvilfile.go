package config

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"gopkg.in/yaml.v3"
)

const anvilFileName = ".anvil.yml"

// AnvilMarker represents the metadata stored in .anvil.yml at the project root.
// It is written by `anvil init` and read by `anvil feature` to detect the project.
type AnvilMarker struct {
	// Version is the AnvilCLI version that generated this project.
	Version string `yaml:"version"`

	// ProjectName is the name of the iOS project.
	ProjectName string `yaml:"project_name"`

	// BundleID is the iOS bundle identifier.
	BundleID string `yaml:"bundle_id"`

	// IOSVersion is the minimum iOS deployment target.
	IOSVersion string `yaml:"ios_version"`

	// SwiftVersion is the Swift language version.
	SwiftVersion string `yaml:"swift_version"`

	// Schemes lists the build scheme names.
	Schemes []string `yaml:"schemes"`

	// AIPacks holds the slugs of AI coding packs installed in this project.
	AIPacks []string `yaml:"ai_packs,omitempty"`

	// SkillsScope indicates where skills were installed: "project" or "global".
	SkillsScope string `yaml:"skills_scope,omitempty"`

	// IncludeClaude is a legacy field for backward compatibility with projects
	// generated before the AI packs system. It is only used during reading;
	// new markers never write this field.
	IncludeClaude bool `yaml:"include_claude,omitempty"`

	// CreatedAt is the timestamp when the project was generated.
	CreatedAt time.Time `yaml:"created_at"`
}

// MigrateMarker converts legacy IncludeClaude=true markers to the new AIPacks
// format. If IncludeClaude is true and AIPacks is empty, it sets
// AIPacks to ["ios-architecture"] and clears IncludeClaude.
func (m *AnvilMarker) MigrateMarker() {
	if m.IncludeClaude && len(m.AIPacks) == 0 {
		m.AIPacks = []string{"ios-architecture"}
		m.IncludeClaude = false
	}
}

// MarkerReadWriter defines operations for reading and writing .anvil.yml files,
// and locating the project root by walking up directories.
type MarkerReadWriter interface {
	Read(dir string) (AnvilMarker, error)
	Write(dir string, marker AnvilMarker) error
	FindProjectRoot(startDir string) (string, error)
}

// FileMarkerReadWriter is the default file-system implementation of MarkerReadWriter.
type FileMarkerReadWriter struct{}

// Read parses the .anvil.yml file in the given directory and returns an AnvilMarker.
func (f FileMarkerReadWriter) Read(dir string) (AnvilMarker, error) {
	path := filepath.Join(dir, anvilFileName)
	data, err := os.ReadFile(path)
	if err != nil {
		return AnvilMarker{}, fmt.Errorf("reading %s: %w", anvilFileName, err)
	}
	var marker AnvilMarker
	if err := yaml.Unmarshal(data, &marker); err != nil {
		return AnvilMarker{}, fmt.Errorf("parsing %s: %w", anvilFileName, err)
	}
	marker.MigrateMarker()
	return marker, nil
}

// Write serializes an AnvilMarker to .anvil.yml in the given directory.
func (f FileMarkerReadWriter) Write(dir string, marker AnvilMarker) error {
	data, err := yaml.Marshal(&marker)
	if err != nil {
		return fmt.Errorf("marshaling %s: %w", anvilFileName, err)
	}
	path := filepath.Join(dir, anvilFileName)
	if err := os.WriteFile(path, data, 0644); err != nil {
		return fmt.Errorf("writing %s: %w", anvilFileName, err)
	}
	return nil
}

// FindProjectRoot walks up directories starting from startDir looking for
// .anvil.yml. Returns the directory containing the marker, or a
// NoAnvilProjectError if the filesystem root is reached without finding one.
func (f FileMarkerReadWriter) FindProjectRoot(startDir string) (string, error) {
	dir, err := filepath.Abs(startDir)
	if err != nil {
		return "", fmt.Errorf("resolving absolute path: %w", err)
	}
	for {
		candidate := filepath.Join(dir, anvilFileName)
		if _, err := os.Stat(candidate); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", NoAnvilProjectError{StartDir: startDir}
		}
		dir = parent
	}
}
