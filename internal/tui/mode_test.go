package tui

import (
	"testing"

	tea "charm.land/bubbletea/v2"
	"github.com/oscarcanton/anvilcli/internal/config"
)

func TestModeModelInitialState(t *testing.T) {
	m := newModeModel(DefaultTheme())
	if m.focused != 0 {
		t.Errorf("initial focused = %d, want 0 (project mode)", m.focused)
	}
}

func TestModeModelDownKeyChangesFocus(t *testing.T) {
	m := newModeModel(DefaultTheme())
	m, _ = m.update(tea.KeyPressMsg{Code: tea.KeyDown})
	if m.focused != 1 {
		t.Errorf("focused after down = %d, want 1", m.focused)
	}
}

func TestModeModelUpKeyAtZeroStays(t *testing.T) {
	m := newModeModel(DefaultTheme())
	m, _ = m.update(tea.KeyPressMsg{Code: tea.KeyUp})
	if m.focused != 0 {
		t.Errorf("focused after up from 0 = %d, want 0", m.focused)
	}
}

func TestModeModelDownKeyAtOneStays(t *testing.T) {
	m := newModeModel(DefaultTheme())
	m.focused = 1
	m, _ = m.update(tea.KeyPressMsg{Code: tea.KeyDown})
	if m.focused != 1 {
		t.Errorf("focused after down from 1 = %d, want 1", m.focused)
	}
}

func TestModeModelEnterAtProjectEmitsProject(t *testing.T) {
	m := newModeModel(DefaultTheme())
	m.focused = 0
	_, cmd := m.update(tea.KeyPressMsg{Code: tea.KeyEnter})
	if cmd == nil {
		t.Fatal("expected a command from enter, got nil")
	}
	msg := cmd()
	modeMsg, ok := msg.(ModeSelectedMsg)
	if !ok {
		t.Fatalf("expected ModeSelectedMsg, got %T", msg)
	}
	if modeMsg.Mode != config.ModeProject {
		t.Errorf("Mode = %q, want %q", modeMsg.Mode, config.ModeProject)
	}
}

func TestModeModelEnterAtToolsEmitsTools(t *testing.T) {
	m := newModeModel(DefaultTheme())
	m.focused = 1
	_, cmd := m.update(tea.KeyPressMsg{Code: tea.KeyEnter})
	if cmd == nil {
		t.Fatal("expected a command from enter, got nil")
	}
	msg := cmd()
	modeMsg, ok := msg.(ModeSelectedMsg)
	if !ok {
		t.Fatalf("expected ModeSelectedMsg, got %T", msg)
	}
	if modeMsg.Mode != config.ModeTools {
		t.Errorf("Mode = %q, want %q", modeMsg.Mode, config.ModeTools)
	}
}
