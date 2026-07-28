package main

import (
	"fmt"
	"io"
	"os"
	"slices"

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

		tui.SetAppVersion(resolveVersion())
		model := tui.NewWizardModel(checker, gen)
		p := tea.NewProgram(model)

		finalModel, err := p.Run()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error running wizard: %v\n", err)
			return err
		}

		if wizard, ok := finalModel.(tui.WizardModel); ok {
			warnMissingAxiom(os.Stdout, wizard.InstalledPacks())
		}

		return nil
	},
}

// warnMissingAxiom points the user at Axiom's install commands when they
// scaffolded the axiom-ios pack without having the plugin. The pack only writes
// conventions for Axiom, so without it the generated /axiom:* commands are dead.
func warnMissingAxiom(w io.Writer, packs []string) {
	if !slices.Contains(packs, deps.AxiomPackSlug) || deps.AxiomInstalled() {
		return
	}

	fmt.Fprint(w, `
Note: the axiom-ios pack is configured, but Axiom is not installed, so its
/axiom:* commands will not resolve. Install it with:

  claude plugin marketplace add CharlesWiltgen/Axiom
  claude plugin install axiom@axiom-marketplace

Then restart Claude Code. Axiom is by Charles Wiltgen, MIT licensed:
https://github.com/CharlesWiltgen/Axiom

`)
}

func init() {
	rootCmd.AddCommand(initCmd)
}
