package tui

import (
	"slices"

	tea "charm.land/bubbletea/v2"
)

// isKey checks whether a KeyPressMsg matches the given key string.
func isKey(msg tea.KeyPressMsg, keys ...string) bool {
	return slices.Contains(keys, msg.String())
}

// isEnter returns true if the key is Enter.
func isEnter(msg tea.KeyPressMsg) bool {
	return isKey(msg, "enter")
}

// isQuit returns true if the key is q or ctrl+c (quit).
func isQuit(msg tea.KeyPressMsg) bool {
	return isKey(msg, "q", "ctrl+c")
}
