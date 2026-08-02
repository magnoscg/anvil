package generator

import (
	"bytes"
	"errors"
	"fmt"
	"io/fs"
	"os"
	pathpkg "path"
	"path/filepath"
	"sort"
	"strings"
	"text/template"

	"github.com/magnoscg/anvil/internal/config"
)

// PackRenderer installs AI coding packs through a non-mutating plan and
// preflight before applying any filesystem changes.
type PackRenderer interface {
	PlanPacks(packs []string, skillsScope string, ctx any, projectDir string) (PackInstallPlan, error)
	Preflight(plan *PackInstallPlan) error
	Apply(plan PackInstallPlan) ([]string, error)
}

type plannedFile struct {
	root        string
	destination string
	displayPath string
	sourcePath  string
	content     []byte
}

type plannedDirectory struct {
	root        string
	destination string
	displayPath string
	sourcePath  string
}

type plannedSettings struct {
	root          string
	destination   string
	displayPath   string
	fragmentPaths []string
	content       []byte
	mode          fs.FileMode
	existed       bool
	original      []byte
}

// PackInstallPlan contains fully rendered pack output and no disk mutations.
type PackInstallPlan struct {
	projectRoot   string
	files         []plannedFile
	exclusiveDirs []plannedDirectory
	settings      *plannedSettings
	preflighted   bool
}

// DefaultPackRenderer is the production pack planner and installer.
type DefaultPackRenderer struct {
	fs     fs.FS
	writer FileWriter
	merger SettingsMerger
}

// NewPackRenderer creates a pack installer. Rendering is performed in memory;
// the renderer argument remains for compatibility with existing construction.
func NewPackRenderer(embeddedFS fs.FS, _ TemplateRenderer, writer FileWriter, merger SettingsMerger) *DefaultPackRenderer {
	return &DefaultPackRenderer{
		fs:     embeddedFS,
		writer: writer,
		merger: merger,
	}
}

// RenderPacks is a convenience wrapper used by direct callers and tests.
func (p *DefaultPackRenderer) RenderPacks(packs []string, skillsScope string, ctx any, projectDir string) ([]string, error) {
	plan, err := p.PlanPacks(packs, skillsScope, ctx, projectDir)
	if err != nil {
		return nil, err
	}
	if err := p.Preflight(&plan); err != nil {
		return nil, err
	}
	return p.Apply(plan)
}

