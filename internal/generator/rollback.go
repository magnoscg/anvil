package generator

import (
	"fmt"
	"log"
	"os"
)

// Rollback removes an entire directory tree. This is used to clean up after
// a failed project generation (`anvil init`). If the directory does not exist,
// Rollback returns nil.
func Rollback(dir string) error {
	info, err := os.Stat(dir)
	if os.IsNotExist(err) {
		log.Printf("rollback: directory %s does not exist, nothing to remove", dir)
		return nil
	}
	if err != nil {
		return fmt.Errorf("rollback: checking directory %s: %w", dir, err)
	}
	if !info.IsDir() {
		return fmt.Errorf("rollback: %s is not a directory", dir)
	}

	log.Printf("rollback: removing directory tree %s", dir)
	if err := os.RemoveAll(dir); err != nil {
		return fmt.Errorf("rollback: removing %s: %w", dir, err)
	}

	return nil
}

// EnsureTrackedDir creates path and any missing parents, appending each
// directory it creates to createdDirs (parents first) so that a rollback can
// remove exactly those. It refuses symlinked or non-directory components.
func EnsureTrackedDir(path string, createdDirs *[]string, createdSet map[string]struct{}) error {
	return ensureTrackedDirectory(path, createdDirs, createdSet)
}

// RollbackCreated removes the given files and then the given directories,
// newest first. Directories are removed only when empty, so anything another
// process wrote into them is kept and reported.
func RollbackCreated(files, dirs []string) error {
	return rollbackInstall(files, dirs)
}

// RollbackFiles removes individual files from the filesystem. This is used
// for partial rollback after a failed feature forge (`anvil feature`).
// Files that do not exist are skipped without error. Empty parent directories
// are NOT removed.
func RollbackFiles(paths []string) error {
	for _, p := range paths {
		if _, err := os.Stat(p); os.IsNotExist(err) {
			log.Printf("rollback: file %s does not exist, skipping", p)
			continue
		}

		log.Printf("rollback: removing file %s", p)
		if err := os.Remove(p); err != nil {
			return fmt.Errorf("rollback: removing file %s: %w", p, err)
		}
	}

	return nil
}
