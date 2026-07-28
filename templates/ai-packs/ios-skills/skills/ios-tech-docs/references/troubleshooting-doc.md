# Troubleshooting Document Template

Use this template when the user asks for: troubleshooting guide, common errors documentation, build issue fixes, "works on my machine" debugging, or developer FAQ.

---

## Template Structure

```markdown
# [Project Name] - Troubleshooting Guide

{toc}

## 1. Quick Diagnosis

Before diving into specific issues, try this checklist:

```bash
# 1. Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData/[ProjectName]*
# or: Xcode → Product → Clean Build Folder (Cmd+Shift+K)

# 2. Reset SPM cache
xcodebuild -resolvePackageDependencies
# or: File → Packages → Reset Package Caches

# 3. Close and reopen Xcode
killall Xcode
open [ProjectName].xcodeproj

# 4. If all else fails
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build  # for SPM-only projects
```

> ⏰ **Time estimate:** This checklist resolves ~70% of build issues in under 5 minutes.

## 2. Build Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `No such module '[ModuleName]'` | SPM package not resolved | File → Packages → Resolve Package Versions |
| `No such module '[ModuleName]'` (after resolve) | Wrong platform selected | Ensure build destination is iOS Simulator, not macOS |
| `Command CompileSwift failed` with no details | Xcode bug — error swallowed | Build from command line: `xcodebuild -scheme [Scheme] build` to see real error |
| `Type '[Type]' does not conform to protocol 'Sendable'` | Swift 6 strict concurrency | See [Swift Concurrency doc](./13-Swift-Concurrency.md) for Sendable rules |
| `Expression is too complex to type-check` | Complex SwiftUI view body | Break view into smaller sub-views or add explicit type annotations |
| `Circular dependency between modules` | SPM package graph has cycle | Review module imports, extract shared code to a `Core` module |
| `Cannot find type '[Type]' in scope` | Missing import or wrong target membership | Check file's Target Membership in File Inspector |
| `Duplicate symbol` linker error | Same file in multiple targets | Remove duplicate target membership |
| `Build input file cannot be found` | Stale file reference in pbxproj | Remove red file from Xcode navigator, re-add if needed |

## 3. Code Signing Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `No signing certificate found` | Certificates not installed | See [Code Signing doc](./12-Code-Signing.md) — run `fastlane match` |
| `Provisioning profile doesn't include signing certificate` | Profile/cert mismatch | `bundle exec fastlane match development --force` |
| `Automatic signing is unable to resolve an issue` | Automatic signing conflict | Uncheck "Automatically manage signing" in target settings |
| `The certificate has expired` | Cert expired | `fastlane match nuke development` + `fastlane match development` |
| `A valid provisioning profile for this executable was not found` | Profile not installed on device | Re-run `fastlane match development`, reconnect device |
| `Code signing identity not found` | Missing from Keychain | Open Keychain Access → check login keychain for Apple Development/Distribution certs |

> ℹ️ **Info:** For detailed code signing setup, see [12-Code-Signing.md](./12-Code-Signing.md).

## 4. SPM (Swift Package Manager) Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `Package resolution failed` | Network issue or version conflict | Check internet, then File → Packages → Reset Package Caches |
| `Missing package product` | Package removed or renamed upstream | Update Package.swift dependency URL/version |
| `Access denied` during resolution | Private repo auth issue | Ensure SSH keys or PAT are configured for git |
| SPM caches stale version | Derived data corruption | Delete `~/Library/Caches/org.swift.swiftpm/` and `DerivedData` |
| `Package requires a newer version of Swift` | Package needs Swift 5.9+ but project uses older | Update Swift tools version in Package.swift |
| Build succeeds but autocomplete broken | SourceKit index corruption | Delete DerivedData, restart Xcode |

### SPM Resolution Full Reset
```bash
# Nuclear option for SPM issues:
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
rm Package.resolved  # Force fresh resolution
open [ProjectName].xcodeproj
# Wait for SPM to re-resolve all packages
```

## 5. Simulator Issues

| Error | Cause | Fix |
|-------|-------|-----|
| Simulator won't boot | Corrupt simulator runtime | `xcrun simctl delete unavailable` then restart |
| App crashes on launch in simulator | Missing build for simulator arch | Clean build + ensure "Build Active Architecture Only" is correct |
| Simulator shows black screen | App window not created | Check `@main` App struct and WindowGroup setup |
| "Unable to boot the Simulator" | Too many simulators running | Close all simulators: `xcrun simctl shutdown all` |
| Push notifications not working in sim | Simulators don't support real push | Use `.apns` file drag-and-drop for testing |
| Location simulation not working | Location not configured in scheme | Edit Scheme → Run → Options → Core Location → select location |