// PlanPacks renders every selected pack in memory and enumerates all outputs.
func (p *DefaultPackRenderer) PlanPacks(packs []string, skillsScope string, ctx any, projectDir string) (PackInstallPlan, error) {
	projectRoot, err := canonicalRoot(projectDir, true)
	if err != nil {
		return PackInstallPlan{}, fmt.Errorf("resolving project root: %w", err)
	}

	plan := PackInstallPlan{projectRoot: projectRoot}
	var claudeContent bytes.Buffer
	var noticeContent bytes.Buffer
	var settingsFragments []string

	for _, slug := range packs {
		packDir := pathpkg.Join("ai-packs", slug)
		info, err := fs.Stat(p.fs, packDir)
		if err != nil {
			if errors.Is(err, fs.ErrNotExist) {
				return PackInstallPlan{}, config.PackNotFoundError{Slug: slug}
			}
			return PackInstallPlan{}, fmt.Errorf("checking pack %s: %w", slug, err)
		}
		if !info.IsDir() {
			return PackInstallPlan{}, fmt.Errorf("pack %s is not a directory", slug)
		}

		baseTemplate := pathpkg.Join(packDir, "CLAUDE.md.tmpl")
		if rendered, present, err := p.renderOptionalTemplate(baseTemplate, ctx); err != nil {
			return PackInstallPlan{}, err
		} else if present {
			claudeContent.Write(rendered)
		}

		sectionTemplate := pathpkg.Join(packDir, "CLAUDE-section.md.tmpl")
		if rendered, present, err := p.renderOptionalTemplate(sectionTemplate, ctx); err != nil {
			return PackInstallPlan{}, err
		} else if present {
			appendComposedContent(&claudeContent, rendered)
		}

		if err := p.planOptionalDirectory(&plan, pathpkg.Join(packDir, "docs"), projectRoot, filepath.Join(".claude", "docs"), filepath.Join(".claude", "docs"), ctx, false); err != nil {
			return PackInstallPlan{}, err
		}
		if err := p.planOptionalDirectory(&plan, pathpkg.Join(packDir, "commands"), projectRoot, filepath.Join(".claude", "commands"), filepath.Join(".claude", "commands"), ctx, false); err != nil {
			return PackInstallPlan{}, err
		}
		if err := p.planOptionalDirectory(&plan, pathpkg.Join(packDir, "agents"), projectRoot, filepath.Join(".claude", "agents"), filepath.Join(".claude", "agents"), ctx, false); err != nil {
			return PackInstallPlan{}, err
		}
		if err := p.planOptionalDirectory(&plan, pathpkg.Join(packDir, "dev"), projectRoot, ".dev", ".dev", ctx, true); err != nil {
			return PackInstallPlan{}, err
		}
		if err := p.planOptionalDirectory(&plan, pathpkg.Join(packDir, "plan"), projectRoot, "plan", "plan", ctx, true); err != nil {
			return PackInstallPlan{}, err
		}
		if err := p.planSkills(&plan, pathpkg.Join(packDir, "skills"), skillsScope, projectRoot, ctx); err != nil {
			return PackInstallPlan{}, err
		}
		if err := p.planTutorials(&plan, pathpkg.Join(packDir, "tutorials"), ctx); err != nil {
			return PackInstallPlan{}, err
		}

		settingsFragment := pathpkg.Join(packDir, "settings-merge.json")
		if present, err := optionalFileExists(p.fs, settingsFragment); err != nil {
			return PackInstallPlan{}, fmt.Errorf("checking settings for pack %s: %w", slug, err)
		} else if present {
			settingsFragments = append(settingsFragments, settingsFragment)
		}

		if err := p.planOptionalDirectory(&plan, pathpkg.Join(packDir, "workflows"), projectRoot, filepath.Join(".github", "workflows"), filepath.Join(".github", "workflows"), ctx, true); err != nil {
			return PackInstallPlan{}, err
		}

		noticePath := pathpkg.Join(packDir, "THIRD_PARTY_NOTICES.md")
		if data, present, err := readOptionalFile(p.fs, noticePath); err != nil {
			return PackInstallPlan{}, fmt.Errorf("reading notices for pack %s: %w", slug, err)
		} else if present {
			appendComposedContent(&noticeContent, data)
		}
	}

	if claudeContent.Len() > 0 {
		if err := addPlannedFile(&plan, projectRoot, "CLAUDE.md", "CLAUDE.md", "composed CLAUDE.md", claudeContent.Bytes()); err != nil {
			return PackInstallPlan{}, err
		}
	}
	if noticeContent.Len() > 0 {
		relative := filepath.Join(".claude", "THIRD_PARTY_NOTICES.md")
		if err := addPlannedFile(&plan, projectRoot, relative, relative, "composed third-party notices", noticeContent.Bytes()); err != nil {
			return PackInstallPlan{}, err
		}
	}
	if len(settingsFragments) > 0 {
		relative := filepath.Join(".claude", "settings.json")
		destination, err := safeDestination(projectRoot, relative)
		if err != nil {
			return PackInstallPlan{}, err
		}
		plan.settings = &plannedSettings{
			root:          projectRoot,
			destination:   destination,
			displayPath:   filepath.ToSlash(relative),
			fragmentPaths: append([]string(nil), settingsFragments...),
			mode:          0644,
		}
	}

	return plan, nil
}

