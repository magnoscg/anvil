package templates

import (
	"io/fs"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
)

type provenanceManifest struct {
	SchemaVersion int               `yaml:"schema_version"`
	Skills        []provenanceEntry `yaml:"skills"`
}

type provenanceEntry struct {
	Slug             string   `yaml:"slug"`
	Pack             string   `yaml:"pack"`
	Author           string   `yaml:"author"`
	Origin           string   `yaml:"origin"`
	License          string   `yaml:"license"`
	SourceURL        string   `yaml:"source_url"`
	SourceCommit     string   `yaml:"source_commit"`
	UpstreamPath     string   `yaml:"upstream_path"`
	ContentSHA256    string   `yaml:"content_sha256"`
	Modifications    string   `yaml:"modifications"`
	DistributedPaths []string `yaml:"distributed_paths"`
}

func TestSkillProvenanceCoversEmbeddedInventory(t *testing.T) {
	data, err := fs.ReadFile(FS, "ai-packs/PROVENANCE.yml")
	if err != nil {
		t.Fatalf("read provenance manifest: %v", err)
	}

	var manifest provenanceManifest
	if err := yaml.Unmarshal(data, &manifest); err != nil {
		t.Fatalf("parse provenance manifest: %v", err)
	}
	if manifest.SchemaVersion != 1 {
		t.Fatalf("schema version = %d, want 1", manifest.SchemaVersion)
	}
	if len(manifest.Skills) != 34 {
		t.Fatalf("provenance entries = %d, want 34", len(manifest.Skills))
	}

	inventory := make(map[string]string)
	err = fs.WalkDir(FS, "ai-packs", func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() || entry.Name() != "SKILL.md" {
			return nil
		}
		parts := strings.Split(path, "/")
		if len(parts) != 5 || parts[2] != "skills" {
			t.Fatalf("unexpected embedded skill path %q", path)
		}
		inventory[parts[3]] = parts[1]
		return nil
	})
	if err != nil {
		t.Fatalf("walk embedded skills: %v", err)
	}
	if len(inventory) != 34 {
		t.Fatalf("embedded skills = %d, want 34", len(inventory))
	}

	seen := make(map[string]struct{})
	thirdParty := 0
	for _, entry := range manifest.Skills {
		if _, exists := seen[entry.Slug]; exists {
			t.Errorf("duplicate provenance entry %q", entry.Slug)
		}
		seen[entry.Slug] = struct{}{}

		pack, exists := inventory[entry.Slug]
		if !exists {
			t.Errorf("manifest skill %q is not embedded", entry.Slug)
			continue
		}
		if entry.Pack != pack {
			t.Errorf("%s pack = %q, want %q", entry.Slug, entry.Pack, pack)
		}
		if entry.License != "MIT" {
			t.Errorf("%s license = %q, want MIT", entry.Slug, entry.License)
		}
		if entry.Modifications == "" || len(entry.DistributedPaths) != 3 {
			t.Errorf("%s has incomplete modification or distribution metadata", entry.Slug)
		}

		switch entry.Origin {
		case "first-party":
			if entry.Author != "Oscar Canton" {
				t.Errorf("%s first-party author = %q", entry.Slug, entry.Author)
			}
			if entry.SourceURL != "" || entry.SourceCommit != "" || entry.UpstreamPath != "" || entry.ContentSHA256 != "" {
				t.Errorf("%s first-party entry unexpectedly declares upstream content", entry.Slug)
			}
		case "third-party":
			thirdParty++
			if entry.Author == "" || entry.SourceURL == "" || len(entry.SourceCommit) != 40 || entry.UpstreamPath == "" || len(entry.ContentSHA256) != 64 {
				t.Errorf("%s third-party entry is incomplete", entry.Slug)
			}
		default:
			t.Errorf("%s has unsupported origin %q", entry.Slug, entry.Origin)
		}
	}
	if thirdParty != 3 {
		t.Errorf("third-party entries = %d, want 3", thirdParty)
	}
}

func TestIOSSkillNoticesContainPinnedSources(t *testing.T) {
	data, err := fs.ReadFile(FS, "ai-packs/ios-skills/THIRD_PARTY_NOTICES.md")
	if err != nil {
		t.Fatalf("read iOS skill notices: %v", err)
	}
	content := string(data)
	for _, commit := range []string{
		"5c2289ffbc3aa5b02f25f73d84e178b08e8ea45c",
		"33a29607cadd8f79dc0d5e51e5e918a8981e794e",
		"c4b82b0ad771190355eb8e204b1329732a18449a",
	} {
		if !strings.Contains(content, commit) {
			t.Errorf("notices missing commit %s", commit)
		}
	}
	if count := strings.Count(content, "MIT License"); count != 3 {
		t.Errorf("MIT license texts = %d, want 3", count)
	}
}
