package generator

import (
	"context"
	"fmt"
	"io/fs"
	"log"
	"path/filepath"
	"strings"
	"time"

	"github.com/magnoscg/anvil/internal/config"
)

// ProjectGenerator orchestrates the full project creation pipeline for `anvil init`.
type ProjectGenerator interface {
	// Generate runs all steps: create directory, render templates, generate xcodeproj,
	// init git, and write .anvil.yml. Returns the generation result or an error.
	// On error, previously created output is rolled back automatically.
	Generate(ctx context.Context, cfg config.ProjectConfig) (config.GenerationResult, error)

	// GenerateToolsOnly installs only AI coding tools (packs) into cfg.OutputDir
	// without creating a project directory, xcodeproj, git, or .anvil.yml marker.
	GenerateToolsOnly(ctx context.Context, cfg config.ProjectConfig) (config.GenerationResult, error)
}

// FeatureForge is the interface for generating a feature forge.
// This is injected into the project generator to support the IncludeExample option.
type FeatureForge interface {
	Forge(cfg config.FeatureConfig) (config.ForgeResult, error)
}

// DefaultProjectGenerator is the production implementation of ProjectGenerator.
type DefaultProjectGenerator struct {
	renderer     TemplateRenderer
	writer       FileWriter
	xcodeproj    XcodeProjGenerator
	git          GitRunner
	marker       config.MarkerReadWriter
	fs           fs.FS
	forge        FeatureForge
	packRenderer PackRenderer
}

// NewProjectGenerator creates a DefaultProjectGenerator with the given dependencies.
func NewProjectGenerator(
	renderer TemplateRenderer,
	writer FileWriter,
	xcodeproj XcodeProjGenerator,
	git GitRunner,
	marker config.MarkerReadWriter,
	embeddedFS fs.FS,
	forge FeatureForge,
	packRenderer PackRenderer,
) *DefaultProjectGenerator {
	return &DefaultProjectGenerator{
		renderer:     renderer,
		writer:       writer,
		xcodeproj:    xcodeproj,
		git:          git,
		marker:       marker,
		fs:           embeddedFS,
		forge:        forge,
		packRenderer: packRenderer,
	}
}

