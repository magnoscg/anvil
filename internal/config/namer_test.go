package config

import "testing"

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
