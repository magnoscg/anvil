// Package templates provides embedded template files for AnvilCLI.
// This is the single source of truth for all embedded template assets.
package templates

import "embed"

// FS contains all template files compiled into the binary.
// Subdirectories: base/, swiftdata/, ai-packs/, example/, feature/.
//
//go:embed all:base all:swiftdata all:ai-packs all:example all:feature
var FS embed.FS
