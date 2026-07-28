package tui

import (
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/oscarcanton/anvilcli/internal/config"
)

// ModeSelectedMsg is sent when the user selects a mode on the mode screen.
type ModeSelectedMsg struct {
	Mode config.ProjectMode
}

// modeModel is the sub-model for the mode selection screen.
type modeModel struct {
	theme   Theme
	width   int
	focused int // 0 = project, 1 = tools
}

// newModeModel creates a mode selection model with default state.
func newModeModel(theme Theme) modeModel {
	return modeModel{
		theme: theme,
	}
}

func (m modeModel) update(msg tea.Msg) (modeModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		return m.handleKey(msg)
	}
	return m, nil
}

func (m modeModel) handleKey(msg tea.KeyPressMsg) (modeModel, tea.Cmd) {
	switch {
	case isKey(msg, "up", "k"):
		if m.focused > 0 {
			m.focused--
		}

	case isKey(msg, "down", "j"):
		if m.focused < 1 {
			m.focused++
		}

	case isEnter(msg):
		mode := config.ModeProject
		if m.focused == 1 {
			mode = config.ModeTools
		}
		return m, func() tea.Msg {
			return ModeSelectedMsg{Mode: mode}
		}
	}

	return m, nil
}

func (m modeModel) view() string {
	w := maxWidth(m.width)

	header := renderBrandHeader(m.theme, w)

	var b strings.Builder
	b.WriteString("\n")

	b.WriteString("  " + m.theme.Bold.Render("What would you like to do?") + "\n\n")

	type modeOption struct {
		label string
		hint  string
	}
	options := []modeOption{
		{"Create new iOS project", "Full project forge with Xcode project, architecture, and AI tools"},
		{"Install AI coding tools", "Add CLAUDE.md, docs, skills, and commands to an existing project"},
	}

	for i, opt := range options {
		isFocused := i == m.focused

		var radio string
		if isFocused {
			radio = m.theme.Prompt.Render("(*)")
		} else {
			radio = m.theme.MutedText.Render("( )")
		}

		label := m.theme.Body.Render(opt.label)
		if isFocused {
			label = m.theme.Bold.Render(opt.label)
		}

		if isFocused {
			b.WriteString("  " + m.theme.Prompt.Render("❯") + " " + radio + " " + label + "\n")
		} else {
			b.WriteString("    " + radio + " " + label + "\n")
		}
		b.WriteString("         " + m.theme.MutedText.Render(opt.hint) + "\n")
	}

	b.WriteString("\n")
	b.WriteString(renderFooter(m.theme, "↑/↓ select • enter confirm • q quit"))

	formContent := lipgloss.NewStyle().Padding(0, 4).Render(b.String())

	return header + formContent
}
