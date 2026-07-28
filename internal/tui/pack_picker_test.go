package tui

import (
	"testing"

	tea "charm.land/bubbletea/v2"
	"github.com/magnoscg/anvil/internal/config"
)

// -- Key helpers --

func keyPress(code rune) tea.KeyPressMsg {
	return tea.KeyPressMsg{Code: code}
}

func spaceKey() tea.KeyPressMsg {
	return tea.KeyPressMsg{Code: tea.KeySpace, Text: " "}
}

func enterKey() tea.KeyPressMsg {
	return tea.KeyPressMsg{Code: tea.KeyEnter}
}

func escKey() tea.KeyPressMsg {
	return tea.KeyPressMsg{Code: tea.KeyEscape}
}

func upKey() tea.KeyPressMsg {
	return tea.KeyPressMsg{Code: tea.KeyUp}
}

func downKey() tea.KeyPressMsg {
	return tea.KeyPressMsg{Code: tea.KeyDown}
}

// -- Tests --

func TestPackPicker_InitialState(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())
	allPacks := config.AllPacks()

	if len(m.packs) != len(allPacks) {
		t.Errorf("packs count = %d, want %d", len(m.packs), len(allPacks))
	}
	if len(m.packs) != 7 {
		t.Errorf("packs count = %d, want 7", len(m.packs))
	}
	if m.focused != 0 {
		t.Errorf("focused = %d, want 0", m.focused)
	}
	for i, item := range m.packs {
		if item.selected {
			t.Errorf("packs[%d] should not be selected initially", i)
		}
		if item.autoSelected {
			t.Errorf("packs[%d] should not be autoSelected initially", i)
		}
	}
	if m.confirmed {
		t.Error("confirmed should be false initially")
	}
	if m.showScopePrompt {
		t.Error("showScopePrompt should be false initially")
	}
}

func TestPackPicker_ToggleSelection(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Focus is on pack[0] (ios-architecture), press space to toggle on
	m, _ = m.update(spaceKey())

	if !m.packs[0].selected {
		t.Error("packs[0] should be selected after space")
	}

	// Press space again to toggle off
	m, _ = m.update(spaceKey())

	if m.packs[0].selected {
		t.Error("packs[0] should be deselected after second space")
	}
}

func TestPackPicker_AutoDependency(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Move to prd-planner (index 1)
	m, _ = m.update(downKey())
	if m.focused != 1 {
		t.Fatalf("focused = %d, want 1", m.focused)
	}

	// Select prd-planner
	m, _ = m.update(spaceKey())

	if !m.packs[1].selected {
		t.Error("prd-planner (packs[1]) should be selected")
	}

	// ios-architecture (packs[0]) should be auto-selected
	if !m.packs[0].selected {
		t.Error("ios-architecture (packs[0]) should be auto-selected as dependency")
	}
	if !m.packs[0].autoSelected {
		t.Error("ios-architecture (packs[0]) should have autoSelected=true")
	}
}

func TestPackPicker_BlockDeselectionOfDependency(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Select prd-planner (which auto-selects ios-architecture)
	m, _ = m.update(downKey()) // focus prd-planner
	m, _ = m.update(spaceKey())

	if !m.packs[0].autoSelected {
		t.Fatal("ios-architecture should be auto-selected before testing deselection block")
	}

	// Move focus to ios-architecture
	m, _ = m.update(upKey())
	if m.focused != 0 {
		t.Fatalf("focused = %d, want 0", m.focused)
	}

	// Try to deselect ios-architecture
	m, _ = m.update(spaceKey())

	// It should still be selected (blocked because prd-planner depends on it)
	if !m.packs[0].selected {
		t.Error("ios-architecture should remain selected (required by prd-planner)")
	}

	if m.statusMsg == "" {
		t.Error("statusMsg should contain a dependency warning")
	}
}

func TestPackPicker_EscEmitsBack(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	_, cmd := m.update(escKey())

	if cmd == nil {
		t.Fatal("Esc should produce a command")
	}

	msg := cmd()
	if _, ok := msg.(PacksBackMsg); !ok {
		t.Errorf("Esc cmd should return PacksBackMsg, got %T", msg)
	}
}

func TestPackPicker_EnterEmitsConfirmNoSkills(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Select ios-architecture (index 0) - no skills
	m, _ = m.update(spaceKey())

	m, cmd := m.update(enterKey())

	if m.showScopePrompt {
		t.Error("showScopePrompt should be false when no skills pack is selected")
	}

	if cmd == nil {
		t.Fatal("Enter should produce a command when packs without skills are selected")
	}

	msg := cmd()
	confirmed, ok := msg.(PacksConfirmedMsg)
	if !ok {
		t.Fatalf("Enter cmd should return PacksConfirmedMsg, got %T", msg)
	}
	if len(confirmed.Packs) != 1 || confirmed.Packs[0] != "ios-architecture" {
		t.Errorf("confirmed packs = %v, want [ios-architecture]", confirmed.Packs)
	}
	if confirmed.SkillsScope != "" {
		t.Errorf("SkillsScope should be empty when no skills, got %q", confirmed.SkillsScope)
	}
}

