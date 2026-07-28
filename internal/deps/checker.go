package deps

import (
	"context"
	"os"
	"os/exec"
	"strings"

	"github.com/oscarcanton/anvilcli/internal/config"
)

// DefaultCommandRunner executes commands using os/exec.
// It enriches PATH with common Homebrew/tool locations and sets a safe
// working directory to avoid crashes when the CWD has been deleted.
func DefaultCommandRunner() CommandRunner {
	return func(ctx context.Context, name string, args ...string) CommandResult {
		cmd := exec.CommandContext(ctx, name, args...)
		cmd.Env = enrichedEnv()
		cmd.Dir = safeWorkDir()

		out, err := cmd.CombinedOutput()
		exitCode := 0
		if err != nil {
			if exitErr, ok := err.(*exec.ExitError); ok {
				exitCode = exitErr.ExitCode()
			} else {
				exitCode = -1
			}
		}

		return CommandResult{
			Output:   strings.TrimSpace(string(out)),
			ExitCode: exitCode,
			Err:      err,
		}
	}
}

// safeWorkDir returns a valid working directory for subprocess execution.
// Falls back to the user's home or /tmp if the current directory is deleted.
func safeWorkDir() string {
	if cwd, err := os.Getwd(); err == nil {
		if _, statErr := os.Stat(cwd); statErr == nil {
			return cwd
		}
	}
	if home, err := os.UserHomeDir(); err == nil {
		return home
	}
	return os.TempDir()
}

// enrichedEnv returns the current environment with extra PATH entries
// for common tool locations (Homebrew, local bin).
func enrichedEnv() []string {
	env := os.Environ()
	extra := []string{"/opt/homebrew/bin", "/usr/local/bin"}

	for i, e := range env {
		if after, found := strings.CutPrefix(e, "PATH="); found {
			for _, p := range extra {
				if !strings.Contains(after, p) {
					after = after + ":" + p
				}
			}
			env[i] = "PATH=" + after
			return env
		}
	}
	return append(env, "PATH="+strings.Join(extra, ":"))
}

// allDeps returns the full list of dependencies to check in order.
func allDeps() []depSpec {
	return []depSpec{
		{
			Name:       "Xcode",
			Command:    "xcodebuild",
			Args:       []string{"-version"},
			Required:   true,
			InstallURL: "https://developer.apple.com/xcode/",
			ParseFn:    parseXcodeVersion,
		},
		{
			Name:       "git",
			Command:    "git",
			Args:       []string{"--version"},
			Required:   true,
			InstallURL: "https://git-scm.com/download/mac",
			ParseFn:    parseGitVersion,
		},
		{
			Name:       "claude-code",
			Command:    "claude",
			Args:       []string{"--version"},
			Required:   false,
			InstallURL: "https://docs.anthropic.com/en/docs/claude-code",
			ParseFn:    parseClaudeVersion,
		},
		{
			Name:       "swiftlint",
			Command:    "swiftlint",
			Args:       []string{"version"},
			Required:   false,
			InstallURL: "https://github.com/realm/SwiftLint",
			ParseFn:    parseSwiftLintVersion,
		},
		{
			Name:       "swiftformat",
			Command:    "swiftformat",
			Args:       []string{"--version"},
			Required:   false,
			InstallURL: "https://github.com/nicklockwood/SwiftFormat",
			ParseFn:    parseSwiftFormatVersion,
		},
	}
}

// SystemChecker checks system dependencies by running commands via a CommandRunner.
type SystemChecker struct {
	runner CommandRunner
}

// NewSystemChecker creates a SystemChecker with the given CommandRunner.
// Pass DefaultCommandRunner() for real execution, or a mock for tests.
func NewSystemChecker(runner CommandRunner) *SystemChecker {
	return &SystemChecker{runner: runner}
}

// Check runs all dependency detection commands and returns a DependencyReport.
func (c *SystemChecker) Check(ctx context.Context) config.DependencyReport {
	specs := allDeps()
	deps := make([]config.Dependency, 0, len(specs))

	for _, spec := range specs {
		dep := config.Dependency{
			Name:        spec.Name,
			Required:    spec.Required,
			InstallHint: spec.InstallURL,
		}

		result := c.runner(ctx, spec.Command, spec.Args...)
		if result.Err == nil {
			dep.Installed = true
			dep.Version = spec.ParseFn(result.Output)
		}

		deps = append(deps, dep)
	}

	return config.DependencyReport{Dependencies: deps}
}
