package generator

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

// FileWriter provides explicit filesystem operations for generated content.
type FileWriter interface {
	// CreateFile creates a new file and never replaces an existing path.
	CreateFile(path string, content []byte, mode fs.FileMode) error

	// EnsureDir creates a directory and its parents when they do not exist.
	EnsureDir(path string) error

	// CreateDir creates exactly one new directory and fails if the path exists.
	CreateDir(path string) error

	// AtomicCreateFile publishes a new file atomically and never replaces a path.
	AtomicCreateFile(path string, content []byte, mode fs.FileMode) error

	// AtomicReplaceFile replaces one existing regular file through a same-directory rename.
	AtomicReplaceFile(path string, content []byte, mode fs.FileMode) error
}

// DiskWriter is the production FileWriter backed by the local filesystem.
type DiskWriter struct{}

// NewDiskWriter creates a new DiskWriter.
func NewDiskWriter() *DiskWriter {
	return &DiskWriter{}
}

// CreateFile writes content to a newly created file. A partially written file
// is removed when the write or close operation fails.
func (w *DiskWriter) CreateFile(path string, content []byte, mode fs.FileMode) error {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, mode)
	if err != nil {
		return fmt.Errorf("creating file %s: %w", path, err)
	}

	removePartial := true
	defer func() {
		if removePartial {
			_ = os.Remove(path)
		}
	}()

	if _, err := file.Write(content); err != nil {
		_ = file.Close()
		return fmt.Errorf("writing file %s: %w", path, err)
	}
	if err := file.Close(); err != nil {
		return fmt.Errorf("closing file %s: %w", path, err)
	}

	removePartial = false
	return nil
}

// EnsureDir creates the directory and all parents with 0755 permissions.
func (w *DiskWriter) EnsureDir(path string) error {
	if err := os.MkdirAll(path, 0755); err != nil {
		return fmt.Errorf("creating directory %s: %w", path, err)
	}
	return nil
}

// CreateDir creates a new directory with 0755 permissions. Parent directories
// must already exist and an existing path is never reused.
func (w *DiskWriter) CreateDir(path string) error {
	if err := os.Mkdir(path, 0755); err != nil {
		return fmt.Errorf("creating new directory %s: %w", path, err)
	}
	return nil
}

// AtomicCreateFile prepares a same-directory temporary file and publishes it
// with an exclusive hard link. Link creation is atomic and fails if path exists.
func (w *DiskWriter) AtomicCreateFile(path string, content []byte, mode fs.FileMode) error {
	dir := filepath.Dir(path)
	temporaryPath, err := writeAtomicTemporary(dir, path, content, mode)
	if err != nil {
		return err
	}
	defer func() { _ = os.Remove(temporaryPath) }()

	if err := os.Link(temporaryPath, path); err != nil {
		return fmt.Errorf("publishing new file %s: %w", path, err)
	}
	return nil
}

// AtomicReplaceFile writes content to a temporary file next to path and then
// renames it over the destination. Existing symlinks and non-regular files are
// rejected immediately before the replacement.
func (w *DiskWriter) AtomicReplaceFile(path string, content []byte, mode fs.FileMode) error {
	if info, err := os.Lstat(path); err == nil {
		if info.Mode()&os.ModeSymlink != 0 || !info.Mode().IsRegular() {
			return fmt.Errorf("atomic replacement target %s is not a regular file", path)
		}
	} else if os.IsNotExist(err) {
		return fmt.Errorf("atomic replacement target %s does not exist", path)
	} else {
		return fmt.Errorf("checking atomic replacement target %s: %w", path, err)
	}

	dir := filepath.Dir(path)
	temporaryPath, err := writeAtomicTemporary(dir, path, content, mode)
	if err != nil {
		return err
	}
	defer func() { _ = os.Remove(temporaryPath) }()
	if err := os.Rename(temporaryPath, path); err != nil {
		return fmt.Errorf("replacing file %s: %w", path, err)
	}
	return nil
}

func writeAtomicTemporary(dir, path string, content []byte, mode fs.FileMode) (string, error) {
	temporary, err := os.CreateTemp(dir, ".anvil-settings-*")
	if err != nil {
		return "", fmt.Errorf("creating temporary file for %s: %w", path, err)
	}
	temporaryPath := temporary.Name()
	keepTemporary := true
	defer func() {
		if keepTemporary {
			_ = os.Remove(temporaryPath)
		}
	}()

	if err := temporary.Chmod(mode); err != nil {
		_ = temporary.Close()
		return "", fmt.Errorf("setting permissions on temporary file for %s: %w", path, err)
	}
	if _, err := temporary.Write(content); err != nil {
		_ = temporary.Close()
		return "", fmt.Errorf("writing temporary file for %s: %w", path, err)
	}
	if err := temporary.Sync(); err != nil {
		_ = temporary.Close()
		return "", fmt.Errorf("syncing temporary file for %s: %w", path, err)
	}
	if err := temporary.Close(); err != nil {
		return "", fmt.Errorf("closing temporary file for %s: %w", path, err)
	}

	keepTemporary = false
	return temporaryPath, nil
}
