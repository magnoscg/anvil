package config

import (
	"strings"
	"unicode"
)

// ToPascalCase converts a string to PascalCase.
// Handles hyphen-separated, underscore-separated, camelCase, and PascalCase input.
// Examples: "pokemon-list" -> "PokemonList", "pokemonList" -> "PokemonList".
func ToPascalCase(s string) string {
	words := splitIntoWords(s)
	var b strings.Builder
	for _, w := range words {
		if len(w) == 0 {
			continue
		}
		b.WriteRune(unicode.ToUpper(rune(w[0])))
		b.WriteString(strings.ToLower(w[1:]))
	}
	return b.String()
}

// ToCamelCase converts a string to camelCase.
// Handles hyphen-separated, underscore-separated, camelCase, and PascalCase input.
// Examples: "pokemon-list" -> "pokemonList", "PokemonList" -> "pokemonList".
func ToCamelCase(s string) string {
	words := splitIntoWords(s)
	var b strings.Builder
	for i, w := range words {
		if len(w) == 0 {
			continue
		}
		if i == 0 {
			b.WriteString(strings.ToLower(w))
		} else {
			b.WriteRune(unicode.ToUpper(rune(w[0])))
			b.WriteString(strings.ToLower(w[1:]))
		}
	}
	return b.String()
}

// ToSnakeCase converts a string to snake_case.
// Handles hyphen-separated, underscore-separated, camelCase, and PascalCase input.
// Examples: "PokemonList" -> "pokemon_list", "pokemonList" -> "pokemon_list".
func ToSnakeCase(s string) string {
	words := splitIntoWords(s)
	lowered := make([]string, 0, len(words))
	for _, w := range words {
		if len(w) == 0 {
			continue
		}
		lowered = append(lowered, strings.ToLower(w))
	}
	return strings.Join(lowered, "_")
}

// TemplateVars returns a map of naming variants for use in Go text/templates.
// Keys: "FeatureName" (PascalCase), "featureName" (camelCase), "feature_name" (snake_case).
func TemplateVars(featureName string) map[string]string {
	return map[string]string{
		"FeatureName":  ToPascalCase(featureName),
		"featureName":  ToCamelCase(featureName),
		"feature_name": ToSnakeCase(featureName),
	}
}

// splitIntoWords breaks a string into words by splitting on hyphens,
// underscores, and camelCase boundaries.
func splitIntoWords(s string) []string {
	s = strings.ReplaceAll(s, "-", " ")
	s = strings.ReplaceAll(s, "_", " ")

	parts := strings.Fields(s)

	var words []string
	for _, part := range parts {
		words = append(words, splitCamelCase(part)...)
	}
	return words
}

// splitCamelCase splits a string on camelCase boundaries.
// "PokemonList" -> ["Pokemon", "List"], "pokemonList" -> ["pokemon", "List"].
func splitCamelCase(s string) []string {
	if len(s) == 0 {
		return nil
	}
	runes := []rune(s)
	var words []string
	start := 0
	for i := 1; i < len(runes); i++ {
		if unicode.IsUpper(runes[i]) && !unicode.IsUpper(runes[i-1]) {
			words = append(words, string(runes[start:i]))
			start = i
		} else if unicode.IsUpper(runes[i]) && unicode.IsUpper(runes[i-1]) && i+1 < len(runes) && unicode.IsLower(runes[i+1]) {
			words = append(words, string(runes[start:i]))
			start = i
		}
	}
	words = append(words, string(runes[start:]))
	return words
}
