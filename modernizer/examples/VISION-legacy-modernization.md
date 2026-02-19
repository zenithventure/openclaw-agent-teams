# 🎯 The Vision

## Mission Statement

> **Modernize a legacy application through a disciplined, phased approach:
> first deeply understand the existing system by examining its source code,
> then generate comprehensive documentation and a migration plan, and
> finally execute an incremental modernization — eliminating tech debt,
> dead code, and architectural gaps while keeping the business running
> without disruption. The new system must be secured, SOC 2 and GDPR
> compliant, and shaped by business needs (not engineer preference).**

## Success Criteria

Define what "done" looks like:

1. [ ] **Phase 1 — LEARN:** Complete system documentation generated from source code, validated by the customer as accurate
2. [ ] **Phase 1 — LEARN:** Dead code audit with confidence scores identifying unused modules, orphaned endpoints, and deprecated features
3. [ ] **Phase 2 — PLAN:** Target architecture designed with customer-approved migration sequence and rollback strategy
4. [ ] **Phase 2 — PLAN:** Compliance gap analysis mapping SOC 2 Phase 2 and GDPR requirements to concrete technical controls
5. [ ] **Phase 3 — EXECUTE:** Each migration step leaves the system fully functional — zero downtime, zero data loss
6. [ ] **Phase 3 — EXECUTE:** Characterization tests capturing legacy behavior pass against the modernized code
7. [ ] **Phase 3 — EXECUTE:** New architecture layers (API, mobile access, etc.) deployed per business feedback
8. [ ] Every deliverable passes compliance gatekeeper review before reaching the customer

## Constraints

What boundaries should the team respect?

- **Timeline:** Phase 1 (LEARN) — 1-2 weeks. Phase 2 (PLAN) — 1 week. Phase 3 (EXECUTE) — incremental, ongoing
- **Scope:** One legacy application at a time. Modernize in bounded contexts — never attempt a big-bang rewrite
- **Deployment:** Target environment may be in-house servers or cloud (AWS, Azure, GCP). Determine per customer
- **Compliance:** All output must meet SOC 2 Phase 2 and GDPR requirements. No exceptions for financial sector clients
- **Quality bar:** Every migration step must be reversible. Characterization tests required before any code changes. Customer sign-off required between phases
- **Security:** No secrets in code, no shared credentials, all data access audited. OWASP Top 10 review on every PR

## Priority Order

When the team must choose, what matters most?

1. Business continuity over migration speed — never disrupt the running system
2. Correctness over coverage — modernize fewer modules correctly rather than many modules poorly
3. Compliance by design over compliance by audit — build it in, don't bolt it on
4. Customer trust over technical ambition — prove understanding before proposing changes

## Context & Background

Any background information the team should know:

- **The "No Tech Debt Vision":** Every step produces clean, tested, documented, compliant code. The goal is zero accumulated debt at every point in the migration
- **Strangler Fig Pattern:** New code runs alongside old code. Traffic shifts gradually. Old modules are decommissioned only after new ones are validated in production
- **Business-Driven Architecture:** New capabilities (mobile access, API layers, real-time features) are added based on business unit feedback, not technical preference
- **Customer Profile:** Financial companies, healthcare organizations, government agencies — entities with legacy systems, strict compliance requirements, and low tolerance for disruption
- **Deployment Flexibility:** Some customers are entirely in-house; others are moving to cloud. The team must handle both. Many financial companies will only move to external hosting if compliance (SOC 2, GDPR) is guaranteed
- **Infrastructure Approach:** Trunk-based development, CI/CD pipelines, infrastructure-as-code. Agents manage the full stack
- **Sub-Agent Usage:** Core DISC agents spawn specialized sub-agents for heavy lifting (code scanning, test generation, compliance checks). Sub-agents are short-lived; core agents retain strategic context
- **Escalate to human for:** Architecture decisions that change the migration plan, compliance interpretation questions, customer communication, spending above agreed budget

---

## Team Working Notes

_This section is maintained by the agents. Do not edit below this line._

### Current Phase
_Not started — awaiting customer codebase ingestion_

### Active Priorities
_None yet_

### Key Decisions Log
| Date | Decision | Made By | Reasoning |
|------|----------|---------|-----------|

### Blockers
_None_

### Customer Feedback
| Date | Source | Feedback | Action Taken |
|------|--------|----------|--------------|