// Generate executes the full project generation pipeline:
//  1. Create output directory
//  2. Render base templates
//  3. Render SwiftData templates (if enabled)
//  4. Render AI Packs via PackRenderer (if any packs selected)
//  5. Forge Example feature (if enabled)
//  6. Generate Xcode project (.xcodeproj bundle)
//  7. Initialize git repository (non-fatal on failure)
//  8. Write .anvil.yml marker
//
// On ANY error at steps 1-6 or 8, Rollback is called to clean up.
// Git failure (step 7) is non-fatal: a warning is logged but generation succeeds.
func (g *DefaultProjectGenerator) Generate(ctx context.Context, cfg config.ProjectConfig) (result config.GenerationResult, resultErr error) {
	cfg.Normalize()

	start := time.Now()
	if err := config.ValidateProjectName(cfg.Name); err != nil {
		return result, err
	}

	projectDir := filepath.Join(cfg.OutputDir, cfg.Name)
	result.ProjectDir = projectDir

	// Step 1: Create and exclusively own the output directory.
	if err := g.writer.EnsureDir(filepath.Dir(projectDir)); err != nil {
		return result, fmt.Errorf("creating output directory: %w", err)
	}
	if err := g.writer.CreateDir(projectDir); err != nil {
		return result, fmt.Errorf("creating project directory: %w", err)
	}
	defer func() {
		if resultErr == nil {
			return
		}
		if rollbackErr := Rollback(projectDir); rollbackErr != nil {
			resultErr = config.RollbackError{
				OriginalError: resultErr,
				RollbackCause: rollbackErr,
			}
		}
	}()

	tmplCtx := NewProjectContext(cfg)

	// Step 2: Render base templates
	baseFiles, err := g.renderTemplateDir("base", tmplCtx, projectDir, cfg.Name)
	if err != nil {
		return result, fmt.Errorf("rendering base templates: %w", err)
	}
	result.FilesCreated = append(result.FilesCreated, baseFiles...)

	// Step 2b: Render per-scheme xcconfig files
	schemeFiles, err := g.renderSchemeXcconfigs(cfg, projectDir)
	if err != nil {
		return result, fmt.Errorf("rendering scheme xcconfigs: %w", err)
	}
	result.FilesCreated = append(result.FilesCreated, schemeFiles...)

	// Step 3: Render SwiftData templates (conditional)
	if cfg.IncludeSwiftData {
		sdFiles, err := g.renderTemplateDir("swiftdata", tmplCtx, projectDir, cfg.Name)
		if err != nil {
			return result, fmt.Errorf("rendering SwiftData templates: %w", err)
		}
		result.FilesCreated = append(result.FilesCreated, sdFiles...)
	}

	// Step 4: Render AI Packs (conditional)
	if cfg.HasAnyPacks() {
		resolved := config.ResolveDependencies(cfg.AIPacks)
		packFiles, err := g.installPacks(resolved, cfg.SkillsScope, tmplCtx, projectDir)
		if err != nil {
			return result, fmt.Errorf("rendering AI packs: %w", err)
		}
		result.FilesCreated = append(result.FilesCreated, packFiles...)
	}

	// Step 5: Forge Example feature (conditional)
	if cfg.IncludeExample && g.forge != nil {
		featureCfg := config.FeatureConfig{
			FeatureName:          "Example",
			ProjectRoot:          projectDir,
			ProjectName:          cfg.Name,
			IncludeRouteResolver: true,
		}
		forgeResult, err := g.forge.Forge(featureCfg)
		if err != nil {
			return result, fmt.Errorf("forging Example feature: %w", err)
		}
		result.FilesCreated = append(result.FilesCreated, forgeResult.FilesCreated...)
	}

	// Step 6: Generate Xcode project (.xcodeproj bundle)
	xcodeOutput, err := g.xcodeproj.Generate(ctx, projectDir, cfg)
	if err != nil {
		return result, fmt.Errorf("generating Xcode project: %w", err)
	}
	result.XcodeProjectOutput = xcodeOutput

	// Step 7: Initialize git (non-fatal on failure)
	gitOutput, gitErr := g.initGit(projectDir)
	if gitErr != nil {
		log.Printf("WARNING: git initialization failed: %v", gitErr)
		log.Printf("You can manually initialize git with: cd %s && git init && git add . && git commit -m \"Initial commit\"", projectDir)
		result.GitOutput = fmt.Sprintf("git init failed: %v", gitErr)
	} else {
		result.GitOutput = gitOutput
	}

	// Step 8: Write .anvil.yml marker
	anvilMarker := config.AnvilMarker{
		Version:      "0.1.0",
		ProjectName:  cfg.Name,
		BundleID:     cfg.BundleID,
		IOSVersion:   cfg.IOSVersion,
		SwiftVersion: cfg.SwiftVersion,
		Schemes:      cfg.Schemes,
		AIPacks:      cfg.AIPacks,
		SkillsScope:  cfg.SkillsScope,
		CreatedAt:    time.Now(),
	}
	if err := g.marker.Write(projectDir, anvilMarker); err != nil {
		return result, fmt.Errorf("writing .anvil.yml: %w", err)
	}
	result.FilesCreated = append(result.FilesCreated, ".anvil.yml")

	result.Duration = time.Since(start)
	return result, nil
}

// GenerateToolsOnly installs only AI coding packs into cfg.OutputDir.
// It skips directory creation, base templates, xcodeproj, git, and .anvil.yml.
func (g *DefaultProjectGenerator) GenerateToolsOnly(_ context.Context, cfg config.ProjectConfig) (config.GenerationResult, error) {
	start := time.Now()
	result := config.GenerationResult{
		ProjectDir: cfg.OutputDir,
	}

	if !cfg.HasAnyPacks() {
		result.Duration = time.Since(start)
		return result, nil
	}

	tmplCtx := NewProjectContext(cfg)
	resolved := config.ResolveDependencies(cfg.AIPacks)

	packFiles, err := g.installPacks(resolved, cfg.SkillsScope, tmplCtx, cfg.OutputDir)
	if err != nil {
		return result, fmt.Errorf("rendering AI packs: %w", err)
	}
	result.FilesCreated = append(result.FilesCreated, packFiles...)

	result.Duration = time.Since(start)
	return result, nil
}

func (g *DefaultProjectGenerator) installPacks(packs []string, skillsScope string, ctx any, projectDir string) ([]string, error) {
	plan, err := g.packRenderer.PlanPacks(packs, skillsScope, ctx, projectDir)
	if err != nil {
		return nil, err
	}
	if err := g.packRenderer.Preflight(&plan); err != nil {
		return nil, err
	}
	return g.packRenderer.Apply(plan)
}

