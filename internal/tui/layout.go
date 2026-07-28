package tui

import (
	"strings"

	"charm.land/lipgloss/v2"
)

// maxContentWidth is the maximum content width for TUI screens.
const maxContentWidth = 80

// appVersion is shown in the header. Set via SetAppVersion before starting the TUI.
var appVersion = "dev"

// SetAppVersion sets the version displayed in the TUI header.
func SetAppVersion(v string) {
	appVersion = v
}

// bannerLines are the filled block-letter "ANVIL" logo lines.
// Generated with oh-my-logo --filled --letter-spacing 0.
var bannerLines = []string{
	" █████╗  ███╗   ██╗ ██╗   ██╗ ██╗ ██╗     ",
	"██╔══██╗ ████╗  ██║ ██║   ██║ ██║ ██║     ",
	"███████║ ██╔██╗ ██║ ██║   ██║ ██║ ██║     ",
	"██╔══██║ ██║╚██╗██║ ╚██╗ ██╔╝ ██║ ██║     ",
	"██║  ██║ ██║ ╚████║  ╚████╔╝  ██║ ███████╗",
	"╚═╝  ╚═╝ ╚═╝  ╚═══╝   ╚═══╝   ╚═╝ ╚══════╝",
}

// renderBrandHeader renders the ANVIL banner with vertical gradient + subtitle.
func renderBrandHeader(theme Theme, width int) string {
	w := maxWidth(width)

	// Render each banner line with a vertical gradient from Mauve → Blue
	gradient := lipgloss.Blend1D(len(bannerLines), theme.Mauve, theme.Primary)
	var gradientBanner strings.Builder
	for i, line := range bannerLines {
		styled := lipgloss.NewStyle().Bold(true).Foreground(gradient[i]).Render(line)
		gradientBanner.WriteString(styled)
		if i < len(bannerLines)-1 {
			gradientBanner.WriteString("\n")
		}
	}

	// Subtitle + version with more spacing
	version := theme.Badge.Render("v" + appVersion)
	subtitle := theme.Badge.Render("iOS project forge")
	info := subtitle + "  " + version

	// Author signature
	author := theme.MutedText.Render("by Oscar Cantón García")

	// Separator with subtle dots
	sep := lipgloss.NewStyle().Foreground(theme.Surface).Render(
		strings.Repeat("─", w-4),
	)

	// Center everything
	center := lipgloss.NewStyle().Width(w).Align(lipgloss.Center)

	return lipgloss.JoinVertical(lipgloss.Center,
		"",
		"",
		"",
		"",
		center.Render(gradientBanner.String()),
		"",
		center.Render(info),
		center.Render(author),
		"",
		sep,
		"",
	)
}

// renderHeader renders a compact header bar for non-setup screens.
func renderHeader(theme Theme, width int) string {
	w := maxWidth(width)
	logo := theme.Title.Render("⬡ AnvilCLI")
	version := theme.Badge.Render("v" + appVersion)

	logoLen := lipgloss.Width(logo)
	versionLen := lipgloss.Width(version)
	gap := w - logoLen - versionLen
	if gap < 1 {
		gap = 1
	}

	return logo + strings.Repeat(" ", gap) + version
}

// renderFooter renders a styled help bar with highlighted keys.
func renderFooter(theme Theme, helpText string) string {
	return theme.HelpBar.Render(helpText)
}

// renderSectionHeader renders a section title with an icon.
func renderSectionHeader(theme Theme, icon string, title string) string {
	return "  " + lipgloss.NewStyle().Foreground(theme.Lavender).Render(icon) +
		" " + lipgloss.NewStyle().Foreground(theme.Lavender).Bold(true).Render(title)
}

// renderSeparator renders a horizontal divider of the given width using the muted color.
func renderSeparator(theme Theme, width int) string {
	if width <= 0 {
		width = maxContentWidth
	}
	line := strings.Repeat("─", width)
	return lipgloss.NewStyle().Foreground(theme.Muted).Render(line)
}

// maxWidth clamps the available width to the maximum content width.
func maxWidth(available int) int {
	if available <= 0 || available > maxContentWidth {
		return maxContentWidth
	}
	return available
}

// pad right-pads a string to the given width with spaces.
func pad(s string, width int) string {
	if len(s) >= width {
		return s
	}
	return s + strings.Repeat(" ", width-len(s))
}
