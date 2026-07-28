# Diagnostics Guide

> Crash analysis, build optimization, and troubleshooting patterns.

## Overview

This guide covers crash log analysis, build troubleshooting, and diagnostic tools for iOS development.

---

## Crash Analysis

### Crash Log Locations

| Source | Location |
|--------|----------|
| Simulator | `~/Library/Logs/DiagnosticReports/` |
| Device (Xcode) | Window -> Devices and Simulators -> View Device Logs |
| TestFlight | App Store Connect -> TestFlight -> Crashes |
| App Store | App Store Connect -> Analytics -> Crashes |

### Crash File Types

| Extension | Description |
|-----------|-------------|
| `.crash` | Older format, plain text |
| `.ips` | JSON format (iOS 15+) |
| `.xccrashpoint` | Xcode crash point bundle |

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
// Edit Scheme -> Run -> Diagnostics -> Zombie Objects

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
| 5 seconds | Suspended -> background transition |

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
# Clean Derived Data for project
rm -rf ~/Library/Developer/Xcode/DerivedData/MyProject-*

# Clean SPM cache
rm -rf ~/Library/Caches/org.swift.swiftpm

# Reset package resolution
xcodebuild -resolvePackageDependencies -scheme MyScheme

# Full clean build
xcodebuild clean build -scheme MyScheme \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

---

## Build Optimization

### Common Optimizations

| Optimization | Impact | How |
|--------------|--------|-----|
| Parallel builds | 20-40% faster | Build Settings -> Enable parallelization |
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

### Selective Cleanup

```bash
# Keep index, clean build
rm -rf ~/Library/Developer/Xcode/DerivedData/MyProject-*/Build

# Clean specific target
rm -rf ~/Library/Developer/Xcode/DerivedData/MyProject-*/Build/Intermediates.noindex/MyProject.build
```

---

## Simulator Troubleshooting

### Reset Simulator

```bash
# Reset specific simulator by UDID
xcrun simctl erase <UDID>

# Reset all simulators
xcrun simctl erase all

# Delete and recreate
xcrun simctl delete <UDID>
xcrun simctl create "iPhone 16 Pro" "iPhone 16 Pro"
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
xcrun simctl uninstall booted com.example.myapp

# Check app is signed for simulator
codesign -d -v MyApp.app
```

---

## MetricKit Integration

### Collecting Diagnostics

```swift
// App/Diagnostics/MetricKitManager.swift
import MetricKit

/// Note: MetricKit requires a singleton because MXMetricManager.shared.add()
/// expects a single subscriber for the app's lifetime. This is an exception
/// to the project's DI rule -- MetricKit's API forces this pattern.
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
        for payload in payloads {
            // payload.cpuMetrics
            // payload.memoryMetrics
            // payload.diskIOMetrics
            // payload.applicationLaunchMetrics
        }
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            // payload.crashDiagnostics
            // payload.hangDiagnostics
            // payload.cpuExceptionDiagnostics
        }
    }
}
```

---

## Logging Best Practices

### os_log for Production

```swift
import os.log

extension Logger {
    static let networking = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "Networking")
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "Persistence")
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
