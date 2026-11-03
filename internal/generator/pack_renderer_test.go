package generator

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"

	"github.com/magnoscg/anvil/internal/config"
)

// mockSettingsMerger records calls to Merge for verification in tests.
type mockSettingsMerger struct {
	mergeErr      error
	mergeCalled   bool
	existingPath  string
	fragmentPaths []string
}

func (m *mockSettingsMerger) Merge(existingPath string, existingData []byte, fragmentPaths []string) ([]byte, error) {
	m.mergeCalled = true
	m.existingPath = existingPath
	m.fragmentPaths = append([]string(nil), fragmentPaths...)
	return []byte("{}\n"), m.mergeErr
}

func TestRenderPacksEmptySlice(t *testing.T) {
	memFS := fstest.MapFS{}
	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	created, err := pr.RenderPacks(nil, "project", ProjectTemplateContext{}, dir)

	if err != nil {
		t.Fatalf("RenderPacks with empty slice should not error, got: %v", err)
	}
	if len(created) != 0 {
		t.Errorf("created %d files, want 0", len(created))
	}
}

func TestRenderPacksNonExistentPackReturnsError(t *testing.T) {
	memFS := fstest.MapFS{}
	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"nonexistent"}, "project", ProjectTemplateContext{}, dir)

	if err == nil {
		t.Fatal("expected error for nonexistent pack, got nil")
	}

	if !strings.Contains(err.Error(), "nonexistent") {
		t.Errorf("error should mention pack slug, got: %v", err)
	}
}

func TestRenderPacksWithBaseCLAUDETemplate(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack": &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/CLAUDE.md.tmpl": &fstest.MapFile{
			Data: []byte("# {{ .ProjectName }}\n\nBase content.\n"),
		},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	ctx := ProjectTemplateContext{ProjectName: "MyApp"}
	created, err := pr.RenderPacks([]string{"test-pack"}, "project", ctx, dir)

	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	// CLAUDE.md should be in created list
	hasClaude := false
	for _, f := range created {
		if f == "CLAUDE.md" {
			hasClaude = true
			break
		}
	}
	if !hasClaude {
		t.Error("CLAUDE.md not in created files list")
	}

	// Verify CLAUDE.md content
	content, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}

	if !strings.Contains(string(content), "# MyApp") {
		t.Errorf("CLAUDE.md should contain rendered project name, got: %s", string(content))
	}
}

func TestRenderPacksSectionsAppendInOrder(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/pack-a":                        &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/pack-a/CLAUDE.md.tmpl":         &fstest.MapFile{Data: []byte("# Base\n")},
		"ai-packs/pack-b":                        &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/pack-b/CLAUDE-section.md.tmpl": &fstest.MapFile{Data: []byte("## Section B\n")},
		"ai-packs/pack-c":                        &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/pack-c/CLAUDE-section.md.tmpl": &fstest.MapFile{Data: []byte("## Section C\n")},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"pack-a", "pack-b", "pack-c"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}

	text := string(content)

	// Verify order: Base appears before Section B, which appears before Section C
	baseIdx := strings.Index(text, "# Base")
	sectionBIdx := strings.Index(text, "## Section B")
	sectionCIdx := strings.Index(text, "## Section C")

	if baseIdx == -1 || sectionBIdx == -1 || sectionCIdx == -1 {
		t.Fatalf("missing expected sections in CLAUDE.md:\n%s", text)
	}

	if baseIdx >= sectionBIdx || sectionBIdx >= sectionCIdx {
		t.Errorf("sections not in expected order: base=%d, B=%d, C=%d", baseIdx, sectionBIdx, sectionCIdx)
	}
}

