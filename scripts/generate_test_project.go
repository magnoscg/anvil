// generate_test_project.go — CLI tool to generate an anvil project without TUI.
// Usage: go run ./scripts/generate_test_project.go -name MyApp -output /tmp/test
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/oscarcanton/anvilcli/internal/config"
	"github.com/oscarcanton/anvilcli/internal/feature"
	"github.com/oscarcanton/anvilcli/internal/generator"
)

func main() {
	name := flag.String("name", "TestApp", "Project name")
	bundleID := flag.String("bundle-id", "com.test.TestApp", "Bundle ID")
	iosVersion := flag.String("ios-version", "18.0", "iOS deployment target")
	swiftVersion := flag.String("swift-version", "6.0", "Swift version")
	schemes := flag.String("schemes", "Dev,Stg,Production", "Comma-separated schemes")
	output := flag.String("output", "", "Output directory (required)")
	includeExample := flag.Bool("include-example", false, "Include Example feature")
	includeSwiftData := flag.Bool("include-swiftdata", false, "Include SwiftData")
	aiPacks := flag.String("ai-packs", "", "Comma-separated AI pack slugs (e.g. ios-architecture,gitflow)")
	flag.Parse()

	if *output == "" {
		fmt.Fprintln(os.Stderr, "error: -output is required")
		os.Exit(1)
	}

	schemeList := strings.Split(*schemes, ",")
	for i, s := range schemeList {
		schemeList[i] = strings.TrimSpace(s)
	}

	var packList []string
	if *aiPacks != "" {
		for _, p := range strings.Split(*aiPacks, ",") {
			trimmed := strings.TrimSpace(p)
			if trimmed != "" {
				packList = append(packList, trimmed)
			}
		}
	}

	cfg := config.ProjectConfig{
		Name:             *name,
		BundleID:         *bundleID,
		Organization:     config.OrganizationFromBundleID(*bundleID),
		IOSVersion:       *iosVersion,
		SwiftVersion:     *swiftVersion,
		Schemes:          schemeList,
		OutputDir:        *output,
		IncludeSwiftData: *includeSwiftData,
		AIPacks:          packList,
		SkillsScope:      "project",
		IncludeExample:   *includeExample,
	}

	writer := generator.NewDiskWriter()
	renderer := generator.NewRenderer(generator.TemplateFS, writer)
	xcodeprojGen := generator.NewXcodeProjGenerator(renderer, writer, generator.TemplateFS)
	gitRunner := generator.NewGitRunner()
	marker := config.FileMarkerReadWriter{}
	forge := feature.NewFeatureForge(renderer)
	merger := generator.NewSettingsMerger(writer, generator.TemplateFS)
	packRenderer := generator.NewPackRenderer(generator.TemplateFS, renderer, writer, merger)

	gen := generator.NewProjectGenerator(
		renderer, writer, xcodeprojGen, gitRunner,
		marker, generator.TemplateFS, forge, packRenderer,
	)

	fmt.Printf("Generating %s at %s/%s...\n", cfg.Name, cfg.OutputDir, cfg.Name)
	result, err := gen.Generate(context.Background(), cfg)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Success! %d files created in %s\n", len(result.FilesCreated), result.Duration.Round(1e6))
}
