# Onboarding Guide Template

Use this template when the user asks for: onboarding guide, getting started guide, new developer setup, project setup documentation, or "how to get started with this project".

---

## Template Structure

```markdown
# [Project Name] - Developer Onboarding Guide

{toc}

## 1. Welcome

Brief project description, what the app does, and who uses it.

> ℹ️ **Quick Links:**
> - Repo: [GitHub/GitLab link]
> - CI/CD: [Pipeline link]
> - Jira Board: [Board link]
> - Figma: [Design link]
> - Confluence Space: [Docs link]
> - Slack: `#team-ios`, `#[project-name]`
> - VPN: [VPN setup link, if needed]

### Key Numbers

| Metric | Value |
|--------|-------|
| iOS Deployment Target | iOS [17]+ |
| Swift Version | [6.x] |
| Swift Language Mode | [5 / 6] |
| Xcode Version Required | [16.x]+ |
| macOS Version Required | [15.x]+ |
| Team Size (iOS) | [N] developers |
| Team Timezone | [Timezone] |
| Sprint Cadence | [2 weeks] |
| Release Cadence | [Every 2 weeks / Monthly] |

> ⏰ **Time Estimate:** Full setup takes ~2 hours. First build should work within 30 minutes.

## 2. Prerequisites

### Required Tools

| Tool | Version | Install |
|------|---------|---------|
| Xcode | 16.x+ | Mac App Store |
| Swift | 6.x | Bundled with Xcode |
| Homebrew | Latest | `brew.sh` |
| SwiftLint | Latest | `brew install swiftlint` |
| SwiftFormat | Latest | `brew install swiftformat` |
| [Other tools] | | |

### Required Access

- [ ] GitHub/GitLab repository access
- [ ] Apple Developer team membership
- [ ] TestFlight access
- [ ] Jira project access
- [ ] Confluence space access
- [ ] Slack channels: `#team-ios`, `#project-name`
- [ ] Figma project access
- [ ] VPN setup (if needed)
- [ ] API keys / environment files

> ⚠️ **Note:** Request access from [Team Lead / IT] before starting setup.

## 3. Project Setup

### 3.1 Clone & Build

```bash
# Clone the repository
git clone [repo-url]
cd [project-name]

# Install dependencies
# If using SPM (no action needed, Xcode resolves automatically)
# If using CocoaPods:
bundle install
bundle exec pod install

# Open the project
open [ProjectName].xcworkspace  # or .xcodeproj
```

### 3.2 Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit with your local values
# API_BASE_URL=https://dev-api.example.com
# API_KEY=your-dev-key
```

### 3.3 Build & Run

1. Select the `[AppName] (Debug)` scheme in Xcode
2. Select a simulator (iPhone 15 Pro recommended)
3. Press `Cmd + R` to build and run
4. First build may take 3-5 minutes for dependency resolution

### 3.4 Common Build Issues

| Problem | Solution |
|---------|----------|
| SPM resolution fails | File → Packages → Reset Package Caches |
| Signing error | Select your team in Signing & Capabilities |
| Missing provisioning profile | Ask team lead for certificate access |
| Module not found | Clean build folder (Cmd+Shift+K) and rebuild |

## 4. Code Signing & Provisioning

### Step 1: Get Added to Apple Developer Team

Ask your iOS Lead to add you to the Apple Developer team. You need:
- An Apple ID (personal or company-provided)
- Your Apple ID email sent to the iOS Lead

### Step 2: Install Certificates

```bash
# From the project root directory:
bundle exec fastlane match development

# When prompted:
# - Git URL: [certificates-repo-url]
# - Passphrase: Get from 1Password vault "[Vault Name]"
```

### Step 3: Register Your Device (for physical device testing)

```bash
# Get your device UDID:
# Connect device → Xcode → Window → Devices and Simulators → Copy Identifier

