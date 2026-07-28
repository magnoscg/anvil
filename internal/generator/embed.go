// Package generator provides template rendering, file writing, and rollback
// utilities for AnvilCLI project and feature forging.
package generator

import (
	"embed"

	"github.com/magnoscg/anvil/templates"
)

// TemplateFS is the embedded filesystem containing all template files.
// It re-exports templates.FS so that all template access goes through this package.
// This is the ONLY variable that references the embedded filesystem.
var TemplateFS embed.FS = templates.FS
