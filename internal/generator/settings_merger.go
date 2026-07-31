package generator

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"reflect"

	"github.com/magnoscg/anvil/internal/config"
)

// SettingsMerger composes embedded settings fragments without writing to disk.
type SettingsMerger interface {
	// Merge applies fragments in order while preserving values from existingData.
	Merge(existingPath string, existingData []byte, fragmentPaths []string) ([]byte, error)
}

// DefaultSettingsMerger reads settings fragments from the embedded filesystem.
type DefaultSettingsMerger struct {
	fs fs.FS
}

// NewSettingsMerger creates a pure settings merger. The writer argument is kept
// for constructor compatibility while filesystem writes belong to the installer.
func NewSettingsMerger(_ FileWriter, embeddedFS fs.FS) *DefaultSettingsMerger {
	return &DefaultSettingsMerger{fs: embeddedFS}
}

// Merge validates and combines an existing object with every fragment.
func (m *DefaultSettingsMerger) Merge(existingPath string, existingData []byte, fragmentPaths []string) ([]byte, error) {
	base := make(map[string]any)
	if len(existingData) > 0 {
		parsed, err := decodeSettingsObject(existingData)
		if err != nil {
			return nil, config.SettingsMergeError{
				Path:  existingPath,
				Cause: fmt.Errorf("parsing existing settings: %w", err),
			}
		}
		base = parsed
	}

	for _, fragmentPath := range fragmentPaths {
		fragmentData, err := fs.ReadFile(m.fs, fragmentPath)
		if err != nil {
			return nil, config.SettingsMergeError{
				Path:  fragmentPath,
				Cause: fmt.Errorf("reading fragment: %w", err),
			}
		}

		overlay, err := decodeSettingsObject(fragmentData)
		if err != nil {
			return nil, config.SettingsMergeError{
				Path:  fragmentPath,
				Cause: fmt.Errorf("parsing fragment: %w", err),
			}
		}
		base = deepMerge(base, overlay)
	}

	out, err := json.MarshalIndent(base, "", "  ")
	if err != nil {
		return nil, config.SettingsMergeError{
			Path:  existingPath,
			Cause: fmt.Errorf("marshaling merged settings: %w", err),
		}
	}
	return append(out, '\n'), nil
}

func decodeSettingsObject(data []byte) (map[string]any, error) {
	var decoded any
	if err := json.Unmarshal(data, &decoded); err != nil {
		return nil, err
	}
	object, ok := decoded.(map[string]any)
	if !ok {
		return nil, fmt.Errorf("expected a JSON object")
	}
	return object, nil
}

// deepMerge recursively merges overlay into base. Existing scalar values win,
// objects recurse, and arrays append values that are not already present.
func deepMerge(base, overlay map[string]any) map[string]any {
	result := make(map[string]any, len(base))
	for key, value := range base {
		result[key] = value
	}

	for key, overlayValue := range overlay {
		baseValue, exists := result[key]
		if !exists {
			result[key] = overlayValue
			continue
		}

		switch typedBase := baseValue.(type) {
		case map[string]any:
			if typedOverlay, ok := overlayValue.(map[string]any); ok {
				result[key] = deepMerge(typedBase, typedOverlay)
			}
		case []any:
			if typedOverlay, ok := overlayValue.([]any); ok {
				result[key] = appendDedup(typedBase, typedOverlay)
			}
		}
	}

	return result
}

func appendDedup(base, overlay []any) []any {
	result := append([]any(nil), base...)
	for _, candidate := range overlay {
		if !containsValue(result, candidate) {
			result = append(result, candidate)
		}
	}
	return result
}

func containsValue(values []any, candidate any) bool {
	for _, value := range values {
		if reflect.DeepEqual(value, candidate) {
			return true
		}
	}
	return false
}
