package generator

import (
	"errors"
	"strings"
	"testing"
)

func TestGitRunnerInterfaceSatisfied(t *testing.T) {
	var _ GitRunner = (*DefaultGitRunner)(nil)
	var _ GitRunner = (*mockGitRunner)(nil)
}

func TestDefaultGitRunnerInitInvalidDir(t *testing.T) {
	// Run git init on a deeply nested nonexistent path — must return a wrapped error.
	runner := NewGitRunner()
	err := runner.Init("/nonexistent/deeply/nested/path/that/does/not/exist")
	if err == nil {
		t.Fatal("expected error when running git init on nonexistent directory, got nil")
	}

	// The error should not be a "git not installed" error — git is present in CI.
	// It should be a wrapped git failure mentioning the command.
	if errors.Is(err, errors.New("git is not installed or not in PATH")) {
		t.Skip("git not available in this environment")
	}

	if !strings.Contains(err.Error(), "git") {
		t.Errorf("error should mention 'git', got: %v", err)
	}
}
