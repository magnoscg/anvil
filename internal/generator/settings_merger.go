package generator

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"

	"github.com/oscarcanton/anvilcli/internal/config"
)

// SettingsMerger merges a JSON fragment from the embedded FS into an existing
// settings.json on disk. Arrays are appended (deduplicated), objects are merged
// recursively, and scalars are kept from the existing file (first wins).
type SettingsMerger interface {
	// Merge reads the existing settings file at existingPath (or starts from {}
	// if the file does not exist), reads the fragment from fragmentPath inside
	// the embedded FS, deep-merges them, and writes the result back to existingPath.
	Merge(existingPath string, fragmentPath string) error
}

// DefaultSettingsMerger is the production implementation of SettingsMerger.
type DefaultSettingsMerger struct {
	writer FileWriter
	fs     fs.FS
}

// NewSettingsMerger creates a DefaultSettingsMerger backed by the given embedded FS.
func NewSettingsMerger(writer FileWriter, embeddedFS fs.FS) *DefaultSettingsMerger {
	return &DefaultSettingsMerger{writer: writer, fs: embeddedFS}
}

// Merge reads the existing JSON file (or creates an empty object), reads the
// fragment from the embedded FS, performs a deep merge, and writes the result.
func (m *DefaultSettingsMerger) Merge(existingPath string, fragmentPath string) error {
	// Read existing file (or start from empty object)
	base := make(map[string]any)
	existingData, err := os.ReadFile(existingPath)
	if err == nil {
		if err := json.Unmarshal(existingData, &base); err != nil {
			return config.SettingsMergeError{
				Path:  existingPath,
				Cause: fmt.Errorf("parsing existing settings: %w", err),
			}
		}
	} else if !os.IsNotExist(err) {
		return config.SettingsMergeError{
			Path:  existingPath,
			Cause: fmt.Errorf("reading existing settings: %w", err),
		}
	}

	// Read fragment from embedded FS
	fragmentData, err := fs.ReadFile(m.fs, fragmentPath)
	if err != nil {
		return config.SettingsMergeError{
			Path:  fragmentPath,
			Cause: fmt.Errorf("reading fragment: %w", err),
		}
	}

	overlay := make(map[string]any)
	if err := json.Unmarshal(fragmentData, &overlay); err != nil {
		return config.SettingsMergeError{
			Path:  fragmentPath,
			Cause: fmt.Errorf("parsing fragment: %w", err),
		}
	}

	// Deep merge
	merged := deepMerge(base, overlay)

	// Write result
	out, err := json.MarshalIndent(merged, "", "  ")
	if err != nil {
		return config.SettingsMergeError{
			Path:  existingPath,
			Cause: fmt.Errorf("marshaling merged settings: %w", err),
		}
	}
	out = append(out, '\n')

	if err := m.writer.WriteFile(existingPath, out); err != nil {
		return config.SettingsMergeError{
			Path:  existingPath,
			Cause: fmt.Errorf("writing merged settings: %w", err),
		}
	}

	return nil
}

// deepMerge recursively merges overlay into base with the following strategy:
//   - Arrays: append overlay values that are not already present (dedup).
//   - Objects: recurse into nested maps.
//   - Scalars: keep existing value (first wins / skip existing).
func deepMerge(base, overlay map[string]any) map[string]any {
	result := make(map[string]any, len(base))
	for k, v := range base {
		result[k] = v
	}

	for k, overlayVal := range overlay {
		baseVal, exists := result[k]
		if !exists {
			result[k] = overlayVal
			continue
		}

		// Both exist — merge based on type
		switch baseTyped := baseVal.(type) {
		case map[string]any:
			if overlayTyped, ok := overlayVal.(map[string]any); ok {
				result[k] = deepMerge(baseTyped, overlayTyped)
			}
			// If types don't match, keep base (first wins)

		case []any:
			if overlayTyped, ok := overlayVal.([]any); ok {
				result[k] = appendDedup(baseTyped, overlayTyped)
			}
			// If types don't match, keep base

		default:
			// Scalar: keep existing (first wins)
		}
	}

	return result
}

// appendDedup appends overlay items to base, skipping items already present.
func appendDedup(base, overlay []any) []any {
	result := make([]any, len(base))
	copy(result, base)

	for _, item := range overlay {
		if !containsValue(result, item) {
			result = append(result, item)
		}
	}
	return result
}

// containsValue checks if a slice contains a value using fmt.Sprintf comparison
// for deep equality of JSON-parsed values.
func containsValue(slice []any, val any) bool {
	valStr := fmt.Sprintf("%v", val)
	for _, item := range slice {
		if fmt.Sprintf("%v", item) == valStr {
			return true
		}
	}
	return false
}
