package config

import (
	"errors"
	"testing"
)

func TestValidateProjectName(t *testing.T) {
	tests := []struct {
		name    string
		wantErr bool
	}{
		{name: "MyApp"},
		{name: "my-app_2"},
		{name: "", wantErr: true},
		{name: "2App", wantErr: true},
		{name: "../App", wantErr: true},
		{name: "App/Child", wantErr: true},
		{name: `App\\Child`, wantErr: true},
		{name: ".", wantErr: true},
		{name: "App Name", wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			err := ValidateProjectName(test.name)
			if (err != nil) != test.wantErr {
				t.Fatalf("ValidateProjectName(%q) error = %v, wantErr %v", test.name, err, test.wantErr)
			}
		})
	}
}

func TestValidateSchemeNames(t *testing.T) {
	tests := []struct {
		label     string
		schemes   []string
		wantErr   bool
		duplicate bool
	}{
		{label: "defaults", schemes: []string{"Dev", "Stg", "Production"}},
		{label: "underscore and digits", schemes: []string{"QA_2", "Release"}},
		{label: "none", schemes: nil},
		{label: "parent traversal", schemes: []string{"Dev", "../../escaped"}, wantErr: true},
		{label: "path separator", schemes: []string{"Dev/Child"}, wantErr: true},
		{label: "backslash", schemes: []string{`Dev\Child`}, wantErr: true},
		{label: "absolute path", schemes: []string{"/tmp/Dev"}, wantErr: true},
		{label: "hyphen breaks the Swift case", schemes: []string{"Pre-Prod"}, wantErr: true},
		{label: "leading digit", schemes: []string{"2Dev"}, wantErr: true},
		{label: "empty", schemes: []string{""}, wantErr: true},
		{label: "case-insensitive duplicate", schemes: []string{"Dev", "dev"}, wantErr: true, duplicate: true},
	}

	for _, test := range tests {
		t.Run(test.label, func(t *testing.T) {
			err := ValidateSchemeNames(test.schemes)
			if (err != nil) != test.wantErr {
				t.Fatalf("ValidateSchemeNames(%q) error = %v, wantErr %v", test.schemes, err, test.wantErr)
			}
			if !test.wantErr {
				return
			}
			var invalid InvalidSchemeNameError
			if !errors.As(err, &invalid) {
				t.Fatalf("error = %T, want InvalidSchemeNameError", err)
			}
			if invalid.Duplicate != test.duplicate {
				t.Fatalf("Duplicate = %v, want %v", invalid.Duplicate, test.duplicate)
			}
		})
	}
}

func TestToPascalCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"pokemon-list", "PokemonList"},
		{"PokemonList", "PokemonList"},
		{"pokemon_list", "PokemonList"},
		{"pokemonList", "PokemonList"},
		{"pokemon", "Pokemon"},
		{"Pokemon", "Pokemon"},
		{"POKEMON", "Pokemon"},
		{"auth-login-screen", "AuthLoginScreen"},
		{"my_cool_feature", "MyCoolFeature"},
		{"already", "Already"},
		{"a", "A"},
		{"", ""},
		{"ABCDef", "AbcDef"},
		{"userID", "UserId"},
	}
	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := ToPascalCase(tt.input)
			if got != tt.want {
				t.Errorf("ToPascalCase(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestToCamelCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"pokemon-list", "pokemonList"},
		{"PokemonList", "pokemonList"},
		{"pokemon_list", "pokemonList"},
		{"pokemonList", "pokemonList"},
		{"pokemon", "pokemon"},
		{"Pokemon", "pokemon"},
		{"POKEMON", "pokemon"},
		{"auth-login-screen", "authLoginScreen"},
		{"my_cool_feature", "myCoolFeature"},
		{"a", "a"},
		{"", ""},
	}
	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := ToCamelCase(tt.input)
			if got != tt.want {
				t.Errorf("ToCamelCase(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestToSnakeCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"pokemon-list", "pokemon_list"},
		{"PokemonList", "pokemon_list"},
		{"pokemon_list", "pokemon_list"},
		{"pokemonList", "pokemon_list"},
		{"pokemon", "pokemon"},
		{"Pokemon", "pokemon"},
		{"auth-login-screen", "auth_login_screen"},
		{"MyCoolFeature", "my_cool_feature"},
		{"a", "a"},
		{"", ""},
	}
	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := ToSnakeCase(tt.input)
			if got != tt.want {
				t.Errorf("ToSnakeCase(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestTemplateVars(t *testing.T) {
	vars := TemplateVars("pokemon-list")

	if vars["FeatureName"] != "PokemonList" {
		t.Errorf("FeatureName = %q, want %q", vars["FeatureName"], "PokemonList")
	}
	if vars["featureName"] != "pokemonList" {
		t.Errorf("featureName = %q, want %q", vars["featureName"], "pokemonList")
	}
	if vars["feature_name"] != "pokemon_list" {
		t.Errorf("feature_name = %q, want %q", vars["feature_name"], "pokemon_list")
	}
}

func TestTemplateVarsPascalInput(t *testing.T) {
	vars := TemplateVars("PokemonDetail")

	if vars["FeatureName"] != "PokemonDetail" {
		t.Errorf("FeatureName = %q, want %q", vars["FeatureName"], "PokemonDetail")
	}
	if vars["featureName"] != "pokemonDetail" {
		t.Errorf("featureName = %q, want %q", vars["featureName"], "pokemonDetail")
	}
	if vars["feature_name"] != "pokemon_detail" {
		t.Errorf("feature_name = %q, want %q", vars["feature_name"], "pokemon_detail")
	}
}
