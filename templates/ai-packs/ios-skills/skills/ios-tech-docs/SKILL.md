---
name: ios-tech-docs
description: "Generate comprehensive technical documentation for iOS/Swift projects, optimized for Confluence upload or GitHub Wiki. Use this skill when the user asks to: document an iOS project, create architecture documentation, write API docs, generate onboarding guides, create ADRs (Architecture Decision Records), document modules or features, create runbooks, document project structure, navigation, testing strategy, coding conventions, CI/CD, design system, or produce any technical documentation related to iOS/Swift/SwiftUI projects. Also triggers on: 'document this', 'write docs for', 'create documentation', 'Confluence page', 'GitHub wiki', 'tech spec', 'design doc', 'architecture doc', 'create wiki', or any request to document Swift code, modules, patterns, or project structure. Supports output in Markdown (direct Confluence/GitHub paste), HTML (Confluence storage format), or DOCX."
---

# iOS Technical Documentation Generator

Generate professional iOS project documentation ready for Confluence or GitHub Wiki.

## Quick Start

1. Identify the document type needed (see Document Types below)
2. Read the appropriate template from `references/`
3. For full project wikis, read `references/wiki-structure.md` first for the overall structure
4. Read `references/best-practices.md` for rules that apply to ALL document types
5. Generate the documentation following the template structure
6. Output as `.md` (recommended) or `.html` for Confluence compatibility

## Output Formats

| Format | Best For | Upload Method |
|--------|----------|---------------|
| Markdown `.md` | Quick paste, GitHub Wiki, readability | Copy → Confluence editor (Ctrl+Shift+V) or GitHub Wiki |
| HTML `.html` | Rich formatting, diagrams | Insert → Storage format, or paste in editor |
| DOCX `.docx` | Offline review, formal docs | Upload as attachment or import via Word |

**Default to Markdown** unless the user requests otherwise. Use clean Markdown compatible with Confluence's wiki renderer and GitHub.

## Document Types

Select the appropriate template based on the user's request:

| Request | Template | Reference File |
|---------|----------|----------------|
| Full project wiki / documentation | Wiki Structure Guide | `references/wiki-structure.md` |
| Architecture overview | Architecture Document | `references/architecture-doc.md` |
| Project structure / modules | Project Structure Doc | `references/project-structure-doc.md` |
| Navigation architecture | Navigation Document | `references/navigation-doc.md` |
| Data flow / state management | Data Flow Document | `references/data-flow-doc.md` |
| Feature/module docs | Module Documentation | `references/module-doc.md` |
| API/service layer docs | API Documentation | `references/api-doc.md` |
| Testing strategy | Testing Strategy Doc | `references/testing-strategy-doc.md` |
| UI components / design system | UI Design System Doc | `references/ui-design-system-doc.md` |
| Coding conventions / style guide | Coding Conventions Doc | `references/coding-conventions-doc.md` |
| Architecture decisions | ADR (Decision Record) | `references/adr.md` |
| New dev onboarding | Onboarding Guide | `references/onboarding.md` |
| CI/CD / release process | CI/CD & Release Doc | `references/ci-cd-release-doc.md` |
| Incident/runbook | Runbook | `references/runbook.md` |
| All-in-one project docs | Full Project Wiki | Use `wiki-structure.md` + combine templates |

**ALWAYS read `references/best-practices.md` before generating ANY documentation.** It contains rules that apply universally.

**Read the relevant reference file(s) before generating documentation.** Each contains the template structure, formatting tips, and examples.

## Reference Projects for Inspiration

When generating documentation, these real-world projects serve as quality benchmarks:

| Project | What to Learn From It |
|---------|----------------------|
| kudoleh/iOS-Clean-Architecture-MVVM | Layer diagrams, folder structure, testing per layer |
| pointfreeco/swift-composable-architecture | Multi-page DocC docs, articles by topic, comprehensive examples |
| futurice/ios-good-practices | Exhaustive iOS best practices guide |
| tuan188/CleanArchitecture | Detailed directory trees, Xcode template integration |
| nalexn/clean-architecture-swiftui | Explains "why" behind every architectural decision |
| joelparkerhenderson/architecture-decision-record | ADR templates and examples |

## Confluence Best Practices

### Structure & Naming
- Use hierarchical page structure: `Project → Module → Subpage`
- Title format: `[Project] - [Type] - [Subject]` (e.g., "MyApp - ADR - Migration to SwiftUI")
- Add a Table of Contents macro placeholder: `{toc}` at the top of long documents
- Use Confluence labels in a metadata footer: `Labels: ios, swift, architecture, [module-name]`

### Formatting Rules for Confluence Compatibility
- Use ATX headings (`## H2`) not Setext (underlines)
- Use fenced code blocks with language identifiers: ` ```swift `
- Use standard Markdown tables (pipe tables)
- For info/warning/note panels, use blockquote markers:
  ```
  > ℹ️ **Info:** This is an informational note.
  > ⚠️ **Warning:** This needs attention.
  > ✅ **Success:** This works as expected.
  ```
- Avoid HTML tags in Markdown (Confluence may strip them)
- Use relative links for cross-referencing: `[See Auth Module](./auth-module)`

### Diagrams
- Include Mermaid diagrams inline (Confluence supports via plugins, GitHub natively)
- Always provide text-based ASCII fallback for environments without Mermaid

### Metadata Footer
Every generated document must end with a metadata table:
```markdown
---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Created | [Date] |
| Last Updated | [Date] |
| Status | Draft / In Review / Approved |
| Confluence Labels | `ios`, `swift`, `[module]`, `[type]` |
```

## iOS-Specific Documentation Conventions

### Swift Code Examples
- Always include Swift version and minimum iOS target
- Use `// MARK: -` comments to indicate code organization
- Show both declaration and usage examples
- Include `@available` annotations when relevant
- Document concurrency context (`@MainActor`, `Sendable`, etc.)

### Architecture Patterns
- Document the pattern used (MVVM, Clean Architecture, TCA, etc.)
- Show dependency flow with diagrams
- List all modules/packages and their responsibilities
- Document the DI (dependency injection) strategy
- Include navigation/routing approach

### SwiftUI-Specific
- Document `@Observable` / `@State` / `@Environment` usage patterns
- Show view composition hierarchy
- Document preview configurations
- Note UIKit bridges (`UIViewRepresentable`, etc.)

### Testing
- Document testing strategy per architecture layer
- Show mock/stub conventions
- Include CI/CD test pipeline notes

## Generation Workflow

1. **Read `references/best-practices.md`** — always, for any document type
2. **Ask clarifying questions** if scope is unclear (audience, depth, modules)
3. **Read the appropriate template(s)** from `references/`
4. **For full wikis**, read `references/wiki-structure.md` and generate pages in order
5. **Generate** following: purpose statement → TOC → overview → details → edge cases → metadata
6. **Output the file(s)** in the requested format (default: Markdown)
7. **Validate** against the checklist in `references/best-practices.md`
