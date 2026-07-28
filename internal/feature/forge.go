package feature

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/oscarcanton/anvilcli/internal/config"
	"github.com/oscarcanton/anvilcli/internal/generator"
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
// ForgeResult. If any step fails, previously created files are rolled back.
func (s *DefaultFeatureForge) Forge(cfg config.FeatureConfig) (config.ForgeResult, error) {
	// 1. Validate feature name
	if err := ValidateFeatureName(cfg.FeatureName); err != nil {
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

	// 3. Build template context
	ctx := generator.NewFeatureContext(cfg)

	// 4. Build layout (all file mappings)
	jobs := FeatureLayout(cfg)

	// 5. Render each file, tracking created paths for potential rollback.
	// Use mapToProjectPath to place source files in <ProjectName>/ and
	// test files in <ProjectName>Tests/, matching the Xcode target structure.
	var created []string
	for _, job := range jobs {
		mappedPath := generator.MapToProjectPath(job.DestPath, cfg.ProjectName)
		destPath := filepath.Join(cfg.ProjectRoot, mappedPath)

		if err := s.renderer.Render(job.TemplatePath, ctx, destPath); err != nil {
			// Rollback files created so far
			rollbackErr := s.Rollback(created)
			if rollbackErr != nil {
				return config.ForgeResult{}, config.RollbackError{
					OriginalError: err,
					RollbackCause: rollbackErr,
				}
			}
			return config.ForgeResult{}, fmt.Errorf("rendering %s: %w", job.TemplatePath, err)
		}
		created = append(created, destPath)
	}

	// 6. Build wiring instructions
	instructions := WiringInstructions(cfg)

	// 7. Return result
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
