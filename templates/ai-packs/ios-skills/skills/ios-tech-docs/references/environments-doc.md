# Environments Document Template

Use this template when the user asks for: environment setup, multi-environment configuration, dev/staging/prod setup, xcconfig documentation, or build configuration management.

---

## Template Structure

```markdown
# [Project Name] - Environments & Configuration

{toc}

## 1. Environment Matrix

| Property | Development | Staging | Production |
|----------|-------------|---------|------------|
| Scheme | `[App]-Dev` | `[App]-Staging` | `[App]-Prod` |
| Bundle ID | `com.company.app.dev` | `com.company.app.staging` | `com.company.app` |
| App Display Name | `[App] DEV` | `[App] STG` | `[App]` |
| API Base URL | `https://api-dev.example.com` | `https://api-staging.example.com` | `https://api.example.com` |
| Firebase Config | `GoogleService-Info-Dev.plist` | `GoogleService-Info-Staging.plist` | `GoogleService-Info.plist` |
| Build Configurations | `Debug-Dev` / `Release-Dev` | `Debug-Staging` / `Release-Staging` | `Debug` / `Release` |
| App Icon | Has "DEV" badge | Has "STG" badge | Standard icon |
| Push Notifications | Sandbox | Sandbox | Production |
| Analytics | Disabled | Enabled (staging) | Enabled (production) |
| Logging | Verbose | Info | Error only |
| App Group | `group.com.company.app.dev` | `group.com.company.app.staging` | `group.com.company.app` |

> ℹ️ **Info:** All environments can be installed simultaneously on the same device because they use different bundle identifiers.

## 2. Build Configuration Structure

### Xcode Build Configurations

| Configuration | Base | Purpose |
|---------------|------|---------|
| Debug-Dev | Debug | Local development against dev API |
| Release-Dev | Release | TestFlight build for dev testing |
| Debug-Staging | Debug | Local development against staging API |
| Release-Staging | Release | TestFlight build for QA |
| Debug | Debug | Local development against production API |
| Release | Release | App Store release build |

### xcconfig File Hierarchy

```
Config/
├── Base.xcconfig                 # Shared settings across ALL environments
├── Debug.xcconfig                # Debug-specific settings (imports Base)
├── Release.xcconfig              # Release-specific settings (imports Base)
├── Environments/
│   ├── Dev.xcconfig              # Dev-specific values (API_BASE_URL, BUNDLE_ID)
│   ├── Staging.xcconfig          # Staging-specific values
│   └── Production.xcconfig       # Production-specific values
├── Local.xcconfig                # ⚠️ Git-ignored! Developer-specific overrides
└── Local.xcconfig.template       # Template for Local.xcconfig (committed)
```

### xcconfig Import Chain
```
// Debug-Dev configuration imports:
// 1. Base.xcconfig (shared)
// 2. Debug.xcconfig (debug flags)
// 3. Dev.xcconfig (environment values)
// 4. Local.xcconfig (developer overrides, if exists)
```

## 3. Secrets Management

### What Goes Where

| Secret Type | Storage | Why |
|-------------|---------|-----|
| API Keys (third-party) | `Local.xcconfig` (git-ignored) | Different per developer account |
| Firebase Config | `GoogleService-Info-[Env].plist` (committed) | Environment-specific, not secret |
| Signing Identity | Managed by fastlane match | Shared via encrypted repo |
| Auth Tokens | Keychain (runtime) | Never stored in config files |
| CI Secrets | GitHub Secrets / Bitrise Env Vars | Never in source code |

### Local.xcconfig Template

The following template is committed to the repo. Each developer copies it and fills in their values:

```xcconfig
// Local.xcconfig.template
// Copy this file to Local.xcconfig and fill in your values.
// DO NOT commit Local.xcconfig to git.

// Third-party API keys (get from 1Password / team vault)
MAPS_API_KEY = YOUR_MAPS_API_KEY_HERE
ANALYTICS_KEY = YOUR_ANALYTICS_KEY_HERE

// Optional: override API URL for local backend
// API_BASE_URL = http:\/\/localhost:8080
```

> 🚫 **Don't:** Never commit `Local.xcconfig`. It must be in `.gitignore`.

## 4. How to Access Configuration in Code

### Using Info.plist + xcconfig

```swift
// In xcconfig:
// API_BASE_URL = https:\/\/api-dev.example.com

// In Info.plist:
// APIBaseURL = $(API_BASE_URL)

// In code:
enum AppConfiguration {
    static let apiBaseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: urlString) else {
            fatalError("APIBaseURL not configured. Check your xcconfig files.")
        }
        return url
    }()

    static let environment: Environment = {
        #if DEBUG
        return .development
        #else
        guard let envString = Bundle.main.object(forInfoDictionaryKey: "AppEnvironment") as? String else {
            return .production
        }
        return Environment(rawValue: envString) ?? .production
        #endif
    }()
}

enum Environment: String {
    case development = "dev"
    case staging = "staging"
    case production = "prod"
}
```

## 5. How to Switch Environments

### In Xcode
1. Click the scheme selector (next to the Run/Stop buttons)
2. Select the desired scheme: `[App]-Dev`, `[App]-Staging`, or `[App]-Prod`
3. Build and run (Cmd+R)

### From Command Line
```bash
# Build for dev
xcodebuild -scheme "[App]-Dev" -configuration Debug-Dev build

# Build for staging
xcodebuild -scheme "[App]-Staging" -configuration Release-Staging build

# Build for production
xcodebuild -scheme "[App]-Prod" -configuration Release build
```

## 6. How to Add a New Environment

1. **Create xcconfig file**: Copy an existing env config (e.g., `Staging.xcconfig`) to `NewEnv.xcconfig`
2. **Update values**: Change API_BASE_URL, BUNDLE_ID, APP_DISPLAY_NAME
3. **Create build configurations**: In Xcode project settings, duplicate existing configs for the new environment
4. **Create scheme**: Duplicate an existing scheme, point it to the new build configurations
5. **Add Firebase plist**: If using Firebase, add the environment-specific `GoogleService-Info-[Env].plist`
6. **Update CI**: Add new lanes/workflows for the new environment
7. **Update this document**: Add the new environment to the matrix table above

## 7. Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| "APIBaseURL not configured" crash | Missing `Local.xcconfig` | Copy `Local.xcconfig.template` to `Local.xcconfig` |
| Wrong API URL at runtime | Selected wrong scheme | Check scheme selector in Xcode |
| Bundle ID conflict on device | Two schemes using same bundle ID | Verify xcconfig BUNDLE_ID values |
| Push notifications not arriving | Wrong push environment (sandbox vs prod) | Check scheme's build configuration matches push cert |
| Firebase crash on launch | Wrong plist for environment | Verify `GoogleService-Info` matches selected scheme |

---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Owner | [Person responsible] |
| Created | [Date] |
| Last Updated | [Date] |
| Last Verified | [Date] |
| Status | Draft |
| Review Schedule | On change |
| Labels | `ios`, `swift`, `environments`, `configuration`, `[project-name]` |
```

## Writing Guidelines

- Always include the full environment matrix table — it is the single most valuable part of this document
- Document EVERY xcconfig variable, even obvious ones — a new developer should never have to guess
- Include copy-pasteable commands for switching environments
- Always mention which secrets are git-ignored vs committed
- Link to Code Signing doc for signing-related environment differences
- Link to CI/CD doc for environment-specific build pipelines
