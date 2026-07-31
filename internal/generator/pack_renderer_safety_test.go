package generator

import (
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"

	"github.com/magnoscg/anvil/internal/config"
)

type failingFileWriter struct {
	base       FileWriter
	failCreate int
	createCall int
	failAtomic bool
}

type statErrorFS struct {
	fs.FS
	path string
	err  error
}

func (filesystem statErrorFS) Stat(name string) (fs.FileInfo, error) {
	if name == filesystem.path {
		return nil, filesystem.err
	}
	return fs.Stat(filesystem.FS, name)
}

func (w *failingFileWriter) CreateFile(path string, content []byte, mode fs.FileMode) error {
	w.createCall++
	if w.createCall == w.failCreate {
		return errors.New("injected create failure")
	}
	return w.base.CreateFile(path, content, mode)
}

func (w *failingFileWriter) EnsureDir(path string) error {
	return w.base.EnsureDir(path)
}

func (w *failingFileWriter) CreateDir(path string) error {
	return w.base.CreateDir(path)
}

func (w *failingFileWriter) AtomicCreateFile(path string, content []byte, mode fs.FileMode) error {
	if w.failAtomic {
		return errors.New("injected atomic creation failure")
	}
	return w.base.AtomicCreateFile(path, content, mode)
}

func (w *failingFileWriter) AtomicReplaceFile(path string, content []byte, mode fs.FileMode) error {
	if w.failAtomic {
		return errors.New("injected atomic replacement failure")
	}
	return w.base.AtomicReplaceFile(path, content, mode)
}

func TestPackPreflightReportsAllCollisionsWithoutWriting(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                      &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":                 &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/existing.md":     &fstest.MapFile{Data: []byte("replacement")},
		"ai-packs/test-pack/docs/new.md":          &fstest.MapFile{Data: []byte("new")},
		"ai-packs/test-pack/commands":             &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/commands/existing.md": &fstest.MapFile{Data: []byte("replacement")},
	}
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, ".claude", "docs"), 0755); err != nil {
		t.Fatalf("setup docs: %v", err)
	}
	if err := os.MkdirAll(filepath.Join(dir, ".claude", "commands"), 0755); err != nil {
		t.Fatalf("setup commands: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, ".claude", "docs", "existing.md"), []byte("keep docs"), 0644); err != nil {
		t.Fatalf("setup docs file: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, ".claude", "commands", "existing.md"), []byte("keep command"), 0644); err != nil {
		t.Fatalf("setup command file: %v", err)
	}

	installer := newTestPackRenderer(memFS, NewDiskWriter())
	_, err := installer.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	var conflictErr config.InstallConflictError
	if !errors.As(err, &conflictErr) {
		t.Fatalf("error = %v, want InstallConflictError", err)
	}
	wantConflicts := []string{".claude/commands/existing.md", ".claude/docs/existing.md"}
	for _, expected := range wantConflicts {
		if !containsString(conflictErr.Paths, expected) {
			t.Errorf("conflicts = %v, missing %s", conflictErr.Paths, expected)
		}
	}
	if _, err := os.Stat(filepath.Join(dir, ".claude", "docs", "new.md")); !os.IsNotExist(err) {
		t.Fatal("preflight wrote a non-conflicting file")
	}
	assertFileContent(t, filepath.Join(dir, ".claude", "docs", "existing.md"), "keep docs")
	assertFileContent(t, filepath.Join(dir, ".claude", "commands", "existing.md"), "keep command")
}

func TestPackPreflightRejectsDuplicatePackOutputs(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/pack-a":                &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/pack-a/docs":           &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/pack-a/docs/shared.md": &fstest.MapFile{Data: []byte("a")},
		"ai-packs/pack-b":                &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/pack-b/docs":           &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/pack-b/docs/shared.md": &fstest.MapFile{Data: []byte("b")},
	}
	dir := t.TempDir()
	installer := newTestPackRenderer(memFS, NewDiskWriter())

	_, err := installer.RenderPacks([]string{"pack-a", "pack-b"}, "project", ProjectTemplateContext{}, dir)
	var conflictErr config.InstallConflictError
	if !errors.As(err, &conflictErr) {
		t.Fatalf("error = %v, want InstallConflictError", err)
	}
	if !containsString(conflictErr.Paths, ".claude/docs/shared.md") {
		t.Fatalf("conflicts = %v", conflictErr.Paths)
	}
	if _, err := os.Stat(filepath.Join(dir, ".claude")); !os.IsNotExist(err) {
		t.Fatal("duplicate preflight created directories")
	}
}

