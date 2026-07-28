package generator

import (
	"fmt"
	"os/exec"
	"strings"
)

// isCommandNotFound checks whether an error indicates the command binary was not found.
func isCommandNotFound(err error) bool {
	if err == nil {
		return false
	}
	if execErr, ok := err.(*exec.Error); ok {
		return execErr.Err == exec.ErrNotFound
	}
	return false
}

// GitRunner executes git commands for repository initialization.
type GitRunner interface {
	// Init runs `git init` in the given directory.
	Init(dir string) error

	// AddAll runs `git add .` in the given directory.
	AddAll(dir string) error

	// Commit runs `git commit -m <msg>` in the given directory.
	Commit(dir string, msg string) error
}

// DefaultGitRunner is the production implementation that shells out to the git binary.
type DefaultGitRunner struct{}

// NewGitRunner creates a DefaultGitRunner.
func NewGitRunner() *DefaultGitRunner {
	return &DefaultGitRunner{}
}

// Init runs `git init` in the specified directory.
func (r *DefaultGitRunner) Init(dir string) error {
	return r.run(dir, "init")
}

// AddAll runs `git add .` in the specified directory.
func (r *DefaultGitRunner) AddAll(dir string) error {
	return r.run(dir, "add", ".")
}

// Commit runs `git commit -m <msg>` in the specified directory.
func (r *DefaultGitRunner) Commit(dir string, msg string) error {
	return r.run(dir, "commit", "-m", msg)
}

// run executes a git subcommand in the given directory.
func (r *DefaultGitRunner) run(dir string, args ...string) error {
	cmd := exec.Command("git", args...)
	cmd.Dir = dir

	out, err := cmd.CombinedOutput()
	if err != nil {
		if isCommandNotFound(err) {
			return fmt.Errorf("git is not installed or not in PATH: %w", err)
		}
		return fmt.Errorf("git %s failed: %s: %w", strings.Join(args, " "), strings.TrimSpace(string(out)), err)
	}

	return nil
}
