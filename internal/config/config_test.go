package config

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// -- Defaults tests --

func TestNewProjectConfigWithDefaults(t *testing.T) {
	cfg := NewProjectConfigWithDefaults("MyApp")

	if cfg.Name != "MyApp" {
		t.Errorf("Name = %q, want %q", cfg.Name, "MyApp")
	}
	if cfg.BundleID != "com.myapp.MyApp" {
		t.Errorf("BundleID = %q, want %q", cfg.BundleID, "com.myapp.MyApp")
	}
	if cfg.Organization != "myapp" {
		t.Errorf("Organization = %q, want %q", cfg.Organization, "myapp")
	}
	if cfg.IOSVersion != DefaultIOSVersion {
		t.Errorf("IOSVersion = %q, want %q", cfg.IOSVersion, DefaultIOSVersion)
	}
	if cfg.SwiftVersion != DefaultSwiftVersion {
		t.Errorf("SwiftVersion = %q, want %q", cfg.SwiftVersion, DefaultSwiftVersion)
	}
	if len(cfg.Schemes) != 3 {
		t.Fatalf("Schemes length = %d, want 3", len(cfg.Schemes))
	}
	expected := []string{"Dev", "Stg", "Production"}
	for i, s := range cfg.Schemes {
		if s != expected[i] {
			t.Errorf("Schemes[%d] = %q, want %q", i, s, expected[i])
		}
	}
	if cfg.OutputDir != "." {
		t.Errorf("OutputDir = %q, want %q", cfg.OutputDir, ".")
	}
	if cfg.IncludeSwiftData {
		t.Error("IncludeSwiftData should default to false")
	}
	if cfg.AIPacks != nil {
		t.Errorf("AIPacks should default to nil, got %v", cfg.AIPacks)
	}
	if cfg.SkillsScope != "project" {
		t.Errorf("SkillsScope should default to %q, got %q", "project", cfg.SkillsScope)
	}
	if cfg.IncludeExample {
		t.Error("IncludeExample should default to false")
	}
}

func TestOrganizationFromBundleID(t *testing.T) {
	tests := []struct {
		bundleID string
		want     string
	}{
		{"com.company.MyApp", "company"},
		{"com.magnos.Arquitectura", "magnos"},
		{"io.github.user.Project", "github"},
		{"com.MyApp", "com"},
		{"singlepart", "singlepart"},
		{"", ""},
	}
	for _, tt := range tests {
		t.Run(tt.bundleID, func(t *testing.T) {
			got := OrganizationFromBundleID(tt.bundleID)
			if got != tt.want {
				t.Errorf("OrganizationFromBundleID(%q) = %q, want %q", tt.bundleID, got, tt.want)
			}
		})
	}
}

// -- AnvilMarker round-trip tests --

func TestAnvilMarkerRoundTrip(t *testing.T) {
	dir := t.TempDir()
	rw := FileMarkerReadWriter{}

	original := AnvilMarker{
		Version:      "1.0.0",
		ProjectName:  "TestProject",
		BundleID:     "com.test.TestProject",
		IOSVersion:   "18.0",
		SwiftVersion: "6.0",
		Schemes:      []string{"Dev", "Production"},
		CreatedAt:    time.Date(2026, 3, 13, 12, 0, 0, 0, time.UTC),
	}

	if err := rw.Write(dir, original); err != nil {
		t.Fatalf("Write failed: %v", err)
	}

	read, err := rw.Read(dir)
	if err != nil {
		t.Fatalf("Read failed: %v", err)
	}

	if read.Version != original.Version {
		t.Errorf("Version = %q, want %q", read.Version, original.Version)
	}
	if read.ProjectName != original.ProjectName {
		t.Errorf("ProjectName = %q, want %q", read.ProjectName, original.ProjectName)
	}
	if read.BundleID != original.BundleID {
		t.Errorf("BundleID = %q, want %q", read.BundleID, original.BundleID)
	}
	if read.IOSVersion != original.IOSVersion {
		t.Errorf("IOSVersion = %q, want %q", read.IOSVersion, original.IOSVersion)
	}
	if read.SwiftVersion != original.SwiftVersion {
		t.Errorf("SwiftVersion = %q, want %q", read.SwiftVersion, original.SwiftVersion)
	}
	if len(read.Schemes) != len(original.Schemes) {
		t.Fatalf("Schemes length = %d, want %d", len(read.Schemes), len(original.Schemes))
	}
	for i, s := range read.Schemes {
		if s != original.Schemes[i] {
			t.Errorf("Schemes[%d] = %q, want %q", i, s, original.Schemes[i])
		}
	}
	if !read.CreatedAt.Equal(original.CreatedAt) {
		t.Errorf("CreatedAt = %v, want %v", read.CreatedAt, original.CreatedAt)
	}
}

func TestAnvilMarkerReadNonExistent(t *testing.T) {
	rw := FileMarkerReadWriter{}
	_, err := rw.Read(t.TempDir())
	if err == nil {
		t.Error("expected error when reading non-existent .anvil.yml")
	}
}

// -- FindProjectRoot tests --