bundle exec fastlane match development --force_for_new_devices
```

### Step 4: Verify in Xcode

1. Open the project in Xcode
2. Select the app target → Signing & Capabilities tab
3. Uncheck "Automatically manage signing"
4. Under "Debug", select: `match Development com.company.app.dev`
5. Under "Release", select: `match AppStore com.company.app`
6. Build should succeed without signing errors

> ℹ️ **Info:** See [Code Signing](./12-Code-Signing.md) for detailed certificate management and troubleshooting.

## 5. Project Structure

```
ProjectName/
├── App/                    # App entry point, DI, app-level config
│   ├── ProjectNameApp.swift
│   ├── DependencyContainer.swift
│   └── AppConfiguration.swift
├── Presentation/           # UI layer
│   ├── Screens/            # Feature screens
│   │   ├── Home/
│   │   ├── Profile/
│   │   └── Settings/
│   ├── Components/         # Reusable UI components
│   └── Navigation/         # Routing/coordination
├── Domain/                 # Business logic
│   ├── Entities/           # Domain models
│   ├── UseCases/           # Business operations
│   └── Repositories/       # Repository protocols
├── Data/                   # Data layer
│   ├── Repositories/       # Repository implementations
│   ├── DataSources/        # Remote & local data sources
│   ├── DTOs/               # API response/request models
│   └── Mappers/            # DTO ↔ Entity mappers
├── Core/                   # Shared utilities
│   ├── Extensions/
│   ├── Helpers/
│   └── Constants/
├── Resources/              # Assets, strings, fonts
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

> ℹ️ **Architecture:** We follow Clean Architecture with MVVM. See [Architecture Documentation](./architecture) for details.

## 6. Development Workflow

### 6.1 Git Branching Strategy

| Branch | Purpose | Naming |
|--------|---------|--------|
| `main` | Production-ready code | Protected |
| `develop` | Integration branch | Protected |
| `feature/*` | New features | `feature/JIRA-123-short-description` |
| `bugfix/*` | Bug fixes | `bugfix/JIRA-456-short-description` |
| `hotfix/*` | Production fixes | `hotfix/JIRA-789-short-description` |

### 6.2 PR Process

1. Create feature branch from `develop`
2. Implement changes following coding conventions
3. Write/update tests (aim for >80% coverage on new code)
4. Run SwiftLint and SwiftFormat locally
5. Open PR with description template
6. Minimum 1 approval required
7. CI must pass (build + tests)
8. Squash merge into `develop`

### 6.3 Coding Conventions

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use `// MARK: -` for code organization
- Protocol-first design: define protocols for dependencies
- Prefer value types (`struct`) over reference types (`class`)
- Use Swift Concurrency (`async/await`) over closures for async work
- Document public APIs with `///` doc comments

## 7. Testing

### How to Run Tests

```bash
# Run all tests from Xcode
Cmd + U

# Run specific test file
# Click the diamond icon next to the test class/method

# Run from CLI
xcodebuild test -scheme ProjectName -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Testing Conventions

- Test file mirrors source: `LoginViewModel.swift` → `LoginViewModelTests.swift`
- Use Swift Testing (`@Test`, `#expect`) for new tests
- Use `MockX` prefix for mock types
- Each test follows Arrange → Act → Assert pattern

## 8. Debugging Tips

### Network Debugging
- Use [Proxyman/Charles] for inspecting network traffic
- Enable network logging in Debug scheme: `Settings → Debug → Network Logging`

### SwiftUI Previews
- Use `#Preview` macro for quick UI iteration
- Group previews by state: default, loading, error, empty

### Useful Breakpoints
- Symbolic breakpoint on `UIViewAlertForUnsatisfiableConstraints` (Auto Layout issues)
- Exception breakpoint for unhandled exceptions

## 9. 30-Day Onboarding Framework

### Day 1: Setup & First Build

- [ ] Complete project setup (Section 3)
- [ ] Complete code signing setup (Section 4)
- [ ] Build and run on simulator
- [ ] Build and run on physical device (if available)
- [ ] Read Architecture Overview doc
- [ ] Explore the codebase — understand the folder structure
- [ ] Join Slack channels: `#team-ios`, `#[project-name]`

### Week 1: Understand the Project

- [ ] Read all project documentation (start with wiki index)
- [ ] Shadow a PR review — watch how the team reviews code
- [ ] Fix a small bug or typo (your first PR!)
- [ ] Set up IDE preferences (see recommended Xcode settings below)
- [ ] Run the test suite locally
- [ ] Meet with iOS Lead for architecture walkthrough (30 min)
- [ ] Meet with QA for testing process walkthrough (30 min)

### Weeks 2-3: First Feature

- [ ] Pick a small feature or improvement from the backlog
- [ ] Implement following the project conventions
- [ ] Write tests for your implementation
- [ ] Submit PR and iterate on review feedback
- [ ] Pair program with a teammate on a task (at least once)

### Week 4: Independence