// Preflight validates every output and gathers all collisions before Apply.
func (p *DefaultPackRenderer) Preflight(plan *PackInstallPlan) error {
	if plan == nil {
		return fmt.Errorf("pack install plan is nil")
	}
	plan.preflighted = false

	conflicts := make(map[string]struct{})
	seenTargets := make(map[string]string)

	checkTarget := func(root, destination, displayPath string, allowExistingRegular bool) (bool, error) {
		if err := validateContainedPath(root, destination); err != nil {
			return false, err
		}

		key := filepath.Clean(destination)
		if previous, exists := seenTargets[key]; exists {
			conflicts[previous] = struct{}{}
			conflicts[displayPath] = struct{}{}
		} else {
			seenTargets[key] = displayPath
		}

		unsafe, err := firstUnsafeAncestor(root, destination)
		if err != nil {
			return false, err
		}
		if unsafe != "" {
			conflicts[displayPath] = struct{}{}
			return false, nil
		}

		info, err := os.Lstat(destination)
		if err == nil {
			if allowExistingRegular && info.Mode().IsRegular() && info.Mode()&os.ModeSymlink == 0 {
				return true, nil
			}
			conflicts[displayPath] = struct{}{}
			return false, nil
		}
		if !os.IsNotExist(err) {
			return false, fmt.Errorf("checking destination %s: %w", destination, err)
		}
		return false, nil
	}

	for _, directory := range plan.exclusiveDirs {
		if _, err := checkTarget(directory.root, directory.destination, directory.displayPath, false); err != nil {
			return err
		}
	}
	for _, file := range plan.files {
		if _, err := checkTarget(file.root, file.destination, file.displayPath, false); err != nil {
			return err
		}
	}

	settingsSafe := true
	if plan.settings != nil {
		plan.settings.existed = false
		plan.settings.content = nil
		plan.settings.original = nil
		exists, err := checkTarget(plan.settings.root, plan.settings.destination, plan.settings.displayPath, true)
		if err != nil {
			return err
		}
		if _, conflicted := conflicts[plan.settings.displayPath]; conflicted {
			settingsSafe = false
		}

		var existingData []byte
		if settingsSafe && exists {
			info, err := os.Lstat(plan.settings.destination)
			if err != nil {
				return fmt.Errorf("checking settings %s: %w", plan.settings.destination, err)
			}
			plan.settings.mode = info.Mode().Perm()
			plan.settings.existed = true
			existingData, err = os.ReadFile(plan.settings.destination)
			if err != nil {
				return config.SettingsMergeError{Path: plan.settings.destination, Cause: fmt.Errorf("reading existing settings: %w", err)}
			}
			plan.settings.original = append([]byte(nil), existingData...)
		}
		if settingsSafe {
			merged, err := p.merger.Merge(plan.settings.destination, existingData, plan.settings.fragmentPaths)
			if err != nil {
				return err
			}
			plan.settings.content = merged
		}
	}

	if len(conflicts) > 0 {
		paths := make([]string, 0, len(conflicts))
		for path := range conflicts {
			paths = append(paths, filepath.ToSlash(path))
		}
		sort.Strings(paths)
		return config.InstallConflictError{Paths: paths}
	}

	plan.preflighted = true
	return nil
}

// Apply creates planned files exclusively and writes settings atomically last.
func (p *DefaultPackRenderer) Apply(plan PackInstallPlan) ([]string, error) {
	if !plan.preflighted {
		return nil, fmt.Errorf("pack install plan has not passed preflight")
	}

	directories := append([]plannedDirectory(nil), plan.exclusiveDirs...)
	files := append([]plannedFile(nil), plan.files...)
	sort.Slice(directories, func(i, j int) bool { return directories[i].destination < directories[j].destination })
	sort.Slice(files, func(i, j int) bool { return files[i].destination < files[j].destination })

	var createdFiles []string
	var createdDirs []string
	createdDirSet := make(map[string]struct{})
	var result []string

	fail := func(original error) ([]string, error) {
		if rollbackErr := rollbackInstall(createdFiles, createdDirs); rollbackErr != nil {
			return nil, config.RollbackError{OriginalError: original, RollbackCause: rollbackErr}
		}
		return nil, original
	}

	for _, directory := range directories {
		if err := ensureTrackedDirectory(filepath.Dir(directory.destination), &createdDirs, createdDirSet); err != nil {
			return fail(fmt.Errorf("creating parent for %s: %w", directory.displayPath, err))
		}
		if err := p.writer.CreateDir(directory.destination); err != nil {
			return fail(fmt.Errorf("creating skill directory %s: %w", directory.displayPath, err))
		}
		createdDirs = append(createdDirs, directory.destination)
		createdDirSet[directory.destination] = struct{}{}
	}

	for _, file := range files {
		if err := ensureTrackedDirectory(filepath.Dir(file.destination), &createdDirs, createdDirSet); err != nil {
			return fail(fmt.Errorf("creating parent for %s: %w", file.displayPath, err))
		}
		if err := p.writer.CreateFile(file.destination, file.content, 0644); err != nil {
			return fail(fmt.Errorf("creating %s from %s: %w", file.displayPath, file.sourcePath, err))
		}
		createdFiles = append(createdFiles, file.destination)
		result = append(result, filepath.ToSlash(file.displayPath))
	}

	if plan.settings != nil {
		if err := ensureTrackedDirectory(filepath.Dir(plan.settings.destination), &createdDirs, createdDirSet); err != nil {
			return fail(fmt.Errorf("creating settings parent: %w", err))
		}
		var err error
		if plan.settings.existed {
			err = validateSettingsSnapshot(plan.settings)
			if err == nil {
				err = p.writer.AtomicReplaceFile(plan.settings.destination, plan.settings.content, plan.settings.mode)
			}
		} else {
			err = p.writer.AtomicCreateFile(plan.settings.destination, plan.settings.content, plan.settings.mode)
		}
		if err != nil {
			return fail(config.SettingsMergeError{Path: plan.settings.destination, Cause: err})
		}
		result = append(result, filepath.ToSlash(plan.settings.displayPath))
	}

	return result, nil
}

