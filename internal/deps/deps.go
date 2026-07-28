// Package deps provides system dependency detection for AnvilCLI.
// It checks for required and optional tools, extracts their versions,
// and reports readiness via config.DependencyReport.
package deps

import (
	"context"

	"github.com/oscarcanton/anvilcli/internal/config"
)

// CommandResult holds the output and exit status of an executed command.
type CommandResult struct {
	Output   string
	ExitCode int
	Err      error
}

// CommandRunner executes a command with the given name and arguments,
// returning its combined output. Inject a mock for testing.
type CommandRunner func(ctx context.Context, name string, args ...string) CommandResult

// DependencyChecker detects system dependencies and returns a report.
type DependencyChecker interface {
	Check(ctx context.Context) config.DependencyReport
}

// depSpec defines a dependency to check: its display name, the command
// and arguments to run, the function to extract a version from command output,
// whether it is required, and an install URL for user guidance.
type depSpec struct {
	Name       string
	Command    string
	Args       []string
	Required   bool
	InstallURL string
	ParseFn    func(output string) string
}
