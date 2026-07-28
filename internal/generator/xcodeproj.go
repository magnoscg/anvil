package generator

import (
	"context"
	"fmt"
	"io/fs"
	"path/filepath"

	"github.com/magnoscg/anvil/internal/config"
)

// XcodeProjGenerator renders a complete .xcodeproj bundle from templates.
type XcodeProjGenerator interface {
	Generate(ctx context.Context, projectDir string, cfg config.ProjectConfig) (string, error)
}

// DefaultXcodeProjGenerator is the production implementation that renders
// project.pbxproj, workspace data, and scheme files from embedded templates.
type DefaultXcodeProjGenerator struct {
	renderer TemplateRenderer
	writer   FileWriter
	fs       fs.FS
}

// NewXcodeProjGenerator creates a DefaultXcodeProjGenerator with the given dependencies.
func NewXcodeProjGenerator(renderer TemplateRenderer, writer FileWriter, embeddedFS fs.FS) *DefaultXcodeProjGenerator {
	return &DefaultXcodeProjGenerator{
		renderer: renderer,
		writer:   writer,
		fs:       embeddedFS,
	}
}

// Generate builds the .xcodeproj bundle for the given project configuration.
// It creates the directory structure, renders the pbxproj, workspace, and scheme
// templates, and returns a summary string on success or an XcodeProjectError on failure.
func (g *DefaultXcodeProjGenerator) Generate(_ context.Context, projectDir string, cfg config.ProjectConfig) (string, error) {
	pbxCtx := NewPbxprojContext(cfg)

	xcodeprojDir := filepath.Join(projectDir, cfg.Name+".xcodeproj")
	workspaceDir := filepath.Join(xcodeprojDir, "project.xcworkspace")
	schemesDir := filepath.Join(xcodeprojDir, "xcshareddata", "xcschemes")

	for _, dir := range []string{xcodeprojDir, workspaceDir, schemesDir} {
		if err := g.writer.EnsureDir(dir); err != nil {
			return "", config.XcodeProjectError{
				Phase: "create directories",
				Cause: err,
			}
		}
	}

	pbxprojPath := filepath.Join(xcodeprojDir, "project.pbxproj")
	if err := g.renderer.Render("base/xcodeproj/project.pbxproj.tmpl", pbxCtx, pbxprojPath); err != nil {
		return "", config.XcodeProjectError{
			Phase: "render project.pbxproj",
			Cause: err,
		}
	}

	wsCtx := NewWorkspaceContext(cfg)
	wsPath := filepath.Join(workspaceDir, "contents.xcworkspacedata")
	if err := g.renderer.Render("base/xcodeproj/contents.xcworkspacedata.tmpl", wsCtx, wsPath); err != nil {
		return "", config.XcodeProjectError{
			Phase: "render contents.xcworkspacedata",
			Cause: err,
		}
	}

	schemeContexts := NewXcschemeContexts(cfg, pbxCtx.UUIDs)
	for _, schemeCtx := range schemeContexts {
		schemePath := filepath.Join(schemesDir, schemeCtx.SchemeName+".xcscheme")
		if err := g.renderer.Render("base/xcodeproj/xcscheme.tmpl", schemeCtx, schemePath); err != nil {
			return "", config.XcodeProjectError{
				Phase: fmt.Sprintf("render scheme %s", schemeCtx.SchemeName),
				Cause: err,
			}
		}
	}

	return fmt.Sprintf("generated %s.xcodeproj (%d schemes)", cfg.Name, len(cfg.Schemes)), nil
}
