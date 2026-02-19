---
name: migration-plan
description: Phase 2 (PLAN) protocol for designing the target architecture, compliance strategy, and incremental migration sequence.
requirements:
  - Completed and customer-validated Phase 1 (LEARN) deliverables
  - Read/write access to shared workspace
  - Ability to spawn sub-agents via sessions_spawn
  - Customer business feedback on desired new capabilities
---

# Migration Plan Skill — Phase 2: PLAN

This skill drives Phase 2 of legacy modernization: designing the target architecture and the step-by-step path to get there.

## Prerequisites

Phase 2 **must not begin** until:
- [ ] Phase 1 System Documentation Package is delivered
- [ ] Customer has validated the documentation as accurate
- [ ] Customer has provided feedback on desired new capabilities (mobile access, API layers, etc.)
- [ ] Phase gate approval recorded in VISION.md

## The Deliverable

Phase 2 produces a **Migration Plan Package** that the customer approves before any code changes begin:

1. **Target Architecture** — component diagrams, data flows, API contracts, technology choices
2. **Compliance Gap Analysis** — SOC 2 Phase 2 and GDPR requirements mapped to technical controls, with current gaps identified
3. **Migration Sequence** — ordered steps, each leaving the system functional, with dependencies and rollback strategies
4. **Infrastructure Plan** — deployment target (in-house/cloud), CI/CD pipeline design, IaC approach
5. **Risk Register** — identified risks ranked by probability and impact, with mitigations

## Planning Protocol

### Step 1: Gather Business Requirements (Red Commander leads)

Before architecture design begins:
- Review customer feedback from Phase 1 documentation review
- Identify desired new capabilities (mobile access, API layer, real-time features, etc.)
- Identify business constraints (downtime windows, budget, team skills, regulatory deadlines)
- Record requirements in: `business-requirements.md`

### Step 2: Design Target Architecture (Yellow Spark leads)

Yellow Spark spawns **architecture-designer** sub-agents:
- Design the target architecture for each bounded context / module group
- Incorporate customer-requested capabilities as first-class architectural elements
- Ensure the design supports incremental migration (strangler fig compatible)
- Produce 2-3 alternative approaches for major architectural decisions
- Output per module group: `target-architecture-[group].md`

Yellow Spark spawns **capability-mapper** sub-agents:
- Map each business-requested capability to specific architectural components
- Identify which legacy modules must change to support new capabilities
- Output per capability: `capability-map-[feature].md`

### Step 3: Stress-Test Architecture (Blue Lens leads)

Blue Lens spawns **architecture-stress-tester** sub-agents:
- Evaluate failure modes for each proposed architecture
- Assess scalability limits and performance implications
- Identify single points of failure
- Check data consistency guarantees during migration
- Evaluate compliance implications of architecture choices
- Output per proposal: `architecture-review-[group].md`

### Step 4: Compliance Gap Analysis (Blue Lens leads)

Blue Lens spawns a **compliance-gap-analyzer** sub-agent:
- Map SOC 2 Phase 2 Trust Service Criteria to required technical controls in the target architecture
- Map GDPR articles (especially 5, 6, 7, 17, 25, 32, 33, 35) to data handling procedures
- Identify gaps between current legacy compliance posture and target requirements
- Propose remediation for each gap
- Output: `compliance-gap-analysis.md`

### Step 5: Sequence the Migration (Red Commander leads)

Red Commander spawns a **migration-sequencer** sub-agent:
- Given the dependency graph, dead code report, and target architecture, propose an ordered migration sequence
- Each step must leave the system fully functional (no "dark period")
- Account for: module dependencies, data migration needs, integration contract changes
- Define rollback strategy per step (what to revert and how long it takes)
- Identify the "strangler fig" boundaries — where new and old code coexist
- Output: `migration-sequence.md`

### Step 6: Infrastructure Planning (Red Commander + Blue Lens)

Based on the customer's deployment environment:

**If in-house deployment:**
- Design the parallel infrastructure for new code alongside legacy
- Plan network segmentation for migration boundary
- Define monitoring and observability for both old and new systems

**If cloud migration:**
- Design the cloud infrastructure (IaC templates)
- Plan the data migration strategy (replication, sync, cutover)
- Design the CI/CD pipeline for the new system
- Ensure cloud configuration meets SOC 2 and GDPR requirements

Output: `infrastructure-plan.md`

### Step 7: Risk Assessment (Blue Lens leads)

Blue Lens compiles the risk register from all analysis:
- Migration risks (data loss, behavioral regression, downtime)
- Compliance risks (gaps that could delay go-live)
- Technical risks (performance, scalability, integration)
- Business risks (customer disruption, timeline overrun)
- Each risk: probability, impact, mitigation, owner
- Output: `risk-register.md`

### Step 8: Assemble Migration Plan (Green Anchor leads)

Green Anchor spawns a **migration-plan-writer** sub-agent:
- Compile all Phase 2 outputs into the customer-facing Migration Plan Package
- Add: executive summary, timeline visualization, decision points, success criteria per step
- Format for mixed audience (technical leads + business stakeholders)
- Output: `migration-plan.md`

Green Anchor spawns a **compliance-matrix-builder** sub-agent:
- Build the master compliance tracking matrix
- Every SOC 2 control and GDPR requirement mapped to: current status, target implementation, responsible agent, verification method
- Output: `compliance-matrix.md`

### Step 9: Customer Approval Gate (Red Commander drives)

Red Commander presents the Migration Plan to the customer:
- Walk through the target architecture and the reasoning behind key decisions
- Present the migration sequence with timeline and risk mitigations
- Review the compliance gap analysis and remediation plan
- Get explicit approval before proceeding to Phase 3 (EXECUTE)
- Record approval in VISION.md

## Role Summary During Phase 2

| Agent | Primary Responsibility | Sub-Agents Spawned |
|-------|----------------------|-------------------|
| Red Commander | Gathers requirements, sequences migration, gates approval | migration-sequencer |
| Yellow Spark | Designs target architecture, maps capabilities | architecture-designer, capability-mapper |
| Green Anchor | Assembles plan documents, builds compliance matrix | migration-plan-writer, compliance-matrix-builder |
| Blue Lens | Stress-tests architecture, analyzes compliance gaps, assesses risk | architecture-stress-tester, compliance-gap-analyzer |

## Completion Criteria

Phase 2 is complete when:
- [ ] Target Architecture designed and stress-tested
- [ ] Compliance Gap Analysis delivered with remediation plan
- [ ] Migration Sequence defined with rollback strategies per step
- [ ] Infrastructure Plan defined for target deployment environment
- [ ] Risk Register compiled and reviewed
- [ ] Master Migration Plan Package assembled
- [ ] Compliance Matrix built and baselined
- [ ] Customer has reviewed and approved the Migration Plan
- [ ] Approval recorded in VISION.md
