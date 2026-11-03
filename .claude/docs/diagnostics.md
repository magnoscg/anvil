# Diagnostics Guide

> Crash analysis, build optimization, and troubleshooting patterns.
> Related skills: `/axiom:analyze-crash`, `/axiom:optimize-build`, `axiom:build-fixer`
> Debugging skills: `axiom:axiom-swiftui-debugging`, `axiom:axiom-memory-debugging`, `axiom:axiom-xcode-debugging`
> Axiom complementa: MetricKit field diagnostics, crash symbolication

## Overview

This guide covers crash log analysis, build troubleshooting, and diagnostic tools for iOS development.

---

## Crash Analysis

### Crash Log Locations

| Source | Location |
|--------|----------|
| Simulator | `~/Library/Logs/DiagnosticReports/` |
| Device (Xcode) | Window → Devices and Simulators → View Device Logs |
| TestFlight | App Store Connect → TestFlight → Crashes |
| App Store | App Store Connect → Analytics → Crashes |

### Crash File Types

| Extension | Description |
|-----------|-------------|
| `.crash` | Older format, plain text |
| `.ips` | JSON format (iOS 15+) |
| `.xccrashpoint` | Xcode crash point bundle |

### Using Axiom Crash Analyzer

```bash
# Analyze a crash file
/axiom:analyze-crash ~/Library/Logs/DiagnosticReports/MyApp.ips

# Or paste crash content directly
/axiom:analyze-crash
# [paste crash log]
```

### Manual Symbolication

```bash
# Find your dSYM
mdfind "com_apple_xcode_dsym_uuids == UUID-FROM-CRASH"

# Symbolicate a single address
atos -arch arm64 -o MyApp.app.dSYM/Contents/Resources/DWARF/MyApp -l 0x100000000 0x100001234

# Full crash log symbolication
xcrun symbolicatecrash MyApp.crash MyApp.app.dSYM > symbolicated.crash
```

### Common Crash Patterns

| Pattern | Symptom | Solution |
|---------|---------|----------|
| **EXC_BAD_ACCESS** | Accessing deallocated memory | Check for dangling pointers, weak references |
| **EXC_CRASH (SIGABRT)** | Assertion/precondition failed | Check force unwraps, array bounds |
| **SIGKILL (0x8badf00d)** | Watchdog timeout | App too slow to launch/respond |
| **SIGSEGV** | Null pointer dereference | Check optionals, uninitialized vars |
| **SIGBUS** | Memory alignment | Usually Swift runtime issue |

### EXC_BAD_ACCESS Debugging

```swift
// Enable Zombie Objects in scheme
// Edit Scheme → Run → Diagnostics → Zombie Objects

// Or via command line
export NSZombieEnabled=YES
export MallocStackLogging=YES
```

### SIGKILL Watchdog

App killed for taking too long:

| Timeout | Phase |
|---------|-------|
| 20 seconds | Launch (main scene visible) |
| 10 seconds | Background task completion |
| 5 seconds | Suspended → background transition |

**Fix**: Move heavy work off main thread, defer initialization.

---

## Build Troubleshooting

### Common Build Failures

| Error | Cause | Fix |
|-------|-------|-----|
| "No such module" | SPM resolution failed | Clean SPM cache |
| "Duplicate symbols" | Multiple definitions | Check target membership |
| "Code signing" | Certificate/profile issue | Reset signing in Xcode |
| "Command failed" | Various | Check full error in Report Navigator |

### Clean Build Commands

```bash
# Clean Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData/<PROJECT>-*

# Clean SPM cache
rm -rf ~/Library/Caches/org.swift.swiftpm

# Reset package resolution
xcodebuild -resolvePackageDependencies -scheme <SCHEME>

# Full clean build
xcodebuild clean build -scheme <SCHEME> \
    -destination "platform=iOS Simulator,id=<SIMULATOR_UDID>"
```

### Using Build Fixer Agent

When build fails repeatedly without clear cause:

```bash
# Auto-diagnose and fix
axiom:build-fixer agent
```

The agent checks:
1. Zombie processes (xcrun, xcodebuild)
2. Derived Data corruption
3. SPM cache issues
4. Simulator state
5. Code signing problems

---

## Build Optimization

### Using Build Optimizer

```bash
/axiom:optimize-build
```

### Common Optimizations

| Optimization | Impact | How |
|--------------|--------|-----|
| Parallel builds | 20-40% faster | Build Settings → Enable parallelization |
| Incremental builds | Variable | Don't clean unnecessarily |
| Module stability | Faster incremental | Build Libraries for Distribution = YES |
| Explicit modules | 10-30% faster | Enable in Build Settings |

### Slow Type Checking

Find slow expressions:

