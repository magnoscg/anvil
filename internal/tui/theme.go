package tui

import (
	"image/color"

	"charm.land/lipgloss/v2"
)

// Theme holds all Lipgloss v2 styles used across TUI screens.
// Color palette: Catppuccin Mocha.
type Theme struct {
	// Colors
	Primary  color.Color
	Lavender color.Color
	Mauve    color.Color
	Success  color.Color
	Warning  color.Color
	Error    color.Color
	Muted    color.Color
	Text     color.Color
	Surface  color.Color
	Subtext0 color.Color

	// Text styles
	Title       lipgloss.Style
	Subtitle    lipgloss.Style
	Body        lipgloss.Style
	Bold        lipgloss.Style
	ErrorText   lipgloss.Style
	SuccessText lipgloss.Style
	WarningText lipgloss.Style
	MutedText   lipgloss.Style
	Prompt      lipgloss.Style

	// Container styles
	Box        lipgloss.Style
	ErrorBox   lipgloss.Style
	SuccessBox lipgloss.Style
	HelpBar    lipgloss.Style
	CodeBlock  lipgloss.Style
	Badge      lipgloss.Style
}

// DefaultTheme creates the Catppuccin Mocha theme for AnvilCLI.
func DefaultTheme() Theme {
	blue := lipgloss.Color("#89B4FA")
	lavender := lipgloss.Color("#B4BEFE")
	mauve := lipgloss.Color("#CBA6F7")
	green := lipgloss.Color("#A6E3A1")
	yellow := lipgloss.Color("#F9E2AF")
	red := lipgloss.Color("#F38BA8")
	overlay0 := lipgloss.Color("#6C7086")
	subtext0 := lipgloss.Color("#A6ADC8")
	text := lipgloss.Color("#CDD6F4")
	surface0 := lipgloss.Color("#313244")

	t := Theme{
		Primary:  blue,
		Lavender: lavender,
		Mauve:    mauve,
		Success:  green,
		Warning:  yellow,
		Error:    red,
		Muted:    overlay0,
		Text:     text,
		Surface:  surface0,
		Subtext0: subtext0,
	}

	t.Title = lipgloss.NewStyle().
		Bold(true).
		Foreground(blue)

	t.Subtitle = lipgloss.NewStyle().
		Foreground(lavender)

	t.Body = lipgloss.NewStyle().
		Foreground(text)

	t.Bold = lipgloss.NewStyle().
		Bold(true).
		Foreground(text)

	t.ErrorText = lipgloss.NewStyle().
		Bold(true).
		Foreground(red)

	t.SuccessText = lipgloss.NewStyle().
		Bold(true).
		Foreground(green)

	t.WarningText = lipgloss.NewStyle().
		Bold(true).
		Foreground(yellow)

	t.MutedText = lipgloss.NewStyle().
		Foreground(overlay0)

	t.Prompt = lipgloss.NewStyle().
		Foreground(mauve).
		Bold(true)

	t.Box = lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(blue).
		Padding(1, 2)

	t.ErrorBox = lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(red).
		Padding(1, 2)

	t.SuccessBox = lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(green).
		Padding(1, 2)

	t.HelpBar = lipgloss.NewStyle().
		Foreground(overlay0).
		MarginTop(1)

	t.CodeBlock = lipgloss.NewStyle().
		Foreground(blue).
		Padding(0, 1)

	t.Badge = lipgloss.NewStyle().
		Foreground(subtext0)

	return t
}
