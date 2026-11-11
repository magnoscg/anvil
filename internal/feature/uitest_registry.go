package feature

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/magnoscg/anvil/internal/config"
)

// UITestRegistryMarker is the line in App/Navigation/UITestScreenRegistry.swift above which
// anvil feature registers the screen of every feature generated with UI tests.
const UITestRegistryMarker = "// anvil:ui-test-screens"

// UITestRegistryMissingError reports a project without the UI test registry marker, such as one
// generated before anvil init created the UI test target. Nothing is written in that case.
type UITestRegistryMissingError struct {
	Path string
}

func (e UITestRegistryMissingError) Error() string {
	return fmt.Sprintf(
		"UI tests need %s with the %q marker, which anvil init creates together with the UI test target and the Shared/ group; this project does not have it, so run anvil feature again and answer no to UI tests",
		e.Path, UITestRegistryMarker,
	)
}

// uiTestRegistryPath returns the absolute path of the project's UI test screen registry.
func uiTestRegistryPath(cfg config.FeatureConfig) string {
	return filepath.Join(cfg.ProjectRoot, cfg.ProjectName, "App", "Navigation", "UITestScreenRegistry.swift")
}

// checkUITestRegistry fails with UITestRegistryMissingError when the registry or its marker is missing.
func checkUITestRegistry(cfg config.FeatureConfig) error {
	path := uiTestRegistryPath(cfg)
	content, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return UITestRegistryMissingError{Path: relativeToRoot(cfg.ProjectRoot, path)}
	}
	if err != nil {
		return fmt.Errorf("reading %s: %w", path, err)
	}
	if !strings.Contains(string(content), UITestRegistryMarker) {
		return UITestRegistryMissingError{Path: relativeToRoot(cfg.ProjectRoot, path)}
	}
	return nil
}

// registerUITestScreen inserts the feature's entry above the registry marker, with the marker's
// indentation. An entry that is already there is left alone; a failed write restores the file.
func registerUITestScreen(cfg config.FeatureConfig) error {
	path := uiTestRegistryPath(cfg)
	original, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("reading %s: %w", path, err)
	}
	info, err := os.Stat(path)
	if err != nil {
		return fmt.Errorf("reading %s: %w", path, err)
	}

	name := cfg.FeatureName
	if strings.Contains(string(original), fmt.Sprintf("UITestScreen(name: %q)", name)) {
		return nil
	}

	lines := strings.SplitAfter(string(original), "\n")
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != UITestRegistryMarker {
			continue
		}
		indent := line[:len(line)-len(strings.TrimLeft(line, " \t"))]
		entry := fmt.Sprintf("%sUITestScreen(name: %q) { AnyView(%sFactory.makeView(appRouter: $0, dependencies: $1)) },\n", indent, name, name)
		updated := strings.Join(lines[:i], "") + entry + strings.Join(lines[i:], "")
		if err := os.WriteFile(path, []byte(updated), info.Mode().Perm()); err != nil {
			_ = os.WriteFile(path, original, info.Mode().Perm())
			return fmt.Errorf("writing %s: %w", path, err)
		}
		return nil
	}

	return UITestRegistryMissingError{Path: relativeToRoot(cfg.ProjectRoot, path)}
}

// relativeToRoot returns path relative to root, or path itself when that fails.
func relativeToRoot(root, path string) string {
	rel, err := filepath.Rel(root, path)
	if err != nil {
		return path
	}
	return rel
}