func TestRenderPacksCopiesDocs(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                      &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/docs":                 &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/docs/ARCHITECTURE.md": &fstest.MapFile{Data: []byte("# Architecture\n")},
		"ai-packs/test-pack/docs/testing.md":      &fstest.MapFile{Data: []byte("# Testing\n")},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	archContent, err := os.ReadFile(filepath.Join(dir, ".claude", "docs", "ARCHITECTURE.md"))
	if err != nil {
		t.Fatalf("reading ARCHITECTURE.md: %v", err)
	}
	if string(archContent) != "# Architecture\n" {
		t.Errorf("ARCHITECTURE.md = %q, want %q", string(archContent), "# Architecture\n")
	}

	testContent, err := os.ReadFile(filepath.Join(dir, ".claude", "docs", "testing.md"))
	if err != nil {
		t.Fatalf("reading testing.md: %v", err)
	}
	if string(testContent) != "# Testing\n" {
		t.Errorf("testing.md = %q, want %q", string(testContent), "# Testing\n")
	}
}

func TestRenderPacksCopiesCommands(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                       &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/commands":              &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/commands/dev-build.md": &fstest.MapFile{Data: []byte("build command\n")},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, ".claude", "commands", "dev-build.md"))
	if err != nil {
		t.Fatalf("reading dev-build.md: %v", err)
	}
	if string(content) != "build command\n" {
		t.Errorf("dev-build.md = %q, want %q", string(content), "build command\n")
	}
}

func TestRenderPacksCopiesAgents(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                           &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/agents":                    &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/agents/DEV-IMPLEMENTER.md": &fstest.MapFile{Data: []byte("implementer agent\n")},
		"ai-packs/test-pack/agents/DEV-VERIFIER.md":    &fstest.MapFile{Data: []byte("verifier agent\n")},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	implContent, err := os.ReadFile(filepath.Join(dir, ".claude", "agents", "DEV-IMPLEMENTER.md"))
	if err != nil {
		t.Fatalf("reading DEV-IMPLEMENTER.md: %v", err)
	}
	if string(implContent) != "implementer agent\n" {
		t.Errorf("DEV-IMPLEMENTER.md = %q, want %q", string(implContent), "implementer agent\n")
	}

	verifierContent, err := os.ReadFile(filepath.Join(dir, ".claude", "agents", "DEV-VERIFIER.md"))
	if err != nil {
		t.Fatalf("reading DEV-VERIFIER.md: %v", err)
	}
	if string(verifierContent) != "verifier agent\n" {
		t.Errorf("DEV-VERIFIER.md = %q, want %q", string(verifierContent), "verifier agent\n")
	}
}

func TestRenderPacksRendersDevTemplates(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                        &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/dev":                    &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/dev/arch-index.md.tmpl": &fstest.MapFile{Data: []byte("# {{ .ProjectName }} Arch\n")},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	ctx := ProjectTemplateContext{ProjectName: "TestApp"}
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, ".dev", "arch-index.md"))
	if err != nil {
		t.Fatalf("reading arch-index.md: %v", err)
	}
	if string(content) != "# TestApp Arch\n" {
		t.Errorf("arch-index.md = %q, want %q", string(content), "# TestApp Arch\n")
	}
}

func TestRenderPacksCallsSettingsMerger(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                     &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/settings-merge.json": &fstest.MapFile{Data: []byte(`{"permissions":{"allow":["mcp:test"]}}`)},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	if !merger.mergeCalled {
		t.Error("SettingsMerger.Merge was not called")
	}
	canonicalDir, err := canonicalRoot(dir, true)
	if err != nil {
		t.Fatalf("canonicalRoot failed: %v", err)
	}
	expectedSettingsPath := filepath.Join(canonicalDir, ".claude", "settings.json")
	if merger.existingPath != expectedSettingsPath {
		t.Errorf("merge existingPath = %q, want %q", merger.existingPath, expectedSettingsPath)
	}
	if len(merger.fragmentPaths) != 1 || merger.fragmentPaths[0] != "ai-packs/test-pack/settings-merge.json" {
		t.Errorf("merge fragmentPaths = %q, want %q", merger.fragmentPaths, []string{"ai-packs/test-pack/settings-merge.json"})
	}
}

