package tui

import (
	"fmt"
	"strings"
	"time"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/magnoscg/anvil/internal/config"
	"github.com/magnoscg/anvil/internal/generator"
)

// generateDoneMsg is sent when project generation completes.
type generateDoneMsg struct {
	result config.GenerationResult
	err    error
}

// generateTickMsg drives the spinner animation.
type generateTickMsg time.Time

type generateModel struct {
	theme      Theme
	width      int
	cfg        config.ProjectConfig
	generating bool
	done       bool
	result     config.GenerationResult
	err        error
	frame      int
	steps      []string
	stepIndex  int
	toolsMode  bool
}

var spinnerFrames = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

var generateSteps = []string{
	"Creating directory structure",
	"Rendering templates",
	"Generating Xcode project",
	"Initializing git repository",
	"Writing configuration",
}

var toolsSteps = []string{
	"Resolving pack dependencies",
	"Installing AI coding tools",
	"Writing configuration files",
}

func newGenerateModel(theme Theme) generateModel {
	return generateModel{
		theme: theme,
		steps: generateSteps,
	}
}

func (m generateModel) start(gen generator.ProjectGenerator, cfg config.ProjectConfig) tea.Cmd {
	return tea.Batch(
		runGenerate(gen, cfg),
		doTick(),
	)
}

func (m *generateModel) startTools(gen generator.ProjectGenerator, cfg config.ProjectConfig) tea.Cmd {
	m.steps = toolsSteps
	m.toolsMode = true
	return tea.Batch(
		runGenerateTools(gen, cfg),
		doTick(),
	)
}

func doTick() tea.Cmd {
	return tea.Tick(80*time.Millisecond, func(t time.Time) tea.Msg {
		return generateTickMsg(t)
	})
}

func (m generateModel) update(msg tea.Msg) (generateModel, tea.Cmd) {
	switch msg := msg.(type) {
	case generateTickMsg:
		if m.generating {
			m.frame = (m.frame + 1) % len(spinnerFrames)
			if m.stepIndex < len(m.steps)-1 {
				m.stepIndex++
			}
			return m, doTick()
		}
		return m, nil

	case generateDoneMsg:
		m.generating = false
		m.done = true
		m.result = msg.result
		m.err = msg.err
		return m, nil

	case tea.KeyPressMsg:
		if m.done {
			if isEnter(msg) || isQuit(msg) {
				return m, tea.Quit
			}
		}
	}

	return m, nil
}

func (m generateModel) view() string {
	w := maxWidth(m.width)
	var b strings.Builder

	projectName := m.cfg.Name
	if projectName == "" {
		projectName = "project"
	}

	b.WriteString(renderHeader(m.theme, w))
	b.WriteString("\n\n")

	if m.generating {
		if m.toolsMode {
			b.WriteString("  " + m.theme.Bold.Render("Installing AI coding tools...") + "\n\n")
		} else {
			b.WriteString("  " + m.theme.Bold.Render("Generating "+projectName+"...") + "\n\n")
		}
	}

	// Progress steps
	for i, step := range m.steps {
		var icon, label string
		switch {
		case i < m.stepIndex:
			icon = m.theme.SuccessText.Render("✓")
			label = m.theme.Body.Render(step)
		case i == m.stepIndex && m.generating:
			icon = m.theme.WarningText.Render(spinnerFrames[m.frame])
			label = m.theme.Bold.Render(step)
		case m.done && m.err == nil:
			icon = m.theme.SuccessText.Render("✓")
			label = m.theme.Body.Render(step)
		case m.done && m.err != nil && i == m.stepIndex:
			icon = m.theme.ErrorText.Render("✗")
			label = m.theme.ErrorText.Render(step)
		default:
			icon = m.theme.MutedText.Render("○")
			label = m.theme.MutedText.Render(step)
		}
		b.WriteString("  " + icon + " " + label + "\n")
	}

	b.WriteString("\n")

	if m.done && m.err == nil {
		r := m.result
		fileCount := len(r.FilesCreated)
		duration := r.Duration.Round(100 * time.Millisecond).String()

		var box strings.Builder

		if m.toolsMode {
			box.WriteString(m.theme.SuccessText.Render("✓  AI coding tools installed successfully!"))
			box.WriteString("\n\n")
			box.WriteString(m.theme.MutedText.Render(fmt.Sprintf("%d files • %s", fileCount, duration)))
			box.WriteString("\n\n")
			box.WriteString(m.theme.Body.Render("Your CLAUDE.md, docs, skills, and commands are ready."))
		} else {
			scheme := projectName + "-Dev"
			if len(m.cfg.Schemes) > 0 {
				scheme = projectName + "-" + m.cfg.Schemes[0]
			}

			box.WriteString(m.theme.SuccessText.Render("✓  " + projectName + " created successfully!"))
			box.WriteString("\n\n")
			box.WriteString(m.theme.MutedText.Render(fmt.Sprintf("%d files • %s • %s", fileCount, duration, r.ProjectDir)))
			box.WriteString("\n\n")
			box.WriteString(m.theme.Body.Render("$ cd " + projectName))
			box.WriteString("\n")
			box.WriteString(m.theme.Body.Render("$ open " + projectName + ".xcodeproj"))
			box.WriteString("\n")
			box.WriteString(m.theme.Body.Render("$ xcodebuild build -scheme " + scheme))
		}

		b.WriteString(m.theme.SuccessBox.Width(w - 4).Render(box.String()))
		b.WriteString("\n\n")
		b.WriteString(renderFooter(m.theme, "enter exit • q quit"))
	} else if m.done && m.err != nil {
		b.WriteString(m.theme.ErrorBox.Width(w - 4).Render(
			m.theme.ErrorText.Render("Generation failed") + "\n\n" +
				m.theme.Body.Render(m.err.Error()),
		))
		b.WriteString("\n\n")
		b.WriteString(renderFooter(m.theme, "q quit"))
	}

	return lipgloss.NewStyle().Padding(1, 2).Render(b.String())
}
