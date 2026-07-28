package generator

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"
)

func TestMergeArraysAppendDedup(t *testing.T) {
	memFS := fstest.MapFS{
		"fragment.json": &fstest.MapFile{
			Data: []byte(`{"permissions":{"allow":["b"]}}`),
		},
	}

	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	existing := `{"permissions":{"allow":["a"]}}`
	if err := os.WriteFile(settingsPath, []byte(existing), 0644); err != nil {
		t.Fatalf("writing existing settings: %v", err)
	}

	merger := NewSettingsMerger(NewDiskWriter(), memFS)
	if err := merger.Merge(settingsPath, "fragment.json"); err != nil {
		t.Fatalf("Merge failed: %v", err)
	}

	got := readJSON(t, settingsPath)
	permissions := got["permissions"].(map[string]any)
	allow := permissions["allow"].([]any)

	if len(allow) != 2 {
		t.Fatalf("allow has %d items, want 2", len(allow))
	}
	if allow[0] != "a" || allow[1] != "b" {
		t.Errorf("allow = %v, want [a, b]", allow)
	}
}

func TestMergeObjects(t *testing.T) {
	memFS := fstest.MapFS{
		"fragment.json": &fstest.MapFile{
			Data: []byte(`{"b":2}`),
		},
	}

	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	if err := os.WriteFile(settingsPath, []byte(`{"a":1}`), 0644); err != nil {
		t.Fatalf("writing existing settings: %v", err)
	}

	merger := NewSettingsMerger(NewDiskWriter(), memFS)
	if err := merger.Merge(settingsPath, "fragment.json"); err != nil {
		t.Fatalf("Merge failed: %v", err)
	}

	got := readJSON(t, settingsPath)

	if got["a"] != float64(1) {
		t.Errorf("a = %v, want 1", got["a"])
	}
	if got["b"] != float64(2) {
		t.Errorf("b = %v, want 2", got["b"])
	}
}

func TestMergeSkipExistingScalars(t *testing.T) {
	memFS := fstest.MapFS{
		"fragment.json": &fstest.MapFile{
			Data: []byte(`{"key":"new"}`),
		},
	}

	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	if err := os.WriteFile(settingsPath, []byte(`{"key":"old"}`), 0644); err != nil {
		t.Fatalf("writing existing settings: %v", err)
	}

	merger := NewSettingsMerger(NewDiskWriter(), memFS)
	if err := merger.Merge(settingsPath, "fragment.json"); err != nil {
		t.Fatalf("Merge failed: %v", err)
	}

	got := readJSON(t, settingsPath)
	if got["key"] != "old" {
		t.Errorf("key = %v, want 'old' (first wins)", got["key"])
	}
}

func TestMergeWithNonExistentFile(t *testing.T) {
	memFS := fstest.MapFS{
		"fragment.json": &fstest.MapFile{
			Data: []byte(`{"key":"value","nested":{"a":1}}`),
		},
	}

	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	merger := NewSettingsMerger(NewDiskWriter(), memFS)
	if err := merger.Merge(settingsPath, "fragment.json"); err != nil {
		t.Fatalf("Merge failed: %v", err)
	}

	got := readJSON(t, settingsPath)
	if got["key"] != "value" {
		t.Errorf("key = %v, want 'value'", got["key"])
	}

	nested := got["nested"].(map[string]any)
	if nested["a"] != float64(1) {
		t.Errorf("nested.a = %v, want 1", nested["a"])
	}
}

func TestMergeDeepRecursive(t *testing.T) {
	memFS := fstest.MapFS{
		"fragment.json": &fstest.MapFile{
			Data: []byte(`{"level1":{"level2":{"newKey":"newVal","array":["c"]}}}`),
		},
	}

	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	existing := `{"level1":{"level2":{"existingKey":"existingVal","array":["a","b"]}}}`
	if err := os.WriteFile(settingsPath, []byte(existing), 0644); err != nil {
		t.Fatalf("writing existing settings: %v", err)
	}

	merger := NewSettingsMerger(NewDiskWriter(), memFS)
	if err := merger.Merge(settingsPath, "fragment.json"); err != nil {
		t.Fatalf("Merge failed: %v", err)
	}

	got := readJSON(t, settingsPath)
	level1 := got["level1"].(map[string]any)
	level2 := level1["level2"].(map[string]any)

	if level2["existingKey"] != "existingVal" {
		t.Errorf("existingKey = %v, want 'existingVal'", level2["existingKey"])
	}
	if level2["newKey"] != "newVal" {
		t.Errorf("newKey = %v, want 'newVal'", level2["newKey"])
	}

	array := level2["array"].([]any)
	if len(array) != 3 {
		t.Fatalf("array has %d items, want 3", len(array))
	}
	if array[0] != "a" || array[1] != "b" || array[2] != "c" {
		t.Errorf("array = %v, want [a, b, c]", array)
	}
}

func TestMergeArrayDedup(t *testing.T) {
	memFS := fstest.MapFS{
		"fragment.json": &fstest.MapFile{
			Data: []byte(`{"items":["a","b","c"]}`),
		},
	}

	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	if err := os.WriteFile(settingsPath, []byte(`{"items":["a","b"]}`), 0644); err != nil {
		t.Fatalf("writing existing settings: %v", err)
	}

	merger := NewSettingsMerger(NewDiskWriter(), memFS)
	if err := merger.Merge(settingsPath, "fragment.json"); err != nil {
		t.Fatalf("Merge failed: %v", err)
	}

	got := readJSON(t, settingsPath)
	items := got["items"].([]any)

	if len(items) != 3 {
		t.Fatalf("items has %d entries, want 3 (a, b from existing + c from overlay)", len(items))
	}
}

func TestMergeInvalidFragmentJSON(t *testing.T) {
	memFS := fstest.MapFS{
		"bad-fragment.json": &fstest.MapFile{
			Data: []byte(`{this is not valid json}`),
		},
	}

	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	merger := NewSettingsMerger(NewDiskWriter(), memFS)
	err := merger.Merge(settingsPath, "bad-fragment.json")

	if err == nil {
		t.Fatal("expected error for invalid JSON fragment, got nil")
	}

	if !strings.Contains(err.Error(), "parsing fragment") {
		t.Errorf("error should mention 'parsing fragment', got: %v", err)
	}
}

func TestMergeInvalidExistingJSON(t *testing.T) {
	memFS := fstest.MapFS{
		"fragment.json": &fstest.MapFile{
			Data: []byte(`{"key":"value"}`),
		},
	}

	dir := t.TempDir()
	settingsPath := filepath.Join(dir, "settings.json")

	// Write invalid JSON as the existing file
	if err := os.WriteFile(settingsPath, []byte(`{broken`), 0644); err != nil {
		t.Fatalf("writing invalid existing file: %v", err)
	}

	merger := NewSettingsMerger(NewDiskWriter(), memFS)
	err := merger.Merge(settingsPath, "fragment.json")

	if err == nil {
		t.Fatal("expected error for invalid existing JSON, got nil")
	}

	if !strings.Contains(err.Error(), "parsing existing settings") {
		t.Errorf("error should mention 'parsing existing settings', got: %v", err)
	}
}

// readJSON is a test helper that reads and parses a JSON file.
func readJSON(t *testing.T, path string) map[string]any {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("reading %s: %v", path, err)
	}
	var result map[string]any
	if err := json.Unmarshal(data, &result); err != nil {
		t.Fatalf("parsing %s: %v\ncontent: %s", path, err, string(data))
	}
	return result
}