func validateSettingsSnapshot(settings *plannedSettings) error {
	info, err := os.Lstat(settings.destination)
	if err != nil {
		return fmt.Errorf("settings changed after preflight: %w", err)
	}
	if info.Mode()&os.ModeSymlink != 0 || !info.Mode().IsRegular() {
		return fmt.Errorf("settings changed after preflight: target is not a regular file")
	}
	if info.Mode().Perm() != settings.mode {
		return fmt.Errorf("settings changed after preflight: permissions changed")
	}
	content, err := os.ReadFile(settings.destination)
	if err != nil {
		return fmt.Errorf("settings changed after preflight: %w", err)
	}
	if !bytes.Equal(content, settings.original) {
		return fmt.Errorf("settings changed after preflight: content changed")
	}
	return nil
}

func (p *DefaultPackRenderer) planOptionalDirectory(plan *PackInstallPlan, sourceDir, root, destinationPrefix, displayPrefix string, ctx any, renderTemplates bool) error {
	info, err := fs.Stat(p.fs, sourceDir)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil
		}
		return fmt.Errorf("checking optional pack directory %s: %w", sourceDir, err)
	}
	if !info.IsDir() {
		return fmt.Errorf("optional pack path %s is not a directory", sourceDir)
	}
	return p.planDirectory(plan, sourceDir, root, destinationPrefix, displayPrefix, ctx, renderTemplates)
}

func (p *DefaultPackRenderer) planDirectory(plan *PackInstallPlan, sourceDir, root, destinationPrefix, displayPrefix string, ctx any, renderTemplates bool) error {
	return fs.WalkDir(p.fs, sourceDir, func(sourcePath string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() {
			return nil
		}
		if entry.Name() == ".gitkeep" || entry.Name() == ".DS_Store" {
			return nil
		}

		relative := strings.TrimPrefix(sourcePath, sourceDir+"/")
		if relative == sourcePath || relative == "" {
			return fmt.Errorf("source %s is not below directory %s", sourcePath, sourceDir)
		}
		destinationRelative := filepath.Join(destinationPrefix, filepath.FromSlash(relative))
		displayRelative := filepath.Join(displayPrefix, filepath.FromSlash(relative))

		var content []byte
		var err error
		if renderTemplates && strings.HasSuffix(sourcePath, ".tmpl") {
			content, err = p.renderTemplate(sourcePath, ctx)
			destinationRelative = strings.TrimSuffix(destinationRelative, ".tmpl")
			displayRelative = strings.TrimSuffix(displayRelative, ".tmpl")
		} else {
			content, err = fs.ReadFile(p.fs, sourcePath)
		}
		if err != nil {
			return fmt.Errorf("preparing %s: %w", sourcePath, err)
		}

		return addPlannedFile(plan, root, destinationRelative, displayRelative, sourcePath, content)
	})
}

func (p *DefaultPackRenderer) planSkills(plan *PackInstallPlan, sourceDir, skillsScope, projectRoot string, ctx any) error {
	info, err := fs.Stat(p.fs, sourceDir)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil
		}
		return fmt.Errorf("checking skills directory %s: %w", sourceDir, err)
	}
	if !info.IsDir() {
		return fmt.Errorf("skills path %s is not a directory", sourceDir)
	}

	root := projectRoot
	destinationBase := filepath.Join(".claude", "skills")
	displayBase := destinationBase
	if skillsScope == "global" {
		home, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("determining home directory: %w", err)
		}
		root, err = canonicalRoot(filepath.Join(home, ".claude", "skills"), false)
		if err != nil {
			return fmt.Errorf("resolving global skills root: %w", err)
		}
		destinationBase = ""
		displayBase = filepath.Join("~", ".claude", "skills")
	}

	entries, err := fs.ReadDir(p.fs, sourceDir)
	if err != nil {
		return fmt.Errorf("reading skills directory %s: %w", sourceDir, err)
	}
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		skillName := entry.Name()
		destinationRelative := filepath.Join(destinationBase, skillName)
		displayRelative := filepath.Join(displayBase, skillName)
		destination, err := safeDestination(root, destinationRelative)
		if err != nil {
			return err
		}
		plan.exclusiveDirs = append(plan.exclusiveDirs, plannedDirectory{
			root:        root,
			destination: destination,
			displayPath: filepath.ToSlash(displayRelative),
			sourcePath:  pathpkg.Join(sourceDir, skillName),
		})

		if err := p.planDirectory(plan, pathpkg.Join(sourceDir, skillName), root, destinationRelative, displayRelative, ctx, false); err != nil {
			return fmt.Errorf("planning skill %s: %w", skillName, err)
		}
	}
	return nil
}

