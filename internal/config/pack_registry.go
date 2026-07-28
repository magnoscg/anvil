package config

// AllPacks returns the complete list of available AI coding packs in display order.
func AllPacks() []Pack {
	return []Pack{
		{
			Slug:        "ios-architecture",
			DisplayName: "iOS Architecture",
			Description: "Clean Architecture rules, anti-patterns, 13 reference docs",
			Requires:    nil,
			HasSkills:   false,
		},
		{
			Slug:        "prd-planner",
			DisplayName: "PRD Planner",
			Description: "10 agents + 16 commands (dev-prd, dev-plan, dev-build, dev-design, dev-qa...)",
			Requires:    []string{"ios-architecture"},
			HasSkills:   true,
		},
		{
			Slug:        "axiom-ios",
			DisplayName: "Axiom iOS",
			Description: "Axiom simulator skills, audits, and debugging agents",
			Requires:    nil,
			HasSkills:   false,
		},
		{
			Slug:        "swift-design-patterns",
			DisplayName: "Swift Design Patterns",
			Description: "22 design pattern skills + 3 overview skills for Swift",
			Requires:    nil,
			HasSkills:   true,
		},
		{
			Slug:        "gitflow",
			DisplayName: "Gitflow",
			Description: "Git branching conventions and workflow skill",
			Requires:    nil,
			HasSkills:   true,
		},
		{
			Slug:        "ios-skills",
			DisplayName: "iOS Skills",
			Description: "7 skills: Swift Charts, Concurrency, SwiftUI Expert, iOS/macOS Design, Glass UI, Tech Docs",
			Requires:    nil,
			HasSkills:   true,
		},
		{
			Slug:        "github-actions",
			DisplayName: "GitHub Actions",
			Description: "CI/CD workflows for Go + Swift (ci.yml, release.yml)",
			Requires:    nil,
			HasSkills:   false,
		},
	}
}

// PackBySlug looks up a pack by its unique slug identifier.
// Returns the pack and true if found, or a zero Pack and false otherwise.
func PackBySlug(slug string) (Pack, bool) {
	for _, p := range AllPacks() {
		if p.Slug == slug {
			return p, true
		}
	}
	return Pack{}, false
}

// ResolveDependencies expands a list of selected pack slugs to include all
// transitive dependencies. The returned slice is in topological order:
// dependencies appear before the packs that require them.
func ResolveDependencies(selected []string) []string {
	set := make(map[string]bool, len(selected))
	for _, s := range selected {
		set[s] = true
	}

	// Add transitive dependencies
	changed := true
	for changed {
		changed = false
		for slug := range set {
			pack, ok := PackBySlug(slug)
			if !ok {
				continue
			}
			for _, dep := range pack.Requires {
				if !set[dep] {
					set[dep] = true
					changed = true
				}
			}
		}
	}

	// Build result in topological order: dependencies first.
	// Walk AllPacks() to preserve a stable display order and ensure deps come first.
	all := AllPacks()
	var result []string
	for _, p := range all {
		if set[p.Slug] {
			result = append(result, p.Slug)
		}
	}
	return result
}

// ValidatePacks checks that every slug in the list exists in the registry.
// Returns a PackNotFoundError for the first unknown slug, or nil if all are valid.
func ValidatePacks(slugs []string) error {
	for _, slug := range slugs {
		if _, ok := PackBySlug(slug); !ok {
			return PackNotFoundError{Slug: slug}
		}
	}
	return nil
}