func TestOptionalPackDirectoryOnlyIgnoresNotExist(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack": &fstest.MapFile{Mode: fs.ModeDir | 0755},
	}
	filesystem := statErrorFS{
		FS:   memFS,
		path: "ai-packs/test-pack/docs",
		err:  fs.ErrPermission,
	}
	installer := newTestPackRenderer(filesystem, NewDiskWriter())

	_, err := installer.PlanPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, t.TempDir())
	if !errors.Is(err, fs.ErrPermission) {
		t.Fatalf("error = %v, want fs.ErrPermission", err)
	}
}

func TestPackPreflightRejectsSymlinkAncestor(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                  &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":             &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/security.md": &fstest.MapFile{Data: []byte("content")},
	}
	dir := t.TempDir()
	external := t.TempDir()
	if err := os.Symlink(external, filepath.Join(dir, ".claude")); err != nil {
		t.Fatalf("setup symlink: %v", err)
	}
	installer := newTestPackRenderer(memFS, NewDiskWriter())

	_, err := installer.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	var conflictErr config.InstallConflictError
	if !errors.As(err, &conflictErr) {
		t.Fatalf("error = %v, want InstallConflictError", err)
	}
	if _, err := os.Stat(filepath.Join(external, "docs", "security.md")); !os.IsNotExist(err) {
		t.Fatal("installer followed a symlink outside the project")
	}
}

func TestPackApplyRollsBackOnlyCreatedResources(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":           &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":      &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/a.md": &fstest.MapFile{Data: []byte("a")},
		"ai-packs/test-pack/docs/b.md": &fstest.MapFile{Data: []byte("b")},
	}
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "keep.txt"), []byte("keep"), 0644); err != nil {
		t.Fatalf("setup keep file: %v", err)
	}
	writer := &failingFileWriter{base: NewDiskWriter(), failCreate: 2}
	installer := newTestPackRenderer(memFS, writer)

	_, err := installer.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err == nil || !strings.Contains(err.Error(), "injected create failure") {
		t.Fatalf("error = %v, want injected failure", err)
	}
	assertFileContent(t, filepath.Join(dir, "keep.txt"), "keep")
	if _, err := os.Stat(filepath.Join(dir, ".claude")); !os.IsNotExist(err) {
		t.Fatal("failed apply left created files or directories")
	}
}

func TestPackApplyDoesNotOverwriteCollisionCreatedAfterPreflight(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":           &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":      &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/a.md": &fstest.MapFile{Data: []byte("a")},
		"ai-packs/test-pack/docs/b.md": &fstest.MapFile{Data: []byte("b")},
	}
	dir := t.TempDir()
	installer := newTestPackRenderer(memFS, NewDiskWriter())
	plan, err := installer.PlanPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("PlanPacks failed: %v", err)
	}
	if err := installer.Preflight(&plan); err != nil {
		t.Fatalf("Preflight failed: %v", err)
	}
	lateCollision := filepath.Join(dir, ".claude", "docs", "b.md")
	if err := os.MkdirAll(filepath.Dir(lateCollision), 0755); err != nil {
		t.Fatalf("setup late collision directory: %v", err)
	}
	if err := os.WriteFile(lateCollision, []byte("keep"), 0644); err != nil {
		t.Fatalf("setup late collision: %v", err)
	}

	_, err = installer.Apply(plan)
	if err == nil {
		t.Fatal("Apply succeeded despite a late collision")
	}
	assertFileContent(t, lateCollision, "keep")
	if _, err := os.Stat(filepath.Join(dir, ".claude", "docs", "a.md")); !os.IsNotExist(err) {
		t.Fatal("late collision did not roll back files created earlier in Apply")
	}
}