func (p *DefaultPackRenderer) planTutorials(plan *PackInstallPlan, sourceDir string, ctx any) error {
	info, err := fs.Stat(p.fs, sourceDir)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil
		}
		return fmt.Errorf("checking tutorials directory %s: %w", sourceDir, err)
	}
	if !info.IsDir() {
		return fmt.Errorf("tutorials path %s is not a directory", sourceDir)
	}

	home, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("determining home directory: %w", err)
	}
	root, err := canonicalRoot(filepath.Join(home, ".claude", "tutorials"), false)
	if err != nil {
		return fmt.Errorf("resolving global tutorials root: %w", err)
	}
	return p.planDirectory(plan, sourceDir, root, "", filepath.Join("~", ".claude", "tutorials"), ctx, false)
}

func (p *DefaultPackRenderer) renderOptionalTemplate(templatePath string, ctx any) ([]byte, bool, error) {
	data, err := fs.ReadFile(p.fs, templatePath)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil, false, nil
		}
		return nil, false, fmt.Errorf("reading optional template %s: %w", templatePath, err)
	}
	rendered, err := renderTemplateData(templatePath, data, ctx)
	if err != nil {
		return nil, false, err
	}
	return rendered, true, nil
}

func (p *DefaultPackRenderer) renderTemplate(templatePath string, ctx any) ([]byte, error) {
	data, err := fs.ReadFile(p.fs, templatePath)
	if err != nil {
		return nil, err
	}
	return renderTemplateData(templatePath, data, ctx)
}

func renderTemplateData(templatePath string, data []byte, ctx any) ([]byte, error) {
	tmpl, err := template.New(pathpkg.Base(templatePath)).Funcs(templateFuncs()).Parse(string(data))
	if err != nil {
		return nil, config.TemplateRenderError{TemplateName: templatePath, Cause: fmt.Errorf("parsing template: %w", err)}
	}
	var rendered bytes.Buffer
	if err := tmpl.Execute(&rendered, ctx); err != nil {
		return nil, config.TemplateRenderError{TemplateName: templatePath, Cause: fmt.Errorf("executing template: %w", err)}
	}
	return rendered.Bytes(), nil
}

func addPlannedFile(plan *PackInstallPlan, root, relative, displayPath, sourcePath string, content []byte) error {
	destination, err := safeDestination(root, relative)
	if err != nil {
		return fmt.Errorf("planning %s: %w", sourcePath, err)
	}
	plan.files = append(plan.files, plannedFile{
		root:        root,
		destination: destination,
		displayPath: filepath.ToSlash(displayPath),
		sourcePath:  sourcePath,
		content:     append([]byte(nil), content...),
	})
	return nil
}

func appendComposedContent(destination *bytes.Buffer, content []byte) {
	if destination.Len() > 0 && !bytes.HasSuffix(destination.Bytes(), []byte("\n\n")) {
		destination.WriteByte('\n')
	}
	destination.Write(content)
}

func optionalFileExists(filesystem fs.FS, filePath string) (bool, error) {
	info, err := fs.Stat(filesystem, filePath)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return false, nil
		}
		return false, err
	}
	if !info.Mode().IsRegular() {
		return false, fmt.Errorf("%s is not a regular file", filePath)
	}
	return true, nil
}

func readOptionalFile(filesystem fs.FS, filePath string) ([]byte, bool, error) {
	data, err := fs.ReadFile(filesystem, filePath)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil, false, nil
		}
		return nil, false, err
	}
	return data, true, nil
}

