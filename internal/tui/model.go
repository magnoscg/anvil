package tui

import (
	"context"
	"os"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/oscarcanton/anvilcli/internal/config"
	"github.com/oscarcanton/anvilcli/internal/deps"
	"github.com/oscarcanton/anvilcli/internal/generator"
)

// Screen enumerates the wizard screens.
type Screen int

const (
	ScreenMode     Screen = iota // Mode selection: project vs tools
	ScreenSetup                  // Form: fields + options + deps
	ScreenAIPacks                // AI coding pack selection
	ScreenGenerate               // Progress + done combined
)

// WizardModel is the root BubbleTea v2 model for the `anvil init` wizard.
type WizardModel struct {
	screen Screen
	theme  Theme
	width  int
	height int

	// Shared state
	mode config.ProjectMode
	cfg  config.ProjectConfig
	err  error

	// Dependencies
	checker   *deps.SystemChecker
	generator generator.ProjectGenerator

	// Sub-models (4 screens)
	modeView       modeModel
	setupView      setupModel
	packPickerView packPickerModel
	generateView   generateModel

	// Quit confirmation
	confirmQuit bool
}

// NewWizardModel creates the root wizard model with injected dependencies.
func NewWizardModel(checker *deps.SystemChecker, gen generator.ProjectGenerator) WizardModel {
	theme := DefaultTheme()
	return WizardModel{
		screen:         ScreenMode,
		theme:          theme,
		checker:        checker,
		generator:      gen,
		modeView:       newModeModel(theme),
		setupView:      newSetupModel(theme),
		packPickerView: newPackPickerModel(theme),
		generateView:   newGenerateModel(theme),
	}
}

// Init implements tea.Model.
func (m WizardModel) Init() tea.Cmd {
	return nil
}

// Update implements tea.Model.
func (m WizardModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.modeView.width = msg.Width
		m.setupView.width = msg.Width
		m.packPickerView.width = msg.Width
		m.generateView.width = msg.Width
		return m, nil

	case ModeSelectedMsg:
		m.mode = msg.Mode
		if msg.Mode == config.ModeProject {
			m.screen = ScreenSetup
			return m, m.setupView.startDepsCheck(m.checker)
		}
		// Tools mode: skip setup, go directly to AI packs
		m.screen = ScreenAIPacks
		return m, nil

	case OpenPacksMsg:
		m.screen = ScreenAIPacks
		return m, nil

	case SetupBackMsg:
		m.screen = ScreenMode
		return m, nil

	case PacksConfirmedMsg:
		if m.mode == config.ModeTools {
			cwd, err := os.Getwd()
			if err != nil {
				m.err = err
				return m, nil
			}
			cfg := config.ProjectConfig{
				Mode:        config.ModeTools,
				AIPacks:     msg.Packs,
				SkillsScope: msg.SkillsScope,
				OutputDir:   cwd,
			}
			m.cfg = cfg
			m.screen = ScreenGenerate
			m.generateView.generating = true
			m.generateView.cfg = cfg
			return m, m.generateView.startTools(m.generator, cfg)
		}
		cfg, err := m.setupView.buildConfig()
		if err != nil {
			m.err = err
			return m, nil
		}
		cfg.Mode = config.ModeProject
		cfg.AIPacks = msg.Packs
		cfg.SkillsScope = msg.SkillsScope
		m.cfg = cfg
		m.screen = ScreenGenerate
		m.generateView.generating = true
		m.generateView.cfg = cfg
		return m, m.generateView.start(m.generator, cfg)

	case PacksBackMsg:
		if m.mode == config.ModeTools {
			m.screen = ScreenMode
		} else {
			m.screen = ScreenSetup
		}
		return m, nil

	case tea.KeyPressMsg:
		if m.confirmQuit {
			return m.handleQuitConfirmation(msg)
		}
		if isQuit(msg) && (m.screen == ScreenMode || m.screen == ScreenSetup || m.screen == ScreenAIPacks) {
			m.confirmQuit = true
			return m, nil
		}
	}

	// Delegate to current screen
	var cmd tea.Cmd
	switch m.screen {
	case ScreenMode:
		m.modeView, cmd = m.modeView.update(msg)
	case ScreenSetup:
		m.setupView, cmd = m.setupView.update(msg)
	case ScreenAIPacks:
		m.packPickerView, cmd = m.packPickerView.update(msg)
	case ScreenGenerate:
		m.generateView, cmd = m.generateView.update(msg)
	}

	return m, cmd
}

// View implements tea.Model.
func (m WizardModel) View() tea.View {
	var content string

	if m.confirmQuit {
		content = m.renderQuitConfirmation()
	} else {
		switch m.screen {
		case ScreenMode:
			content = m.modeView.view()
		case ScreenSetup:
			content = m.setupView.view()
		case ScreenAIPacks:
			content = m.packPickerView.view()
		case ScreenGenerate:
			content = m.generateView.view()
		}
	}

	// Center the content block in the full terminal width
	termWidth := m.width
	if termWidth > maxContentWidth {
		content = lipgloss.NewStyle().
			Width(termWidth).
			Align(lipgloss.Center).
			Render(content)
	}

	v := tea.NewView(content)
	v.AltScreen = true
	return v
}

func (m WizardModel) handleQuitConfirmation(msg tea.KeyPressMsg) (tea.Model, tea.Cmd) {
	if isKey(msg, "y") {
		return m, tea.Quit
	}
	m.confirmQuit = false
	return m, nil
}

func (m WizardModel) renderQuitConfirmation() string {
	w := maxWidth(m.width)

	modal := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(m.theme.Warning).
		Padding(1, 3).
		Width(w / 2).
		Render(
			m.theme.WarningText.Render("Quit AnvilCLI?") + "\n\n" +
				m.theme.Body.Render("Press ") +
				m.theme.Bold.Render("y") +
				m.theme.Body.Render(" to quit, any other key to continue."),
		)

	return lipgloss.NewStyle().
		Width(w).
		Padding(3, 0).
		Align(lipgloss.Center).
		Render(modal)
}

// runGenerate runs the project generator and returns the result as a Msg.
func runGenerate(gen generator.ProjectGenerator, cfg config.ProjectConfig) tea.Cmd {
	return func() tea.Msg {
		result, err := gen.Generate(context.Background(), cfg)
		return generateDoneMsg{result: result, err: err}
	}
}

// runGenerateTools runs the tools-only generator and returns the result as a Msg.
func runGenerateTools(gen generator.ProjectGenerator, cfg config.ProjectConfig) tea.Cmd {
	return func() tea.Msg {
		result, err := gen.GenerateToolsOnly(context.Background(), cfg)
		return generateDoneMsg{result: result, err: err}
	}
}