func TestRenderPacksCopiesSkillsProjectScope(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                          &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills":                   &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills/my-skill":          &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills/my-skill/SKILL.md": &fstest.MapFile{Data: []byte("# My Skill\n")},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, ".claude", "skills", "my-skill", "SKILL.md"))
	if err != nil {
		t.Fatalf("reading SKILL.md: %v", err)
	}
	if string(content) != "# My Skill\n" {
		t.Errorf("SKILL.md = %q, want %q", string(content), "# My Skill\n")
	}
}

func TestRenderPacksRendersWorkflowTemplates(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                       &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/workflows":             &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/workflows/ci.yml.tmpl": &fstest.MapFile{Data: []byte("name: CI {{ .ProjectName }}\n")},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	ctx := ProjectTemplateContext{ProjectName: "MyApp"}
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, ".github", "workflows", "ci.yml"))
	if err != nil {
		t.Fatalf("reading ci.yml: %v", err)
	}
	if string(content) != "name: CI MyApp\n" {
		t.Errorf("ci.yml = %q, want %q", string(content), "name: CI MyApp\n")
	}
}

func TestRenderPacksCopiesSkillsGlobalScope(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                              &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills":                       &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills/global-skill":          &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills/global-skill/SKILL.md": &fstest.MapFile{Data: []byte("# Global Skill\n")},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	// Use a temp dir as HOME to avoid writing to the real ~/.claude/
	tmpHome := t.TempDir()
	t.Setenv("HOME", tmpHome)

	projectDir := t.TempDir()
	_, err := pr.RenderPacks([]string{"test-pack"}, "global", ProjectTemplateContext{}, projectDir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	// Skills should be in HOME/.claude/skills/, not in projectDir/.claude/skills/
	globalPath := filepath.Join(tmpHome, ".claude", "skills", "global-skill", "SKILL.md")
	content, err := os.ReadFile(globalPath)
	if err != nil {
		t.Fatalf("reading global skill: %v", err)
	}
	if string(content) != "# Global Skill\n" {
		t.Errorf("global SKILL.md = %q, want %q", string(content), "# Global Skill\n")
	}

	// Should NOT exist in project scope
	projectPath := filepath.Join(projectDir, ".claude", "skills", "global-skill", "SKILL.md")
	if _, err := os.Stat(projectPath); !os.IsNotExist(err) {
		t.Error("skill should NOT exist in project .claude/skills/ when scope is global")
	}
}

func skillPackFS(content string) fstest.MapFS {
	return fstest.MapFS{
		"ai-packs/test-pack":                                &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills":                         &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills/existing-skill":          &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/skills/existing-skill/SKILL.md": &fstest.MapFile{Data: []byte(content)},
		"ai-packs/test-pack/CLAUDE.md.tmpl":                 &fstest.MapFile{Data: []byte("# Pack\n")},
	}
}

func writeSkill(t *testing.T, dir, content string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0755); err != nil {
		t.Fatalf("creating skill dir: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, "SKILL.md"), []byte(content), 0644); err != nil {
		t.Fatalf("writing skill: %v", err)
	}
}

func planAndPreflight(t *testing.T, memFS fstest.MapFS, scope, projectDir string) (*DefaultPackRenderer, PackInstallPlan, error) {
	t.Helper()
	pr := NewPackRenderer(memFS, NewRenderer(memFS, NewDiskWriter()), NewDiskWriter(), &mockSettingsMerger{})
	plan, err := pr.PlanPacks([]string{"test-pack"}, scope, ProjectTemplateContext{}, projectDir)
	if err != nil {
		t.Fatalf("PlanPacks: %v", err)
	}
	return pr, plan, pr.Preflight(&plan)
}

func TestGlobalSkillThatDiffersIsKeptAndReported(t *testing.T) {
	tmpHome := t.TempDir()
	t.Setenv("HOME", tmpHome)
	existingSkillDir := filepath.Join(tmpHome, ".claude", "skills", "existing-skill")
	writeSkill(t, existingSkillDir, "# Old version\n")
	projectDir := t.TempDir()

	pr, plan, err := planAndPreflight(t, skillPackFS("# New version\n"), "global", projectDir)
	if err != nil {
		t.Fatalf("Preflight = %v, want an existing global skill to be kept, not a conflict", err)
	}
	created, err := pr.Apply(plan)
	if err != nil {
		t.Fatalf("Apply: %v", err)
	}

	want := []KeptSkill{{Path: "~/.claude/skills/existing-skill", Identical: false}}
	if got := plan.KeptSkills(); len(got) != 1 || got[0] != want[0] {
		t.Fatalf("KeptSkills() = %+v, want %+v", got, want)
	}
	content, err := os.ReadFile(filepath.Join(existingSkillDir, "SKILL.md"))
	if err != nil || string(content) != "# Old version\n" {
		t.Fatalf("existing skill changed: %q, %v", content, err)
	}
	for _, path := range created {
		if strings.Contains(path, "existing-skill") {
			t.Fatalf("Apply reported %s as created, but the skill was kept", path)
		}
	}
	if _, err := os.Stat(filepath.Join(projectDir, "CLAUDE.md")); err != nil {
		t.Fatalf("the rest of the pack should still be installed: %v", err)
	}
}

func TestGlobalSkillThatMatchesIsReusedAsIdentical(t *testing.T) {
	tmpHome := t.TempDir()
	t.Setenv("HOME", tmpHome)
	writeSkill(t, filepath.Join(tmpHome, ".claude", "skills", "existing-skill"), "# Same\n")
	if err := os.WriteFile(filepath.Join(tmpHome, ".claude", "skills", "existing-skill", ".DS_Store"), []byte("finder"), 0644); err != nil {
		t.Fatalf("writing .DS_Store: %v", err)
	}

	_, plan, err := planAndPreflight(t, skillPackFS("# Same\n"), "global", t.TempDir())
	if err != nil {
		t.Fatalf("Preflight: %v", err)
	}

	if got := plan.KeptSkills(); len(got) != 1 || !got[0].Identical {
		t.Fatalf("KeptSkills() = %+v, want one identical skill", got)
	}
}

func TestGlobalSkillWithExtraFilesIsNotIdentical(t *testing.T) {
	tmpHome := t.TempDir()
	t.Setenv("HOME", tmpHome)
	skillDir := filepath.Join(tmpHome, ".claude", "skills", "existing-skill")
	writeSkill(t, skillDir, "# Same\n")
	if err := os.WriteFile(filepath.Join(skillDir, "notes.md"), []byte("mine"), 0644); err != nil {
		t.Fatalf("writing extra file: %v", err)
	}

	_, plan, err := planAndPreflight(t, skillPackFS("# Same\n"), "global", t.TempDir())
	if err != nil {
		t.Fatalf("Preflight: %v", err)
	}

	if got := plan.KeptSkills(); len(got) != 1 || got[0].Identical {
		t.Fatalf("KeptSkills() = %+v, want one skill that is not identical", got)
	}
}

func TestGlobalSkillSymlinkIsKeptWithoutWritingThroughIt(t *testing.T) {
	tmpHome := t.TempDir()
	t.Setenv("HOME", tmpHome)
	target := filepath.Join(t.TempDir(), "my-skill")
	writeSkill(t, target, "# Mine\n")
	skillsDir := filepath.Join(tmpHome, ".claude", "skills")
	if err := os.MkdirAll(skillsDir, 0755); err != nil {
		t.Fatalf("creating skills dir: %v", err)
	}
	if err := os.Symlink(target, filepath.Join(skillsDir, "existing-skill")); err != nil {
		t.Fatalf("symlinking skill: %v", err)
	}

	pr, plan, err := planAndPreflight(t, skillPackFS("# New\n"), "global", t.TempDir())
	if err != nil {
		t.Fatalf("Preflight: %v", err)
	}
	if _, err := pr.Apply(plan); err != nil {
		t.Fatalf("Apply: %v", err)
	}

	if got := plan.KeptSkills(); len(got) != 1 || got[0].Identical {
		t.Fatalf("KeptSkills() = %+v, want the symlinked skill kept as different", got)
	}
	content, err := os.ReadFile(filepath.Join(target, "SKILL.md"))
	if err != nil || string(content) != "# Mine\n" {
		t.Fatalf("symlink target changed: %q, %v", content, err)
	}
}

func TestProjectScopeSkillThatExistsStillConflicts(t *testing.T) {
	projectDir := t.TempDir()
	writeSkill(t, filepath.Join(projectDir, ".claude", "skills", "existing-skill"), "# Old\n")

	_, plan, err := planAndPreflight(t, skillPackFS("# New\n"), "project", projectDir)

	var conflictErr config.InstallConflictError
	if !errors.As(err, &conflictErr) {
		t.Fatalf("error = %v, want InstallConflictError for a project-scope skill", err)
	}
	if kept := plan.KeptSkills(); kept != nil {
		t.Fatalf("project-scope skills must not be kept, got %+v", kept)
	}
}

func TestRollbackNeverRemovesAKeptGlobalSkill(t *testing.T) {
	tmpHome := t.TempDir()
	t.Setenv("HOME", tmpHome)
	skillDir := filepath.Join(tmpHome, ".claude", "skills", "existing-skill")
	writeSkill(t, skillDir, "# Old\n")
	projectDir := t.TempDir()

	pr, plan, err := planAndPreflight(t, skillPackFS("# New\n"), "global", projectDir)
	if err != nil {
		t.Fatalf("Preflight: %v", err)
	}
	if err := os.WriteFile(filepath.Join(projectDir, "CLAUDE.md"), []byte("appeared after preflight"), 0644); err != nil {
		t.Fatalf("creating late collision: %v", err)
	}

	if _, err := pr.Apply(plan); err == nil {
		t.Fatal("Apply should fail on the file that appeared after preflight")
	}
	content, err := os.ReadFile(filepath.Join(skillDir, "SKILL.md"))
	if err != nil || string(content) != "# Old\n" {
		t.Fatalf("rollback touched the kept skill: %q, %v", content, err)
	}
}

func TestRenderPacks_WithToolsModeContext(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack": &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/CLAUDE.md.tmpl": &fstest.MapFile{
			Data: []byte("{{ if not .IsToolsMode }}PROJECT{{ end }}ALWAYS"),
		},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	ctx := ProjectTemplateContext{IsToolsMode: true}
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}

	got := string(content)
	if got != "ALWAYS" {
		t.Errorf("tools mode output = %q, want %q", got, "ALWAYS")
	}
}

