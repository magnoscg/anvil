package generator

import (
	"encoding/json"
	"errors"
	"testing"
	"testing/fstest"

	"github.com/magnoscg/anvil/internal/config"
)

func TestSettingsMergeArraysAppendDedup(t *testing.T) {
	merger := NewSettingsMerger(NewDiskWriter(), fstest.MapFS{
		"fragment.json": &fstest.MapFile{Data: []byte(`{"permissions":{"allow":["Bash(git:*)","Read"]}}`)},
	})

	result := mergeSettingsForTest(t, merger, `{"permissions":{"allow":["Read","Write"]}}`, "fragment.json")
	allow := result["permissions"].(map[string]any)["allow"].([]any)
	want := []any{"Read", "Write", "Bash(git:*)"}
	if !equalJSONValues(allow, want) {
		t.Fatalf("allow = %v, want %v", allow, want)
	}
}

func TestSettingsMergeObjectsRecursively(t *testing.T) {
	merger := NewSettingsMerger(NewDiskWriter(), fstest.MapFS{
		"one.json": &fstest.MapFile{Data: []byte(`{"env":{"B":"2"},"nested":{"level":{"second":2}}}`)},
		"two.json": &fstest.MapFile{Data: []byte(`{"env":{"C":"3"},"nested":{"level":{"third":3}}}`)},
	})

	result := mergeSettingsForTest(t, merger, `{"env":{"A":"1"},"nested":{"level":{"first":1}}}`, "one.json", "two.json")
	environment := result["env"].(map[string]any)
	if environment["A"] != "1" || environment["B"] != "2" || environment["C"] != "3" {
		t.Fatalf("merged environment = %v", environment)
	}
	level := result["nested"].(map[string]any)["level"].(map[string]any)
	if len(level) != 3 {
		t.Fatalf("merged nested object = %v", level)
	}
}

func TestSettingsMergeKeepsExistingScalars(t *testing.T) {
	merger := NewSettingsMerger(NewDiskWriter(), fstest.MapFS{
		"fragment.json": &fstest.MapFile{Data: []byte(`{"theme":"light","enabled":false,"count":2}`)},
	})

	result := mergeSettingsForTest(t, merger, `{"theme":"dark","enabled":true,"count":1}`, "fragment.json")
	if result["theme"] != "dark" || result["enabled"] != true || result["count"] != float64(1) {
		t.Fatalf("existing scalar values were replaced: %v", result)
	}
}

func TestSettingsMergeUsesDeterministicDeepEquality(t *testing.T) {
	merger := NewSettingsMerger(NewDiskWriter(), fstest.MapFS{
		"fragment.json": &fstest.MapFile{Data: []byte(`{"items":[{"a":1,"b":2},{"a":2}]}`)},
	})

	result := mergeSettingsForTest(t, merger, `{"items":[{"b":2,"a":1}]}`, "fragment.json")
	items := result["items"].([]any)
	if len(items) != 2 {
		t.Fatalf("items = %v, want one deduplicated object and one new object", items)
	}
}

func TestSettingsMergeRejectsInvalidJSONAndNonObjects(t *testing.T) {
	tests := []struct {
		name      string
		existing  string
		fragment  string
		errorPath string
	}{
		{name: "invalid existing", existing: `{broken`, fragment: `{}`, errorPath: "settings.json"},
		{name: "existing array", existing: `[]`, fragment: `{}`, errorPath: "settings.json"},
		{name: "invalid fragment", existing: `{}`, fragment: `{broken`, errorPath: "fragment.json"},
		{name: "fragment array", existing: `{}`, fragment: `[]`, errorPath: "fragment.json"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			merger := NewSettingsMerger(NewDiskWriter(), fstest.MapFS{
				"fragment.json": &fstest.MapFile{Data: []byte(test.fragment)},
			})
			_, err := merger.Merge("settings.json", []byte(test.existing), []string{"fragment.json"})
			var mergeErr config.SettingsMergeError
			if !errors.As(err, &mergeErr) {
				t.Fatalf("error = %v, want SettingsMergeError", err)
			}
			if mergeErr.Path != test.errorPath {
				t.Fatalf("error path = %q, want %q", mergeErr.Path, test.errorPath)
			}
		})
	}
}

func TestSettingsMergeRejectsMissingFragment(t *testing.T) {
	merger := NewSettingsMerger(NewDiskWriter(), fstest.MapFS{})
	_, err := merger.Merge("settings.json", nil, []string{"missing.json"})
	var mergeErr config.SettingsMergeError
	if !errors.As(err, &mergeErr) {
		t.Fatalf("error = %v, want SettingsMergeError", err)
	}
}

func mergeSettingsForTest(t *testing.T, merger SettingsMerger, existing string, fragments ...string) map[string]any {
	t.Helper()
	data, err := merger.Merge("settings.json", []byte(existing), fragments)
	if err != nil {
		t.Fatalf("Merge failed: %v", err)
	}
	var result map[string]any
	if err := json.Unmarshal(data, &result); err != nil {
		t.Fatalf("decoding result: %v", err)
	}
	return result
}

func equalJSONValues(left, right any) bool {
	leftData, _ := json.Marshal(left)
	rightData, _ := json.Marshal(right)
	return string(leftData) == string(rightData)
}
