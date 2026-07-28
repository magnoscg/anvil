package deps

import (
	"context"
	"fmt"
	"testing"
)

// mockRunner returns a CommandRunner that resolves commands from a map.
// Keys are command names (e.g., "git"). If the command is not in the map,
// it returns an error simulating "command not found".
func mockRunner(responses map[string]CommandResult) CommandRunner {
	return func(_ context.Context, name string, _ ...string) CommandResult {
		if r, ok := responses[name]; ok {
			return r
		}
		return CommandResult{
			Output:   "",
			ExitCode: -1,
			Err:      fmt.Errorf("exec: %q: executable file not found in $PATH", name),
		}
	}
}

func TestCheckAllDetected(t *testing.T) {
	runner := mockRunner(map[string]CommandResult{
		"xcodebuild":  {Output: "Xcode 17.0\nBuild version 17C529", ExitCode: 0},
		"git":         {Output: "git version 2.39.3 (Apple Git-146)", ExitCode: 0},
		"claude":      {Output: "1.0.12 (Claude Code)", ExitCode: 0},
		"swiftlint":   {Output: "0.54.0", ExitCode: 0},
		"swiftformat": {Output: "0.53.1", ExitCode: 0},
	})

	checker := NewSystemChecker(runner)
	report := checker.Check(context.Background())

	if !report.Ready() {
		t.Error("Ready() should return true when all deps are detected")
	}
	if len(report.Dependencies) != 5 {
		t.Fatalf("expected 5 dependencies, got %d", len(report.Dependencies))
	}
	for _, dep := range report.Dependencies {
		if !dep.Installed {
			t.Errorf("expected %q to be installed", dep.Name)
		}
		if dep.Version == "" {
			t.Errorf("expected %q to have a version", dep.Name)
		}
	}
}

func TestCheckRequiredMissing(t *testing.T) {
	runner := mockRunner(map[string]CommandResult{
		"xcodebuild": {Output: "Xcode 17.0\nBuild version 17C529", ExitCode: 0},
		// git is missing — a required dep
	})

	checker := NewSystemChecker(runner)
	report := checker.Check(context.Background())

	if report.Ready() {
		t.Error("Ready() should return false when a required dep (git) is missing")
	}

	var gitDep *struct {
		installed bool
		version   string
	}
	for _, dep := range report.Dependencies {
		if dep.Name == "git" {
			gitDep = &struct {
				installed bool
				version   string
			}{dep.Installed, dep.Version}
			break
		}
	}
	if gitDep == nil {
		t.Fatal("git dependency not found in report")
	}
	if gitDep.installed {
		t.Error("git should not be marked as installed")
	}
	if gitDep.version != "" {
		t.Errorf("git version should be empty, got %q", gitDep.version)
	}
}

func TestCheckOptionalMissingStillReady(t *testing.T) {
	runner := mockRunner(map[string]CommandResult{
		"xcodebuild": {Output: "Xcode 17.0\nBuild version 17C529", ExitCode: 0},
		"git":        {Output: "git version 2.39.3", ExitCode: 0},
		// claude, swiftlint, swiftformat are all missing
	})

	checker := NewSystemChecker(runner)
	report := checker.Check(context.Background())

	if !report.Ready() {
		t.Error("Ready() should return true when only optional deps are missing")
	}

	for _, dep := range report.Dependencies {
		if !dep.Required && dep.Installed {
			t.Errorf("optional dep %q should not be installed in this test", dep.Name)
		}
	}
}

func TestCheckMalformedOutput(t *testing.T) {
	runner := mockRunner(map[string]CommandResult{
		"xcodebuild":  {Output: "some garbage output without a version", ExitCode: 0},
		"git":         {Output: "git version", ExitCode: 0},
		"claude":      {Output: "claude", ExitCode: 0},
		"swiftlint":   {Output: "\n\n\n", ExitCode: 0},
		"swiftformat": {Output: "not a version at all", ExitCode: 0},
	})

	checker := NewSystemChecker(runner)
	report := checker.Check(context.Background())

	if !report.Ready() {
		t.Error("Ready() should return true (all commands succeeded)")
	}

	for _, dep := range report.Dependencies {
		if !dep.Installed {
			t.Errorf("dep %q should be installed (command did not error)", dep.Name)
		}
	}
}

func TestCheckCommandError(t *testing.T) {
	runner := mockRunner(map[string]CommandResult{
		"xcodebuild": {Output: "Xcode 17.0\nBuild version 17C529", ExitCode: 0},
		"git":        {Output: "permission denied", ExitCode: 1, Err: fmt.Errorf("exit status 1")},
	})

	checker := NewSystemChecker(runner)
	report := checker.Check(context.Background())

	if report.Ready() {
		t.Error("Ready() should return false when git command errors")
	}

	for _, dep := range report.Dependencies {
		if dep.Name == "git" && dep.Installed {
			t.Error("git should not be installed when command returns an error")
		}
	}
}

func TestCheckInstallHintsPresent(t *testing.T) {
	runner := mockRunner(map[string]CommandResult{})

	checker := NewSystemChecker(runner)
	report := checker.Check(context.Background())

	for _, dep := range report.Dependencies {
		if dep.InstallHint == "" {
			t.Errorf("dep %q should have a non-empty InstallHint", dep.Name)
		}
	}
}

func TestCheckContextCancelled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	runner := func(ctx context.Context, name string, args ...string) CommandResult {
		if ctx.Err() != nil {
			return CommandResult{Err: ctx.Err(), ExitCode: -1}
		}
		return CommandResult{Output: "should not reach", ExitCode: 0}
	}

	checker := NewSystemChecker(runner)
	report := checker.Check(ctx)

	for _, dep := range report.Dependencies {
		if dep.Installed {
			t.Errorf("dep %q should not be installed when context is cancelled", dep.Name)
		}
	}
}
