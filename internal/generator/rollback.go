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