func TestFindProjectRoot(t *testing.T) {
	// Create structure: root/.anvil.yml, root/sub/deep/
	root := t.TempDir()
	rw := FileMarkerReadWriter{}

	marker := AnvilMarker{Version: "1.0.0", ProjectName: "TestRoot"}
	if err := rw.Write(root, marker); err != nil {
		t.Fatalf("Write failed: %v", err)
	}

	deep := filepath.Join(root, "sub", "deep")
	if err := os.MkdirAll(deep, 0755); err != nil {
		t.Fatalf("MkdirAll failed: %v", err)
	}

	found, err := rw.FindProjectRoot(deep)
	if err != nil {
		t.Fatalf("FindProjectRoot failed: %v", err)
	}
	if found != root {
		t.Errorf("FindProjectRoot = %q, want %q", found, root)
	}
}

func TestFindProjectRootFromRoot(t *testing.T) {
	root := t.TempDir()
	rw := FileMarkerReadWriter{}

	marker := AnvilMarker{Version: "1.0.0", ProjectName: "DirectRoot"}
	if err := rw.Write(root, marker); err != nil {
		t.Fatalf("Write failed: %v", err)
	}

	found, err := rw.FindProjectRoot(root)
	if err != nil {
		t.Fatalf("FindProjectRoot failed: %v", err)
	}
	if found != root {
		t.Errorf("FindProjectRoot = %q, want %q", found, root)
	}
}

func TestFindProjectRootNotFound(t *testing.T) {
	rw := FileMarkerReadWriter{}
	_, err := rw.FindProjectRoot(t.TempDir())
	if err == nil {
		t.Error("expected NoAnvilProjectError when no .anvil.yml exists")
	}
	var target NoAnvilProjectError
	if !errors.As(err, &target) {
		t.Errorf("expected NoAnvilProjectError, got %T: %v", err, err)
	}
}

// -- MigrateMarker tests --

func TestMigrateMarkerLegacyClaude(t *testing.T) {
	marker := AnvilMarker{
		Version:       "1.0.0",
		ProjectName:   "LegacyProject",
		IncludeClaude: true,
	}
	marker.MigrateMarker()

	if marker.IncludeClaude {
		t.Error("IncludeClaude should be false after migration")
	}
	if len(marker.AIPacks) != 1 || marker.AIPacks[0] != "ios-architecture" {
		t.Errorf("AIPacks should be [\"ios-architecture\"] after migration, got %v", marker.AIPacks)
	}
}

func TestMigrateMarkerAlreadyMigrated(t *testing.T) {
	marker := AnvilMarker{
		Version: "1.0.0",
		AIPacks: []string{"gitflow"},
	}
	marker.MigrateMarker()

	if len(marker.AIPacks) != 1 || marker.AIPacks[0] != "gitflow" {
		t.Errorf("AIPacks should remain unchanged, got %v", marker.AIPacks)
	}
}

func TestMigrateMarkerNoLegacy(t *testing.T) {
	marker := AnvilMarker{
		Version: "1.0.0",
	}
	marker.MigrateMarker()

	if marker.AIPacks != nil {
		t.Errorf("AIPacks should remain nil, got %v", marker.AIPacks)
	}
}

// -- DependencyReport tests --

func TestDependencyReportReady(t *testing.T) {
	report := DependencyReport{
		Dependencies: []Dependency{
			{Name: "Xcode", Required: true, Installed: true},
			{Name: "git", Required: true, Installed: true},
			{Name: "swiftlint", Required: false, Installed: false},
		},
	}
	if !report.Ready() {
		t.Error("Ready() should return true when all required deps are installed")
	}
}

func TestDependencyReportNotReady(t *testing.T) {
	report := DependencyReport{
		Dependencies: []Dependency{
			{Name: "Xcode", Required: true, Installed: true},
			{Name: "git", Required: true, Installed: false},
		},
	}
	if report.Ready() {
		t.Error("Ready() should return false when a required dep is missing")
	}
}

func TestDependencyReportEmpty(t *testing.T) {
	report := DependencyReport{}
	if !report.Ready() {
		t.Error("Ready() should return true for empty dependency list")
	}
}

// -- Error message tests --

func TestErrorMessages(t *testing.T) {
	tests := []struct {
		name string
		err  error
		want string
	}{
		{
			name: "MissingDependencyError with hint",
			err:  MissingDependencyError{Name: "Xcode", InstallHint: "xcode-select --install"},
			want: `required dependency "Xcode" is not installed; install with: xcode-select --install`,
		},
		{
			name: "MissingDependencyError without hint",
			err:  MissingDependencyError{Name: "git"},
			want: `required dependency "git" is not installed`,
		},
		{
			name: "NoAnvilProjectError",
			err:  NoAnvilProjectError{StartDir: "/some/dir"},
			want: `no Anvil project found (no .anvil.yml in "/some/dir" or any parent directory)`,
		},
		{
			name: "FeatureExistsError",
			err:  FeatureExistsError{FeatureName: "Auth", ExistingDir: "Features/Auth"},
			want: `feature "Auth" already exists at Features/Auth`,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.err.Error()
			if got != tt.want {
				t.Errorf("Error() = %q, want %q", got, tt.want)
			}
		})
	}
}