func TestPackSettingsMergeIsAtomicAndPreservesPermissions(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                     &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/settings-merge.json": &fstest.MapFile{Data: []byte(`{"theme":"light","permissions":{"allow":["Write"]}}`)},
	}
	dir := t.TempDir()
	settingsDir := filepath.Join(dir, ".claude")
	if err := os.Mkdir(settingsDir, 0755); err != nil {
		t.Fatalf("setup settings directory: %v", err)
	}
	settingsPath := filepath.Join(settingsDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"theme":"dark","permissions":{"allow":["Read"]}}`), 0600); err != nil {
		t.Fatalf("setup settings: %v", err)
	}
	installer := newTestPackRenderer(memFS, NewDiskWriter())

	_, err := installer.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}
	info, err := os.Stat(settingsPath)
	if err != nil {
		t.Fatalf("stat settings: %v", err)
	}
	if info.Mode().Perm() != 0600 {
		t.Fatalf("settings mode = %o, want 600", info.Mode().Perm())
	}
	content, err := os.ReadFile(settingsPath)
	if err != nil {
		t.Fatalf("read settings: %v", err)
	}
	if !strings.Contains(string(content), `"theme": "dark"`) || !strings.Contains(string(content), `"Write"`) {
		t.Fatalf("merged settings = %s", content)
	}
	if matches, _ := filepath.Glob(filepath.Join(settingsDir, ".anvil-settings-*")); len(matches) != 0 {
		t.Fatalf("temporary settings files remain: %v", matches)
	}
}

func TestInvalidSettingsFailsBeforeAnyWrite(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                     &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":                &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/new.md":         &fstest.MapFile{Data: []byte("new")},
		"ai-packs/test-pack/settings-merge.json": &fstest.MapFile{Data: []byte(`{"enabled":true}`)},
	}
	dir := t.TempDir()
	if err := os.Mkdir(filepath.Join(dir, ".claude"), 0755); err != nil {
		t.Fatalf("setup settings directory: %v", err)
	}
	settingsPath := filepath.Join(dir, ".claude", "settings.json")
	if err := os.WriteFile(settingsPath, []byte("{broken"), 0600); err != nil {
		t.Fatalf("setup settings: %v", err)
	}
	before, err := snapshotPath(dir)
	if err != nil {
		t.Fatalf("snapshot before: %v", err)
	}
	installer := newTestPackRenderer(memFS, NewDiskWriter())

	_, err = installer.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	var mergeErr config.SettingsMergeError
	if !errors.As(err, &mergeErr) {
		t.Fatalf("error = %v, want SettingsMergeError", err)
	}
	after, err := snapshotPath(dir)
	if err != nil {
		t.Fatalf("snapshot after: %v", err)
	}
	if before != after {
		t.Fatalf("invalid settings changed the project:\nbefore: %s\nafter: %s", before, after)
	}
}

func TestSettingsSymlinkFailsPreflightWithoutWriting(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                     &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":                &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/new.md":         &fstest.MapFile{Data: []byte("new")},
		"ai-packs/test-pack/settings-merge.json": &fstest.MapFile{Data: []byte(`{"enabled":true}`)},
	}
	dir := t.TempDir()
	if err := os.Mkdir(filepath.Join(dir, ".claude"), 0755); err != nil {
		t.Fatalf("setup settings directory: %v", err)
	}
	externalSettings := filepath.Join(t.TempDir(), "settings.json")
	if err := os.WriteFile(externalSettings, []byte(`{"keep":true}`), 0600); err != nil {
		t.Fatalf("setup external settings: %v", err)
	}
	settingsPath := filepath.Join(dir, ".claude", "settings.json")
	if err := os.Symlink(externalSettings, settingsPath); err != nil {
		t.Fatalf("setup settings symlink: %v", err)
	}
	installer := newTestPackRenderer(memFS, NewDiskWriter())

	_, err := installer.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	var conflictErr config.InstallConflictError
	if !errors.As(err, &conflictErr) {
		t.Fatalf("error = %v, want InstallConflictError", err)
	}
	if !containsString(conflictErr.Paths, ".claude/settings.json") {
		t.Fatalf("conflicts = %v", conflictErr.Paths)
	}
	assertFileContent(t, externalSettings, `{"keep":true}`)
	if _, err := os.Stat(filepath.Join(dir, ".claude", "docs")); !os.IsNotExist(err) {
		t.Fatal("settings symlink preflight created files")
	}
}

func TestMissingSettingsCreatedAfterPreflightIsNotOverwritten(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                     &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":                &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/new.md":         &fstest.MapFile{Data: []byte("new")},
		"ai-packs/test-pack/settings-merge.json": &fstest.MapFile{Data: []byte(`{"enabled":true}`)},
	}
	dir := t.TempDir()
	installer := newTestPackRenderer(memFS, NewDiskWriter())
	plan, err := installer.PlanPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("PlanPacks failed: %v", err)
	}
	if err := installer.Preflight(&plan); err != nil {
		t.Fatalf("Preflight failed: %v", err)
	}
	settingsPath := filepath.Join(dir, ".claude", "settings.json")
	if err := os.MkdirAll(filepath.Dir(settingsPath), 0755); err != nil {
		t.Fatalf("setup settings directory: %v", err)
	}
	if err := os.WriteFile(settingsPath, []byte(`{"keep":true}`), 0600); err != nil {
		t.Fatalf("setup late settings: %v", err)
	}

	_, err = installer.Apply(plan)
	if err == nil {
		t.Fatal("Apply succeeded despite settings appearing after preflight")
	}
	assertFileContent(t, settingsPath, `{"keep":true}`)
	if _, err := os.Stat(filepath.Join(dir, ".claude", "docs")); !os.IsNotExist(err) {
		t.Fatal("late settings collision did not roll back newly created files")
	}
}

func TestExistingSettingsChangedAfterPreflightIsNotOverwritten(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                     &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":                &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/new.md":         &fstest.MapFile{Data: []byte("new")},
		"ai-packs/test-pack/settings-merge.json": &fstest.MapFile{Data: []byte(`{"enabled":true}`)},
	}
	dir := t.TempDir()
	settingsPath := filepath.Join(dir, ".claude", "settings.json")
	if err := os.MkdirAll(filepath.Dir(settingsPath), 0755); err != nil {
		t.Fatalf("setup settings directory: %v", err)
	}
	if err := os.WriteFile(settingsPath, []byte(`{"keep":"original"}`), 0600); err != nil {
		t.Fatalf("setup settings: %v", err)
	}
	installer := newTestPackRenderer(memFS, NewDiskWriter())
	plan, err := installer.PlanPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("PlanPacks failed: %v", err)
	}
	if err := installer.Preflight(&plan); err != nil {
		t.Fatalf("Preflight failed: %v", err)
	}
	if err := os.WriteFile(settingsPath, []byte(`{"keep":"newer"}`), 0600); err != nil {
		t.Fatalf("change settings after preflight: %v", err)
	}

	_, err = installer.Apply(plan)
	if err == nil || !strings.Contains(err.Error(), "content changed") {
		t.Fatalf("error = %v, want changed-settings failure", err)
	}
	assertFileContent(t, settingsPath, `{"keep":"newer"}`)
	if _, err := os.Stat(filepath.Join(dir, ".claude", "docs")); !os.IsNotExist(err) {
		t.Fatal("changed settings did not roll back newly created files")
	}
}

func TestAtomicSettingsFailureRollsBackNewFiles(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/test-pack":                     &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs":                &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/test-pack/docs/new.md":         &fstest.MapFile{Data: []byte("new")},
		"ai-packs/test-pack/settings-merge.json": &fstest.MapFile{Data: []byte(`{"enabled":true}`)},
	}
	dir := t.TempDir()
	if err := os.Mkdir(filepath.Join(dir, ".claude"), 0755); err != nil {
		t.Fatalf("setup settings directory: %v", err)
	}
	settingsPath := filepath.Join(dir, ".claude", "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"keep":true}`), 0600); err != nil {
		t.Fatalf("setup settings: %v", err)
	}
	writer := &failingFileWriter{base: NewDiskWriter(), failAtomic: true}
	installer := newTestPackRenderer(memFS, writer)

	_, err := installer.RenderPacks([]string{"test-pack"}, "project", ProjectTemplateContext{}, dir)
	if err == nil || !strings.Contains(err.Error(), "injected atomic replacement failure") {
		t.Fatalf("error = %v, want injected atomic failure", err)
	}
	assertFileContent(t, settingsPath, `{"keep":true}`)
	if _, err := os.Stat(filepath.Join(dir, ".claude", "docs")); !os.IsNotExist(err) {
		t.Fatal("settings failure left newly created files")
	}
}

