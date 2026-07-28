package config

import (
	"errors"
	"fmt"
	"testing"
)

func TestAllPacksCount(t *testing.T) {
	packs := AllPacks()
	if len(packs) != 7 {
		t.Errorf("AllPacks() returned %d packs, want 7", len(packs))
	}
}

func TestPackBySlugFound(t *testing.T) {
	pack, ok := PackBySlug("ios-architecture")
	if !ok {
		t.Fatal("PackBySlug(\"ios-architecture\") returned ok=false, want true")
	}
	if pack.DisplayName != "iOS Architecture" {
		t.Errorf("DisplayName = %q, want %q", pack.DisplayName, "iOS Architecture")
	}
	if pack.HasSkills {
		t.Error("ios-architecture should not have HasSkills=true")
	}
}

func TestPackBySlugNotFound(t *testing.T) {
	_, ok := PackBySlug("nonexistent")
	if ok {
		t.Error("PackBySlug(\"nonexistent\") returned ok=true, want false")
	}
}

func TestResolveDependenciesPrdPlanner(t *testing.T) {
	result := ResolveDependencies([]string{"prd-planner"})

	found := map[string]bool{}
	for _, s := range result {
		found[s] = true
	}

	if !found["ios-architecture"] {
		t.Error("ResolveDependencies([\"prd-planner\"]) should include \"ios-architecture\"")
	}
	if !found["prd-planner"] {
		t.Error("ResolveDependencies([\"prd-planner\"]) should include \"prd-planner\"")
	}

	// ios-architecture must come before prd-planner (topological order)
	iosIdx, prdIdx := -1, -1
	for i, s := range result {
		if s == "ios-architecture" {
			iosIdx = i
		}
		if s == "prd-planner" {
			prdIdx = i
		}
	}
	if iosIdx >= prdIdx {
		t.Errorf("ios-architecture (idx %d) should come before prd-planner (idx %d)", iosIdx, prdIdx)
	}
}

func TestResolveDependenciesNoDeps(t *testing.T) {
	result := ResolveDependencies([]string{"ios-architecture"})

	if len(result) != 1 {
		t.Errorf("ResolveDependencies([\"ios-architecture\"]) returned %d slugs, want 1: %v", len(result), result)
	}
	if result[0] != "ios-architecture" {
		t.Errorf("result[0] = %q, want %q", result[0], "ios-architecture")
	}
}

func TestResolveDependenciesIndependent(t *testing.T) {
	result := ResolveDependencies([]string{"swift-design-patterns"})

	if len(result) != 1 {
		t.Errorf("ResolveDependencies([\"swift-design-patterns\"]) returned %d slugs, want 1: %v", len(result), result)
	}
}

func TestValidatePacksAllValid(t *testing.T) {
	err := ValidatePacks([]string{"ios-architecture", "gitflow"})
	if err != nil {
		t.Errorf("ValidatePacks with valid slugs returned error: %v", err)
	}
}

func TestValidatePacksInvalid(t *testing.T) {
	err := ValidatePacks([]string{"nonexistent"})
	if err == nil {
		t.Fatal("ValidatePacks with invalid slug should return error")
	}

	var target PackNotFoundError
	if !errors.As(err, &target) {
		t.Errorf("expected PackNotFoundError, got %T: %v", err, err)
	}
	if target.Slug != "nonexistent" {
		t.Errorf("PackNotFoundError.Slug = %q, want %q", target.Slug, "nonexistent")
	}
}

func TestPackErrorMessages(t *testing.T) {
	tests := []struct {
		name string
		err  error
		want string
	}{
		{
			name: "PackNotFoundError",
			err:  PackNotFoundError{Slug: "unknown"},
			want: `pack "unknown" not found in registry`,
		},
		{
			name: "PackDependencyError",
			err:  PackDependencyError{Pack: "prd-planner", Missing: "ios-architecture"},
			want: `pack "prd-planner" requires "ios-architecture" which is not selected`,
		},
		{
			name: "SettingsMergeError",
			err:  SettingsMergeError{Path: "/tmp/settings.json", Cause: fmt.Errorf("permission denied")},
			want: `failed to merge settings at /tmp/settings.json: permission denied`,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.err.Error()
			if got != tt.want {
				t.Errorf("Error() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestResolveDependenciesDuplicateSlugs(t *testing.T) {
	result := ResolveDependencies([]string{"ios-architecture", "ios-architecture"})

	// Should be deduplicated to 1 entry
	count := 0
	for _, s := range result {
		if s == "ios-architecture" {
			count++
		}
	}
	if count != 1 {
		t.Errorf("ios-architecture appeared %d times, want 1 (deduplicated)", count)
	}
}

func TestResolveDependenciesAllPacks(t *testing.T) {
	allSlugs := make([]string, 0)
	for _, p := range AllPacks() {
		allSlugs = append(allSlugs, p.Slug)
	}

	result := ResolveDependencies(allSlugs)

	if len(result) != 7 {
		t.Errorf("all packs resolved to %d slugs, want 7: %v", len(result), result)
	}

	// ios-architecture must come before prd-planner (dependency order)
	iosIdx, prdIdx := -1, -1
	for i, s := range result {
		if s == "ios-architecture" {
			iosIdx = i
		}
		if s == "prd-planner" {
			prdIdx = i
		}
	}
	if iosIdx >= prdIdx {
		t.Errorf("ios-architecture (idx %d) should come before prd-planner (idx %d)", iosIdx, prdIdx)
	}
}

func TestValidatePacksEmpty(t *testing.T) {
	err := ValidatePacks(nil)
	if err != nil {
		t.Errorf("ValidatePacks(nil) should return nil, got %v", err)
	}

	err = ValidatePacks([]string{})
	if err != nil {
		t.Errorf("ValidatePacks([]) should return nil, got %v", err)
	}
}

func TestPrdPlannerHasSkills(t *testing.T) {
	pack, ok := PackBySlug("prd-planner")
	if !ok {
		t.Fatal("prd-planner not found")
	}
	if !pack.HasSkills {
		t.Error("prd-planner should have HasSkills=true (contains skills/ios-tutorials)")
	}
}

func TestSettingsMergeErrorUnwrap(t *testing.T) {
	cause := fmt.Errorf("disk full")
	err := SettingsMergeError{Path: "/tmp/settings.json", Cause: cause}
	if errors.Unwrap(err) != cause {
		t.Error("SettingsMergeError.Unwrap() should return the cause")
	}
}