func TestPackPicker_ScopePromptAppears(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Find swift-design-patterns index (it has HasSkills=true)
	sdpIdx := -1
	for i, item := range m.packs {
		if item.pack.Slug == "swift-design-patterns" {
			sdpIdx = i
			break
		}
	}
	if sdpIdx < 0 {
		t.Fatal("swift-design-patterns not found in packs")
	}

	// Navigate to swift-design-patterns
	for i := 0; i < sdpIdx; i++ {
		m, _ = m.update(downKey())
	}

	// Select it
	m, _ = m.update(spaceKey())

	// Press enter
	m, cmd := m.update(enterKey())

	if !m.showScopePrompt {
		t.Error("showScopePrompt should be true when a pack with skills is selected")
	}
	if cmd != nil {
		t.Error("no command should be emitted yet (scope prompt shown)")
	}

	// Confirm scope with enter (default is "project")
	m, cmd = m.update(enterKey())

	if cmd == nil {
		t.Fatal("Enter in scope prompt should produce a command")
	}

	msg := cmd()
	confirmed, ok := msg.(PacksConfirmedMsg)
	if !ok {
		t.Fatalf("scope confirm cmd should return PacksConfirmedMsg, got %T", msg)
	}
	if confirmed.SkillsScope != "project" {
		t.Errorf("SkillsScope = %q, want 'project'", confirmed.SkillsScope)
	}
}

func TestPackPicker_ScopePromptGlobal(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Find and select swift-design-patterns
	sdpIdx := -1
	for i, item := range m.packs {
		if item.pack.Slug == "swift-design-patterns" {
			sdpIdx = i
			break
		}
	}
	for i := 0; i < sdpIdx; i++ {
		m, _ = m.update(downKey())
	}
	m, _ = m.update(spaceKey())
	m, _ = m.update(enterKey()) // show scope prompt

	// Move down to select "global"
	m, _ = m.update(downKey())
	if m.scopeFocused != 1 {
		t.Fatalf("scopeFocused = %d, want 1", m.scopeFocused)
	}

	m, cmd := m.update(enterKey())
	msg := cmd()
	confirmed := msg.(PacksConfirmedMsg)
	if confirmed.SkillsScope != "global" {
		t.Errorf("SkillsScope = %q, want 'global'", confirmed.SkillsScope)
	}
}

func TestPackPicker_NavigationUpDown(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())
	packCount := len(m.packs)

	// Start at 0
	if m.focused != 0 {
		t.Fatalf("initial focused = %d, want 0", m.focused)
	}

	// Down moves to 1
	m, _ = m.update(downKey())
	if m.focused != 1 {
		t.Errorf("after down, focused = %d, want 1", m.focused)
	}

	// Down again moves to 2
	m, _ = m.update(downKey())
	if m.focused != 2 {
		t.Errorf("after second down, focused = %d, want 2", m.focused)
	}

	// Up goes back to 1
	m, _ = m.update(upKey())
	if m.focused != 1 {
		t.Errorf("after up, focused = %d, want 1", m.focused)
	}

	// Up goes to 0
	m, _ = m.update(upKey())
	if m.focused != 0 {
		t.Errorf("after second up, focused = %d, want 0", m.focused)
	}

	// Up at 0 wraps to last
	m, _ = m.update(upKey())
	if m.focused != packCount-1 {
		t.Errorf("up at 0 should wrap to %d, got %d", packCount-1, m.focused)
	}

	// Down at last wraps to 0
	m, _ = m.update(downKey())
	if m.focused != 0 {
		t.Errorf("down at last should wrap to 0, got %d", m.focused)
	}
}

func TestPackPicker_EnterWithNothingSelected(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Enter with nothing selected should emit confirm with nil packs
	m, cmd := m.update(enterKey())

	if cmd == nil {
		t.Fatal("Enter with no selection should still produce a command")
	}

	msg := cmd()
	confirmed, ok := msg.(PacksConfirmedMsg)
	if !ok {
		t.Fatalf("should return PacksConfirmedMsg, got %T", msg)
	}
	if confirmed.Packs != nil {
		t.Errorf("Packs should be nil when nothing selected, got %v", confirmed.Packs)
	}
}

func TestPackPicker_DeselectionRemovesAutoDeps(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Select prd-planner (auto-selects ios-architecture)
	m, _ = m.update(downKey()) // focus prd-planner
	m, _ = m.update(spaceKey())

	if !m.packs[0].autoSelected {
		t.Fatal("ios-architecture should be auto-selected")
	}

	// Now deselect prd-planner
	m, _ = m.update(spaceKey())

	// ios-architecture should no longer be selected
	if m.packs[0].selected {
		t.Error("ios-architecture should be deselected when prd-planner is deselected")
	}
	if m.packs[0].autoSelected {
		t.Error("ios-architecture autoSelected should be false")
	}
}

func TestPackPicker_ScopePromptEscGoesBack(t *testing.T) {
	m := newPackPickerModel(DefaultTheme())

	// Find and select a pack with skills
	for i, item := range m.packs {
		if item.pack.HasSkills {
			for j := 0; j < i; j++ {
				m, _ = m.update(downKey())
			}
			break
		}
	}
	m, _ = m.update(spaceKey())
	m, _ = m.update(enterKey()) // show scope prompt

	if !m.showScopePrompt {
		t.Fatal("scope prompt should be shown")
	}

	// Esc should dismiss the scope prompt, not go back
	m, _ = m.update(escKey())

	if m.showScopePrompt {
		t.Error("showScopePrompt should be false after Esc in scope prompt")
	}
}
