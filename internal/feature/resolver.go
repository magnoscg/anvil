package feature

import (
	"fmt"

	"github.com/oscarcanton/anvilcli/internal/config"
)

// WiringInstructions generates human-readable instructions for integrating a
// newly forged feature into the project's navigation and DI.
func WiringInstructions(cfg config.FeatureConfig) []string {
	name := cfg.FeatureName

	instructions := []string{
		fmt.Sprintf(
			"Register the factory: call %sFactory.makeView(appRouter:dependencies:) from the appropriate navigation entry point.",
			name,
		),
		fmt.Sprintf(
			"Add .with%sRoutes(appRouter:) modifier to the NavigationStack in your app root.",
			name,
		),
	}

	if cfg.IncludeRouteResolver {
		instructions = append(instructions,
			fmt.Sprintf(
				"Wire the RouteResolver: %sRouteResolver is included. Register it in the NavigationStack so that %sRoute destinations are resolved into views.",
				name, name,
			),
		)
	}

	instructions = append(instructions,
		fmt.Sprintf(
			"Add route cases: open Features/%s/Navigation/%sRouter.swift and define the route cases your feature needs (e.g., .detail(id:)).",
			name, name,
		),
	)

	return instructions
}
