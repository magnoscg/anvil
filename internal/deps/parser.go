package deps

import (
	"regexp"
	"strings"
)

// semverPattern matches a semantic version (e.g., "2.3.1", "15.0", "1.0.0-beta.1").
var semverPattern = regexp.MustCompile(`\d+\.\d+(?:\.\d+)?(?:-[\w.]+)?`)

// extractSemver returns the first semver-like string found in output, or empty string.
func extractSemver(output string) string {
	match := semverPattern.FindString(output)
	return match
}

// parseXcodeVersion extracts the version from `xcodebuild -version` output.
// Example: "Xcode 17.0\nBuild version 17C529" -> "17.0"
// Extracts the version number from the first line after the "Xcode " prefix.
func parseXcodeVersion(output string) string {
	firstLine := output
	if idx := strings.IndexByte(output, '\n'); idx >= 0 {
		firstLine = output[:idx]
	}
	firstLine = strings.TrimSpace(firstLine)

	after, found := strings.CutPrefix(firstLine, "Xcode ")
	if found {
		return strings.TrimSpace(after)
	}

	v := extractSemver(firstLine)
	if v != "" {
		return v
	}

	if firstLine == "" {
		return "unknown"
	}
	return firstLine
}

// parseGitVersion extracts the version from `git --version` output.
// Example: "git version 2.39.3 (Apple Git-146)" -> "2.39.3"
func parseGitVersion(output string) string {
	v := extractSemver(output)
	if v != "" {
		return v
	}
	trimmed := strings.TrimSpace(output)
	if trimmed == "" {
		return "unknown"
	}
	return trimmed
}

// parseClaudeVersion extracts the version from `claude --version` output.
// Example: "1.0.12 (Claude Code)" -> "1.0.12"
func parseClaudeVersion(output string) string {
	v := extractSemver(output)
	if v != "" {
		return v
	}
	trimmed := strings.TrimSpace(output)
	if trimmed == "" {
		return "unknown"
	}
	return trimmed
}

// parseSwiftLintVersion extracts the version from `swiftlint version` output.
// Example: "0.54.0" -> "0.54.0"
func parseSwiftLintVersion(output string) string {
	v := extractSemver(output)
	if v != "" {
		return v
	}
	trimmed := strings.TrimSpace(output)
	if trimmed == "" {
		return "unknown"
	}
	return trimmed
}

// parseSwiftFormatVersion extracts the version from `swiftformat --version` output.
// Example: "0.53.1" -> "0.53.1"
func parseSwiftFormatVersion(output string) string {
	v := extractSemver(output)
	if v != "" {
		return v
	}
	trimmed := strings.TrimSpace(output)
	if trimmed == "" {
		return "unknown"
	}
	return trimmed
}
