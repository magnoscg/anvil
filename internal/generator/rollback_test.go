package generator

import (
	"os"
	"path/filepath"
	"testing"
)

func TestRollbackRemovesDirectory(t *testing.T) {
	dir := t.TempDir()
	target := filepath.Join(dir, "project")

	if err := os.MkdirAll(filepath.Join(target, "sub", "deep"), 0755); err != nil {
		t.Fatalf("setup: %v", err)
	}
	if err := os.WriteFile(filepath.Join(target, "file.txt"), []byte("hello"), 0644); err != nil {
		t.Fatalf("setup: %v", err)
	}
	if err := os.WriteFile(filepath.Join(target, "sub", "nested.txt"), []byte("world"), 0644); err != nil {
		t.Fatalf("setup: %v", err)
	}

	if err := Rollback(target); err != nil {
		t.Fatalf("Rollback failed: %v", err)
	}

	if _, err := os.Stat(target); !os.IsNotExist(err) {
		t.Errorf("directory %s should have been removed", target)
	}
}

func TestRollbackNonExistentDirDoesNotError(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "does-not-exist")

	if err := Rollback(dir); err != nil {
		t.Errorf("Rollback on non-existent dir should not error, got: %v", err)
	}
}

func TestRollbackFilesRemovesListedFiles(t *testing.T) {
	dir := t.TempDir()

	fileA := filepath.Join(dir, "a.swift")
	fileB := filepath.Join(dir, "b.swift")
	fileC := filepath.Join(dir, "c.swift")

	for _, f := range []string{fileA, fileB, fileC} {
		if err := os.WriteFile(f, []byte("content"), 0644); err != nil {
			t.Fatalf("setup: %v", err)
		}
	}

	if err := RollbackFiles([]string{fileA, fileB}); err != nil {
		t.Fatalf("RollbackFiles failed: %v", err)
	}

	if _, err := os.Stat(fileA); !os.IsNotExist(err) {
		t.Error("fileA should have been removed")
	}
	if _, err := os.Stat(fileB); !os.IsNotExist(err) {
		t.Error("fileB should have been removed")
	}
	if _, err := os.Stat(fileC); os.IsNotExist(err) {
		t.Error("fileC should NOT have been removed")
	}
}

func TestRollbackFilesSkipsNonExistent(t *testing.T) {
	dir := t.TempDir()

	existing := filepath.Join(dir, "exists.swift")
	if err := os.WriteFile(existing, []byte("content"), 0644); err != nil {
		t.Fatalf("setup: %v", err)
	}

	missing := filepath.Join(dir, "missing.swift")

	if err := RollbackFiles([]string{missing, existing}); err != nil {
		t.Fatalf("RollbackFiles should not error on missing files, got: %v", err)
	}

	if _, err := os.Stat(existing); !os.IsNotExist(err) {
		t.Error("existing file should have been removed")
	}
}

func TestRollbackFilesEmptyList(t *testing.T) {
	if err := RollbackFiles(nil); err != nil {
		t.Errorf("RollbackFiles(nil) should not error, got: %v", err)
	}
	if err := RollbackFiles([]string{}); err != nil {
		t.Errorf("RollbackFiles([]) should not error, got: %v", err)
	}
}
