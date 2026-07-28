package generator

import (
	"fmt"
	"hash/fnv"
	"maps"
	"strings"
)

// UUIDProvider generates deterministic 24-character uppercase hex identifiers
// suitable for use in Xcode project files (.pbxproj).
type UUIDProvider interface {
	Generate(seed string) string
}

// FNV1aUUIDProvider produces 24-char uppercase hex strings from FNV-1a hashes.
// The algorithm hashes the seed to get 16 hex chars, then hashes the seed again
// with a suffix to get 8 more, yielding 24 total characters.
type FNV1aUUIDProvider struct{}

// Generate returns a deterministic 24-character uppercase hex string for the given seed.
func (p FNV1aUUIDProvider) Generate(seed string) string {
	h1 := fnv.New64a()
	h1.Write([]byte(seed))
	part1 := fmt.Sprintf("%016X", h1.Sum64())

	h2 := fnv.New64a()
	h2.Write([]byte(seed + ":suffix"))
	part2 := fmt.Sprintf("%08X", uint32(h2.Sum64()))

	return part1 + part2
}

// UUIDRegistry stores generated UUIDs for named lookup within a project.
// It ensures each key maps to exactly one UUID and provides retrieval by name.
type UUIDRegistry struct {
	provider UUIDProvider
	prefix   string
	store    map[string]string
}

// NewUUIDRegistry creates a registry that generates UUIDs using the given provider.
// The prefix is prepended to all seeds (typically the project name).
func NewUUIDRegistry(provider UUIDProvider, prefix string) *UUIDRegistry {
	return &UUIDRegistry{
		provider: provider,
		prefix:   prefix,
		store:    make(map[string]string),
	}
}

// Generate creates and stores a UUID for the given key. The seed is formed as "prefix:key".
// If the key already exists, the previously generated UUID is returned.
func (r *UUIDRegistry) Generate(key string) string {
	if existing, ok := r.store[key]; ok {
		return existing
	}
	seed := r.prefix + ":" + key
	uuid := r.provider.Generate(seed)
	r.store[key] = uuid
	return uuid
}

// Get retrieves a previously generated UUID by key.
// Returns an empty string if the key has not been generated.
func (r *UUIDRegistry) Get(key string) string {
	return r.store[key]
}

// All returns a copy of all stored key-UUID pairs.
func (r *UUIDRegistry) All() map[string]string {
	cp := make(map[string]string, len(r.store))
	maps.Copy(cp, r.store)
	return cp
}

// Keys returns all registered key names sorted alphabetically.
func (r *UUIDRegistry) Keys() []string {
	keys := make([]string, 0, len(r.store))
	for k := range r.store {
		keys = append(keys, k)
	}
	return keys
}

// isUpperHex reports whether s contains only uppercase hex characters (0-9, A-F).
func isUpperHex(s string) bool {
	for _, c := range s {
		if (c < '0' || c > '9') && (c < 'A' || c > 'F') {
			return false
		}
	}
	return len(s) > 0
}

// seedForConfig builds a seed string combining the config key with a scheme name.
func seedForConfig(configSet string, scheme string, isDebug bool) string {
	mode := "Release"
	if isDebug {
		mode = "Debug"
	}
	return configSet + ":" + scheme + ":" + strings.ToLower(mode)
}
