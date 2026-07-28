# Runbook Template

Use this template when the user asks for: runbook, incident response, operational procedure, release process, troubleshooting guide, or "what to do when X happens".

---

## Template Structure

```markdown
# [Project Name] - Runbook: [Topic]

{toc}

> ⚠️ **This is an operational runbook.** Follow steps in order. Do not skip steps unless explicitly noted.

## 1. Purpose

What situation this runbook addresses and when to use it.

**Trigger conditions:**
- Condition that means you should use this runbook
- Alert or notification that triggers this procedure

## 2. Incident Severity Levels

| Severity | Definition | Response Time | Examples |
|----------|-----------|---------------|---------|
| **P0 — Critical** | App completely unusable, data loss risk | <15 minutes | App crashes on launch, payment failures, data corruption |
| **P1 — High** | Major feature broken, significant user impact | <1 hour | Login broken, core feature non-functional |
| **P2 — Medium** | Feature degraded, workaround exists | <4 hours | Slow performance, non-critical feature broken |
| **P3 — Low** | Minor issue, cosmetic, limited impact | <24 hours | UI glitch, minor text error |
| **P4 — Minimal** | Trivial, no user impact | Next sprint | Internal tool issue, documentation update |

### Escalation Procedures

| Time Elapsed | Action | Who to Contact |
|-------------|--------|----------------|
| 0 minutes | Acknowledge in `#incidents` | On-call engineer |
| 15 minutes (P0) | Escalate to iOS Lead | iOS Lead + Engineering Manager |
| 30 minutes (P0) | Escalate to Engineering Manager | Engineering Manager |
| 1 hour (P0/P1) | Status update to stakeholders | iOS Lead |
| 4 hours (P0) | Exec notification | Engineering Director |
| Every 2 hours | Status update | On-call engineer |

## 3. Prerequisites

- [ ] Access to [system/tool]
- [ ] Permissions: [required role]
- [ ] Tools: [required CLI tools or apps]

## 4. Quick Reference

| Action | Command / Link |
|--------|---------------|
| Check app status | [Monitoring dashboard link] |
| View crash reports | [Crashlytics/Sentry link] |
| View CI pipeline | [CI link] |
| Contact on-call | [PagerDuty/Slack link] |

## 5. Procedure

### Step 1: [Assessment]

Describe what to check first.

```bash
# Example command
curl -s https://api.example.com/health | jq .
```

**Expected result:** Description of what a healthy state looks like.

**If unhealthy:** Proceed to Step 2.
**If healthy:** The issue may be elsewhere — see [Alternative Runbook].

### Step 2: [Diagnosis]

How to identify the root cause.

| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| App crashes on launch | Bad config push | Rollback config (Step 3a) |
| API timeouts | Backend issue | Escalate to backend team |
| Auth failures | Token service down | Step 3b |
| UI broken after release | Regression | Hotfix release (Step 4) |

### Step 3: [Resolution Options]

#### 3a: Rollback Configuration

```bash
# Steps to rollback a remote config change
1. Open [Firebase/LaunchDarkly console]
2. Navigate to [config section]
3. Revert to previous version
4. Verify in app
```

#### 3b: Token Service Recovery

```bash
# Steps to address token issues
1. Check token service health: [dashboard]
2. If down, restart: [procedure]
3. Clear local tokens: instruct users to force-quit and reopen
```

### Step 4: [Hotfix Release Process]

```bash
# Create hotfix branch
git checkout main
git checkout -b hotfix/JIRA-XXX-description

# Make minimal fix
# ... code changes ...

# Fast-track PR (1 reviewer minimum)
# Merge to main
# Trigger release pipeline

# Tag release
git tag -a v1.2.1 -m "Hotfix: description"
git push origin v1.2.1
```

**TestFlight build time:** ~20 minutes
**App Store review (expedited):** ~24 hours

## 6. Feature Flag Kill Switches

### Active Kill Switches

| Kill Switch | What It Disables | How to Activate |
|------------|-----------------|-----------------|
| `kill_chat_feature` | In-app chat | Firebase Remote Config → set to `true` |
| `kill_payments` | All in-app purchases | Firebase Remote Config → set to `true` |
| `maintenance_mode` | All API calls | Firebase Remote Config → set to `true` |

### Kill Switch Activation Procedure

1. Go to [Remote Config Dashboard URL]
2. Find the kill switch flag
3. Set value to `true`
4. **Publish changes**
5. Users will see the change within [N minutes / next app launch]
6. Post in `#incidents`: "Kill switch `[flag_name]` activated. Reason: [reason]"
7. Create incident ticket

### Kill Switch Deactivation

1. Confirm the underlying issue is resolved
2. Set the kill switch flag back to `false`
3. **Publish changes**
4. Monitor for 30 minutes to confirm normal behavior
5. Post in `#incidents`: "Kill switch `[flag_name]` deactivated. Issue resolved."

> ℹ️ **Info:** See [Feature Flags](./15-Feature-Flags.md) for full flag architecture and lifecycle.

## 7. Verification

After resolving, verify the fix:

- [ ] Check monitoring dashboard: [link]
- [ ] Verify crash-free rate returning to normal
- [ ] Confirm affected user flow works end-to-end
- [ ] Check analytics for normal user behavior

## 8. Communication

### During Incident

| Audience | Channel | Template |
|----------|---------|----------|
| Engineering | `#incidents` Slack | See templates below |
| Stakeholders | Email / Slack | See templates below |
| Users (if needed) | Status page / In-app | See templates below |

