package tui

import (
	"fmt"
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/oscarcanton/anvilcli/internal/config"
)

// OpenPacksMsg is sent when the user navigates to the pack selection screen.
type OpenPacksMsg struct{}

// PacksConfirmedMsg is sent when the user confirms their pack selection.
type PacksConfirmedMsg struct {
	Packs       []string
	SkillsScope string
}

// PacksBackMsg is sent when the user presses Esc to return to setup.
type PacksBackMsg struct{}

// packItem wraps a config.Pack with selection state.
type packItem struct {
	pack         config.Pack
	selected     bool
	autoSelected bool
}

// packPickerModel is a standalone sub-model for the AI pack selection screen.
type packPickerModel struct {
	theme           Theme
	width           int
	packs           []packItem
	focused         int
	confirmed       bool
	showScopePrompt bool
	scopeFocused    int // 0=project, 1=global

	// manuallySelected tracks which slugs the user explicitly toggled on.
	// Used to distinguish manual selections from auto-selected dependencies.
	manuallySelected map[string]bool

	// statusMsg is a brief feedback message shown after toggling (e.g. dependency info).
	statusMsg string
}

// newPackPickerModel creates a pack picker initialized with all available packs.
func newPackPickerModel(theme Theme) packPickerModel {
	allPacks := config.AllPacks()
	items := make([]packItem, len(allPacks))
	for i, p := range allPacks {
		items[i] = packItem{pack: p}
	}
	return packPickerModel{
		theme:            theme,
		packs:            items,
		manuallySelected: make(map[string]bool),
	}
}

func (m packPickerModel) update(msg tea.Msg) (packPickerModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		return m.handleKey(msg)
	}
	return m, nil
}

func (m packPickerModel) handleKey(msg tea.KeyPressMsg) (packPickerModel, tea.Cmd) {
	// Scope prompt mode
	if m.showScopePrompt {
		return m.handleScopeKey(msg)
	}

	switch {
	case isKey(msg, "up", "k"):
		m.statusMsg = ""
		if m.focused > 0 {
			m.focused--
		} else {
			m.focused = len(m.packs) - 1
		}

	case isKey(msg, "down", "j"):
		m.statusMsg = ""
		if m.focused < len(m.packs)-1 {
			m.focused++
		} else {
			m.focused = 0
		}

	case isKey(msg, " ", "space"):
		m.togglePack()

	case isEnter(msg):
		return m.confirmSelection()

	case isKey(msg, "esc"):
		return m, func() tea.Msg { return PacksBackMsg{} }
	}

	return m, nil
}

func (m packPickerModel) handleScopeKey(msg tea.KeyPressMsg) (packPickerModel, tea.Cmd) {
	switch {
	case isKey(msg, "up", "k", "down", "j"):
		// Toggle between 0 and 1
		m.scopeFocused = 1 - m.scopeFocused

	case isEnter(msg):
		scope := "project"
		if m.scopeFocused == 1 {
			scope = "global"
		}
		m.confirmed = true
		slugs := m.selectedSlugs()
		return m, func() tea.Msg {
			return PacksConfirmedMsg{Packs: slugs, SkillsScope: scope}
		}

	case isKey(msg, "esc"):
		m.showScopePrompt = false
		m.scopeFocused = 0
	}

	return m, nil
}

// togglePack handles space-bar toggle with dependency resolution.
func (m *packPickerModel) togglePack() {
	item := &m.packs[m.focused]

	if item.selected {
		// Attempting to deselect
		if item.autoSelected {
			// Cannot deselect an auto-selected dependency
			m.statusMsg = fmt.Sprintf("Required by %s - deselect it first", m.findDependent(item.pack.Slug))
			return
		}

		// Check if any other selected pack depends on this one
		if dep := m.findDependent(item.pack.Slug); dep != "" {
			m.statusMsg = fmt.Sprintf("Required by %s - deselect it first", dep)
			return
		}

		// Safe to deselect
		item.selected = false
		delete(m.manuallySelected, item.pack.Slug)
		m.statusMsg = ""
		m.recalculateAutoSelections()
	} else {
		// Selecting
		item.selected = true
		m.manuallySelected[item.pack.Slug] = true
		m.statusMsg = ""
		m.resolveAndAutoSelect()
	}
}

