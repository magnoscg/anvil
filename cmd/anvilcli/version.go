package main

import (
	"fmt"

	"github.com/spf13/cobra"
)

// Version is set at build time via ldflags:
//
//	go build -ldflags "-X main.Version=1.0.0" ./cmd/anvilcli
var Version = "dev"

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the AnvilCLI version",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("anvil version %s\n", Version)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
