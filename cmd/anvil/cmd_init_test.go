package main

import (
	"bytes"
	"strings"
	"testing"

	"github.com/magnoscg/anvil/internal/deps"
	"github.com/magnoscg/anvil/internal/tui"
)

func TestWarnMissingAxiomStaysQuietWithoutThePack(t *testing.T) {
	var out bytes.Buffer

	warnMissingAxiom(&out, []string{"ios-architecture", "gitflow"})

	if out.Len() != 0 {
		t.Errorf("warnMissingAxiom() wrote %q, want nothing when the pack was not installed", out.String())
	}
}

func TestWarnMissingAxiomStaysQuietWhenNothingWasGenerated(t *testing.T) {
	var out bytes.Buffer

	warnMissingAxiom(&out, nil)

	if out.Len() != 0 {
		t.Errorf("warnMissingAxiom() wrote %q, want nothing when no packs were installed", out.String())
	}
}

func TestWarnMissingAxiomMentionsInstallCommands(t *testing.T) {
	if deps.AxiomInstalled() {
		t.Skip("Axiom is installed on this machine, so the hint is correctly suppressed")
	}

	var out bytes.Buffer
	warnMissingAxiom(&out, []string{"ios-architecture", "axiom-ios"})

	got := out.String()
	for _, want := range []string{
		"claude plugin marketplace add CharlesWiltgen/Axiom",
		"claude plugin install axiom@axiom-marketplace",
		"https://github.com/CharlesWiltgen/Axiom",
	} {
		if !strings.Contains(got, want) {
			t.Errorf("warnMissingAxiom() output missing %q, got:\n%s", want, got)
		}
	}
}

func TestFinishInitSucceedsWhenTheWizardEndedWithoutAnError(t *testing.T) {
	var out bytes.Buffer

	if err := finishInit(&out, tui.NewWizardModel(nil, nil)); err != nil {
		t.Fatalf("finishInit() = %v, want nil", err)
	}
}
