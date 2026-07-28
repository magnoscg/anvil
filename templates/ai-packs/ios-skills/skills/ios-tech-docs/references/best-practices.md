# Best Practices & Rules for iOS Documentation

**Read this file BEFORE generating any document.** These rules apply universally to ALL document types.

---

## 1. General Documentation Rules

1. **Write in present tense**: "The app uses Clean Architecture" (not "will use")
2. **Explain the WHY, not just the WHAT**: Every architectural decision must have its justification
3. **Single source of truth**: Never duplicate information between pages; use cross-links
4. **Include real code**: Always use actual code snippets from the project, never pseudocode
5. **Docs as code**: Documentation lives in the repo, reviewed in PRs, updated with code changes
6. **Audience-first**: Write as if a new developer joins the team tomorrow
7. **Max 2 heading levels per section**: Avoid documents with 5 levels of nesting
8. **Diagrams over text**: A Mermaid diagram is worth 500 words of description
9. **Keep it concise**: If a section exceeds 2 pages, split it into its own document
10. **Cross-reference always**: Link to related pages, ADRs, Jira tickets, external docs
11. **Progressive disclosure**: Simple information first, expanding to detail. Use collapsible `<details>` sections for verbose content. A reader should understand what the project does within 5 seconds of opening the README
12. **Security-first documentation**: Never include real API keys, tokens, passwords, or secrets in documentation. Use `[REDACTED]`, `YOUR_API_KEY`, or reference a secrets manager. Document where secrets are stored, never the secrets themselves
13. **Accessibility is mandatory**: Every UI documentation must include accessibility considerations. If a component lacks accessibility documentation, flag it as incomplete

## 2. Document Ownership & Freshness

1. **Every document has an owner**: Assign a team member responsible for keeping each doc current. Rotate ownership to prevent single-point-of-failure
2. **Freshness indicators**: Every document must include a "Last Verified" date in its metadata footer. A document not verified in 90 days is considered potentially stale
3. **Quarterly audits**: Schedule quarterly reviews of all documentation. Remove or archive obsolete content aggressively — dead docs actively harm the project
4. **Update with code changes**: Documentation updates must be part of the same PR that changes the code. Add this to the PR checklist
5. **Staleness alerts**: Flag documents that reference modules, classes, or APIs that no longer exist. If a doc mentions a dependency not in Package.swift, it is outdated

## 3. iOS/Xcode-Specific Rules

1. **Document Swift version and deployment target** in README and Tech Stack table
2. **Document Swift language mode** (5 or 6) and strict concurrency checking level (warnings or errors)
3. **Include the project folder tree** as it appears in Xcode (not just filesystem)
4. **Document Xcode schemes**: Debug, Release, Staging — what config each uses
5. **Specify SPM packages** or dependencies with exact versions
6. **Document Environment Variables** and how to configure per scheme
7. **Include `// MARK: -` conventions** used in the project
8. **Document the concurrency architecture**:
   - `@MainActor` policy: which types get it, why
   - `Sendable` conformance: which types, how enforced
   - Actor isolation boundaries: where data crosses isolation domains
   - Structured concurrency: TaskGroup usage, cancellation strategy
   - `nonisolated(unsafe)` usage: require ADR justification
9. **Specify what goes in each layer**: Which types belong to Domain, Data, Presentation
10. **Document SwiftUI patterns** used:
    - `@Observable` (preferred over ObservableObject)
    - `@State` for view-local state only
    - `@Environment` for dependency injection
    - `@Bindable` for two-way bindings to Observable models
    - `@Query` for SwiftData integration
    - View decomposition rules: when to extract subviews vs use @ViewBuilder
11. **Include testing strategy per layer** with real mock examples from the project
12. **Document code generation**: If using Sourcery, SwiftGen, build plugins, or macros
13. **Document provisioning & signing**: Profiles, certificates, team setup, fastlane match
14. **Document multi-environment setup**: Matrix of dev/staging/prod with bundle IDs, API URLs, xcconfig files, app icons
15. **Document offline behavior**: What works without internet, what data is cached, what is not
16. **Document analytics/telemetry**: Event naming conventions, where events are defined, tracking SDK

## 4. Multi-Project-Type Awareness

Templates must adapt to the specific project type. When generating documentation, identify and note:

| Project Type | Key Differences |
|-------------|----------------|
| SPM-only package | No .xcodeproj, Package.swift is source of truth, no schemes/xcconfig |
| Xcode project (single target) | .xcodeproj, possibly manual deps, single scheme |
| Xcode workspace (multi-target) | .xcworkspace, App + Extensions + Widgets, multiple schemes |
| Tuist / XcodeGen | Generated .xcodeproj, manifest files as source of truth |
| Modular SPM monorepo | Root Package.swift with local packages, feature modules |
| CocoaPods project | Podfile, .xcworkspace, Pods/ directory |
| Mixed (UIKit + SwiftUI) | Hybrid navigation, UIViewRepresentable bridges, incremental migration |

