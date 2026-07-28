# Wiki Structure Guide

Use this reference when the user asks to create a full project wiki, documentation structure, or wants to organize documentation for an iOS project across multiple pages.

---

## Recommended Wiki Structure

```
📁 Project Wiki
│
├── 🏠 README.md (Home)
│   └── Index, badges, description, quick start, team contacts
│
├── 📐 01-Architecture-Overview.md
│   └── Pattern, layer diagram, dependency rule, concurrency architecture, key decisions
│
├── 📦 02-Project-Structure.md
│   └── Folder tree, modules/SPM packages, responsibilities, dependency diagram, build phases
│
├── 🧭 03-Navigation.md
│   └── Navigation strategy, deep linking, coordinators/routers, flow diagrams, sheet coordination
│
├── 🔄 04-Data-Flow.md
│   └── Request lifecycle, state management, error handling, cancellation, optimistic updates
│
├── 🌐 05-Networking.md
│   └── API client, endpoints by domain, DTOs, mappers, auth flow, caching, rate limiting
│
├── 💾 06-Persistence.md
│   └── SwiftData/CoreData, caching strategy, Keychain usage, migrations, schema versioning
│
├── 🧪 07-Testing-Strategy.md
│   └── Test pyramid, Swift Testing conventions, mocks, what to test per layer, CI pipeline
│
├── 🎨 08-UI-Design-System.md
│   └── Components, theming/colors/typography, animations, haptics, accessibility, previews
│
├── 🔧 09-Developer-Onboarding.md
│   └── 30-day framework, setup, code signing walkthrough, troubleshooting, key contacts
│
├── 📋 10-Coding-Conventions.md
│   └── Swift style guide, MARK sections, naming, concurrency conventions, linting, PR template
│
├── 🔐 11-Environments.md
│   └── Environment matrix (dev/staging/prod), xcconfig, bundle IDs, secrets management
│
├── ✍️ 12-Code-Signing.md
│   └── Certificates, provisioning, fastlane match, new dev setup, troubleshooting
│
├── ⚡ 13-Swift-Concurrency.md
│   └── Swift 6 mode, migration status per module, conventions, known issues
│
├── 📝 ADRs/
│   ├── ADR-001-Architecture-Pattern.md
│   ├── ADR-002-UI-Framework.md
│   ├── ADR-003-Navigation-Strategy.md
│   ├── ADR-004-DI-Strategy.md
│   ├── ADR-005-Networking-Library.md
│   ├── ADR-006-Persistence-Solution.md
│   ├── ADR-007-Testing-Framework.md
│   ├── ADR-008-State-Management.md
│   ├── ADR-009-Modularization-Strategy.md
│   ├── ADR-010-Minimum-iOS-Version.md
│   └── ADR-011-Swift-Concurrency-Adoption.md
│
├── 🚀 14-CI-CD-Release.md
│   └── Build configs, pipelines, release process, rollback, app size monitoring
│
├── 🚩 15-Feature-Flags.md
│   └── Flag architecture, lifecycle, naming, testing, kill switches
│
├── 🔧 16-Troubleshooting.md
│   └── Common build errors, signing issues, SPM failures, "works on my machine" checklist
│
└── 📖 17-Glossary.md
    └── Domain terms, abbreviations, useful links, reference projects
```

## Page Priority Order

When creating documentation for a project, generate pages in this order (most critical first):

| Priority | Page | Why |
|----------|------|-----|
| 1 | README.md | First thing anyone sees; entry point to all docs |
| 2 | 09-Developer-Onboarding.md | Unblocks new developers immediately |
| 3 | 12-Code-Signing.md | #1 pain point for new devs — blocks first build |
| 4 | 01-Architecture-Overview.md | Foundation for understanding all other docs |
| 5 | 02-Project-Structure.md | "Where do I find X?" is the #1 new dev question |
| 6 | 11-Environments.md | "How do I switch environments?" is the #2 question |
| 7 | 10-Coding-Conventions.md | Prevents inconsistent code from day 1 |
| 8 | 16-Troubleshooting.md | Saves hours of debugging for common issues |
| 9 | 13-Swift-Concurrency.md | Critical for Swift 6 projects — prevents data races |
| 10 | 07-Testing-Strategy.md | Ensures quality standards are clear |
| 11 | ADRs/ | Captures decisions before context is lost |
| 12 | 03-Navigation.md | Navigation is often the most complex part |
| 13 | 04-Data-Flow.md | Understanding data flow prevents architectural errors |
| 14 | 05-Networking.md | API layer docs prevent duplicated work |
| 15 | 08-UI-Design-System.md | Ensures consistent UI across the app |
| 16 | 06-Persistence.md | Less critical unless persistence is complex |
| 17 | 14-CI-CD-Release.md | Important but fewer people need it daily |
| 18 | 15-Feature-Flags.md | Important if using feature flags |
| 19 | 17-Glossary.md | Useful but can grow organically |

## README.md (Home) Template

```markdown
# [Project Name]

> [One-line description of what the app does and who uses it.]

## Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Swift | [5.x / 6.x] |
| Swift Language Mode | [5 / 6] | - |
| UI Framework | SwiftUI | iOS [17+/18+] |
| Architecture | [Clean Architecture + MVVM / TCA / MVVM-C] | - |
| Concurrency | Swift Concurrency (async/await) | - |
| DI | [manual / Swinject / Factory / @Environment] | - |
| Networking | [URLSession / Alamofire / custom] | - |
| Persistence | [SwiftData / Core Data / Realm / GRDB] | - |
| Testing | [Swift Testing / XCTest / both] | - |
| CI/CD | [GitHub Actions / Bitrise / Xcode Cloud] | - |
| Linting | [SwiftLint + SwiftFormat / SwiftFormat only] | - |
| Xcode | [version] | - |
| macOS | [minimum version] | - |

## Quick Start

> ⏰ **Time estimate:** ~30 minutes for first setup, ~5 minutes for subsequent builds.

​```bash
# 1. Clone
git clone [repo-url]
cd [project-name]

