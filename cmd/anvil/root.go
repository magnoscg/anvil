package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "anvil",
	Short: "AnvilCLI — iOS project forge tool",
	Long: `AnvilCLI forges new iOS projects following Clean Architecture + MVVM + Router.

It generates the full project structure with all layers (Domain, Data, Features),
navigation, dependency injection, and SwiftData persistence — ready to build.

Use "anvil init" to create a new project or "anvil feature" to add a feature forge.`,
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		// TODO(phase-16): load configuration and wire TUI global state.
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
