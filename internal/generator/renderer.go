package generator

import (
	"bytes"
	"fmt"
	"io/fs"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/oscarcanton/anvilcli/internal/config"
)

// TemplateRenderer renders Go text/template files from the embedded FS.
type TemplateRenderer interface {
	// Render reads a single template from the embedded FS, executes it with ctx,
	// and writes the result to destPath on disk.
	Render(tmplPath string, ctx any, destPath string) error

	// RenderDir walks a template directory in the embedded FS, renders each
	// .tmpl file with ctx, and writes results to destDir. Returns the list of
	// created file paths.
	RenderDir(tmplDir string, ctx any, destDir string) ([]string, error)
}

// DefaultRenderer is the production implementation of TemplateRenderer.
type DefaultRenderer struct {
	fs     fs.FS
	writer FileWriter
}

// NewRenderer creates a DefaultRenderer backed by the given embedded FS.
func NewRenderer(embeddedFS fs.FS, w FileWriter) *DefaultRenderer {
	return &DefaultRenderer{fs: embeddedFS, writer: w}
}

// Render reads the template at tmplPath from the embedded FS, renders it with
// ctx, and writes the output to destPath. The .tmpl extension is stripped from
// the destination if present in tmplPath.
func (r *DefaultRenderer) Render(tmplPath string, ctx any, destPath string) error {
	data, err := fs.ReadFile(r.fs, tmplPath)
	if err != nil {
		return config.TemplateRenderError{
			TemplateName: tmplPath,
			Cause:        fmt.Errorf("reading template: %w", err),
		}
	}

	tmpl, err := template.New(filepath.Base(tmplPath)).Funcs(templateFuncs()).Parse(string(data))
	if err != nil {
		return config.TemplateRenderError{
			TemplateName: tmplPath,
			Cause:        fmt.Errorf("parsing template: %w", err),
		}
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, ctx); err != nil {
		return config.TemplateRenderError{
			TemplateName: tmplPath,
			Cause:        fmt.Errorf("executing template: %w", err),
		}
	}

	if err := r.writer.WriteFile(destPath, buf.Bytes()); err != nil {
		return config.TemplateRenderError{
			TemplateName: tmplPath,
			Cause:        fmt.Errorf("writing output: %w", err),
		}
	}

	return nil
}

// RenderDir walks tmplDir in the embedded FS, renders every .tmpl file with
// ctx, and writes results to destDir preserving the directory structure.
// Returns the list of absolute paths of created files.
func (r *DefaultRenderer) RenderDir(tmplDir string, ctx any, destDir string) ([]string, error) {
	var created []string

	err := fs.WalkDir(r.fs, tmplDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(tmplDir, path)
		if err != nil {
			return fmt.Errorf("computing relative path: %w", err)
		}

		if d.IsDir() {
			dirDest := filepath.Join(destDir, relPath)
			return r.writer.EnsureDir(dirDest)
		}

		if !strings.HasSuffix(path, ".tmpl") {
			return nil
		}

		outputName, err := renderFilename(relPath, ctx)
		if err != nil {
			return config.TemplateRenderError{
				TemplateName: path,
				Cause:        fmt.Errorf("rendering filename %q: %w", relPath, err),
			}
		}

		destPath := filepath.Join(destDir, outputName)
		if err := r.Render(path, ctx, destPath); err != nil {
			return err
		}

		created = append(created, destPath)
		return nil
	})

	if err != nil {
		return created, err
	}

	return created, nil
}

// renderFilename processes a template filename by:
// 1. Stripping the .tmpl extension
// 2. Executing any Go template expressions in the filename (e.g., {{.FeatureName}})
func renderFilename(name string, ctx any) (string, error) {
	name = strings.TrimSuffix(name, ".tmpl")

	if !strings.Contains(name, "{{") {
		return name, nil
	}

	tmpl, err := template.New("filename").Funcs(templateFuncs()).Parse(name)
	if err != nil {
		return "", fmt.Errorf("parsing filename template: %w", err)
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, ctx); err != nil {
		return "", fmt.Errorf("executing filename template: %w", err)
	}

	return buf.String(), nil
}

// templateFuncs returns the custom FuncMap registered for all templates.
func templateFuncs() template.FuncMap {
	return template.FuncMap{
		"lower":  strings.ToLower,
		"upper":  strings.ToUpper,
		"pascal": config.ToPascalCase,
		"camel":  config.ToCamelCase,
		"snake":  config.ToSnakeCase,
		"plural": simplePlural,
		"join":   strings.Join,
		"sub":    func(a, b int) int { return a - b },
		"last": func(s []string) string {
			if len(s) == 0 {
				return ""
			}
			return s[len(s)-1]
		},
	}
}

// simplePlural adds an "s" to the end of a word.
// Handles basic English pluralization (not exhaustive).
func simplePlural(s string) string {
	if s == "" {
		return ""
	}
	lower := strings.ToLower(s)
	switch {
	case strings.HasSuffix(lower, "s"),
		strings.HasSuffix(lower, "x"),
		strings.HasSuffix(lower, "z"),
		strings.HasSuffix(lower, "sh"),
		strings.HasSuffix(lower, "ch"):
		return s + "es"
	case strings.HasSuffix(lower, "y") && len(s) > 1 && !isVowel(rune(lower[len(lower)-2])):
		return s[:len(s)-1] + "ies"
	default:
		return s + "s"
	}
}

func isVowel(r rune) bool {
	switch r {
	case 'a', 'e', 'i', 'o', 'u':
		return true
	}
	return false
}
