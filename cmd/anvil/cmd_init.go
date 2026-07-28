package main

import (
	"fmt"
	"os"

	tea "charm.land/bubbletea/v2"
	"github.com/magnoscg/anvil/internal/config"
	"github.com/magnoscg/anvil/internal/deps"
	"github.com/magnoscg/anvil/internal/feature"
	"github.com/magnoscg/anvil/internal/generator"
	"github.com/magnoscg/anvil/internal/tui"
	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Create a new iOS project with Clean Architecture forge",
	Long: `Interactive TUI wizard that forges a new iOS project with all layers:
Domain, Data, Features, Navigation, DI, and SwiftData persistence.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		checker := deps.NewSystemChecker(deps.DefaultCommandRunner())

		writer := generator.NewDiskWriter()
		renderer := generator.NewRenderer(generator.TemplateFS, writer)
		xcodeprojGen := generator.NewXcodeProjGenerator(renderer, writer, generator.TemplateFS)
		gitRunner := generator.NewGitRunner()
		marker := config.FileMarkerReadWriter{}
		forge := feature.NewFeatureForge(renderer)
		merger := generator.NewSettingsMerger(writer, generator.TemplateFS)
		packRenderer := generator.NewPackRenderer(generator.TemplateFS, renderer, writer, merger)

		gen := generator.NewProjectGenerator(
			renderer,
			writer,
			xcodeprojGen,
			gitRunner,
			marker,
			generator.TemplateFS,
			forge,
			packRenderer,
		)

		tui.SetAppVersion(Version)
		model := tui.NewWizardModel(checker, gen)
		p := tea.NewProgram(model)

		if _, err := p.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "Error running wizard: %v\n", err)
			return err
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(initCmd)
}
