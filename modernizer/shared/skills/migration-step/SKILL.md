---
name: migration-step
description: Phase 3 (EXECUTE) protocol for carrying out a single incremental migration step. Covers characterization testing, code migration, compliance verification, and deployment.
requirements:
  - Completed and customer-approved Phase 2 (PLAN) Migration Plan
  - Characterization tests for the target module
  - Compliance matrix with requirements mapped
  - Read/write access to both legacy and target codebases
  - Ability to spawn sub-agents via sessions_spawn
---

# Migration Step Skill — Phase 3: EXECUTE

This skill drives one incremental step of Phase 3: migrating a single bounded context / module from legacy to target architecture.

## Prerequisites

Each migration step **must not begin** until:
- [ ] Phase 2 Migration Plan is customer-approved
- [ ] The module's characterization tests are written and passing against legacy code
- [ ] The module's dependencies (if any) from the migration sequence have been completed
- [ ] The compliance matrix entry for this module is baselined

## The Strangler Fig Pattern

Every migration step follows the strangler fig pattern:
1. **Build new** — create the modernized version alongside the legacy module
2. **Verify** — prove behavioral equivalence via characterization tests
3. **Route** — gradually shift traffic/calls from legacy to new
4. **Validate** — monitor in production, verify compliance, confirm no regressions
5. **Decommission** — remove the legacy module only after the new one is proven

At no point does the legacy system stop working. The old and new run side by side.

## Migration Step Protocol

### Step 1: Pre-Migration Checklist (Red Commander verifies)

Before any code is written:
- [ ] Module identified from migration sequence: `[module-name]`
- [ ] Characterization tests exist and pass against legacy code
- [ ] Upstream dependencies are stable (already migrated or unchanged)
- [ ] Downstream consumers identified and their contracts documented
- [ ] Compliance requirements for this module identified (PII? Auth? Payments?)
- [ ] Rollback strategy defined and documented
- [ ] Anti-corruption layer designed (if needed for coexistence)

If any item is missing, **stop** and resolve before proceeding.

### Step 2: Build Characterization Tests (Blue Lens leads)

If tests don't yet exist for this module:

Blue Lens spawns **characterization-test-builder** sub-agents:
- Generate tests that capture all observable behaviors of the legacy module
- Cover: normal flows, error handling, edge cases, integration contracts
- Tests must pass against the current legacy code (they define "correct" behavior)
- Include performance baseline measurements
- Output: `characterization-tests-[module]/`

Characterization tests are the **contract of correctness**. The migrated code must pass these same tests.

### Step 3: Migrate the Module (Red Commander coordinates)

Red Commander spawns **module-migrator** sub-agents:
- Rewrite the module to the target architecture pattern
- Preserve all behavior captured by characterization tests
- Implement any new capabilities planned for this module (from capability map)
- Build the anti-corruption layer for coexistence with remaining legacy modules
- Follow the coding standards and patterns defined in the target architecture
- Output: PR with migrated code

Yellow Spark provides guidance on:
- Target architecture pattern for this module
- Anti-corruption layer design
- Integration approach with already-migrated and still-legacy modules

### Step 4: Verify Migration (Blue Lens leads)

Blue Lens spawns **migration-reviewer** sub-agents:
- Run characterization tests against the migrated code — all must pass
- Security review (OWASP Top 10) on the new code
- Performance comparison: new code vs. legacy baseline
- Review anti-corruption layer for correctness
- Verify no new dependencies on legacy patterns were introduced
- Output: `migration-review-[module].md` with APPROVE / REJECT / CHANGES-NEEDED

If REJECT or CHANGES-NEEDED: iterate. Red Commander coordinates fixes. Re-review.

### Step 5: Compliance Verification (Blue Lens leads)

Blue Lens spawns **compliance-verifier** sub-agents:
- Verify this migration step against the compliance matrix
- Check: data handling changes, access control modifications, audit trail continuity
- Verify encryption requirements are met
- Verify PII scope is unchanged or improved
- Verify logging and monitoring meet SOC 2 audit trail requirements
- Output: `compliance-verification-step-[N].md`

Green Anchor updates the compliance matrix with verification results.

### Step 6: Deploy with Coexistence (Red Commander drives)

Deploy the migrated module alongside the legacy version:
- Both old and new code running simultaneously
- Traffic/calls initially routed to legacy (0% new)
- Monitoring in place for both versions
- Rollback mechanism tested and ready

Green Anchor spawns **deployment-documenter** sub-agent:
- Document the deployment: environment, config changes, monitoring setup, rollback procedure
- Output: `deployment-doc-step-[N].md`

### Step 7: Traffic Shift (Red Commander drives)

Gradually shift traffic from legacy to new:
- Start: 5% to new, 95% to legacy
- Monitor: error rates, latency, correctness
- Increase: 25% → 50% → 75% → 100%
- At each increase, verify: characterization tests still pass, compliance maintained, no regressions
- If issues: roll back to previous percentage, investigate, fix, retry

### Step 8: Validate and Decommission (Team consensus)

Once 100% traffic runs through the new module for a defined observation period:
- Blue Lens confirms: all tests passing, compliance verified, no issues in monitoring
- Green Anchor confirms: documentation updated, compliance matrix updated
- Red Commander confirms: customer informed, no objections
- **Decommission the legacy module** — remove the code, update the dependency graph
- Green Anchor records the decommission in the migration tracking document

### Step 9: Update and Report (Green Anchor leads)

Green Anchor spawns **migration-tracker** sub-agent:
- Update the master migration tracking document
- Record: what changed, tests passed, compliance cleared, rollback verified, deployment date
- Update the dependency graph (legacy module removed, new module integrated)
- Output: updated `migration-tracking.md`

Red Commander reports to the customer:
- Module [X] successfully migrated
- New capabilities available (if any)
- Next module in sequence: [Y]

## Role Summary During Each Migration Step

| Agent | Primary Responsibility | Sub-Agents Spawned |
|-------|----------------------|-------------------|
| Red Commander | Coordinates step, drives deployment and traffic shift | module-migrator, integration-validator |
| Yellow Spark | Provides architecture guidance, designs anti-corruption layers | anti-corruption-designer |
| Green Anchor | Documents deployment, tracks migration, updates compliance matrix | deployment-documenter, migration-tracker |
| Blue Lens | Tests, reviews, verifies compliance at every stage | characterization-test-builder, migration-reviewer, compliance-verifier |

## Completion Criteria (per step)

A migration step is complete when:
- [ ] Characterization tests pass against new code
- [ ] Security review passed (OWASP Top 10)
- [ ] Compliance verification passed (SOC 2 + GDPR)
- [ ] 100% traffic running through new code
- [ ] Observation period completed with no issues
- [ ] Legacy module decommissioned
- [ ] Documentation and compliance matrix updated
- [ ] Customer informed

## Rollback Protocol

If issues are detected at any stage:
1. **Immediately** route traffic back to legacy module (the old code is still running)
2. Red Commander assesses: is this a minor fix or a fundamental problem?
3. If minor: fix, re-verify, re-deploy
4. If fundamental: roll back completely, update migration plan, consult customer
5. Green Anchor records the rollback: what happened, why, what changed in the plan
6. Blue Lens performs root cause analysis and updates the risk register