// resolveAndAutoSelect uses ResolveDependencies to mark missing deps as autoSelected.
func (m *packPickerModel) resolveAndAutoSelect() {
	selected := m.selectedSlugs()
	resolved := config.ResolveDependencies(selected)

	for _, slug := range resolved {
		idx := m.indexBySlug(slug)
		if idx < 0 {
			continue
		}
		if !m.packs[idx].selected {
			m.packs[idx].selected = true
			m.packs[idx].autoSelected = true
			dep, _ := config.PackBySlug(slug)
			m.statusMsg = fmt.Sprintf("%s auto-selected - required by %s",
				dep.DisplayName, m.packs[m.focused].pack.DisplayName)
		}
	}
}

// recalculateAutoSelections recalculates which packs should be autoSelected
// based on current manual selections.
func (m *packPickerModel) recalculateAutoSelections() {
	// Collect manually selected slugs
	var manualSlugs []string
	for slug := range m.manuallySelected {
		manualSlugs = append(manualSlugs, slug)
	}

	// Resolve all deps from manual selections
	resolved := config.ResolveDependencies(manualSlugs)
	resolvedSet := make(map[string]bool, len(resolved))
	for _, s := range resolved {
		resolvedSet[s] = true
	}

	// Update every pack
	for i := range m.packs {
		slug := m.packs[i].pack.Slug
		if m.manuallySelected[slug] {
			m.packs[i].selected = true
			m.packs[i].autoSelected = false
		} else if resolvedSet[slug] {
			m.packs[i].selected = true
			m.packs[i].autoSelected = true
		} else {
			m.packs[i].selected = false
			m.packs[i].autoSelected = false
		}
	}
}

// findDependent returns the DisplayName of the first selected pack that depends on slug.
func (m packPickerModel) findDependent(slug string) string {
	for _, item := range m.packs {
		if !item.selected || item.pack.Slug == slug {
			continue
		}
		for _, dep := range item.pack.Requires {
			if dep == slug {
				return item.pack.DisplayName
			}
		}
	}
	return ""
}

// selectedSlugs returns the slugs of all currently selected packs.
func (m packPickerModel) selectedSlugs() []string {
	var slugs []string
	for _, item := range m.packs {
		if item.selected {
			slugs = append(slugs, item.pack.Slug)
		}
	}
	return slugs
}

// hasSelectedSkills returns true if any selected pack has HasSkills=true.
func (m packPickerModel) hasSelectedSkills() bool {
	for _, item := range m.packs {
		if item.selected && item.pack.HasSkills {
			return true
		}
	}
	return false
}

// confirmSelection handles the enter key: show scope prompt or emit confirmed.
func (m packPickerModel) confirmSelection() (packPickerModel, tea.Cmd) {
	slugs := m.selectedSlugs()
	if len(slugs) == 0 {
		// Nothing selected, emit with empty list (skip packs)
		m.confirmed = true
		return m, func() tea.Msg {
			return PacksConfirmedMsg{Packs: nil, SkillsScope: ""}
		}
	}

	if m.hasSelectedSkills() {
		m.showScopePrompt = true
		m.scopeFocused = 0
		return m, nil
	}

	m.confirmed = true
	return m, func() tea.Msg {
		return PacksConfirmedMsg{Packs: slugs, SkillsScope: ""}
	}
}

// indexBySlug returns the index of a pack by slug, or -1 if not found.
func (m packPickerModel) indexBySlug(slug string) int {
	for i, item := range m.packs {
		if item.pack.Slug == slug {
			return i
		}
	}
	return -1
}

