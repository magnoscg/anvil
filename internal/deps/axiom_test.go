package deps

import (
	"os"
	"path/filepath"
	"testing"
)

func writePluginIndex(t *testing.T, contents string) string {
	t.Helper()

	dir := t.TempDir()
	path := filepath.Join(dir, "installed_plugins.json")
	if err := os.WriteFile(path, []byte(contents), 0o644); err != nil {
		t.Fatalf("writing plugin index: %v", err)
	}
	return dir
}

func TestAxiomInstalledInDetectsPlugin(t *testing.T) {
	dir := writePluginIndex(t, `{"version":2,"plugins":{
		"github@claude-plugins-official":[],
		"axiom@axiom-marketplace":[]
	}}`)

	if !axiomInstalledIn(dir) {
		t.Error("axiomInstalledIn() = false, want true when axiom@ is present")
	}
}

func TestAxiomInstalledInAcceptsOtherMarketplaces(t *testing.T) {
	dir := writePluginIndex(t, `{"version":2,"plugins":{"axiom@my-fork":[]}}`)

	if !axiomInstalledIn(dir) {
		t.Error("axiomInstalledIn() = false, want true for axiom from any marketplace")
	}
}

func TestAxiomInstalledInRejectsUnrelatedPlugins(t *testing.T) {
	dir := writePluginIndex(t, `{"version":2,"plugins":{
		"github@claude-plugins-official":[],
		"axiomatic@somewhere":[]
	}}`)

	if axiomInstalledIn(dir) {
		t.Error("axiomInstalledIn() = true, want false when no axiom@ plugin is installed")
	}
}

func TestAxiomInstalledInHandlesMissingAndMalformedIndex(t *testing.T) {
	if axiomInstalledIn(t.TempDir()) {
		t.Error("axiomInstalledIn() = true, want false when the index does not exist")
	}

	dir := writePluginIndex(t, `{"plugins": [not json`)
	if axiomInstalledIn(dir) {
		t.Error("axiomInstalledIn() = true, want false when the index cannot be parsed")
	}
}
