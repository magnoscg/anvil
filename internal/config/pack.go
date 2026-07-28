package config

// Pack describes a selectable AI coding pack that groups related skills,
// docs, commands, and configuration for Claude Code. Each pack can be
// independently installed during `anvil init`.
type Pack struct {
	// Slug is the unique identifier for this pack (e.g. "ios-architecture").
	Slug string

	// DisplayName is the human-readable name shown in the TUI (e.g. "iOS Architecture").
	DisplayName string

	// Description is a one-line summary of what the pack includes.
	Description string

	// Requires lists slugs of packs that must also be installed when this pack is selected.
	Requires []string

	// HasSkills indicates whether this pack contains skills that need the
	// global vs project scope question during installation.
	HasSkills bool
}
