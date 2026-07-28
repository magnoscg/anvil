package deps

import "testing"

func TestExtractSemver(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{"simple semver", "2.3.1", "2.3.1"},
		{"two part version", "15.0", "15.0"},
		{"with prefix text", "git version 2.39.3 (Apple Git-146)", "2.39.3"},
		{"with suffix text", "tool version 4.2.1", "4.2.1"},
		{"pre-release", "1.0.0-beta.1", "1.0.0-beta.1"},
		{"no version", "no version here", ""},
		{"empty string", "", ""},
		{"only digits no dots", "12345", ""},
		{"single digit with dot", "xcrun version 68.", ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := extractSemver(tt.input)
			if got != tt.want {
				t.Errorf("extractSemver(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestParseXcodeVersion(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{"standard output", "Xcode 17.0\nBuild version 17C529", "17.0"},
		{"version with patch", "Xcode 16.2.1\nBuild version 16C5032a", "16.2.1"},
		{"single line", "Xcode 17.0", "17.0"},
		{"empty output", "", "unknown"},
		{"no Xcode prefix fallback to semver", "17.0.1", "17.0.1"},
		{"no version at all", "some garbage", "some garbage"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseXcodeVersion(tt.input)
			if got != tt.want {
				t.Errorf("parseXcodeVersion(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestParseGitVersion(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{"standard output", "git version 2.39.3 (Apple Git-146)", "2.39.3"},
		{"linux output", "git version 2.43.0", "2.43.0"},
		{"two part", "git version 2.39", "2.39"},
		{"empty output", "", "unknown"},
		{"no prefix", "2.39.3", "2.39.3"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseGitVersion(tt.input)
			if got != tt.want {
				t.Errorf("parseGitVersion(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestParseClaudeVersion(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{"with label", "1.0.12 (Claude Code)", "1.0.12"},
		{"bare version", "1.0.12", "1.0.12"},
		{"empty output", "", "unknown"},
		{"no version text", "claude", "claude"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseClaudeVersion(tt.input)
			if got != tt.want {
				t.Errorf("parseClaudeVersion(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestParseSwiftLintVersion(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{"bare version", "0.54.0", "0.54.0"},
		{"with whitespace", "  0.54.0  ", "0.54.0"},
		{"empty output", "", "unknown"},
		{"multiline", "0.54.0\nLoaded config", "0.54.0"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseSwiftLintVersion(tt.input)
			if got != tt.want {
				t.Errorf("parseSwiftLintVersion(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestParseSwiftFormatVersion(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{"bare version", "0.53.1", "0.53.1"},
		{"with whitespace", "  0.53.1\n", "0.53.1"},
		{"empty output", "", "unknown"},
		{"no version", "not a version at all", "not a version at all"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseSwiftFormatVersion(tt.input)
			if got != tt.want {
				t.Errorf("parseSwiftFormatVersion(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}
