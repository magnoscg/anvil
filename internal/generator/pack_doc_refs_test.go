package generator

import (
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/magnoscg/anvil/templates"
)

var claudeDocReference = regexp.MustCompile(`\.claude/docs/[A-Za-z0-9_.-]+\.(?:md|yml)`)

func renderPacksForDocRefs(t *testing.T, packs []string, ctx ProjectTemplateContext) string {
	t.Helper()
	writer := NewDiskWriter()
	renderer := NewRenderer(templates.FS, writer)
	packRenderer := NewPackRenderer(templates.FS, renderer, writer, NewSettingsMerger(writer, templates.FS))
	dir := t.TempDir()
	if _, err := packRenderer.RenderPacks(packs, "project", ctx, dir); err != nil {
		t.Fatalf("RenderPacks %v: %v", packs, err)
	}
	return dir
}

func TestPackDocReferencesResolveToInstalledDocs(t *testing.T) {
	packs := []string{"ios-architecture", "prd-planner", "axiom-ios"}
	for _, ctx := range []ProjectTemplateContext{
		{ProjectName: "MyApp", Schemes: []string{"Dev"}, HasIosArchitecture: true, HasAxiomIos: true},
		{IsToolsMode: true, HasIosArchitecture: true, HasAxiomIos: true},
	} {
		dir := renderPacksForDocRefs(t, packs, ctx)
		err := filepath.WalkDir(dir, func(path string, entry fs.DirEntry, err error) error {
			if err != nil || entry.IsDir() {
				return err
			}
			data, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			text := string(data)
			relative, _ := filepath.Rel(dir, path)
			if strings.Contains(text, "dev-verify-docs") {
				t.Errorf("tools mode %v: %s points to ~/.claude/dev-verify-docs, which nothing installs", ctx.IsToolsMode, relative)
			}
			for _, reference := range claudeDocReference.FindAllString(text, -1) {
				if _, statErr := os.Stat(filepath.Join(dir, filepath.FromSlash(reference))); statErr != nil {
					t.Errorf("tools mode %v: %s references %s, which is not installed", ctx.IsToolsMode, relative, reference)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatalf("walking rendered packs: %v", err)
		}
	}
}

func TestAxiomSectionDoesNotPromiseDocsWithoutIosArchitecture(t *testing.T) {
	dir := renderPacksForDocRefs(t, []string{"axiom-ios"}, ProjectTemplateContext{ProjectName: "MyApp", HasAxiomIos: true})

	data, err := os.ReadFile(filepath.Join(dir, "CLAUDE.md"))
	if err != nil {
		t.Fatalf("reading CLAUDE.md: %v", err)
	}
	text := string(data)
	if strings.Contains(text, "Consult the detailed documentation in `.claude/docs/`") {
		t.Error("axiom-ios alone must not send readers to .claude/docs/, which only ios-architecture installs")
	}
	if !strings.Contains(text, "does not have unless that pack is added") {
		t.Errorf("axiom-ios alone should explain where the Doc column points, got:\n%s", text)
	}
}
