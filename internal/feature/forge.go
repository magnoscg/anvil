package feature

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/magnoscg/anvil/internal/config"
	"github.com/magnoscg/anvil/internal/generator"
)

// DefaultFeatureForge is the production implementation of generator.FeatureForge.
type DefaultFeatureForge struct {
	renderer generator.TemplateRenderer
}

// NewFeatureForge creates a DefaultFeatureForge using the provided renderer.
func NewFeatureForge(renderer generator.TemplateRenderer) *DefaultFeatureForge {
	return &DefaultFeatureForge{renderer: renderer}
}

// Forge validates the config, renders all feature templates, and returns a
// ForgeResult. Every destination is checked before anything is written, and if
// a step fails, the files and directories created so far are rolled back, so
// a failed run can be retried.
func (s *DefaultFeatureForge) Forge(cfg config.FeatureConfig) (config.ForgeResult, error) {
	// 1. Validate the feature and project names
	if err := ValidateFeatureName(cfg.FeatureName); err != nil {
		return config.ForgeResult{}, err
	}
	if err := config.ValidateProjectName(cfg.ProjectName); err != nil {
		return config.ForgeResult{}, err
	}

	// 2. Check feature does not already exist in any of the three canonical locations.
	existenceDirs := []string{
		filepath.Join(cfg.ProjectRoot, cfg.ProjectName, "Domain", cfg.FeatureName),
		filepath.Join(cfg.ProjectRoot, cfg.ProjectName, "Features", cfg.FeatureName),
		filepath.Join(cfg.ProjectRoot, cfg.ProjectName, "Data", cfg.FeatureName),
	}
	for _, dir := range existenceDirs {
		if _, err := os.Stat(dir); err == nil {
			return config.ForgeResult{}, config.FeatureExistsError{
				FeatureName: cfg.FeatureName,
				ExistingDir: dir,
			}
		}
	}

	// UI tests need the registry that anvil init creates; check it before writing anything.
	if cfg.IncludeUITests {
		if err := checkUITestRegistry(cfg); err != nil {
			return config.ForgeResult{}, err
		}
	}

	// 3. Build template context
	ctx := generator.NewFeatureContext(cfg)

	// 4. Build layout (all file mappings). MapToProjectPath places source
	// files in <ProjectName>/ and test files in <ProjectName>Tests/, matching
	// the Xcode target structure.
	jobs := FeatureLayout(cfg)
	destPaths := make([]string, len(jobs))
	for i, job := range jobs {
		destPaths[i] = filepath.Join(cfg.ProjectRoot, generator.MapToProjectPath(job.DestPath, cfg.ProjectName))
	}

	// 5. Refuse to start when any destination already exists, so a collision
	// cannot leave a half-written feature behind.
	for _, destPath := range destPaths {
		if _, err := os.Lstat(destPath); err == nil {
			return config.ForgeResult{}, config.FeatureExistsError{
				FeatureName: cfg.FeatureName,
				ExistingDir: destPath,
			}
		} else if !os.IsNotExist(err) {
			return config.ForgeResult{}, fmt.Errorf("checking %s: %w", destPath, err)
		}
	}

	// 6. Render each file, tracking the files and directories it creates.
	var created []string
	var createdDirs []string
	createdDirSet := make(map[string]struct{})
	for i, job := range jobs {
		destPath := destPaths[i]

		err := generator.EnsureTrackedDir(filepath.Dir(destPath), &createdDirs, createdDirSet)
		if err == nil {
			err = s.renderer.Render(job.TemplatePath, ctx, destPath)
		}
		if err != nil {
			if rollbackErr := generator.RollbackCreated(created, createdDirs); rollbackErr != nil {
				return config.ForgeResult{}, config.RollbackError{
					OriginalError: err,
					RollbackCause: rollbackErr,
				}
			}
			return config.ForgeResult{}, fmt.Errorf("rendering %s: %w", job.TemplatePath, err)
		}
		created = append(created, destPath)
	}

	// 7. Register the screen in the UI test registry, so UI tests can open it as the root view.
	if cfg.IncludeUITests {
		if err := registerUITestScreen(cfg); err != nil {
			if rollbackErr := generator.RollbackCreated(created, createdDirs); rollbackErr != nil {
				return config.ForgeResult{}, config.RollbackError{
					OriginalError: err,
					RollbackCause: rollbackErr,
				}
			}
			return config.ForgeResult{}, fmt.Errorf("registering %s for UI tests: %w", cfg.FeatureName, err)
		}
	}

	// 8. Build wiring instructions
	instructions := WiringInstructions(cfg)

	// 9. Return result
	featureDir := filepath.Join("Features", cfg.FeatureName)
	result := config.ForgeResult{
		FeatureDir:         featureDir,
		FilesCreated:       relativePaths(cfg.ProjectRoot, created),
		WiringInstructions: instructions,
	}

	return result, nil
}

// Rollback removes only the files at the given absolute paths. Files that do
// not exist are skipped. This delegates to generator.RollbackFiles.
func (s *DefaultFeatureForge) Rollback(paths []string) error {
	return generator.RollbackFiles(paths)
}

// relativePaths converts absolute paths to paths relative to root.
func relativePaths(root string, absPaths []string) []string {
	rel := make([]string, 0, len(absPaths))
	for _, p := range absPaths {
		r, err := filepath.Rel(root, p)
		if err != nil {
			rel = append(rel, p)
			continue
		}
		rel = append(rel, r)
	}
	return rel
}
