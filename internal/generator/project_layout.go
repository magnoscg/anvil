package generator

import (
	"io/fs"
	"path/filepath"
	"strings"

	"github.com/magnoscg/anvil/internal/config"
)

// FileJob describes a single file to render or copy during project generation.
type FileJob struct {
	// TemplatePath is the path within the embedded FS (e.g. "base/App/Config/AppEnvironment.swift.tmpl").
	TemplatePath string

	// DestinationPath is the relative output path under the project directory.
	DestinationPath string

	// IsTemplate indicates whether the file should be rendered as a Go template (.tmpl)
	// or copied verbatim.
	IsTemplate bool

	// Conditional indicates that this file is only included when a config flag is set.
	Conditional bool

	// Condition describes which config flag must be true (e.g. "SwiftData", "Claude", "Example").
	Condition string
}

// ProjectLayout returns the complete list of template-to-destination file mappings
// for a given project configuration. This is a pure function with no I/O side effects,
// making it testable without touching the filesystem.
//
// The returned FileJob list includes only the files that should actually be created
// based on the config flags (conditional files are filtered out when their condition is false).
func ProjectLayout(cfg config.ProjectConfig, embeddedFS fs.FS) ([]FileJob, error) {
	var jobs []FileJob

	// Base templates (always included)
	baseJobs, err := walkTemplateDir(embeddedFS, "base", cfg.Name, "")
	if err != nil {
		return nil, err
	}
	jobs = append(jobs, baseJobs...)

	// SwiftData templates (conditional)
	if cfg.IncludeSwiftData {
		sdJobs, err := walkTemplateDir(embeddedFS, "swiftdata", cfg.Name, "SwiftData")
		if err != nil {
			return nil, err
		}
		jobs = append(jobs, sdJobs...)
	}

	// AI Pack templates (conditional — one walk per selected pack)
	if cfg.HasAnyPacks() {
		resolved := config.ResolveDependencies(cfg.AIPacks)
		for _, slug := range resolved {
			packJobs, err := walkTemplateDir(embeddedFS, "ai-packs/"+slug, cfg.Name, "AIPack:"+slug)
			if err != nil {
				return nil, err
			}
			jobs = append(jobs, packJobs...)
		}
	}

	return jobs, nil
}

// walkTemplateDir walks a directory in the embedded FS and creates FileJob entries
// for each file found. Files ending in .tmpl are marked as templates; all others
// are marked for verbatim copy.
func walkTemplateDir(embeddedFS fs.FS, tmplDir string, projectName string, condition string) ([]FileJob, error) {
	var jobs []FileJob

	err := fs.WalkDir(embeddedFS, tmplDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Skip the xcodeproj/ subdirectory entirely — rendered by XcodeProjGenerator.
		if d.IsDir() {
			relDir, _ := filepath.Rel(tmplDir, path)
			if relDir == "xcodeproj" || strings.HasPrefix(relDir, "xcodeproj"+string(filepath.Separator)) {
				return fs.SkipDir
			}
			return nil
		}

		// Skip special files
		base := filepath.Base(path)
		if base == ".gitkeep" || base == ".DS_Store" || base == "Scheme.xcconfig.tmpl" {
			return nil
		}

		relPath, err := filepath.Rel(tmplDir, path)
		if err != nil {
			return err
		}

		isTemplate := strings.HasSuffix(path, ".tmpl")
		destPath := relPath
		if isTemplate {
			destPath = strings.TrimSuffix(destPath, ".tmpl")
		}

		// Destination goes inside <ProjectName>/<ProjectName>/ for source files
		// except for root-level project config files
		destPath = mapToProjectPath(destPath, projectName)

		job := FileJob{
			TemplatePath:    path,
			DestinationPath: destPath,
			IsTemplate:      isTemplate,
			Conditional:     condition != "",
			Condition:       condition,
		}
		jobs = append(jobs, job)
		return nil
	})

	return jobs, err
}

// MapToProjectPath is the exported version of mapToProjectPath for use by
// the feature forge when placing files in the correct project structure.
func MapToProjectPath(relPath string, projectName string) string {
	return mapToProjectPath(relPath, projectName)
}

// mapToProjectPath maps a template-relative destination path to the correct
// location within the generated project structure.
//
// Root-level files (Project.swift, .gitignore, .swiftlint.yml, etc.) stay at root.
// Source files (App/, Core/, Domain/, Data/, Features/, Resources/) go inside <ProjectName>/.
// Test files (Tests/) go at root level as <ProjectName>Tests/.
// Claude files (.claude/) go at root level.
func mapToProjectPath(relPath string, projectName string) string {
	topDir := strings.SplitN(relPath, string(filepath.Separator), 2)[0]

	// Root-level config files
	switch {
	case relPath == "Info.plist":
		return filepath.Join(projectName, relPath)
	case relPath == "placeholder.txt":
		return relPath
	case relPath == "swiftlint.yml":
		return ".swiftlint.yml"
	case relPath == "swiftformat":
		return ".swiftformat"
	case relPath == ".gitignore":
		return ".gitignore"
	case strings.HasPrefix(relPath, "docs/"):
		return filepath.Join(".claude", relPath)
	case relPath == "CLAUDE.md":
		return "CLAUDE.md"
	case relPath == "settings-merge.json":
		return "" // skip — not a direct output file
	case strings.HasPrefix(relPath, "commands/"):
		return filepath.Join(".claude", relPath)
	case strings.HasPrefix(relPath, "workflows/"):
		return filepath.Join(".github", relPath)
	case strings.HasPrefix(relPath, "dev/"):
		return filepath.Join("." + relPath)
	case strings.HasPrefix(relPath, "plan/"):
		return relPath
	case strings.HasPrefix(relPath, "skills/"):
		return filepath.Join(".claude", relPath)
	case relPath == "CLAUDE-section.md.tmpl" || relPath == "CLAUDE.md.tmpl":
		return "" // skip — handled by PackRenderer composition
	}

	// Source directories go inside <ProjectName>/
	switch topDir {
	case "App", "Core", "Domain", "Data", "Features", "Resources":
		return filepath.Join(projectName, relPath)
	case "Tests":
		return filepath.Join(projectName+"Tests", strings.TrimPrefix(relPath, "Tests/"))
	default:
		return relPath
	}
}
