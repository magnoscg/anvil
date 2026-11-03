package feature

import (
	"fmt"

	"github.com/magnoscg/anvil/internal/config"
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
	}

	if cfg.IncludeRouteResolver {
		instructions = append(instructions,
			fmt.Sprintf(
				"Register the RouteResolver: add .with%sRoutes(appRouter: appRouter, dependencies: dependencies) to the NavigationStack in App/Navigation/RootNavigationView.swift so that %sRoute destinations are resolved into views.",
				name, name,
			),
		)
	} else {
		instructions = append(instructions,
			fmt.Sprintf(
				"No RouteResolver was generated: %sRouterImpl can only push routes that an existing resolver already handles. If %s needs its own destinations, re-run anvil feature and answer yes to \"Include RouteResolver?\".",
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
