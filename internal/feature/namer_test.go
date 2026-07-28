package feature

import (
	"errors"
	"testing"
)

func TestNormalizeFeatureName(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"pokemon-list", "PokemonList"},
		{"PokemonList", "PokemonList"},
		{"pokemon_list", "PokemonList"},
		{"pokemonList", "PokemonList"},
		{"pokemon", "Pokemon"},
		{"auth-login-screen", "AuthLoginScreen"},
		{"my_cool_feature", "MyCoolFeature"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := NormalizeFeatureName(tt.input)
			if got != tt.want {
				t.Errorf("NormalizeFeatureName(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestValidateFeatureName(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		wantErr bool
	}{
		{"valid PascalCase", "PokemonList", false},
		{"valid hyphenated", "pokemon-list", false},
		{"valid underscored", "pokemon_list", false},
		{"valid camelCase", "pokemonList", false},
		{"valid single word", "Pokemon", false},
		{"empty string", "", true},
		{"starts with digit", "123invalid", true},
		{"swift keyword class", "class", true},
		{"swift keyword struct", "struct", true},
		{"swift keyword enum", "enum", true},
		{"swift keyword func", "func", true},
		{"swift keyword import", "import", true},
		{"swift keyword var", "var", true},
		{"swift keyword let", "let", true},
		{"swift keyword actor", "actor", true},
		{"swift keyword async", "async", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateFeatureName(tt.input)
			if tt.wantErr && err == nil {
				t.Errorf("ValidateFeatureName(%q) expected error, got nil", tt.input)
			}
			if !tt.wantErr && err != nil {
				t.Errorf("ValidateFeatureName(%q) unexpected error: %v", tt.input, err)
			}
		})
	}
}

func TestValidateFeatureNameErrorType(t *testing.T) {
	err := ValidateFeatureName("")
	var target InvalidFeatureNameError
	if !errors.As(err, &target) {
		t.Errorf("expected InvalidFeatureNameError, got %T: %v", err, err)
	}
}

func TestValidateFeatureNameSwiftKeywordSuggestion(t *testing.T) {
	err := ValidateFeatureName("class")
	var target InvalidFeatureNameError
	if !errors.As(err, &target) {
		t.Fatalf("expected InvalidFeatureNameError, got %T: %v", err, err)
	}
	if target.Suggestion == "" {
		t.Error("expected non-empty suggestion for keyword error")
	}
}

func TestValidateFeatureNameStartsWithDigitNormalized(t *testing.T) {
	err := ValidateFeatureName("123feature")
	if err == nil {
		t.Error("expected error for name starting with digit, got nil")
	}
}