> ℹ️ **Info:** When a section doesn't apply to the project type (e.g., "Xcode Schemes" for a pure SPM package), mark it as "N/A — [reason]" rather than omitting it. This confirms the topic was considered.

## 5. ADR-Specific Rules

1. **One ADR per decision**: Never group multiple decisions in one ADR
2. **Immutable records**: If a decision changes, create new ADR that "Supersedes" the old one
3. **Always include rejected options**: Not just the chosen one, also what was considered
4. **Be honest about trade-offs**: Every option has pros AND cons
5. **Use comparison matrix** when evaluating 3+ options
6. **Write Context for the future**: As if explaining to someone joining in 6 months
7. **Link to benchmarks or POCs** if they exist
8. **Keep Decision section decisive**: Start with "We will use [X]" — no ambiguity
9. **Assess reversibility**: How easy is it to undo this decision? Document the reversal cost
10. **Include success metrics**: How will you know this decision was the right one?
11. **Estimate implementation timeline**: Not just the "what" but the "when"

## 6. Formatting Rules

### Headings & Structure
- Use Markdown ATX headings (`## H2`, not underline style)
- Every long document starts with `{toc}`
- Use numbered sections for sequential content, named sections for reference content

### Code Blocks
- Always specify language: ` ```swift `, ` ```bash `, ` ```json `
- Never use untagged code blocks
- Include `// MARK: -` comments to show code organization patterns
- Show both declaration AND usage when documenting interfaces
- Include `@available` annotations when documenting version-specific APIs
- For Swift 6 code, include `@MainActor`, `Sendable`, and isolation annotations

### Tables
- Use standard pipe tables for inventories, comparisons, and listings
- Left-align text columns, center-align status/emoji columns
- Use emoji indicators: ✅ Good, ⚠️ Moderate, ❌ Poor

### Diagrams
- Use Mermaid for all diagrams (supported in GitHub natively, Confluence via plugin)
- Always provide ASCII text fallback below for environments without Mermaid support
- Keep diagrams simple — max 10-12 nodes for readability
- Use consistent colors/styles across all diagrams in the project

### Info Panels
```markdown
> ℹ️ **Info:** Informational notes
> ⚠️ **Warning:** Things that need attention
> ✅ **Success:** Confirmed working patterns
> 🚫 **Don't:** Anti-patterns to avoid
> ⏰ **Time estimate:** Expected duration for a task
```

### Links
- Use relative links between wiki pages: `[See Navigation](./03-Navigation.md)`
- Use absolute URLs for external resources
- Always verify links work after generating docs

### Metadata Footer
Every document MUST end with:
```markdown
---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Owner | [Person responsible for keeping this current] |
| Created | [Date] |
| Last Updated | [Date] |
| Last Verified | [Date — confirms content is still accurate] |
| Status | Draft / In Review / Approved |
| Review Schedule | Quarterly / On change / [Custom] |
| Labels | `ios`, `swift`, `[type]`, `[module]` |
```

## 7. Documentation Completeness Checklist

Use this checklist to validate any project wiki:

### README / Home
- [ ] Description (1-2 lines, what the app does)
- [ ] Tech stack table with versions (Swift, iOS, Xcode, key deps)
- [ ] Quick Start (clone → build → run in ≤5 steps)
- [ ] Index with links to all wiki pages
- [ ] Team contacts table
- [ ] Badges (CI status, Swift version, platform) — optional

### Architecture
- [ ] Pattern documented with justification (link to ADR)
- [ ] Layer diagram (Mermaid + ASCII fallback)
- [ ] Dependency rule explained
- [ ] Example of complete flow (UI tap → data displayed)
- [ ] Concurrency architecture (actor model, @MainActor policy, Sendable boundaries)
- [ ] State management pattern documented
- [ ] Feature flag architecture documented
- [ ] Error handling strategy across layers

### Project Structure
- [ ] Complete folder tree
- [ ] Module table with responsibilities
- [ ] "Where do I put X?" guide for new files
- [ ] Module dependency diagram
- [ ] Build phases and code generation documented
- [ ] Multi-target setup explained (if applicable)

### Environments
- [ ] Environment matrix (dev/staging/prod) with bundle IDs, URLs, schemes
- [ ] xcconfig file structure documented
- [ ] Secrets management explained
- [ ] How to switch environments

### Code Signing
- [ ] Certificate management approach documented (manual vs fastlane match)
- [ ] New developer signing setup steps
- [ ] "Signing broke" troubleshooting
- [ ] Certificate rotation schedule

