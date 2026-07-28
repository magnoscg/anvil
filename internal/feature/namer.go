package feature

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/oscarcanton/anvilcli/internal/config"
)

// swiftKeywords lists reserved Swift keywords that cannot be used as feature names.
var swiftKeywords = map[string]bool{
	"associatedtype": true, "class": true, "deinit": true, "enum": true,
	"extension": true, "fileprivate": true, "func": true, "import": true,
	"init": true, "inout": true, "internal": true, "let": true,
	"open": true, "operator": true, "private": true, "precedencegroup": true,
	"protocol": true, "public": true, "rethrows": true, "static": true,
	"struct": true, "subscript": true, "typealias": true, "var": true,
	"break": true, "case": true, "catch": true, "continue": true,
	"default": true, "defer": true, "do": true, "else": true,
	"fallthrough": true, "for": true, "guard": true, "if": true,
	"in": true, "repeat": true, "return": true, "switch": true,
	"throw": true, "throws": true, "try": true, "where": true,
	"while": true, "as": true, "any": true, "false": true,
	"is": true, "nil": true, "self": true, "Self": true,
	"super": true, "true": true, "async": true, "await": true,
	"actor": true, "some": true, "macro": true, "package": true,
	"consuming": true, "borrowing": true, "nonisolated": true,
}

// InvalidFeatureNameError indicates that the provided feature name is not valid.
type InvalidFeatureNameError struct {
	Name       string
	Reason     string
	Suggestion string
}

func (e InvalidFeatureNameError) Error() string {
	msg := fmt.Sprintf("invalid feature name %q: %s", e.Name, e.Reason)
	if e.Suggestion != "" {
		msg += fmt.Sprintf("; suggestion: %s", e.Suggestion)
	}
	return msg
}

// ValidateFeatureName checks that the given name is a valid Swift identifier,
// is not a Swift keyword, and follows PascalCase conventions.
func ValidateFeatureName(name string) error {
	if name == "" {
		return InvalidFeatureNameError{
			Name:   name,
			Reason: "feature name cannot be empty",
		}
	}

	normalized := NormalizeFeatureName(name)

	if !isValidSwiftIdentifier(normalized) {
		return InvalidFeatureNameError{
			Name:   name,
			Reason: "must be a valid Swift identifier (start with letter, contain only letters and digits)",
		}
	}

	if swiftKeywords[strings.ToLower(normalized)] {
		return InvalidFeatureNameError{
			Name:       name,
			Reason:     fmt.Sprintf("%q is a Swift reserved keyword", normalized),
			Suggestion: fmt.Sprintf("try %q instead", normalized+"Feature"),
		}
	}

	if !unicode.IsUpper(rune(normalized[0])) {
		return InvalidFeatureNameError{
			Name:       name,
			Reason:     "feature name must start with an uppercase letter (PascalCase)",
			Suggestion: fmt.Sprintf("try %q", normalized),
		}
	}

	return nil
}

// NormalizeFeatureName converts any input format to PascalCase.
// Examples: "my-feature" -> "MyFeature", "my_feature" -> "MyFeature",
// "myFeature" -> "MyFeature", "PokemonList" -> "PokemonList".
func NormalizeFeatureName(input string) string {
	return config.ToPascalCase(input)
}

// isValidSwiftIdentifier checks that s starts with a letter (or underscore)
// and contains only letters, digits, or underscores.
func isValidSwiftIdentifier(s string) bool {
	if len(s) == 0 {
		return false
	}
	for i, r := range s {
		if i == 0 {
			if !unicode.IsLetter(r) && r != '_' {
				return false
			}
		} else {
			if !unicode.IsLetter(r) && !unicode.IsDigit(r) && r != '_' {
				return false
			}
		}
	}
	return true
}
