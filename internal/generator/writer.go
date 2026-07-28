package generator

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
)

// FileWriter handles writing rendered content to the filesystem.
type FileWriter interface {
	// WriteFile writes content to path, creating parent directories as needed.
	WriteFile(path string, content []byte) error

	// EnsureDir creates a directory (and parents) if it does not exist.
	EnsureDir(path string) error

	// CopyFile copies a file from src to dst, preserving permissions.
	CopyFile(src, dst string) error
}

// DiskWriter is the production FileWriter that writes to the real filesystem.
type DiskWriter struct{}

// NewDiskWriter creates a new DiskWriter.
func NewDiskWriter() *DiskWriter {
	return &DiskWriter{}
}

// WriteFile writes content to the given path with 0644 permissions.
// Parent directories are created with 0755 permissions.
func (w *DiskWriter) WriteFile(path string, content []byte) error {
	dir := filepath.Dir(path)
	if err := w.EnsureDir(dir); err != nil {
		return fmt.Errorf("creating parent directory for %s: %w", path, err)
	}
	if err := os.WriteFile(path, content, 0644); err != nil {
		return fmt.Errorf("writing file %s: %w", path, err)
	}
	return nil
}

// EnsureDir creates the directory and all parents with 0755 permissions.
// Returns nil if the directory already exists.
func (w *DiskWriter) EnsureDir(path string) error {
	if err := os.MkdirAll(path, 0755); err != nil {
		return fmt.Errorf("creating directory %s: %w", path, err)
	}
	return nil
}

// CopyFile copies a file from src to dst, creating parent directories as needed.
// The destination file receives 0644 permissions.
func (w *DiskWriter) CopyFile(src, dst string) error {
	srcFile, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("opening source %s: %w", src, err)
	}
	defer func() { _ = srcFile.Close() }()

	dir := filepath.Dir(dst)
	if err := w.EnsureDir(dir); err != nil {
		return fmt.Errorf("creating parent directory for %s: %w", dst, err)
	}

	dstFile, err := os.OpenFile(dst, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("creating destination %s: %w", dst, err)
	}
	defer func() { _ = dstFile.Close() }()

	if _, err := io.Copy(dstFile, srcFile); err != nil {
		return fmt.Errorf("copying %s to %s: %w", src, dst, err)
	}

	return nil
}