### Navigation
- [ ] Navigation pattern documented (Coordinator, Router, NavigationStack)
- [ ] Main flow diagrams
- [ ] Deep linking strategy
- [ ] How to add a new screen (step by step)

### Testing
- [ ] Test pyramid defined
- [ ] What to test per layer (with examples)
- [ ] Swift Testing (#expect, @Test) conventions
- [ ] Real mock example from the project
- [ ] CI pipeline documented

### Onboarding
- [ ] Prerequisites (tools + versions + access)
- [ ] Step-by-step setup tested on clean machine (with time estimate)
- [ ] 30-day onboarding framework (Day 1, Week 1, Weeks 2-3, Week 4)
- [ ] Common build issues table
- [ ] Code signing walkthrough
- [ ] Key contacts and escalation path

### ADRs
- [ ] At least 1 ADR per significant architectural decision
- [ ] Each ADR includes rejected options with pros/cons
- [ ] Status is current (not everything stuck on "Proposed")

### Coding Conventions
- [ ] Swift style guide (project-specific or reference to external)
- [ ] Standard `// MARK: -` sections documented
- [ ] Naming conventions per type (View, ViewModel, UseCase, Repository)
- [ ] Swift 6 concurrency conventions documented
- [ ] SwiftLint / SwiftFormat configuration documented
- [ ] PR template included

### Swift Concurrency
- [ ] Swift language mode documented (5 or 6)
- [ ] Module-by-module migration status table
- [ ] @MainActor and Sendable conventions
- [ ] nonisolated(unsafe) usage policy

### Troubleshooting
- [ ] Common build errors with solutions
- [ ] Signing troubleshooting
- [ ] SPM resolution failures
- [ ] "Works on my machine" debugging checklist

### Feature Flags (if applicable)
- [ ] Flag architecture (local vs remote)
- [ ] Flag lifecycle documented
- [ ] Kill switch procedures

## 8. Anti-Patterns to Avoid

| ❌ Don't | ✅ Do Instead |
|----------|--------------|
| 2000-line README with everything mixed | Separate pages by topic |
| Documentation nobody reviews | Integrate doc updates into PR workflow |
| Diagrams as static PNG images | Use Mermaid (text-based, version-controlled) |
| "It's in the code" as excuse | Code explains HOW, docs explain WHY |
| Copy-paste outdated code snippets | Reference real files or keep snippets updated |
| Docs only in English when team speaks Spanish | Write in the team's working language |
| Document only happy paths | Include error handling, edge cases, known issues |
| Orphan pages with no links | Every page linked from index and cross-referenced |
| Writing docs at the end of the project | Start with README + Architecture + Onboarding on day 1 |
| Assuming everyone knows Xcode setup | Document every step, including "obvious" ones |
| Hardcoding secrets in documentation | Use placeholders and reference secrets manager |
| Skipping accessibility in UI docs | Every UI component must document VoiceOver, Dynamic Type |
| Ignoring document staleness | Add "Last Verified" dates, audit quarterly |
| No document owner assigned | Every doc has an owner responsible for currency |
| Using ObservableObject in new code examples | Use @Observable (Swift 5.9+) for modern projects |
| Documenting only for Xcode projects | Adapt to SPM-only, Tuist, or hybrid setups |

## 9. Practical Tips

### Getting Started
1. Don't document everything at once — start with README + Architecture + Onboarding
2. Document what hurts most: if every new dev asks the same question, document that first
3. Update with every PR: add a line to PR template asking "Does documentation need updating?"
4. Review quarterly: set a reminder to check everything is still accurate
5. A feature is not shipped until its documentation is written and reviewed

### Recommended Tools
- **Mermaid**: Diagrams in Markdown (GitHub native, Confluence via plugin)
- **SwiftUI Previews**: Capture screenshots for UI component documentation
- **DocC**: API documentation inline in Swift (complements, doesn't replace the wiki)
- **log4brains**: ADR management and auto-publication tool
- **SwiftLint + SwiftFormat**: Enforce conventions documented in coding standards
- **fastlane match**: Automate certificate and provisioning management
- **Makefile / Justfile**: Document common commands (`make setup`, `make test`, `make lint`)

### PR Template Lines for Docs
Add this to your PR template:
```markdown
## Documentation
- [ ] I have updated the relevant documentation (wiki, README, ADR)
- [ ] No documentation changes needed

## Concurrency
- [ ] New types crossing isolation boundaries are Sendable
- [ ] UI-bound types are @MainActor
```

### Documentation Quality Metrics
Track these to measure documentation effectiveness:
- Time from clone to first successful build (target: < 30 minutes)
- Number of "how do I...?" questions in Slack per week (should decrease)
- Documentation coverage: % of modules with module-doc pages
- Staleness: % of documents verified in last 90 days