// renderTemplateDir renders all templates in a template directory, placing output
// files in the correct project structure locations.
func (g *DefaultProjectGenerator) renderTemplateDir(tmplDir string, ctx any, projectDir string, projectName string) ([]string, error) {
	var created []string

	err := fs.WalkDir(g.fs, tmplDir, func(path string, d fs.DirEntry, err error) error {
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

		base := filepath.Base(path)
		if base == ".gitkeep" || base == ".DS_Store" || base == "Scheme.xcconfig.tmpl" {
			return nil
		}

		relPath, relErr := filepath.Rel(tmplDir, path)
		if relErr != nil {
			return relErr
		}

		destRel := strings.TrimSuffix(relPath, ".tmpl")

		destRel = mapToProjectPath(destRel, projectName)
		destPath := filepath.Join(projectDir, destRel)

		if strings.HasSuffix(path, ".tmpl") {
			if renderErr := g.renderer.Render(path, ctx, destPath); renderErr != nil {
				return renderErr
			}
		} else {
			if copyErr := g.copyEmbeddedFile(path, destPath); copyErr != nil {
				return copyErr
			}
		}

		created = append(created, destRel)
		return nil
	})

	return created, err
}

// copyEmbeddedFile reads a file from the embedded FS and writes it to the destination.
func (g *DefaultProjectGenerator) copyEmbeddedFile(srcPath string, destPath string) error {
	data, err := fs.ReadFile(g.fs, srcPath)
	if err != nil {
		return fmt.Errorf("reading embedded file %s: %w", srcPath, err)
	}
	return g.writer.CreateFile(destPath, data, 0644)
}

// initGit runs the git init + add + commit sequence.
func (g *DefaultProjectGenerator) initGit(dir string) (string, error) {
	if err := g.git.Init(dir); err != nil {
		return "", err
	}
	if err := g.git.AddAll(dir); err != nil {
		return "", err
	}
	if err := g.git.Commit(dir, "Initial commit"); err != nil {
		return "", err
	}
	return "git repository initialized with initial commit", nil
}

// schemeXcconfigContext holds per-scheme data for rendering Scheme.xcconfig.tmpl.
type schemeXcconfigContext struct {
	SchemeName        string
	EnvironmentName   string
	APISuffix         string
	BundleID          string
	BundleIDSuffix    string
	ProjectName       string
	ProductNameSuffix string
	SSLEnabled        string
	SSLHashes         string
}

// renderSchemeXcconfigs renders one xcconfig file per scheme using the Scheme.xcconfig.tmpl template.
func (g *DefaultProjectGenerator) renderSchemeXcconfigs(cfg config.ProjectConfig, projectDir string) ([]string, error) {
	var created []string
	tmplPath := "base/App/Config/Xcconfig/Scheme.xcconfig.tmpl"

	lastIdx := len(cfg.Schemes) - 1
	for i, scheme := range cfg.Schemes {
		isLast := i == lastIdx
		ctx := buildSchemeContext(scheme, cfg, isLast)

		destRel := filepath.Join(cfg.Name, "App", "Config", "Xcconfig", scheme+".xcconfig")
		destPath := filepath.Join(projectDir, destRel)

		if err := g.renderer.Render(tmplPath, ctx, destPath); err != nil {
			return nil, fmt.Errorf("rendering xcconfig for scheme %s: %w", scheme, err)
		}
		created = append(created, destRel)
	}
	return created, nil
}

// buildSchemeContext creates the template context for a given scheme.
// The last scheme is treated as "production" (no bundle suffix, SSL enabled).
func buildSchemeContext(scheme string, cfg config.ProjectConfig, isProduction bool) schemeXcconfigContext {
	ctx := schemeXcconfigContext{
		SchemeName:        scheme,
		EnvironmentName:   strings.ToLower(scheme),
		APISuffix:         "-" + strings.ToLower(scheme),
		BundleID:          cfg.BundleID,
		BundleIDSuffix:    "." + strings.ToLower(scheme),
		ProjectName:       cfg.Name,
		ProductNameSuffix: " " + strings.ToUpper(scheme),
		SSLEnabled:        "NO",
		SSLHashes:         "",
	}

	if isProduction {
		ctx.APISuffix = ""
		ctx.BundleIDSuffix = ""
		ctx.ProductNameSuffix = ""
		ctx.SSLEnabled = "YES"
		ctx.SSLHashes = "sha256/REPLACE_WITH_YOUR_PRODUCTION_CERTIFICATE_HASH="
	}

	return ctx
}