# 2. Setup (installs tools, resolves deps, configures signing)
make setup  # or: ./scripts/bootstrap.sh

# 3. Configure environment
cp Config.xcconfig.template Config.xcconfig
# Edit Config.xcconfig with your values (see 11-Environments.md)

# 4. Open and build
open [ProjectName].xcodeproj  # or .xcworkspace
# Select "[Debug]" scheme → iPhone simulator → Cmd+R
​```

> ℹ️ **First build may take 3-5 min** for SPM dependency resolution.
> ⚠️ **Code signing issues?** See [12-Code-Signing.md](./docs/12-Code-Signing.md) before troubleshooting.

## Documentation Index

| Page | Description |
|------|------------|
| [Architecture](./docs/01-Architecture-Overview.md) | Pattern, layers, concurrency, dependency rules |
| [Project Structure](./docs/02-Project-Structure.md) | Modules, folders, responsibilities |
| [Navigation](./docs/03-Navigation.md) | Router, deep linking, flow diagrams |
| [Data Flow](./docs/04-Data-Flow.md) | Requests, state management, errors |
| [Networking](./docs/05-Networking.md) | API client, endpoints, auth flow |
| [Persistence](./docs/06-Persistence.md) | Storage, caching, migrations |
| [Testing](./docs/07-Testing-Strategy.md) | Strategy, mocks, CI pipeline |
| [UI Design System](./docs/08-UI-Design-System.md) | Components, theming, accessibility |
| [Developer Onboarding](./docs/09-Developer-Onboarding.md) | 30-day guide for new developers |
| [Coding Conventions](./docs/10-Coding-Conventions.md) | Style guide, naming, linting |
| [Environments](./docs/11-Environments.md) | Dev/staging/prod setup |
| [Code Signing](./docs/12-Code-Signing.md) | Certificates, provisioning, troubleshooting |
| [Swift Concurrency](./docs/13-Swift-Concurrency.md) | Swift 6 migration, conventions |
| [ADRs](./docs/ADRs/) | Architecture Decision Records |
| [CI/CD & Release](./docs/14-CI-CD-Release.md) | Build, deploy, release process |
| [Feature Flags](./docs/15-Feature-Flags.md) | Toggle architecture, lifecycle |
| [Troubleshooting](./docs/16-Troubleshooting.md) | Common errors, debugging guide |
| [Glossary](./docs/17-Glossary.md) | Terms, abbreviations, links |

## Team

| Role | Name | Contact | Timezone |
|------|------|---------|----------|
| iOS Lead | [Name] | Slack / Email | [TZ] |
| Backend Lead | [Name] | Slack / Email | [TZ] |
| Designer | [Name] | Slack / Email | [TZ] |
| QA | [Name] | Slack / Email | [TZ] |
| Product Owner | [Name] | Slack / Email | [TZ] |

## Key Slack Channels

| Channel | Purpose |
|---------|---------|
| `#ios` | General iOS development |
| `#ios-releases` | Release announcements |
| `#code-review` | PR review requests |
| `#incidents` | Production issues |
```

## Cross-Referencing Rules

- Every page must be linked from the README index
- Architecture page links to relevant ADRs
- Module docs link back to Architecture and Project Structure
- Testing page links to Coding Conventions (for naming)
- Onboarding links to Environments, Code Signing, and Troubleshooting
- ADRs link to the pages they affect
- Troubleshooting links to relevant docs for each issue category
- Swift Concurrency page cross-references Architecture (for actor model) and Coding Conventions (for rules)
- Environments page links to CI/CD (for env-specific builds)

## Naming Convention for Files

| Pattern | Example |
|---------|---------|
| Numbered pages | `01-Architecture-Overview.md` |
| ADR files | `ADR-001-Architecture-Pattern.md` |
| Module docs | `Module-Auth.md`, `Module-Payment.md` |
| Runbooks | `Runbook-Hotfix-Release.md` |
| Feature docs | `Feature-Push-Notifications.md` |

Numbers ensure consistent ordering in file browsers and wiki sidebars.

## Documentation Maintenance

### Quarterly Review Process
1. Schedule a 1-hour meeting each quarter to review all docs
2. For each document:
   - Is the "Last Verified" date within 90 days?
   - Does the doc reference modules/deps that still exist?
   - Are code examples still valid?
3. Update, archive, or delete stale docs
4. Update the README index if pages were added/removed

### Documentation Changelog
When updating documentation, add a brief note in the PR description:
```markdown
## Documentation Changes
- Updated 01-Architecture-Overview.md: Added feature flag architecture section
- Created ADR-012-SwiftData-Migration.md
- Archived Module-Legacy.md (module removed in v3.0)
```

### External Tool Integration
Link to external tools from documentation rather than duplicating their content:
- **Figma**: Link to design system components directly
- **Jira/Linear**: Link to epics and project boards
- **Confluence**: If some docs live in Confluence, link from README index
- **App Store Connect**: Link to the app page for release managers
- **CI Dashboard**: Link to the build status page

### Documentation Quality Signals

| Signal | Healthy | Unhealthy |
|--------|---------|-----------|
| Last Verified date | Within 90 days | Over 6 months ago |
| Broken links | 0 | Any |
| Module docs coverage | All modules documented | Missing modules |
| ADR count | 1 per significant decision | 0 or all "Proposed" |
| Onboarding success | New dev builds in < 30 min | New dev stuck for hours |
| Slack doc questions | Decreasing over time | Same questions repeated |
