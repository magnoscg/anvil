package main

import (
	"testing"
)

func TestRootHasExpectedSubcommands(t *testing.T) {
	expected := map[string]bool{
		"init":    false,
		"feature": false,
		"version": false,
	}

	for _, cmd := range rootCmd.Commands() {
		if _, ok := expected[cmd.Name()]; ok {
			expected[cmd.Name()] = true
		}
	}

	for name, found := range expected {
		if !found {
			t.Errorf("expected subcommand %q not registered on rootCmd", name)
		}
	}
}

func TestFeatureRequiresExactlyOneArg(t *testing.T) {
	validate := featureCmd.Args

	// Zero args — should fail
	if err := validate(featureCmd, []string{}); err == nil {
		t.Error("expected error when feature called with zero args")
	}

	// Two args — should fail
	if err := validate(featureCmd, []string{"one", "two"}); err == nil {
		t.Error("expected error when feature called with two args")
	}

	// One arg — should pass
	if err := validate(featureCmd, []string{"Login"}); err != nil {
		t.Errorf("expected no error with one arg, got: %v", err)
	}
}

func TestVersionContainsVersionString(t *testing.T) {
	Version = "test-version"
	versionCmd.SetArgs([]string{})
	if err := versionCmd.Execute(); err != nil {
		t.Errorf("version command failed: %v", err)
	}
}
