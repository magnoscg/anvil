# ADR (Architecture Decision Record) Template

Use this template when the user asks for: ADR, architecture decision, technical decision record, "why did we choose X", decision log, or when documenting a significant technical choice.

---

## Template Structure

```markdown
# ADR-[NNN]: [Title of Decision]

**Status:** Proposed | Accepted | Deprecated | Superseded by [ADR-XXX]
**Date:** [YYYY-MM-DD]
**Deciders:** [List of people involved]
**Technical Story:** [Jira ticket or link]

## Context

Describe the situation that motivates this decision. What is the technical or business problem? What constraints exist? Include:

- Current state of the system
- Pain points or limitations
- Business requirements driving the change
- Technical constraints (iOS version, team size, timeline, etc.)

## Decision

State the decision clearly in one sentence, then elaborate.

**We will use [chosen option].**

Describe the approach in detail:
- What changes to the codebase
- Migration strategy (if replacing something)
- Timeline and rollout plan

## Options Considered

### Option 1: [Name] ✅ (Chosen)

**Description:** Brief description of this approach.

**Pros:**
- Pro 1
- Pro 2

**Cons:**
- Con 1
- Con 2

### Option 2: [Name]

**Description:** Brief description.

**Pros:**
- Pro 1

**Cons:**
- Con 1
- Con 2 (dealbreaker)

### Option 3: [Name]

**Description:** Brief description.

**Pros:**
- Pro 1

**Cons:**
- Con 1

## Comparison Matrix

| Criteria | Weight | Option 1 | Option 2 | Option 3 |
|----------|--------|-----------|----------|----------|
| Performance | High | ✅ Good | ⚠️ Moderate | ❌ Poor |
| Maintainability | High | ✅ Good | ✅ Good | ⚠️ Moderate |
| Learning Curve | Medium | ⚠️ Steep | ✅ Easy | ✅ Easy |
| Community Support | Medium | ✅ Strong | ⚠️ Moderate | ❌ Weak |
| iOS Compatibility | High | ✅ iOS 16+ | ✅ iOS 15+ | ✅ iOS 14+ |

## Consequences

### Positive
- What improves as a result of this decision
- Long-term benefits

### Negative
- What trade-offs are accepted
- New complexity introduced
- Migration costs

### Risks
- What could go wrong
- Mitigation strategies

## Reversibility Assessment

| Aspect | Assessment |
|--------|------------|
| Reversibility | [Easily reversible / Partially reversible / Irreversible] |
| Reversal Cost | [Low / Medium / High] |
| Reversal Timeframe | [Hours / Days / Weeks / Months] |
| Data Migration Needed | [Yes / No] |

> ℹ️ **Info:** Easily reversible decisions can be made quickly. Irreversible decisions (database schema changes, public API contracts, framework migrations) require thorough review and broader consensus.

## Implementation Timeline

| Phase | Scope | Duration | Owner |
|-------|-------|----------|-------|
| Phase 1 | [Initial implementation / POC] | [Duration] | [Person] |
| Phase 2 | [Migration of existing code] | [Duration] | [Person] |
| Phase 3 | [Cleanup of old approach] | [Duration] | [Person] |

## Success Metrics

How we will measure whether this decision was correct:

| Metric | Current (Before) | Target (After) | Measurement |
|--------|-------------------|----------------|-------------|
| [Build time] | [Xs] | [<Ys] | CI pipeline duration |
| [Crash rate] | [X%] | [<Y%] | Crashlytics dashboard |
| [Developer velocity] | [Qualitative] | [Quantitative target] | PR cycle time |
| [User satisfaction] | [X rating] | [>Y rating] | App Store reviews |

> ℹ️ **Info:** Review these metrics [N months] after implementation to validate the decision.

## Decision Communication Plan

| Audience | Channel | When |
|----------|---------|------|
| iOS team | Team meeting + Slack `#ios` | Before implementation |
| Backend team | Slack `#backend` (if API changes) | Before implementation |
| QA team | Jira ticket + Slack `#qa` | Before testing phase |
| All engineering | Engineering newsletter / All-hands | After implementation |

## Exception Handling

When exceptions to this decision are acceptable:

| Exception | Justification Required | Approval |
|-----------|----------------------|----------|
| Legacy module can't adopt yet | Tech debt ticket with timeline | Tech Lead |
| Third-party library incompatibility | Document workaround | Tech Lead |
| Performance regression | Benchmark data required | Team consensus |

## Cost Analysis

| Cost Type | Estimate | Notes |
|-----------|----------|-------|
| Implementation effort | [Person-days/weeks] | Initial development |
| Migration effort | [Person-days/weeks] | Migrating existing code |
| Ongoing maintenance | [Hours/month] | Long-term cost |
| Learning curve | [Days per developer] | Team ramp-up |
| Risk of delay | [Low / Medium / High] | Impact on roadmap |

## Related ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-XXX: Title] | Supersedes / Superseded by / Related to / Depends on |

## Follow-Up Actions

- [ ] Action item 1 (Owner, Due date)
- [ ] Action item 2 (Owner, Due date)
- [ ] Update related documentation

## References

- [Link to relevant documentation]
- [Link to proof of concept]
- [Link to benchmark results]

---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Owner | [Name/Team] |
| Created | [Date] |
| Last Updated | [Date] |
| Last Verified | [Date] |
| Review Schedule | [Quarterly / Semi-annually / Annually] |
| Status | Draft |
| Confluence Labels | `ios`, `adr`, `architecture`, `decision` |
```

## Common iOS ADR Topics

When the user wants to document a decision but hasn't specified the topic, suggest these common iOS ADR subjects:

- Architecture pattern selection (MVVM vs TCA vs VIPER vs Clean Swift)
- UI framework choice (SwiftUI vs UIKit vs hybrid)
- Navigation approach (Coordinator, NavigationStack, Router)
- Dependency injection strategy (manual vs Swinject vs Factory)
- Networking library (URLSession vs Alamofire vs custom)
- Persistence solution (SwiftData vs Core Data vs Realm vs SQLite)
- State management (@Observable vs Combine vs TCA Store)
- Modularization strategy (SPM packages vs Frameworks vs Tuist)
- Testing framework (Swift Testing vs XCTest)
- CI/CD platform choice
- Minimum iOS version support
- Feature flags strategy
- Analytics/logging framework
- Image loading/caching solution
- Localization approach
- Swift 6 migration strategy (incremental vs big-bang)
- Offline-first vs online-first data strategy
- SwiftData vs Core Data migration
- App architecture for multi-platform (iOS + macOS + visionOS)
- Privacy manifest and tracking transparency approach

## Writing Guidelines

- Write ADRs as if explaining the decision to a new team member joining 6 months from now
- Be honest about trade-offs — every option has cons
- Include concrete examples and benchmarks when available
- Keep the "Context" section factual, not persuasive
- The decision should feel like a natural conclusion from the context and comparison
- Include reversibility assessment — it determines how much consensus is needed
- Include success metrics — every decision should be measurable
- Include cost analysis for decisions with significant migration effort
- Link related ADRs to show decision evolution