### Communication Templates

**Initial Report (Engineering):**
```
🔴 [P0/P1/P2] Incident: [Brief description]
Impact: [Number of users / percentage affected]
Status: Investigating
ETA: [Unknown / Estimated time]
Thread: [Link to incident thread]
```

**Status Update (Stakeholders):**
```
Update on [Issue]: We have identified the cause as [brief cause].
We are [implementing a fix / deploying a kill switch / submitting a hotfix].
Expected resolution: [time estimate].
User impact: [description].
```

**Resolution Notice:**
```
✅ Resolved: [Issue description]
Duration: [start time] - [end time] ([total duration])
Impact: [users affected, if known]
Root cause: [brief cause]
Fix: [what was done]
Follow-up: [post-mortem scheduled for DATE]
```

### Customer Communication (App Store)

If the issue affects many users and is visible:
```
We're aware of an issue affecting [feature] and are working on a fix.
A fix will be available in version [X.Y.Z], currently under review.
We apologize for the inconvenience.
```

## 9. Post-Mortem

### Culture

> ℹ️ **Blame-free culture:** Post-mortems focus on systems and processes, never on individuals. If a person could make a mistake, the system should have prevented it.

### Post-Mortem Template

```markdown
# Post-Mortem: [Incident Title]

**Date:** [Date]
**Duration:** [Start] - [End] ([total])
**Severity:** [P0/P1/P2/P3]
**Author:** [Name]

## Timeline
| Time | Event |
|------|-------|
| HH:MM | [First alert / user report] |
| HH:MM | [Investigation started] |
| HH:MM | [Root cause identified] |
| HH:MM | [Fix deployed / kill switch activated] |
| HH:MM | [Verified resolved] |

## Root Cause
[Detailed technical explanation]

## Impact
- Users affected: [number / percentage]
- Revenue impact: [if applicable]
- Data impact: [if applicable]

## What Went Well
- [Item 1]
- [Item 2]

## What Could Be Improved
- [Item 1]
- [Item 2]

## Action Items
| Action | Owner | Due Date | Ticket |
|--------|-------|----------|--------|
| [Action 1] | [Name] | [Date] | [JIRA-XXX] |
| [Action 2] | [Name] | [Date] | [JIRA-XXX] |
```

### Post-Mortem Checklist

- [ ] Write incident timeline within 48 hours
- [ ] Identify root cause (not just symptoms)
- [ ] Document what went well (celebrate good response)
- [ ] Document what could be improved (systems, not people)
- [ ] Create follow-up Jira tickets with owners and due dates
- [ ] Update monitoring/alerts if gaps identified
- [ ] Update this runbook if steps were missing or incorrect
- [ ] Share post-mortem with the team
- [ ] Schedule follow-up to verify action items are completed

## 10. Data Validation Procedures

### After Data-Affecting Incidents

- [ ] Verify database integrity checks pass
- [ ] Compare pre/post incident data counts
- [ ] Check for orphaned records
- [ ] Validate user-facing data is correct
- [ ] Confirm backups are available from before the incident

## 11. Change Control During Incidents

| Rule | Rationale |
|------|-----------|
| No unrelated deploys during P0/P1 | Avoid compounding issues |
| Minimal fix only (no refactoring) | Reduce risk of new bugs |
| Fast-track PR review (1 reviewer) | Speed over thoroughness |
| Monitor for 30 min after deploy | Catch regressions early |
| Roll back if fix doesn't work in 15 min | Don't iterate in production |

---
**Document Metadata**
| Field | Value |
|-------|-------|
| Author | [Name/Team] |
| Owner | [Team/Individual responsible for maintaining] |
| Created | [Date] |
| Last Updated | [Date] |
| Last Verified | [Date runbook was last tested] |
| Review Schedule | [Monthly/Quarterly/After each use] |
| Status | Draft |
| Confluence Labels | `ios`, `runbook`, `operations`, `[topic]` |
```

## Common iOS Runbook Topics

Suggest these when the user wants a runbook but hasn't specified the topic:

- **Release Process:** Step-by-step App Store submission
- **Hotfix Release:** Emergency fix pipeline
- **Crash Spike Response:** What to do when crash rate spikes
- **Certificate/Provisioning Renewal:** Annual Apple cert rotation
- **Backend Outage Impact:** How to handle when APIs go down
- **Feature Flag Rollback:** How to disable a feature remotely
- **App Store Rejection Response:** Common reasons and fixes
- **Push Notification Issues:** Debugging APNs problems
- **App Size Regression:** When the binary gets too large
- **Memory/Performance Regression:** Detecting and addressing performance issues
- **Data Migration Failure:** What to do when a database migration fails on user devices
- **Third-Party SDK Outage:** How to handle when Firebase/analytics/payment SDK goes down

## Writing Guidelines

- Write in imperative mood ("Check the dashboard", not "You should check the dashboard")
- Each step must be independently actionable
- Include exact commands, links, and expected outputs
- Always include a verification step — never assume the fix worked
- Keep the Quick Reference table at the top for rapid access during incidents
- Test the runbook by having someone unfamiliar with the process follow it
- Include severity levels (P0-P4) to help prioritize incident response
- Document kill switches for critical features that may need emergency disabling
- Emphasize blame-free culture in post-mortems — focus on systems, not people
- Provide communication templates for consistency during high-stress incidents
- Keep escalation procedures clear with specific timeframes and contacts
