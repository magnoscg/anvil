package tui

import (
	"strings"
	"testing"

	"github.com/charmbracelet/x/ansi"
)

func TestMaxWidth(t *testing.T) {
	tests := []struct {
		name      string
		available int
		want      int
	}{
		{"zero defaults to max", 0, maxContentWidth},
		{"negative defaults to max", -1, maxContentWidth},
		{"within limit", 60, 60},
		{"at limit", maxContentWidth, maxContentWidth},
		{"above limit clamps", 120, maxContentWidth},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := maxWidth(tt.available); got != tt.want {
				t.Errorf("maxWidth(%d) = %d, want %d", tt.available, got, tt.want)
			}
		})
	}
}

func TestRenderSeparator(t *testing.T) {
	theme := DefaultTheme()
	result := ansi.Strip(renderSeparator(theme, 10))
	expected := strings.Repeat("─", 10)
	if !strings.Contains(result, expected) {
		t.Errorf("renderSeparator should contain 10 dash characters, got: %q", result)
	}
}

func TestRenderSeparatorDefaultWidth(t *testing.T) {
	theme := DefaultTheme()
	result := ansi.Strip(renderSeparator(theme, 0))
	expected := strings.Repeat("─", maxContentWidth)
	if !strings.Contains(result, expected) {
		t.Errorf("renderSeparator(0) should use maxContentWidth dashes")
	}
}

func TestRenderHeader(t *testing.T) {
	theme := DefaultTheme()
	result := ansi.Strip(renderHeader(theme, 80))
	if !strings.Contains(result, "AnvilCLI") {
		t.Error("renderHeader should contain AnvilCLI")
	}
	if !strings.Contains(result, "v"+appVersion) {
		t.Error("renderHeader should contain version")
	}
}

func TestRenderBrandHeader(t *testing.T) {
	theme := DefaultTheme()
	result := ansi.Strip(renderBrandHeader(theme, 80))
	if !strings.Contains(result, "v"+appVersion) {
		t.Error("renderBrandHeader should contain version")
	}
	if !strings.Contains(result, "iOS project forge") {
		t.Error("renderBrandHeader should contain subtitle")
	}
	if !strings.Contains(result, "█████") {
		t.Error("renderBrandHeader should contain block banner")
	}
	if !strings.Contains(result, "Oscar") {
		t.Error("renderBrandHeader should contain author signature")
	}
}

func TestRenderFooter(t *testing.T) {
	theme := DefaultTheme()
	result := ansi.Strip(renderFooter(theme, "press q to quit"))
	if !strings.Contains(result, "press q to quit") {
		t.Error("renderFooter should contain the help text")
	}
}

func TestScreenConstants(t *testing.T) {
	// Verify the 4-screen architecture
	if ScreenMode != 0 {
		t.Error("ScreenMode should be 0")
	}
	if ScreenSetup != 1 {
		t.Error("ScreenSetup should be 1")
	}
	if ScreenAIPacks != 2 {
		t.Error("ScreenAIPacks should be 2")
	}
	if ScreenGenerate != 3 {
		t.Error("ScreenGenerate should be 3")
	}
}

func TestPad(t *testing.T) {
	tests := []struct {
		name  string
		input string
		width int
		want  string
	}{
		{"shorter than width", "hi", 5, "hi   "},
		{"equal to width", "hello", 5, "hello"},
		{"longer than width", "hello world", 5, "hello world"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := pad(tt.input, tt.width); got != tt.want {
				t.Errorf("pad(%q, %d) = %q, want %q", tt.input, tt.width, got, tt.want)
			}
		})
	}
}
