package generator

import (
	"bytes"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/magnoscg/anvil/internal/config"
)

// PackRenderer renders AI coding packs into a project directory.
// Each pack can contribute templates, docs, commands, skills, workflows,
// settings fragments, and CLAUDE.md sections.
type PackRenderer interface {
	// RenderPacks processes each pack slug in order: renders templates, copies
	// files, merges settings, and composes the final CLAUDE.md. Returns the
	// list of created file paths relative to projectDir.
	RenderPacks(packs []string, skillsScope string, ctx any, projectDir string) ([]string, error)
}

// DefaultPackRenderer is the production implementation of PackRenderer.
type DefaultPackRenderer struct {
	fs       fs.FS
	renderer TemplateRenderer
	writer   FileWriter
	merger   SettingsMerger
}

// NewPackRenderer creates a DefaultPackRenderer with the given dependencies.
func NewPackRenderer(embeddedFS fs.FS, renderer TemplateRenderer, writer FileWriter, merger SettingsMerger) *DefaultPackRenderer {
	return &DefaultPackRenderer{
		fs:       embeddedFS,
		renderer: renderer,
		writer:   writer,
		merger:   merger,
	}
}

// RenderPacks processes each pack in the order provided. It builds a composite
// CLAUDE.md from base and section templates, copies docs/commands/skills, renders
// dev/plan/workflow templates, and merges settings.json fragments.
func (p *DefaultPackRenderer) RenderPacks(packs []string, skillsScope string, ctx any, projectDir string) ([]string, error) {
	var created []string
	var claudeBuf bytes.Buffer

	for _, slug := range packs {
		packDir := filepath.Join("ai-packs", slug)

		// Verify pack directory exists in embedded FS
		if _, err := fs.Stat(p.fs, packDir); err != nil {
			return created, config.PackNotFoundError{Slug: slug}
		}

		// a. CLAUDE.md.tmpl (base pack — full CLAUDE.md template)
		baseTmpl := filepath.Join(packDir, "CLAUDE.md.tmpl")
		if content, err := p.renderTemplate(baseTmpl, ctx); err == nil {
			claudeBuf.WriteString(content)
		}

		// b. CLAUDE-section.md.tmpl (section to append)
		sectionTmpl := filepath.Join(packDir, "CLAUDE-section.md.tmpl")
		if content, err := p.renderTemplate(sectionTmpl, ctx); err == nil {
			if claudeBuf.Len() > 0 && !strings.HasSuffix(claudeBuf.String(), "\n\n") {
				claudeBuf.WriteString("\n")
			}
			claudeBuf.WriteString(content)
		}

		// c. docs/ — copy verbatim to .claude/docs/
		docsDir := filepath.Join(packDir, "docs")
		if docsCreated, err := p.copyDir(docsDir, filepath.Join(projectDir, ".claude", "docs")); err == nil {
			created = append(created, docsCreated...)
		}

		// d. commands/ — copy verbatim to .claude/commands/
		commandsDir := filepath.Join(packDir, "commands")
		if cmdsCreated, err := p.copyDir(commandsDir, filepath.Join(projectDir, ".claude", "commands")); err == nil {
			created = append(created, cmdsCreated...)
		}

		// d2. agents/ — copy verbatim to .claude/agents/
		agentsDir := filepath.Join(packDir, "agents")
		if agentsCreated, err := p.copyDir(agentsDir, filepath.Join(projectDir, ".claude", "agents")); err == nil {
			created = append(created, agentsCreated...)
		}

		// e. dev/ — render templates to .dev/
		devDir := filepath.Join(packDir, "dev")
		if devCreated, err := p.renderDir(devDir, ctx, filepath.Join(projectDir, ".dev")); err == nil {
			created = append(created, devCreated...)
		}

		// f. plan/ — render templates to plan/
		planDir := filepath.Join(packDir, "plan")
		if planCreated, err := p.renderDir(planDir, ctx, filepath.Join(projectDir, "plan")); err == nil {
			created = append(created, planCreated...)
		}

		// g. skills/ — copy to project or global scope
		skillsDir := filepath.Join(packDir, "skills")
		if skillsCreated, err := p.copySkills(skillsDir, skillsScope, projectDir); err == nil {
			created = append(created, skillsCreated...)
		}

		// h. tutorials/ — copy verbatim to ~/.claude/tutorials/ (always global)
		tutorialsDir := filepath.Join(packDir, "tutorials")
		if _, err := fs.Stat(p.fs, tutorialsDir); err == nil {
			homeDir, _ := os.UserHomeDir()
			globalTutorialsDir := filepath.Join(homeDir, ".claude", "tutorials")
			if tutCreated, err := p.copyDir(tutorialsDir, globalTutorialsDir); err == nil {
				created = append(created, tutCreated...)
			}
		}

		// i. settings-merge.json — merge into .claude/settings.json
		settingsFragment := filepath.Join(packDir, "settings-merge.json")
		if _, err := fs.Stat(p.fs, settingsFragment); err == nil {
			settingsPath := filepath.Join(projectDir, ".claude", "settings.json")
			if err := p.merger.Merge(settingsPath, settingsFragment); err != nil {
				return created, fmt.Errorf("merging settings for pack %s: %w", slug, err)
			}
			created = append(created, ".claude/settings.json")
		}

		// i. workflows/ — render templates to .github/workflows/
		workflowsDir := filepath.Join(packDir, "workflows")
		if wfCreated, err := p.renderDir(workflowsDir, ctx, filepath.Join(projectDir, ".github", "workflows")); err == nil {
			created = append(created, wfCreated...)
		}
	}

	// Write the composed CLAUDE.md to project root
	if claudeBuf.Len() > 0 {
		claudePath := filepath.Join(projectDir, "CLAUDE.md")
		if err := p.writer.WriteFile(claudePath, claudeBuf.Bytes()); err != nil {
			return created, fmt.Errorf("writing CLAUDE.md: %w", err)
		}
		created = append(created, "CLAUDE.md")
	}

	return created, nil
}