- [ ] Complete your first feature end-to-end
- [ ] Review a teammate's PR
- [ ] Understand the CI/CD pipeline and release process
- [ ] Know how to switch between environments
- [ ] Troubleshoot a build issue independently

### First PR Expectations

| Aspect | Expectation |
|--------|------------|
| Scope | Small — 1 bug fix or minor improvement |
| Goal | Learn the PR process, not deliver a feature |
| Time | 1-2 days |
| Reviews | Expect 1-2 rounds of feedback — this is normal! |
| Help | Ask questions early and often — Slack or pair programming |

## 10. Recommended Xcode Settings

### IDE Preferences

| Setting | Value | Where |
|---------|-------|-------|
| Indentation | 4 spaces (no tabs) | Xcode → Settings → Text Editing → Indentation |
| Line wrapping | Soft wrap | Xcode → Settings → Text Editing → Display |
| Show line numbers | Yes | Xcode → Settings → Text Editing → Display |
| Show invisibles | No | Personal preference |
| Trim trailing whitespace | Yes | Xcode → Settings → Text Editing → Editing |

### Useful Breakpoints

| Breakpoint | Purpose | How to Add |
|-----------|---------|------------|
| All Exceptions | Catch crashes at the source | Debug → Breakpoints → + → Exception Breakpoint |
| Constraint errors | Catch Auto Layout issues | Symbolic: `UIViewAlertForUnsatisfiableConstraints` |
| Main thread checker | Catch UI threading issues | Edit Scheme → Run → Diagnostics → Main Thread Checker |

### Simulator vs Device

| Task | Simulator | Device |
|------|-----------|--------|
| UI development | ✅ Preferred (faster) | Not needed |
| API integration | ✅ Fine | For network edge cases |
| Camera/sensors | ❌ Not available | ✅ Required |
| Push notifications | ⚠️ .apns file only | ✅ Full support |
| Performance testing | ❌ Not representative | ✅ Required |
| App Store builds | ❌ Cannot | ✅ Required |

## 11. Troubleshooting Escalation Path

If you're stuck:

1. **Check the docs** — [Troubleshooting Guide](./16-Troubleshooting.md) has common issues
2. **Search Slack** — `#team-ios` channel history
3. **Ask in Slack** — Post your error message + what you tried
4. **Pair program** — Book 15 min with a teammate (everyone is happy to help!)
5. **Escalate** — Ask the iOS Lead if the issue is blocking you for >1 hour

## 12. Learning Resources

### Project-Specific

| Resource | Link | Priority |
|----------|------|----------|
| Architecture Overview | [Link to doc] | ✅ Read first |
| Coding Conventions | [Link to doc] | ✅ Read first |
| ADR Index | [Link to doc] | ⚠️ Reference as needed |
| API Documentation | [Link to doc] | ⚠️ Reference as needed |

### iOS Development (General)

| Topic | Resource |
|-------|----------|
| Swift Language | [Swift.org Documentation](https://docs.swift.org/) |
| SwiftUI | [Apple SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui) |
| Swift Concurrency | [Swift Concurrency Docs](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) |
| WWDC Sessions | [developer.apple.com/wwdc](https://developer.apple.com/wwdc/) |

## 13. Key Contacts

| Role | Name | Contact |
|------|------|---------|
| iOS Lead | [Name] | Slack / Email |
| Backend Lead | [Name] | Slack / Email |
| Designer | [Name] | Slack / Email |
| QA | [Name] | Slack / Email |
| Product Owner | [Name] | Slack / Email |

## 14. Further Reading

- [Architecture Documentation](./architecture)
- [API Documentation](./api-docs)
- [ADR Index](./adrs)
- [Release Process](./release-process)

---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Created | [Date] |
| Last Updated | [Date] |
| Owner | [iOS Lead Name] |
| Last Verified | [Date] |
| Review Schedule | [Quarterly / Every Sprint / etc.] |
| Status | Draft |
| Confluence Labels | `ios`, `onboarding`, `getting-started`, `[project-name]` |
```

## Writing Guidelines

- Write as if the reader has never seen the codebase
- The 30-day framework is the most important section — it sets expectations
- Include realistic time estimates for every step
- Test the setup instructions on a clean machine regularly
- Keep tool versions and links updated (mark a calendar reminder)
- Include screenshots for non-obvious Xcode configurations
- The "Common Build Issues" table is extremely valuable — update it whenever a new dev hits an issue
- Include the escalation path — new devs often struggle in silence