```bash
# Add to Other Swift Flags
-Xfrontend -warn-long-expression-type-checking=100
-Xfrontend -warn-long-function-bodies=100
```

### Build Phase Scripts

Slow scripts hurt incremental builds:

```bash
# Show script timing
defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES
```

**Fix**: Add input/output file lists to skip unchanged scripts.

---

## Derived Data Management

### Location

```
~/Library/Developer/Xcode/DerivedData/
```

### Structure

```
DerivedData/
└── <PROJECT>-<hash>/
    ├── Build/
    │   ├── Intermediates.noindex/
    │   └── Products/
    ├── Index/
    ├── Logs/
    └── SourcePackages/
```

### Selective Cleanup

```bash
# Keep index, clean build
rm -rf ~/Library/Developer/Xcode/DerivedData/<PROJECT>-*/Build

# Clean specific target
rm -rf ~/Library/Developer/Xcode/DerivedData/<PROJECT>-*/Build/Intermediates.noindex/<PROJECT>.build
```

### Move Derived Data to RAM Disk (Advanced)

For faster builds (loses data on reboot):

```bash
# Create 8GB RAM disk
diskutil erasevolume HFS+ "RAMDisk" $(hdiutil attach -nomount ram://16777216)

# Set Xcode derived data location
# Xcode → Settings → Locations → Derived Data → Custom: /Volumes/RAMDisk/DerivedData
```

---

## Simulator Troubleshooting

### Reset Simulator

```bash
# Reset specific simulator
xcrun simctl erase <SIMULATOR_UDID>

# Reset all simulators
xcrun simctl erase all

# Delete and recreate
xcrun simctl delete <SIMULATOR_UDID>
xcrun simctl create "<DEVICE_NAME>" "<DEVICE_NAME>"
```

### Simulator Won't Boot

```bash
# Kill simulator processes
killall Simulator
killall com.apple.CoreSimulator.CoreSimulatorService

# Check for issues
xcrun simctl diagnose
```

### App Won't Install

```bash
# Uninstall app
xcrun simctl uninstall booted <BUNDLE_ID>

# Check app is signed for simulator
codesign -d -v MyApp.app  # Should show "Simulator" in platform
```

---

## MetricKit Integration

### Collecting Diagnostics

```swift
// App/Diagnostics/MetricKitManager.swift
import MetricKit

/// Note: MetricKit requires a singleton because MXMetricManager.shared.add()
/// expects a single subscriber for the app's lifetime. This is an exception
/// to the project's DI rule — MetricKit's API forces this pattern.
@MainActor
final class MetricKitManager: NSObject {

    static let shared = MetricKitManager()

    private override init() { super.init() }

    func start() {
        MXMetricManager.shared.add(self)
    }

    func stop() {
        MXMetricManager.shared.remove(self)
    }
}

extension MetricKitManager: MXMetricManagerSubscriber {

    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        // Process performance metrics
        for payload in payloads {
            // payload.cpuMetrics
            // payload.memoryMetrics
            // payload.diskIOMetrics
            // payload.applicationLaunchMetrics
        }
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Process diagnostic reports (crashes, hangs)
        for payload in payloads {
            // payload.crashDiagnostics
            // payload.hangDiagnostics
            // payload.cpuExceptionDiagnostics
        }
    }
}
```

### Enable in App Delegate

```swift
@main
struct MyApp: App {
    init() {
        MetricKitManager.shared.start()
    }
}
```

---

## Logging Best Practices

### os_log for Production

```swift
import os.log

extension Logger {
    static let networking = Logger(subsystem: "<BUNDLE_ID>", category: "Networking")
    static let persistence = Logger(subsystem: "<BUNDLE_ID>", category: "Persistence")
}

// Usage
Logger.networking.debug("Request started: \(url)")
Logger.networking.error("Request failed: \(error)")
```

### DON'T: Log Sensitive Data

```swift
// WRONG: Logging tokens
Logger.auth.info("Token: \(token)")

// RIGHT: Log without sensitive data
Logger.auth.info("Authentication succeeded")
```

---

## Diagnostic Checklist

### Build Issues

- [ ] Clean Derived Data if build is inconsistent
- [ ] Reset SPM cache if "no such module"
- [ ] Check for zombie xcodebuild processes
- [ ] Verify code signing certificates

### Crashes

- [ ] Symbolicate crash logs
- [ ] Enable Zombie Objects for EXC_BAD_ACCESS
- [ ] Check for force unwraps
- [ ] Review recent changes

### Performance

- [ ] Profile with Time Profiler
- [ ] Check for main thread blocking
- [ ] Review MetricKit reports

### Run Diagnostics

```bash
# Build problems
axiom:build-fixer

# Crash analysis
/axiom:analyze-crash <path>

# Build optimization
/axiom:optimize-build
```
