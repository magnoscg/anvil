package tui

import (
	"strings"
	"testing"

	"github.com/magnoscg/anvil/internal/config"
)

func TestGenerateViewShowsEveryInstallConflict(t *testing.T) {
	model := generateModel{
		theme:     DefaultTheme(),
		width:     120,
		done:      true,
		toolsMode: true,
		steps:     toolsSteps,
		stepIndex: 1,
		err: config.InstallConflictError{Paths: []string{
			".claude/CLAUDE.md",
			"~/.claude/skills/swift-concurrency",
		}},
	}

	view := model.view()
	for _, expected := range []string{
		"Generation failed",
		".claude/CLAUDE.md",
		"~/.claude/skills/swift-concurrency",
	} {
		if !strings.Contains(view, expected) {
			t.Fatalf("view does not contain %q:\n%s", expected, view)
		}
	}
}
