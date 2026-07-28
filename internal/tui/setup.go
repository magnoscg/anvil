package tui

import (
	"context"
	"fmt"
	"os"
	"regexp"
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/magnoscg/anvil/internal/config"
	"github.com/magnoscg/anvil/internal/deps"
)

var validDirName = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_-]*$`)

const (
	fieldProjectName = iota
	fieldBundleID
	fieldIOSVersion
	fieldSwiftVersion
	fieldSchemes
	fieldCount
)

// featureNode represents one item in the hierarchical feature tree.
type featureNode struct {
	label    string
	checked  bool
	isGroup  bool
	expanded bool
	depth    int
	packSlug string // Non-empty if this is an AI coding pack item.
}

// SetupBackMsg is sent when the user presses Esc to return to mode selection.
type SetupBackMsg struct{}

// depsCheckedMsg is sent after the dependency check completes.
type depsCheckedMsg struct {
	report config.DependencyReport
}

type configField struct {
	label       string
	placeholder string
	value       string
}

type setupModel struct {
	theme       Theme
	width       int
	fields      [fieldCount]configField
	features    []featureNode
	focused     int
	cursor      int
	depsReport  config.DependencyReport
	depsChecked bool

	// Scope prompt for AI packs with skills.
	showScopePrompt bool
	scopeFocused    int // 0=project, 1=global
}

// buildFeatureTree creates the hierarchical feature list with AI packs as a group.
func buildFeatureTree() []featureNode {
	nodes := []featureNode{
		{label: "SwiftData persistence", depth: 0},
		{label: "Example feature", depth: 0},
	}

	// AI Coding Packs group
	nodes = append(nodes, featureNode{
		label:   "AI Coding Packs",
		isGroup: true,
		depth:   0,
	})

	for _, pack := range config.AllPacks() {
		nodes = append(nodes, featureNode{
			label:    pack.DisplayName,
			depth:    1,
			packSlug: pack.Slug,
		})
	}

	return nodes
}

// totalFocusable returns the count of fields + visible feature nodes.
func (m setupModel) totalFocusable() int {
	return fieldCount + m.visibleFeatureCount()
}

// visibleFeatureCount counts feature nodes that are currently visible.
func (m setupModel) visibleFeatureCount() int {
	count := 0
	skipChildren := false
	for _, f := range m.features {
		if f.depth == 0 {
			skipChildren = false
			count++
			if f.isGroup && !f.expanded {
				skipChildren = true
			}
		} else if !skipChildren {
			count++
		}
	}
	return count
}

// visibleFeatures returns the indices of visible feature nodes.
func (m setupModel) visibleFeatures() []int {
	var indices []int
	skipChildren := false
	for i, f := range m.features {
		if f.depth == 0 {
			skipChildren = false
			indices = append(indices, i)
			if f.isGroup && !f.expanded {
				skipChildren = true
			}
		} else if !skipChildren {
			indices = append(indices, i)
		}
	}
	return indices
}

// featureIndexForFocus maps a focus position (after fields) to the actual feature index.
func (m setupModel) featureIndexForFocus(focus int) int {
	offset := focus - fieldCount
	visible := m.visibleFeatures()
	if offset >= 0 && offset < len(visible) {
		return visible[offset]
	}
	return -1
}

func newSetupModel(theme Theme) setupModel {
	m := setupModel{
		theme: theme,
	}
	m.fields[fieldProjectName] = configField{
		label:       "Project Name",
		placeholder: "MyApp",
	}
	m.fields[fieldBundleID] = configField{
		label:       "Bundle ID",
		placeholder: "com.company.MyApp",
	}
	m.fields[fieldIOSVersion] = configField{
		label:       "iOS Version",
		placeholder: config.DefaultIOSVersion,
		value:       config.DefaultIOSVersion,
	}
	m.fields[fieldSwiftVersion] = configField{
		label:       "Swift Version",
		placeholder: config.DefaultSwiftVersion,
		value:       config.DefaultSwiftVersion,
	}
	m.fields[fieldSchemes] = configField{
		label:       "Schemes",
		placeholder: "Dev, Stg, Production",
		value:       strings.Join(config.DefaultSchemes(), ", "),
	}
	m.features = buildFeatureTree()
	return m
}

func (m setupModel) startDepsCheck(checker *deps.SystemChecker) tea.Cmd {
	return func() tea.Msg {
		report := checker.Check(context.Background())
		return depsCheckedMsg{report: report}
	}
}

func (m setupModel) update(msg tea.Msg) (setupModel, tea.Cmd) {
	switch msg := msg.(type) {
	case depsCheckedMsg:
		m.depsReport = msg.report
		m.depsChecked = true
		return m, nil

	case tea.KeyPressMsg:
		if m.showScopePrompt {
			return m.handleScopeKey(msg)
		}
		return m.handleKey(msg)
	}
	return m, nil
}

func (m setupModel) handleKey(msg tea.KeyPressMsg) (setupModel, tea.Cmd) {
	total := m.totalFocusable()

	switch {
	case isKey(msg, "esc"):
		return m, func() tea.Msg { return SetupBackMsg{} }

	case isKey(msg, "up"):
		if m.focused > 0 {
			m.focused--
			if m.inFieldRange() {
				m.cursor = len(m.fields[m.focused].value)
			}
		}

	case isKey(msg, "down"):
		if m.focused < total-1 {
			m.focused++
			if m.inFieldRange() {
				m.cursor = len(m.fields[m.focused].value)
			}
		}

	case isKey(msg, "tab"):
		m.focused = (m.focused + 1) % total
		if m.inFieldRange() {
			m.cursor = len(m.fields[m.focused].value)
		}

	case isKey(msg, "shift+tab"):
		m.focused = (m.focused - 1 + total) % total
		if m.inFieldRange() {
			m.cursor = len(m.fields[m.focused].value)
		}

	case isKey(msg, "right"):
		if m.inFeatureRange() {
			idx := m.featureIndexForFocus(m.focused)
			if idx >= 0 && m.features[idx].isGroup && !m.features[idx].expanded {
				m.features[idx].expanded = true
				return m, nil
			}
		}
		if m.inFieldRange() && m.cursor < len(m.fields[m.focused].value) {
			m.cursor++
		}

	case isKey(msg, "left"):
		if m.inFeatureRange() {
			idx := m.featureIndexForFocus(m.focused)
			if idx >= 0 && m.features[idx].isGroup && m.features[idx].expanded {
				m.features[idx].expanded = false
				// Clamp focus if it was on a now-hidden child
				newTotal := m.totalFocusable()
				if m.focused >= newTotal {
					m.focused = newTotal - 1
				}
				return m, nil
			}
		}
		if m.inFieldRange() && m.cursor > 0 {
			m.cursor--
		}

	case isKey(msg, " ", "space"):
		if m.inFeatureRange() {
			m.toggleFeature()
		}

	case isEnter(msg):
		if m.inFieldRange() {
			if m.focused < total-1 {
				m.focused++
				if m.inFieldRange() {
					m.cursor = len(m.fields[m.focused].value)
				}
			} else {
				return m.tryConfirm()
			}
		} else if m.inFeatureRange() {
			idx := m.featureIndexForFocus(m.focused)
			if idx >= 0 && m.features[idx].isGroup {
				m.features[idx].expanded = !m.features[idx].expanded
				if !m.features[idx].expanded {
					newTotal := m.totalFocusable()
					if m.focused >= newTotal {
						m.focused = newTotal - 1
					}
				}
			} else {
				return m.tryConfirm()
			}
		}

	case isKey(msg, "home", "ctrl+a"):
		if m.inFieldRange() {
			m.cursor = 0
		}

	case isKey(msg, "end", "ctrl+e"):
		if m.inFieldRange() {
			m.cursor = len(m.fields[m.focused].value)
		}

	case isKey(msg, "backspace"):
		if m.inFieldRange() {
			f := &m.fields[m.focused]
			if m.cursor > 0 {
				f.value = f.value[:m.cursor-1] + f.value[m.cursor:]
				m.cursor--
			}
		}

	case isKey(msg, "delete"):
		if m.inFieldRange() {
			f := &m.fields[m.focused]
			if m.cursor < len(f.value) {
				f.value = f.value[:m.cursor] + f.value[m.cursor+1:]
			}
		}

	case isKey(msg, "ctrl+u"):
		if m.inFieldRange() {
			f := &m.fields[m.focused]
			f.value = f.value[m.cursor:]
			m.cursor = 0
		}

	default:
		if m.inFieldRange() {
			key := msg.String()
			if key == "space" {
				key = " "
			}
			if len(key) == 1 {
				f := &m.fields[m.focused]
				f.value = f.value[:m.cursor] + key + f.value[m.cursor:]
				m.cursor++
			}
		}
	}

	return m, nil
}

// toggleFeature handles space-bar toggle with pack dependency resolution.
func (m *setupModel) toggleFeature() {
	idx := m.featureIndexForFocus(m.focused)
	if idx < 0 {
		return
	}

	feat := &m.features[idx]

	// Groups toggle expand, not checked
	if feat.isGroup {
		feat.expanded = !feat.expanded
		if !feat.expanded {
			newTotal := m.totalFocusable()
			if m.focused >= newTotal {
				m.focused = newTotal - 1
			}
		}
		return
	}

	feat.checked = !feat.checked

	// Pack dependency resolution
	if feat.packSlug != "" {
		m.resolvePackDependencies()
	}
}

// resolvePackDependencies ensures transitive pack dependencies are selected.
func (m *setupModel) resolvePackDependencies() {
	selected := m.selectedPackSlugs()
	resolved := config.ResolveDependencies(selected)

	resolvedSet := make(map[string]bool, len(resolved))
	for _, s := range resolved {
		resolvedSet[s] = true
	}

	manualSet := make(map[string]bool, len(selected))
	for _, s := range selected {
		manualSet[s] = true
	}

	for i := range m.features {
		if m.features[i].packSlug == "" {
			continue
		}
		slug := m.features[i].packSlug
		if manualSet[slug] {
			// Manually selected, keep as-is
			continue
		}
		// Auto-select deps, deselect non-deps
		m.features[i].checked = resolvedSet[slug]
	}
}

// selectedPackSlugs returns slugs of all checked pack features.
func (m setupModel) selectedPackSlugs() []string {
	var slugs []string
	for _, f := range m.features {
		if f.packSlug != "" && f.checked {
			slugs = append(slugs, f.packSlug)
		}
	}
	return slugs
}

// hasSelectedPacksWithSkills checks if any selected pack requires the scope prompt.
func (m setupModel) hasSelectedPacksWithSkills() bool {
	for _, f := range m.features {
		if f.packSlug != "" && f.checked {
			if pack, ok := config.PackBySlug(f.packSlug); ok && pack.HasSkills {
				return true
			}
		}
	}
	return false
}

func (m setupModel) handleScopeKey(msg tea.KeyPressMsg) (setupModel, tea.Cmd) {
	switch {
	case isKey(msg, "up", "k", "down", "j"):
		m.scopeFocused = 1 - m.scopeFocused

	case isEnter(msg):
		scope := "project"
		if m.scopeFocused == 1 {
			scope = "global"
		}
		return m, func() tea.Msg {
			return PacksConfirmedMsg{Packs: m.selectedPackSlugs(), SkillsScope: scope}
		}

	case isKey(msg, "esc"):
		m.showScopePrompt = false
		m.scopeFocused = 0
	}
	return m, nil
}

func (m setupModel) tryConfirm() (setupModel, tea.Cmd) {
	name := m.fields[fieldProjectName].value
	if name == "" || !validDirName.MatchString(name) {
		m.focused = fieldProjectName
		m.cursor = len(m.fields[fieldProjectName].value)
		return m, nil
	}
	if !m.depsChecked || !m.depsReport.Ready() {
		return m, nil
	}

	packs := m.selectedPackSlugs()
	if len(packs) > 0 && m.hasSelectedPacksWithSkills() {
		m.showScopePrompt = true
		m.scopeFocused = 0
		return m, nil
	}

	// No packs or no skills packs — skip scope prompt
	scope := ""
	if len(packs) > 0 {
		scope = "project"
	}
	return m, func() tea.Msg {
		return PacksConfirmedMsg{Packs: packs, SkillsScope: scope}
	}
}

func (m setupModel) inFieldRange() bool {
	return m.focused >= 0 && m.focused < fieldCount
}

func (m setupModel) inFeatureRange() bool {
	return m.focused >= fieldCount && m.focused < m.totalFocusable()
}

func (m setupModel) buildConfig() (config.ProjectConfig, error) {
	name := config.ToPascalCase(m.fields[fieldProjectName].value)

	bundleID := m.fields[fieldBundleID].value
	if bundleID == "" {
		bundleID = "com." + strings.ToLower(name) + "." + name
	}

	iosVer := m.fields[fieldIOSVersion].value
	if iosVer == "" {
		iosVer = config.DefaultIOSVersion
	}

	swiftVer := m.fields[fieldSwiftVersion].value
	if swiftVer == "" {
		swiftVer = config.DefaultSwiftVersion
	}

	schemes := parseSchemes(m.fields[fieldSchemes].value)
	if len(schemes) == 0 {
		schemes = config.DefaultSchemes()
	}

	cwd, err := os.Getwd()
	if err != nil {
		return config.ProjectConfig{}, fmt.Errorf("getting working directory: %w", err)
	}

	// Map feature checkboxes to config flags
	includeSwiftData := false
	includeExample := false
	for _, f := range m.features {
		if f.packSlug != "" || f.isGroup {
			continue
		}
		switch f.label {
		case "SwiftData persistence":
			includeSwiftData = f.checked
		case "Example feature":
			includeExample = f.checked
		}
	}

	return config.ProjectConfig{
		Name:             name,
		BundleID:         bundleID,
		Organization:     config.OrganizationFromBundleID(bundleID),
		IOSVersion:       iosVer,
		SwiftVersion:     swiftVer,
		Schemes:          schemes,
		OutputDir:        cwd,
		IncludeSwiftData: includeSwiftData,
		IncludeExample:   includeExample,
	}, nil
}

// MARK: - View

func (m setupModel) view() string {
	w := maxWidth(m.width)

	header := renderBrandHeader(m.theme, w)

	var b strings.Builder

	b.WriteString("\n")

	// Fields
	for i := range fieldCount {
		f := m.fields[i]
		isFocused := i == m.focused

		if isFocused {
			b.WriteString("  " + m.theme.Prompt.Render("❯") + " ")
			b.WriteString(m.theme.Prompt.Render(pad(f.label, 22)))
		} else {
			b.WriteString("    ")
			b.WriteString(m.theme.MutedText.Render(pad(f.label, 22)))
		}

		if isFocused {
			value := f.value
			if value == "" {
				b.WriteString(m.theme.MutedText.Render("█"))
			} else {
				before := value[:m.cursor]
				cursorChar := " "
				after := ""
				if m.cursor < len(value) {
					cursorChar = string(value[m.cursor])
					after = value[m.cursor+1:]
				}
				cursor := lipgloss.NewStyle().Reverse(true).Render(cursorChar)
				b.WriteString(m.theme.Body.Render(before) + cursor + m.theme.Body.Render(after))
			}
		} else {
			display := f.value
			if display == "" {
				b.WriteString(m.theme.MutedText.Render(f.placeholder))
			} else {
				b.WriteString(m.theme.Body.Render(display))
			}
		}

		b.WriteString("\n")

		if i == fieldProjectName {
			name := m.fields[fieldProjectName].value
			if name != "" && !validDirName.MatchString(name) {
				b.WriteString("                          " + m.theme.ErrorText.Render("Must start with a letter (a-z, 0-9, -, _ only)") + "\n")
			}
		}
	}

	b.WriteString("\n\n")

	// Features section header
	b.WriteString(renderSectionHeader(m.theme, "◆", "Features") + "\n\n")

	// Feature tree
	visible := m.visibleFeatures()
	for vi, fi := range visible {
		feat := m.features[fi]
		focusIdx := fieldCount + vi
		isFocused := focusIdx == m.focused

		indent := strings.Repeat("    ", feat.depth)
		focusIndent := strings.Repeat("    ", feat.depth)

		if feat.isGroup {
			// Group header with expand/collapse indicator
			arrow := "▸"
			if feat.expanded {
				arrow = "▾"
			}
			arrowStyled := lipgloss.NewStyle().Foreground(m.theme.Lavender).Render(arrow)

			label := m.theme.Body.Render(feat.label)
			if isFocused {
				label = m.theme.Bold.Render(feat.label)
			}

			if isFocused {
				b.WriteString(focusIndent + "  " + m.theme.Prompt.Render("❯") + " " + arrowStyled + " " + label + "\n")
			} else {
				b.WriteString(indent + "    " + arrowStyled + " " + label + "\n")
			}
		} else {
			// Checkbox item
			var checkbox string
			if feat.checked {
				checkbox = m.theme.SuccessText.Render("[✓]")
			} else {
				checkbox = m.theme.MutedText.Render("[ ]")
			}

			label := m.theme.Body.Render(feat.label)
			if isFocused {
				label = m.theme.Bold.Render(feat.label)
			}

			// Pack description on focused item
			desc := ""
			if isFocused && feat.packSlug != "" {
				if pack, ok := config.PackBySlug(feat.packSlug); ok {
					desc = "\n" + indent + "         " + m.theme.MutedText.Render(pack.Description)
				}
			}

			if isFocused {
				b.WriteString(focusIndent + "  " + m.theme.Prompt.Render("❯") + " " + checkbox + " " + label + desc + "\n")
			} else {
				b.WriteString(indent + "    " + checkbox + " " + label + "\n")
			}
		}
	}

	b.WriteString("\n\n")

	// Scope prompt overlay
	if m.showScopePrompt {
		b.WriteString(m.renderScopePrompt())
		b.WriteString("\n")
		b.WriteString(renderFooter(m.theme, "↑/↓ select • enter confirm • esc back"))
	} else {
		// Environment section
		b.WriteString(renderSectionHeader(m.theme, "◇", "Environment") + "\n\n")
		if !m.depsChecked {
			b.WriteString("    " + m.theme.MutedText.Render("Checking dependencies...") + "\n")
		} else {
			for _, dep := range m.depsReport.Dependencies {
				var icon string
				if dep.Installed {
					icon = m.theme.SuccessText.Render("✓")
				} else if dep.Required {
					icon = m.theme.ErrorText.Render("✗")
				} else {
					icon = m.theme.MutedText.Render("–")
				}

				name := dep.Name
				if dep.Version != "" && dep.Installed {
					name += " " + dep.Version
				}

				b.WriteString("    " + icon + " " + m.theme.Body.Render(name))
				if !dep.Installed && dep.Required && dep.InstallHint != "" {
					b.WriteString("  " + m.theme.WarningText.Render(dep.InstallHint))
				}
				b.WriteString("\n")
			}
		}

		b.WriteString("\n\n")
		b.WriteString(renderFooter(m.theme, "↑/↓ navigate • tab next • space toggle • ◂/▸ expand • enter next • esc back • q quit"))
	}

	formContent := lipgloss.NewStyle().Padding(0, 4).Render(b.String())

	return header + formContent
}

// renderScopePrompt renders the skills scope selection prompt.
func (m setupModel) renderScopePrompt() string {
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

func parseSchemes(s string) []string {
	parts := strings.Split(s, ",")
	var schemes []string
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			schemes = append(schemes, trimmed)
		}
	}
	return schemes
}