// view renders the pack picker screen.
func (m packPickerModel) view() string {
	w := maxWidth(m.width)

	// Compact header
	header := renderHeader(m.theme, w)

	var b strings.Builder
	b.WriteString("\n\n")

	// Section header
	b.WriteString(renderSectionHeader(m.theme, "◆", "AI Coding Packs") + "\n")
	b.WriteString("  " + m.theme.MutedText.Render("  Select the packs to include in your project") + "\n\n")

	// Pack list
	for i, item := range m.packs {
		isFocused := i == m.focused

		// Checkbox
		var checkbox string
		switch {
		case item.selected && item.autoSelected:
			checkbox = m.theme.MutedText.Render("[✓]")
		case item.selected:
			checkbox = m.theme.SuccessText.Render("[✓]")
		default:
			checkbox = m.theme.MutedText.Render("[ ]")
		}

		// Label
		label := item.pack.DisplayName
		var styledLabel string
		if isFocused {
			styledLabel = m.theme.Bold.Render(label)
		} else if item.autoSelected {
			styledLabel = m.theme.MutedText.Render(label)
		} else {
			styledLabel = m.theme.Body.Render(label)
		}

		// Auto-selected badge
		autoLabel := ""
		if item.autoSelected {
			autoLabel = m.theme.MutedText.Render(" (auto)")
		}

		// Focus indicator
		if isFocused {
			b.WriteString("  " + m.theme.Prompt.Render("❯") + " " + checkbox + " " + styledLabel + autoLabel + "\n")
		} else {
			b.WriteString("    " + checkbox + " " + styledLabel + autoLabel + "\n")
		}

		// Description
		desc := item.pack.Description
		if len(item.pack.Requires) > 0 {
			desc += " (requires " + strings.Join(m.requiresDisplayNames(item.pack.Requires), ", ") + ")"
		}
		if isFocused {
			b.WriteString("         " + m.theme.MutedText.Render(desc) + "\n")
		} else {
			b.WriteString("         " + m.theme.MutedText.Render(desc) + "\n")
		}
	}

	// Status message
	if m.statusMsg != "" {
		b.WriteString("\n  " + m.theme.WarningText.Render(m.statusMsg))
	}

	b.WriteString("\n")

	// Selected packs summary
	selected := m.selectedSlugs()
	if len(selected) > 0 {
		b.WriteString(renderSeparator(m.theme, w-8) + "\n\n")
		b.WriteString("  " + m.theme.Subtitle.Render("Selected: "))
		var names []string
		for _, item := range m.packs {
			if item.selected {
				names = append(names, item.pack.DisplayName)
			}
		}
		b.WriteString(m.theme.Body.Render(strings.Join(names, ", ")) + "\n")
	}

	b.WriteString("\n")

	// Scope prompt overlay
	if m.showScopePrompt {
		b.WriteString(m.renderScopePrompt())
		b.WriteString("\n")
		b.WriteString(renderFooter(m.theme, "↑/↓ select • enter confirm • esc back"))
	} else {
		b.WriteString(renderFooter(m.theme, "↑/↓ navigate • space toggle • enter confirm • esc back"))
	}

	formContent := lipgloss.NewStyle().Padding(0, 4).Render(b.String())

	return lipgloss.NewStyle().Padding(1, 2).Render(header) + formContent
}

// renderScopePrompt renders the skills scope selection prompt.
func (m packPickerModel) renderScopePrompt() string {
	var b strings.Builder

	b.WriteString(renderSeparator(m.theme, 40) + "\n\n")
	b.WriteString("  " + m.theme.Bold.Render("Where should skills be installed?") + "\n\n")

	options := []struct {
		label string
		hint  string
	}{
		{"Project (.claude/skills/)", "Skills available only in this project"},
		{"Global (~/.claude/skills/)", "Skills available in all projects"},
	}

	for i, opt := range options {
		isFocused := i == m.scopeFocused

		var radio string
		if isFocused {
			radio = m.theme.Prompt.Render("(●)")
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

	return b.String()
}

// requiresDisplayNames maps pack slugs to their display names.
func (m packPickerModel) requiresDisplayNames(slugs []string) []string {
	names := make([]string, 0, len(slugs))
	for _, slug := range slugs {
		if p, ok := config.PackBySlug(slug); ok {
			names = append(names, p.DisplayName)
		}
	}
	return names
}
