package generator

import (
	"testing"
)

// MARK: - FNV1aUUIDProvider Tests

func TestFNV1aUUIDProviderReturns24CharUppercaseHex(t *testing.T) {
	provider := FNV1aUUIDProvider{}
	result := provider.Generate("MyApp:PBXProject")

	if len(result) != 24 {
		t.Errorf("expected 24 characters, got %d: %q", len(result), result)
	}

	if !isUpperHex(result) {
		t.Errorf("expected uppercase hex string, got %q", result)
	}
}

func TestFNV1aUUIDProviderDeterminism(t *testing.T) {
	provider := FNV1aUUIDProvider{}
	seed := "MyApp:PBXProject"

	first := provider.Generate(seed)
	second := provider.Generate(seed)

	if first != second {
		t.Errorf("same seed should produce same UUID: %q != %q", first, second)
	}
}

func TestFNV1aUUIDProviderUniqueness(t *testing.T) {
	provider := FNV1aUUIDProvider{}

	seeds := []string{
		"MyApp:PBXProject",
		"MyApp:MainGroup",
		"MyApp:AppTarget",
		"MyApp:TestTarget",
		"OtherApp:PBXProject",
	}

	seen := make(map[string]string)
	for _, seed := range seeds {
		uuid := provider.Generate(seed)
		if prevSeed, exists := seen[uuid]; exists {
			t.Errorf("collision: seeds %q and %q produced same UUID %q", prevSeed, seed, uuid)
		}
		seen[uuid] = seed
	}
}

func TestFNV1aUUIDProviderMultipleSeeds24Chars(t *testing.T) {
	provider := FNV1aUUIDProvider{}

	seeds := []string{
		"A:B",
		"LongProjectName:VeryLongObjectType",
		"X:Y:Z:Extra:Parts",
		"",
	}

	for _, seed := range seeds {
		result := provider.Generate(seed)
		if len(result) != 24 {
			t.Errorf("seed %q: expected 24 chars, got %d: %q", seed, len(result), result)
		}
		if !isUpperHex(result) {
			t.Errorf("seed %q: expected uppercase hex, got %q", seed, result)
		}
	}
}

// MARK: - UUIDRegistry Tests

func TestUUIDRegistryStoreAndRetrieve(t *testing.T) {
	provider := FNV1aUUIDProvider{}
	reg := NewUUIDRegistry(provider, "TestApp")

	uuid := reg.Generate("PBXProject")

	if uuid == "" {
		t.Fatal("Generate should return a non-empty UUID")
	}

	retrieved := reg.Get("PBXProject")
	if retrieved != uuid {
		t.Errorf("Get should return the same UUID: %q != %q", retrieved, uuid)
	}
}

func TestUUIDRegistryReturnsSameUUIDForDuplicateKey(t *testing.T) {
	provider := FNV1aUUIDProvider{}
	reg := NewUUIDRegistry(provider, "TestApp")

	first := reg.Generate("AppTarget")
	second := reg.Generate("AppTarget")

	if first != second {
		t.Errorf("duplicate Generate should return same UUID: %q != %q", first, second)
	}
}

func TestUUIDRegistryReturnsEmptyStringForUnknownKey(t *testing.T) {
	provider := FNV1aUUIDProvider{}
	reg := NewUUIDRegistry(provider, "TestApp")

	result := reg.Get("NonExistentKey")
	if result != "" {
		t.Errorf("Get for unknown key should return empty string, got %q", result)
	}
}

func TestUUIDRegistryAllReturnsCopy(t *testing.T) {
	provider := FNV1aUUIDProvider{}
	reg := NewUUIDRegistry(provider, "TestApp")

	reg.Generate("A")
	reg.Generate("B")

	all := reg.All()
	if len(all) != 2 {
		t.Errorf("expected 2 entries, got %d", len(all))
	}

	all["C"] = "injected"
	if reg.Get("C") != "" {
		t.Error("modifying All() result should not affect registry")
	}
}

func TestUUIDRegistryDifferentPrefixesDifferentUUIDs(t *testing.T) {
	provider := FNV1aUUIDProvider{}
	reg1 := NewUUIDRegistry(provider, "AppOne")
	reg2 := NewUUIDRegistry(provider, "AppTwo")

	uuid1 := reg1.Generate("PBXProject")
	uuid2 := reg2.Generate("PBXProject")

	if uuid1 == uuid2 {
		t.Errorf("different prefixes should produce different UUIDs: both are %q", uuid1)
	}
}
