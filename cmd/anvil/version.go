package main

import (
	"fmt"
	"runtime/debug"
	"strings"

	"github.com/spf13/cobra"
)

// Version is set at build time via ldflags:
//
//	go build -ldflags "-X main.Version=1.0.0" ./cmd/anvil
//
// Release archives are built that way. Binaries produced by `go install`
// are not, so use resolveVersion instead of reading this directly.
var Version = "dev"

// resolveVersion reports the version to display. It prefers the ldflags
// value and otherwise falls back to the module version recorded by the Go
// toolchain, which is what `go install <pkg>@<version>` stamps into the
// binary. Returns "dev" when neither is available.
func resolveVersion() string {
	if Version != "dev" {
		return Version
	}

	info, ok := debug.ReadBuildInfo()
	if !ok {
		return Version
	}

	switch info.Main.Version {
	case "", "(devel)":
		return Version
	default:
		return strings.TrimPrefix(info.Main.Version, "v")
	}
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the AnvilCLI version",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("anvil version %s\n", resolveVersion())
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
