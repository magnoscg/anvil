# Tooling

Which command to use to build, test, verify on a simulator and diagnose. This is the only doc in the pack that carries commands; the others point here.

`axbuild`, `xcui`, `xclog`, `xcsym` and `xcprof` ship with the Axiom plugin (check with `command -v axbuild`). Placeholders: `<Scheme>`, `<SIMULATOR_UDID>`, `<BUNDLE_ID>`, `<AppName>` (the process name).

## Build and Test

```bash
axbuild xcodebuild -scheme <Scheme> -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' build
axbuild xcodebuild -scheme <Scheme> -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' test
```

- `axbuild` runs the build, prints a bounded JSON report and keeps the full log. Read `command` (the build or test outcome) and `collection` (how complete the captured evidence is) separately, and follow `artifacts` to the full report instead of building again to see the output.
- Never pipe it into another command, and never clean caches or DerivedData as a first step.
- Run a single suite by adding `-only-testing:<TestTarget>/<Suite>` to the `test` command.
- Without the Axiom tools: `( set -o pipefail; xcodebuild <args> | xcbeautify )`.
- Always target a simulator by UDID. A device name is ambiguous across runtimes, and `booted` is ambiguous as soon as two simulators are running.

## Visual Verification on a Simulator

Pass the UDID on every command. Element ids are the `accessibilityIdentifier` values of the feature's `AccessibilityID` enum (`ui-testing.md`).

| Step | Command |
|---|---|
| Check the environment, list booted simulators (JSON field `booted`) | `xcui doctor` |
| Boot, shut down or erase one simulator | `xcrun simctl boot <SIMULATOR_UDID>` (also `shutdown`, `erase`) |
| Install and launch | `xcrun simctl install <SIMULATOR_UDID> <path/to/App.app>`, then `xcrun simctl launch <SIMULATOR_UDID> <BUNDLE_ID>` |
| Open a deep link | `xcrun simctl openurl <SIMULATOR_UDID> <URL>` |
| Wait for a screen | `xcui wait --for-element <id> --udid <SIMULATOR_UDID>` (also `--gone <id>`, `--idle`, `--timeout 10s`) |
| Tap, type | `xcui tap --id <id> --udid <SIMULATOR_UDID>`, `xcui type "<text>" --udid <SIMULATOR_UDID>` |
| Assert on an element | `xcui assert --id <id> --label "<text>" --udid <SIMULATOR_UDID>` (also `--value`, `--trait`) |
| Light or dark appearance | `xcrun devicectl device settings appearance --mode dark -d <SIMULATOR_UDID>` |
| Dynamic Type | `xcui a11y set --toggle dynamic-type --value accessibility-extra-large --udid <SIMULATOR_UDID>`; undo with `xcui a11y reset --udid <SIMULATOR_UDID>` |
| Screenshot | `xcrun devicectl device capture screenshot -d <SIMULATOR_UDID> --destination <file>.png` |
| Console | `xclog launch <BUNDLE_ID> --device <SIMULATOR_UDID> --timeout 30s --max-lines 200` |

- Verify the effect, never the tap: a tap that changes nothing reports the same success as one that works. After every tap that matters, run `xcui wait` or `xcui assert`, or take a screenshot.
- Tap by `--id`, not by label (labels are localized), and through `xcui`: it sends a physical touch, which SwiftUI buttons, list rows and tabs need.
- `xclog launch` restarts the app and captures `print` and `Logger` output. `xclog attach <AppName>` follows a running app (`Logger` and `os_log`, not `print`) and `xclog show <AppName> --last 5m` reads recent logs after the fact; both take `--device <SIMULATOR_UDID>`.

## Crashes and Profiling

- Crash report (`.ips`, MetricKit JSON, `.crash`, `.xccrashpoint`): `xcsym crash <file>`. Read `pattern_tag` first; when symbolication is incomplete, `xcsym verify <file>` reports which images have a missing or mismatched dSYM. It does not handle hang reports.
- CPU profile: `xcprof record --preset cpu --attach <AppName> --time-limit 10s --no-prompt`, then `xcprof analyze <trace>`. Other presets: `memory`, `network`, `energy`, `full`, `full-ios`. `analyze` cannot read `memory` traces: open them in Instruments.
- Regression between two traces of the same workload: `xcprof compare <baseline> <current>`.
- Never terminate build, simulator or Device Hub processes by name. Inventory first, inspect the PID, and stop only a process the current task started (`kill -TERM <PID>`); the procedure is in `axiom-build` (`skills/xcode-debugging.md`).

## Symptom to Axiom Skill

| Symptom | Start with |
|---|---|
| Build fails for no visible reason, stale build, simulator stuck | `axiom-build` (`skills/xcode-debugging.md`, `skills/build-debugging.md`) |
| Slow builds | `axiom-build` (`skills/build-performance.md`) |
| App slow, hangs, slow launch | `axiom-performance` (`skills/performance-profiling.md`, `skills/hang-diagnostics.md`, `skills/app-launch.md`) |
| Janky scrolling, a view that does not update | `axiom-swiftui` (`skills/swiftui-performance.md`, `skills/debugging.md`) |
| Memory grows, leaks, retain cycles | `axiom-performance` (`skills/memory-debugging.md`) |
| Crash | `xcsym crash <file>`, then `axiom-build` (`skills/lldb.md`) to reproduce it live |
| Flaky tests | `axiom-testing` (`skills/test-failure-analyzer.md`, `skills/testing-async.md`) |
| Data races, isolation or `Sendable` errors | `axiom-concurrency` (`skills/swift-concurrency.md`) |

## Logging

- Log with `Logger` (`import os`), one `private static let logger` per type that logs: `Logger(subsystem: Bundle.main.bundleIdentifier ?? "<BUNDLE_ID>", category: "Networking")`.
- The subsystem is the bundle identifier; the category names the area that logs (generated code uses `Networking` and `Navigation`). `xclog --subsystem <name>` filters on it.
- Every interpolated value states its privacy: `\(host, privacy: .public)` for values that identify nobody, `.private` or `.sensitive` for anything tied to a user.
- Never log credentials, tokens or personal data at any level (see `security-privacy.md`).

Deeper reference (Axiom plugin, if installed): `axiom-tools` (`skills/xcui-ref.md`, `skills/xclog-ref.md`, `skills/xcsym-ref.md`, `skills/xcprof-ref.md`, `skills/device-control-ref.md`), `axiom-build`.