func TestRenderPacks_WithProjectModeContext(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack": &fstest.MapFile{Mode: 0755 | os.ModeDir},
		"ai-packs/test-pack/CLAUDE.md.tmpl": &fstest.MapFile{
			Data: []byte("{{ if not .IsToolsMode }}PROJECT{{ end }}ALWAYS"),
		},
	}

	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	ctx := ProjectTemplateContext{IsToolsMode: false}
	_, err := pr.RenderPacks([]string{"test-pack"}, "project", ctx, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}

	got := string(content)
	if got != "PROJECTALWAYS" {
		t.Errorf("project mode output = %q, want %q", got, "PROJECTALWAYS")
	}
}

func TestRenderPacksNoClaudeMDWhenNoPacks(t *testing.T) {
	memFS := fstest.MapFS{}
	renderer := NewRenderer(memFS, NewDiskWriter())
	merger := &mockSettingsMerger{}
	pr := NewPackRenderer(memFS, renderer, NewDiskWriter(), merger)

	dir := t.TempDir()
	created, err := pr.RenderPacks([]string{}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// No CLAUDE.md should be created
	for _, f := range created {
		if f == "CLAUDE.md" {
			t.Error("CLAUDE.md should not be created when no packs are selected")
		}
	}

	if _, err := os.Stat(filepath.Join(dir, "CLAUDE.md")); !os.IsNotExist(err) {
		t.Error("CLAUDE.md file should not exist on disk")
	}
}