func canonicalRoot(root string, mustExist bool) (string, error) {
	absolute, err := filepath.Abs(root)
	if err != nil {
		return "", err
	}
	absolute = filepath.Clean(absolute)

	current := absolute
	var missing []string
	for {
		_, err := os.Lstat(current)
		if err == nil {
			resolved, err := filepath.EvalSymlinks(current)
			if err != nil {
				return "", err
			}
			resolvedInfo, err := os.Stat(resolved)
			if err != nil {
				return "", err
			}
			if !resolvedInfo.IsDir() {
				return "", fmt.Errorf("path component %s is not a directory", current)
			}
			for i := len(missing) - 1; i >= 0; i-- {
				resolved = filepath.Join(resolved, missing[i])
			}
			if mustExist && len(missing) > 0 {
				return "", fmt.Errorf("directory %s does not exist", absolute)
			}
			return filepath.Clean(resolved), nil
		}
		if !os.IsNotExist(err) {
			return "", err
		}

		parent := filepath.Dir(current)
		if parent == current {
			return "", fmt.Errorf("no existing ancestor for %s", absolute)
		}
		missing = append(missing, filepath.Base(current))
		current = parent
	}
}

func safeDestination(root, relative string) (string, error) {
	if filepath.IsAbs(relative) {
		return "", fmt.Errorf("absolute destination %s is not allowed", relative)
	}
	cleanRelative := filepath.Clean(relative)
	if cleanRelative == ".." || strings.HasPrefix(cleanRelative, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("destination %s escapes its install root", relative)
	}
	destination := filepath.Join(root, cleanRelative)
	if err := validateContainedPath(root, destination); err != nil {
		return "", err
	}
	return destination, nil
}

func validateContainedPath(root, destination string) error {
	relative, err := filepath.Rel(root, destination)
	if err != nil {
		return err
	}
	if filepath.IsAbs(relative) || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return fmt.Errorf("destination %s escapes install root %s", destination, root)
	}
	return nil
}

func firstUnsafeAncestor(root, destination string) (string, error) {
	if err := validateContainedPath(root, destination); err != nil {
		return "", err
	}

	parent := filepath.Dir(destination)
	for current := parent; ; current = filepath.Dir(current) {
		info, err := os.Lstat(current)
		if err == nil {
			if info.Mode()&os.ModeSymlink != 0 || !info.IsDir() {
				return current, nil
			}
		} else if !os.IsNotExist(err) {
			return "", fmt.Errorf("checking ancestor %s: %w", current, err)
		}

		if current == root {
			break
		}
		next := filepath.Dir(current)
		if next == current {
			return "", fmt.Errorf("destination %s is not below root %s", destination, root)
		}
		if err := validateContainedPath(root, current); err != nil {
			return "", err
		}
	}
	return "", nil
}

func ensureTrackedDirectory(path string, createdDirs *[]string, createdSet map[string]struct{}) error {
	path = filepath.Clean(path)
	var missing []string
	current := path

	for {
		info, err := os.Lstat(current)
		if err == nil {
			if info.Mode()&os.ModeSymlink != 0 || !info.IsDir() {
				return fmt.Errorf("path component %s is not a directory", current)
			}
			break
		}
		if !os.IsNotExist(err) {
			return err
		}
		parent := filepath.Dir(current)
		if parent == current {
			return fmt.Errorf("no existing directory ancestor for %s", path)
		}
		missing = append(missing, current)
		current = parent
	}

	for i := len(missing) - 1; i >= 0; i-- {
		directory := missing[i]
		if err := os.Mkdir(directory, 0755); err != nil {
			return err
		}
		if _, tracked := createdSet[directory]; !tracked {
			*createdDirs = append(*createdDirs, directory)
			createdSet[directory] = struct{}{}
		}
	}
	return nil
}

func rollbackInstall(createdFiles, createdDirs []string) error {
	var rollbackErrors []error
	for i := len(createdFiles) - 1; i >= 0; i-- {
		if err := os.Remove(createdFiles[i]); err != nil && !os.IsNotExist(err) {
			rollbackErrors = append(rollbackErrors, fmt.Errorf("removing created file %s: %w", createdFiles[i], err))
		}
	}
	for i := len(createdDirs) - 1; i >= 0; i-- {
		if err := os.Remove(createdDirs[i]); err != nil && !os.IsNotExist(err) {
			rollbackErrors = append(rollbackErrors, fmt.Errorf("removing created directory %s: %w", createdDirs[i], err))
		}
	}
	return errors.Join(rollbackErrors...)
}
