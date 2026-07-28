package tui

import (
	"testing"

	tea "charm.land/bubbletea/v2"
	"github.com/magnoscg/anvil/internal/config"
)

func TestSetup_InitialState(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	if m.focused != 0 {
		t.Error("initial focus should be 0 (project name)")
	}
	if len(m.features) == 0 {
		t.Error("features should not be empty")
	}
}

func TestSetup_FeatureTreeContainsAIPacks(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	hasGroup := false
	packCount := 0
	for _, f := range m.features {
		if f.isGroup && f.label == "AI Coding Packs" {
			hasGroup = true
		}
		if f.packSlug != "" {
			packCount++
		}
	}

	if !hasGroup {
		t.Error("feature tree should contain 'AI Coding Packs' group")
	}

	allPacks := config.AllPacks()
	if packCount != len(allPacks) {
		t.Errorf("feature tree should contain %d packs, got %d", len(allPacks), packCount)
	}
}

func TestSetup_GroupCollapsedHidesChildren(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	groupIdx := -1
	for i, f := range m.features {
		if f.isGroup && f.label == "AI Coding Packs" {
			groupIdx = i
			break
		}
	}
	if groupIdx < 0 {
		t.Fatal("AI Coding Packs group not found")
	}

	if m.features[groupIdx].expanded {
		t.Error("group should be collapsed by default")
	}

	collapsedCount := m.visibleFeatureCount()

	m.features[groupIdx].expanded = true
	expandedCount := m.visibleFeatureCount()

	if expandedCount <= collapsedCount {
		t.Errorf("expanding group should show more features: collapsed=%d, expanded=%d", collapsedCount, expandedCount)
	}
}

func TestSetup_ToggleExpandWithRightLeft(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	groupIdx := -1
	for i, f := range m.features {
		if f.isGroup {
			groupIdx = i
			break
		}
	}
	if groupIdx < 0 {
		t.Fatal("no group found")
	}

	visible := m.visibleFeatures()
	groupVisiblePos := -1
	for vi, fi := range visible {
		if fi == groupIdx {
			groupVisiblePos = vi
			break
		}
	}
	m.focused = fieldCount + groupVisiblePos

	rightKey := tea.KeyPressMsg{Code: tea.KeyRight}
	m, _ = m.handleKey(rightKey)

	if !m.features[groupIdx].expanded {
		t.Error("right arrow should expand the group")
	}

	leftKey := tea.KeyPressMsg{Code: tea.KeyLeft}
	m, _ = m.handleKey(leftKey)

	if m.features[groupIdx].expanded {
		t.Error("left arrow should collapse the group")
	}
}

func TestSetup_SpaceTogglesGroupExpand(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	groupIdx := -1
	for i, f := range m.features {
		if f.isGroup {
			groupIdx = i
			break
		}
	}
	if groupIdx < 0 {
		t.Fatal("no group found")
	}

	visible := m.visibleFeatures()
	groupVisiblePos := -1
	for vi, fi := range visible {
		if fi == groupIdx {
			groupVisiblePos = vi
			break
		}
	}
	m.focused = fieldCount + groupVisiblePos

	m, _ = m.handleKey(spaceKey())

	if !m.features[groupIdx].expanded {
		t.Error("space on group should expand it")
	}

	m, _ = m.handleKey(spaceKey())

	if m.features[groupIdx].expanded {
		t.Error("space on group again should collapse it")
	}
}

func TestSetup_SelectedPackSlugs(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	for i := range m.features {
		if m.features[i].packSlug == "axiom-ios" {
			m.features[i].checked = true
			break
		}
	}

	slugs := m.selectedPackSlugs()
	if len(slugs) != 1 || slugs[0] != "axiom-ios" {
		t.Errorf("expected [axiom-ios], got %v", slugs)
	}
}

func TestSetup_PackDependencyResolution(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	for i := range m.features {
		if m.features[i].packSlug == "prd-planner" {
			m.features[i].checked = true
			break
		}
	}

	m.resolvePackDependencies()

	slugs := m.selectedPackSlugs()
	hasArch := false
	hasPRD := false
	for _, s := range slugs {
		if s == "ios-architecture" {
			hasArch = true
		}
		if s == "prd-planner" {
			hasPRD = true
		}
	}

	if !hasPRD {
		t.Error("prd-planner should be selected")
	}
	if !hasArch {
		t.Error("ios-architecture should be auto-selected as dependency")
	}
}

func TestSetup_BuildConfigMapsFeatures(t *testing.T) {
	m := newSetupModel(DefaultTheme())
	m.fields[fieldProjectName].value = "TestApp"

	for i := range m.features {
		if m.features[i].label == "SwiftData persistence" {
			m.features[i].checked = true
			break
		}
	}

	cfg, err := m.buildConfig()
	if err != nil {
		t.Fatalf("buildConfig error: %v", err)
	}

	if !cfg.IncludeSwiftData {
		t.Error("IncludeSwiftData should be true when feature is checked")
	}
	if cfg.IncludeExample {
		t.Error("IncludeExample should be false when feature is not checked")
	}
}

func TestSetup_HasSelectedPacksWithSkills(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	if m.hasSelectedPacksWithSkills() {
		t.Error("should return false when no packs selected")
	}

	for i := range m.features {
		if m.features[i].packSlug == "swift-design-patterns" {
			m.features[i].checked = true
			break
		}
	}

	if !m.hasSelectedPacksWithSkills() {
		t.Error("should return true when a pack with skills is selected")
	}
}

func TestSetup_FocusClampOnCollapse(t *testing.T) {
	m := newSetupModel(DefaultTheme())

	// Expand the group
	groupIdx := -1
	for i, f := range m.features {
		if f.isGroup {
			groupIdx = i
			break
		}
	}
	if groupIdx < 0 {
		t.Fatal("no group found")
	}
	m.features[groupIdx].expanded = true

	// Focus on a child item
	visible := m.visibleFeatures()
	lastVisiblePos := len(visible) - 1
	m.focused = fieldCount + lastVisiblePos

	// Collapse the group
	m.features[groupIdx].expanded = false
	newTotal := m.totalFocusable()
	if m.focused >= newTotal {
		m.focused = newTotal - 1
	}

	if m.focused >= newTotal {
		t.Error("focus should be clamped within visible range after collapse")
	}
}