// renderTemplate reads a template from the embedded FS, renders it with ctx,
// and returns the result as a string. Returns an error if the template does
// not exist or fails to parse/execute.
func (p *DefaultPackRenderer) renderTemplate(tmplPath string, ctx any) (string, error) {
	data, err := fs.ReadFile(p.fs, tmplPath)
	if err != nil {
		return "", err
	}

	tmpl, err := template.New(filepath.Base(tmplPath)).Funcs(templateFuncs()).Parse(string(data))
	if err != nil {
		return "", config.TemplateRenderError{
			TemplateName: tmplPath,
			Cause:        fmt.Errorf("parsing template: %w", err),
		}
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, ctx); err != nil {
		return "", config.TemplateRenderError{
			TemplateName: tmplPath,
			Cause:        fmt.Errorf("executing template: %w", err),
		}
	}

	return buf.String(), nil
}

// copyDir copies all files from srcDir (in the embedded FS) to destDir on disk,
// preserving directory structure. Returns the list of created paths.
func (p *DefaultPackRenderer) copyDir(srcDir string, destDir string) ([]string, error) {
	var created []string

	// Check if directory exists in embedded FS
	if _, err := fs.Stat(p.fs, srcDir); err != nil {
		return nil, err
	}

	err := fs.WalkDir(p.fs, srcDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		relPath, relErr := filepath.Rel(srcDir, path)
		if relErr != nil {
			return relErr
		}

		destPath := filepath.Join(destDir, relPath)

		if d.IsDir() {
			return p.writer.EnsureDir(destPath)
		}

		// Skip hidden files
		base := filepath.Base(path)
		if base == ".gitkeep" || base == ".DS_Store" {
			return nil
		}

		data, readErr := fs.ReadFile(p.fs, path)
		if readErr != nil {
			return fmt.Errorf("reading %s: %w", path, readErr)
		}

		if writeErr := p.writer.WriteFile(destPath, data); writeErr != nil {
			return fmt.Errorf("writing %s: %w", destPath, writeErr)
		}

		created = append(created, relPath)
		return nil
	})

	return created, err
}

// renderDir walks a template directory in the embedded FS, renders .tmpl files
// with ctx, copies non-.tmpl files verbatim, and writes results to destDir.
func (p *DefaultPackRenderer) renderDir(srcDir string, ctx any, destDir string) ([]string, error) {
	var created []string

	// Check if directory exists
	if _, err := fs.Stat(p.fs, srcDir); err != nil {
		return nil, err
	}

	err := fs.WalkDir(p.fs, srcDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		relPath, relErr := filepath.Rel(srcDir, path)
		if relErr != nil {
			return relErr
		}

		destPath := filepath.Join(destDir, relPath)

		if d.IsDir() {
			return p.writer.EnsureDir(destPath)
		}

		base := filepath.Base(path)
		if base == ".gitkeep" || base == ".DS_Store" {
			return nil
		}

		if strings.HasSuffix(path, ".tmpl") {
			// Render template
			destPath = strings.TrimSuffix(destPath, ".tmpl")
			if renderErr := p.renderer.Render(path, ctx, destPath); renderErr != nil {
				return renderErr
			}
			created = append(created, strings.TrimSuffix(relPath, ".tmpl"))
		} else {
			// Copy verbatim
			data, readErr := fs.ReadFile(p.fs, path)
			if readErr != nil {
				return fmt.Errorf("reading %s: %w", path, readErr)
			}
			if writeErr := p.writer.WriteFile(destPath, data); writeErr != nil {
				return fmt.Errorf("writing %s: %w", destPath, writeErr)
			}
			created = append(created, relPath)
		}

		return nil
	})

	return created, err
}

// copySkills copies skill directories from the embedded FS to the appropriate
// destination based on skillsScope ("project" or "global"). Skills in project
// scope go to <projectDir>/.claude/skills/, global scope to ~/.claude/skills/.
// If a skill directory already exists at the global destination, it is skipped.
func (p *DefaultPackRenderer) copySkills(srcDir string, skillsScope string, projectDir string) ([]string, error) {
	// Check if skills directory exists
	if _, err := fs.Stat(p.fs, srcDir); err != nil {
		return nil, err
	}

	var destBase string
	if skillsScope == "global" {
		home, err := os.UserHomeDir()
		if err != nil {
			return nil, fmt.Errorf("determining home directory: %w", err)
		}
		destBase = filepath.Join(home, ".claude", "skills")
	} else {
		destBase = filepath.Join(projectDir, ".claude", "skills")
	}

	var created []string

	// Walk top-level entries in skills/ to find skill directories
	entries, err := fs.ReadDir(p.fs, srcDir)
	if err != nil {
		return nil, fmt.Errorf("reading skills directory: %w", err)
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		skillName := entry.Name()
		destSkillDir := filepath.Join(destBase, skillName)

		// If global scope and already exists, skip silently
		if skillsScope == "global" {
			if _, err := os.Stat(destSkillDir); err == nil {
				continue
			}
		}

		// Copy entire skill directory
		skillSrcDir := filepath.Join(srcDir, skillName)
		copied, copyErr := p.copyDir(skillSrcDir, destSkillDir)
		if copyErr != nil {
			return created, fmt.Errorf("copying skill %s: %w", skillName, copyErr)
		}

		for _, f := range copied {
			created = append(created, filepath.Join("skills", skillName, f))
		}
	}

	return created, nil
}