func TestPackNoticesComposeAndThenConflict(t *testing.T) {
	memFS := fstest.MapFS{
		"ai-packs/pack-a":                        &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/pack-a/THIRD_PARTY_NOTICES.md": &fstest.MapFile{Data: []byte("Notice A\n")},
		"ai-packs/pack-b":                        &fstest.MapFile{Mode: fs.ModeDir | 0755},
		"ai-packs/pack-b/THIRD_PARTY_NOTICES.md": &fstest.MapFile{Data: []byte("Notice B\n")},
	}
	dir := t.TempDir()
	installer := newTestPackRenderer(memFS, NewDiskWriter())

	_, err := installer.RenderPacks([]string{"pack-a", "pack-b"}, "project", ProjectTemplateContext{}, dir)
	if err != nil {
		t.Fatalf("RenderPacks failed: %v", err)
	}
	noticesPath := filepath.Join(dir, ".claude", "THIRD_PARTY_NOTICES.md")
	content, err := os.ReadFile(noticesPath)
	if err != nil {
		t.Fatalf("read notices: %v", err)
	}
	if !strings.Contains(string(content), "Notice A") || !strings.Contains(string(content), "Notice B") {
		t.Fatalf("notices = %s", content)
	}

	_, err = installer.RenderPacks([]string{"pack-a", "pack-b"}, "project", ProjectTemplateContext{}, dir)
	var conflictErr config.InstallConflictError
	if !errors.As(err, &conflictErr) {
		t.Fatalf("second install error = %v, want InstallConflictError", err)
	}
	assertFileContent(t, noticesPath, string(content))
}

func newTestPackRenderer(memFS fs.FS, writer FileWriter) *DefaultPackRenderer {
	return NewPackRenderer(memFS, NewRenderer(memFS, writer), writer, NewSettingsMerger(writer, memFS))
}

func containsString(values []string, expected string) bool {
	for _, value := range values {
		if value == expected {
			return true
		}
	}
	return false
}

func assertFileContent(t *testing.T, path, expected string) {
	t.Helper()
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	if string(content) != expected {
		t.Fatalf("%s = %q, want %q", path, content, expected)
	}
}
