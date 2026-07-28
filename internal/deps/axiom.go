package deps

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
)

// AxiomPackSlug is the AI pack that configures a project to use Axiom.
const AxiomPackSlug = "axiom-ios"

// AxiomInstalled reports whether the Axiom plugin is installed for the current
// user. Axiom is a Claude Code plugin rather than a binary on PATH, so this
// inspects Claude Code's plugin index instead of probing a command.
func AxiomInstalled() bool {
	home, err := os.UserHomeDir()
	if err != nil {
		return false
	}
	return axiomInstalledIn(filepath.Join(home, ".claude", "plugins"))
}

// axiomInstalledIn looks for an installed plugin named axiom@<marketplace>,
// so a plugin installed from a fork or a renamed marketplace still counts.
func axiomInstalledIn(pluginsDir string) bool {
	data, err := os.ReadFile(filepath.Join(pluginsDir, "installed_plugins.json"))
	if err != nil {
		return false
	}

	var index struct {
		Plugins map[string]json.RawMessage `json:"plugins"`
	}
	if err := json.Unmarshal(data, &index); err != nil {
		return false
	}

	for name := range index.Plugins {
		if strings.HasPrefix(name, "axiom@") {
			return true
		}
	}
	return false
}
