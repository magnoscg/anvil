package main

import (
	"runtime/debug"
	"strings"
	"testing"
)

func TestResolveVersionPrefersLdflags(t *testing.T) {
	original := Version
	t.Cleanup(func() { Version = original })

	Version = "1.2.3"

	if got := resolveVersion(); got != "1.2.3" {
		t.Errorf("resolveVersion() = %q, want %q", got, "1.2.3")
	}
}

func TestResolveVersionFallsBackToBuildInfo(t *testing.T) {
	original := Version
	t.Cleanup(func() { Version = original })

	Version = "dev"
	got := resolveVersion()

	if got == "" {
		t.Fatal("resolveVersion() returned an empty string")
	}
	if strings.HasPrefix(got, "v") {
		t.Errorf("resolveVersion() = %q, should not carry the leading v", got)
	}

	info, ok := debug.ReadBuildInfo()
	if !ok || info.Main.Version == "" || info.Main.Version == "(devel)" {
		if got != "dev" {
			t.Errorf("resolveVersion() = %q, want %q when build info carries no module version", got, "dev")
		}
		return
	}

	want := strings.TrimPrefix(info.Main.Version, "v")
	if got != want {
		t.Errorf("resolveVersion() = %q, want %q", got, want)
	}
}
