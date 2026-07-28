//go:build tools

package tools

// Blank imports to retain dependencies in go.mod until they are used in later phases.
import (
	_ "charm.land/bubbletea/v2"
	_ "charm.land/lipgloss/v2"
	_ "github.com/charmbracelet/huh"
)
