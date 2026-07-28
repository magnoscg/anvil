package main

import (
	"fmt"
	"os"

	"github.com/charmbracelet/huh"
	"github.com/oscarcanton/anvilcli/internal/config"
	"github.com/oscarcanton/anvilcli/internal/feature"
	"github.com/oscarcanton/anvilcli/internal/generator"
	"github.com/spf13/cobra"
)

var featureCmd = &cobra.Command{
	Use:   "feature <name>",
	Short: "Forge a new feature in an existing iOS project",
	Long: `Generates all files for a new feature following Clean Architecture:
ViewModel, View, State, Decorator, Router, Factory, UseCase, Repository, and more.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		featureName := config.ToPascalCase(args[0])

		marker := config.FileMarkerReadWriter{}
		cwd, err := os.Getwd()
		if err != nil {
			return fmt.Errorf("getting working directory: %w", err)
		}

		projectRoot, err := marker.FindProjectRoot(cwd)
		if err != nil {
			return fmt.Errorf("not inside an Anvil project: %w", err)
		}

		anvilMarker, err := marker.Read(projectRoot)
		if err != nil {
			return fmt.Errorf("reading .anvil.yml: %w", err)
		}

		var includeLocal bool
		var includeKeychain bool
		var includeResolver bool
		var includeUITests bool

		form := huh.NewForm(
			huh.NewGroup(
				huh.NewConfirm().
					Title("Include local data source (UserDefaults)?").
					Value(&includeLocal),
				huh.NewConfirm().
					Title("Include Keychain storage?").
					Value(&includeKeychain),
				huh.NewConfirm().
					Title("Include RouteResolver?").
					Value(&includeResolver),
				huh.NewConfirm().
					Title("Include UI tests (AccessibilityID, Stubs, ScreenTests)?").
					Value(&includeUITests),
			),
		)

		if err := form.Run(); err != nil {
			return fmt.Errorf("form cancelled: %w", err)
		}

		featureCfg := config.FeatureConfig{
			FeatureName:            featureName,
			FeatureNameLower:       config.ToCamelCase(featureName),
			ProjectRoot:            projectRoot,
			ProjectName:            anvilMarker.ProjectName,
			IncludeLocalDataSource: includeLocal,
			IncludeKeychain:        includeKeychain,
			IncludeRouteResolver:   includeResolver,
			IncludeUITests:         includeUITests,
		}

		writer := generator.NewDiskWriter()
		renderer := generator.NewRenderer(generator.TemplateFS, writer)
		forge := feature.NewFeatureForge(renderer)

		result, err := forge.Forge(featureCfg)
		if err != nil {
			return fmt.Errorf("forging feature %q: %w", featureName, err)
		}

		fmt.Printf("\n✓ Feature %q forged successfully!\n\n", featureName)
		fmt.Printf("  Directory: %s\n", result.FeatureDir)
		fmt.Printf("  Files created: %d\n\n", len(result.FilesCreated))

		for _, f := range result.FilesCreated {
			fmt.Printf("    %s\n", f)
		}

		if len(result.WiringInstructions) > 0 {
			fmt.Println("\n  Wiring instructions:")
			for i, instr := range result.WiringInstructions {
				fmt.Printf("    %d. %s\n", i+1, instr)
			}
		}

		fmt.Println()
		return nil
	},
}

func init() {
	rootCmd.AddCommand(featureCmd)
}
