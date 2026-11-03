package feature

import (
	"strings"
	"testing"

	"github.com/magnoscg/anvil/internal/config"
)

func TestWiringInstructionsWithRouteResolver(t *testing.T) {
	cfg := config.FeatureConfig{FeatureName: "Pokemon", IncludeRouteResolver: true}

	got := WiringInstructions(cfg)
	joined := strings.Join(got, "\n")

	if !strings.Contains(joined, ".withPokemonRoutes(appRouter: appRouter, dependencies: dependencies)") {
		t.Errorf("expected the generated resolver signature (appRouter:dependencies:), got:\n%s", joined)
	}
	if !strings.Contains(joined, "App/Navigation/RootNavigationView.swift") {
		t.Errorf("expected the registration file path, got:\n%s", joined)
	}
	if strings.Count(joined, ".withPokemonRoutes") != 1 {
		t.Errorf("expected the resolver modifier to be mentioned exactly once, got:\n%s", joined)
	}
}

func TestWiringInstructionsWithoutRouteResolver(t *testing.T) {
	cfg := config.FeatureConfig{FeatureName: "Pokemon", IncludeRouteResolver: false}

	got := WiringInstructions(cfg)
	joined := strings.Join(got, "\n")

	if strings.Contains(joined, ".withPokemonRoutes") {
		t.Errorf("must not ask to register a resolver that was not generated, got:\n%s", joined)
	}
	if !strings.Contains(joined, "PokemonFactory.makeView(appRouter:dependencies:)") {
		t.Errorf("expected the factory registration step, got:\n%s", joined)
	}
	if !strings.Contains(joined, "Features/Pokemon/Navigation/PokemonRouteResolver.swift") {
		t.Errorf("expected guidance on how to add a resolver, got:\n%s", joined)
	}
	if strings.Contains(joined, "re-run") {
		t.Errorf("must not suggest re-running anvil feature, which refuses an existing feature, got:\n%s", joined)
	}
}
