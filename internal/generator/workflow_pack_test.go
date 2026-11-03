package generator

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"

	"github.com/magnoscg/anvil/templates"
)

var shaPinnedAction = regexp.MustCompile(`^[\w.-]+/[\w.-]+@[0-9a-f]{40}$`)

type workflowFile struct {
	Permissions map[string]string `yaml:"permissions"`
	Env         map[string]string `yaml:"env"`
	Jobs        map[string]struct {
		Steps []struct {
			Uses string `yaml:"uses"`
		} `yaml:"steps"`
	} `yaml:"jobs"`
}

func renderWorkflowPack(t *testing.T, ctx ProjectTemplateContext) map[string]string {
	t.Helper()
	writer := NewDiskWriter()
	renderer := NewRenderer(templates.FS, writer)
	packRenderer := NewPackRenderer(templates.FS, renderer, writer, NewSettingsMerger(writer, templates.FS))
	dir := t.TempDir()
	if _, err := packRenderer.RenderPacks([]string{"github-actions"}, "project", ctx, dir); err != nil {
		t.Fatalf("RenderPacks github-actions: %v", err)
	}
	rendered := make(map[string]string)
	for _, name := range []string{"ci.yml", "release.yml"} {
		data, err := os.ReadFile(filepath.Join(dir, ".github", "workflows", name))
		if err != nil {
			t.Fatalf("reading %s: %v", name, err)
		}
		rendered[name] = string(data)
	}
	return rendered
}

func TestWorkflowPackIsLeastPrivilegeAndPinned(t *testing.T) {
	rendered := renderWorkflowPack(t, ProjectTemplateContext{ProjectName: "MyApp", Schemes: []string{"QA", "Production"}})

	for name, text := range rendered {
		var workflow workflowFile
		if err := yaml.Unmarshal([]byte(text), &workflow); err != nil {
			t.Fatalf("%s is not valid YAML: %v\n%s", name, err, text)
		}
		if workflow.Permissions["contents"] != "read" {
			t.Errorf("%s must default to contents: read, got %v", name, workflow.Permissions)
		}
		for jobName, job := range workflow.Jobs {
			for _, step := range job.Steps {
				if step.Uses != "" && !shaPinnedAction.MatchString(step.Uses) {
					t.Errorf("%s job %s uses %q; actions must be pinned to a commit SHA", name, jobName, step.Uses)
				}
			}
		}
		for _, stale := range []string{"Xcode_16.app", "iPhone 16 Pro", "{{"} {
			if stale == "{{" {
				if strings.Contains(strings.ReplaceAll(text, "${{", ""), "{{") {
					t.Errorf("%s contains an unrendered template action", name)
				}
				continue
			}
			if strings.Contains(text, stale) {
				t.Errorf("%s hardcodes %q", name, stale)
			}
		}
	}
}

func TestWorkflowPackBuildsTheFirstScheme(t *testing.T) {
	rendered := renderWorkflowPack(t, ProjectTemplateContext{ProjectName: "MyApp", Schemes: []string{"QA", "Production"}})

	var ci workflowFile
	if err := yaml.Unmarshal([]byte(rendered["ci.yml"]), &ci); err != nil {
		t.Fatalf("ci.yml is not valid YAML: %v", err)
	}
	if ci.Env["SCHEME"] != "MyApp-QA" {
		t.Fatalf("SCHEME = %q, want MyApp-QA", ci.Env["SCHEME"])
	}
}

func TestWorkflowPackAsksForASchemeInToolsMode(t *testing.T) {
	rendered := renderWorkflowPack(t, ProjectTemplateContext{IsToolsMode: true})

	var ci workflowFile
	if err := yaml.Unmarshal([]byte(rendered["ci.yml"]), &ci); err != nil {
		t.Fatalf("ci.yml is not valid YAML: %v", err)
	}
	if ci.Env["SCHEME"] != "YourApp" {
		t.Fatalf("SCHEME = %q, want the YourApp placeholder", ci.Env["SCHEME"])
	}
	if !strings.Contains(rendered["ci.yml"], "Set this to the scheme CI should build") {
		t.Fatal("tools mode should explain the SCHEME placeholder")
	}
}