### Reset Simulator
```bash
# Reset a specific simulator
xcrun simctl erase [DEVICE_UDID]

# Reset ALL simulators
xcrun simctl erase all

# Delete and recreate all simulators
xcrun simctl delete all
# Xcode will recreate default simulators on next launch
```

## 6. Runtime Crashes

| Crash | Cause | Fix |
|-------|-------|-----|
| `fatalError("APIBaseURL not configured")` | Missing `Local.xcconfig` | Copy `Local.xcconfig.template` to `Local.xcconfig` |
| `Thread 1: EXC_BAD_ACCESS` | Use-after-free or force unwrap of nil | Check crash log for the exact line, add nil checks |
| `Precondition failed: publishing changes from background thread` | UI update from non-main thread | Wrap in `@MainActor` or `Task { @MainActor in }` |
| `Fatal error: UnsafeRawBufferPointer with negative count` | Corrupt data in persistence layer | Clear app data in simulator, check SwiftData migration |
| `-[NSManagedObject release]: message sent to deallocated instance` | Core Data threading violation | Access NSManagedObject only on its context's queue |

## 7. Environment-Specific Issues

| Issue | Environment | Fix |
|-------|------------|-----|
| Wrong API URL at runtime | Wrong scheme selected | Check scheme selector — should show `[App]-Dev` |
| Push not working on TestFlight | Wrong push cert type | Staging uses sandbox APNS; production uses production APNS |
| Firebase crash analytics not showing | Wrong GoogleService-Info.plist | Verify plist matches the selected environment |
| API returns 401 Unauthorized | Token expired or wrong environment | Check if token was issued for the correct API environment |

## 8. "Works on My Machine" Debugging Checklist

When something works for you but not a teammate:

- [ ] **Same Xcode version?** Check `xcodebuild -version`
- [ ] **Same macOS version?** Check `sw_vers`
- [ ] **Same scheme selected?** Check scheme selector in Xcode
- [ ] **Same branch and commit?** `git log -1 --oneline`
- [ ] **Same `Local.xcconfig` values?** Compare (without secrets)
- [ ] **SPM packages resolved?** File → Packages → Resolve Package Versions
- [ ] **DerivedData clean?** Delete and rebuild
- [ ] **Certificates installed?** Re-run `fastlane match`
- [ ] **Same simulator runtime?** Check Xcode → Settings → Platforms
- [ ] **VPN connected?** Some APIs require VPN access
- [ ] **Disk space available?** `df -h` — Xcode needs several GB free

## 9. Performance Issues

| Symptom | Likely Cause | Investigation |
|---------|-------------|---------------|
| Slow builds | Type checker inference, no module caching | Check build times in Build Log, look for files > 5s |
| Laggy scrolling | Heavy view bodies, no lazy loading | Profile with Instruments → SwiftUI Template |
| High memory usage | Image caching, retained closures | Profile with Instruments → Leaks / Allocations |
| Battery drain in background | Timer abuse, continuous location updates | Check background tasks, location accuracy settings |
| Slow app launch | Too much work in `init()` or `@main` | Profile with Instruments → App Launch |

## 10. Getting Help

If the troubleshooting guide doesn't resolve your issue:

1. **Search Slack** `#ios` channel for the error message — someone may have hit it before
2. **Ask in `#ios`** with: error message, what you tried, your Xcode/macOS version
3. **Pair with a teammate** — 15 minutes of pairing often solves hours of solo debugging
4. **Check Apple Developer Forums** and **Swift Forums** for framework-specific issues
5. **File a bug** if you identify a new common issue — and add it to this document

---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Owner | [Rotating — whoever last added an issue] |
| Created | [Date] |
| Last Updated | [Date] |
| Last Verified | [Date] |
| Status | Living Document |
| Review Schedule | Quarterly + on new discovery |
| Labels | `ios`, `swift`, `troubleshooting`, `debugging`, `[project-name]` |
```

## Writing Guidelines

- This is a LIVING document — add new issues as they are discovered
- Every entry must have a concrete FIX, not just "investigate"
- Include exact error messages so developers can search for them
- Include terminal commands that can be copy-pasted
- Keep the "Works on My Machine" checklist updated with project-specific items
- Link to other docs (Code Signing, Environments, Swift Concurrency) for detailed solutions
- Use the severity/frequency of issues to order sections (most common first)
