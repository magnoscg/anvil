package config

import "fmt"

// MissingDependencyError indicates that a required system dependency is not installed.
type MissingDependencyError struct {
	Name        string
	InstallHint string
}

// InvalidProjectNameError indicates that a project name cannot be used as a
// single filesystem directory component.
type InvalidProjectNameError struct {
	Name string
}

func (e InvalidProjectNameError) Error() string {
	return fmt.Sprintf("invalid project name %q; use a letter followed by letters, numbers, hyphens, or underscores", e.Name)
}

func (e MissingDependencyError) Error() string {
	msg := fmt.Sprintf("required dependency %q is not installed", e.Name)
	if e.InstallHint != "" {
		msg += fmt.Sprintf("; install with: %s", e.InstallHint)
	}
	return msg
}

// TemplateRenderError indicates a failure while rendering a Go text/template.
type TemplateRenderError struct {
	TemplateName string
	Cause        error
}

func (e TemplateRenderError) Error() string {
	return fmt.Sprintf("failed to render template %q: %v", e.TemplateName, e.Cause)
}

func (e TemplateRenderError) Unwrap() error {
	return e.Cause
}

// RollbackError indicates that the cleanup after a failed generation also failed.
type RollbackError struct {
	OriginalError error
	RollbackCause error
}

func (e RollbackError) Error() string {
	return fmt.Sprintf("generation failed (%v) and rollback also failed (%v)", e.OriginalError, e.RollbackCause)
}

func (e RollbackError) Unwrap() []error {
	return []error{e.OriginalError, e.RollbackCause}
}

// NoAnvilProjectError indicates that no .anvil.yml marker was found when
// walking up directories from the given start directory.
type NoAnvilProjectError struct {
	StartDir string
}

func (e NoAnvilProjectError) Error() string {
	return fmt.Sprintf("no Anvil project found (no %s in %q or any parent directory)", anvilFileName, e.StartDir)
}

// XcodeProjectError indicates a failure during native .xcodeproj generation.
type XcodeProjectError struct {
	Phase string
	Cause error
}

func (e XcodeProjectError) Error() string {
	return fmt.Sprintf("xcodeproj generation failed at %s: %v", e.Phase, e.Cause)
}

func (e XcodeProjectError) Unwrap() error {
	return e.Cause
}

// FeatureExistsError indicates that a feature with the given name already exists.
type FeatureExistsError struct {
	FeatureName string
	ExistingDir string
}

func (e FeatureExistsError) Error() string {
	return fmt.Sprintf("feature %q already exists at %s", e.FeatureName, e.ExistingDir)
}

// PackNotFoundError indicates that a pack slug does not exist in the registry.
type PackNotFoundError struct {
	Slug string
}

func (e PackNotFoundError) Error() string {
	return fmt.Sprintf("pack %q not found in registry", e.Slug)
}

// PackDependencyError indicates that a required dependency pack is not selected.
type PackDependencyError struct {
	Pack    string
	Missing string
}

func (e PackDependencyError) Error() string {
	return fmt.Sprintf("pack %q requires %q which is not selected", e.Pack, e.Missing)
}

// SettingsMergeError indicates a failure while merging a settings.json fragment.
type SettingsMergeError struct {
	Path  string
	Cause error
}

func (e SettingsMergeError) Error() string {
	return fmt.Sprintf("failed to merge settings at %s: %v", e.Path, e.Cause)
}

func (e SettingsMergeError) Unwrap() error {
	return e.Cause
}
