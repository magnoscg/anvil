package tui

import (
	"errors"
	"testing"

	"github.com/magnoscg/anvil/internal/config"
)

func TestWizardErrIsNilBeforeGeneration(t *testing.T) {
	wizard := NewWizardModel(nil, nil)

	if err := wizard.Err(); err != nil {
		t.Fatalf("Err() = %v, want nil before generation", err)
	}
}

func TestWizardErrReportsAFailedGeneration(t *testing.T) {
	wizard := NewWizardModel(nil, nil)
	wizard.screen = ScreenGenerate
	wizard.cfg = config.ProjectConfig{AIPacks: []string{"ios-architecture"}}
	generationErr := errors.New("disk full")

	updated, _ := wizard.Update(generateDoneMsg{err: generationErr})
	finished := updated.(WizardModel)

	if !errors.Is(finished.Err(), generationErr) {
		t.Fatalf("Err() = %v, want the generation error", finished.Err())
	}
	if packs := finished.InstalledPacks(); packs != nil {
		t.Fatalf("InstalledPacks() = %v, want nil after a failed generation", packs)
	}
}

func TestWizardErrIsNilAfterASuccessfulGeneration(t *testing.T) {
	wizard := NewWizardModel(nil, nil)
	wizard.screen = ScreenGenerate

	updated, _ := wizard.Update(generateDoneMsg{})

	if err := updated.(WizardModel).Err(); err != nil {
		t.Fatalf("Err() = %v, want nil after success", err)
	}
}
