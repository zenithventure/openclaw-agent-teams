---
name: legacy-modernization
description: "Legacy application modernization workflow for OpenClaw. Phases: LEARN (understand codebase), PLAN (design migration), EXECUTE (incremental strangler fig migration with compliance verification)."
user-invocable: false
---

# Legacy Modernization Workflow

You have access to the `legacy-mod` workflow for modernizing legacy applications. This document tells you when and how to use it.

## Installation

This module installs with one line on any vanilla OpenClaw setup:

```bash
git clone <repo> ~/.openclaw/workspace/legacy-mod && ~/.openclaw/workspace/legacy-mod/setup.sh
```

Or tell your OpenClaw agent: *"Clone and install the legacy modernization module from `<repo>`"*

The setup script handles everything: agent provisioning, skill installation, orchestrator setup, cron jobs, and main-agent guidance injection.

## When to Use This Workflow

Use the `legacy-mod` workflow when the user asks to:
- Modernize a legacy application or codebase
- Migrate from an old tech stack to a new one
- Analyze and document an existing codebase they don't fully understand
- Eliminate tech debt from a legacy system
- Add new capabilities (mobile, API layer) to an existing system
- Ensure a legacy system meets compliance requirements (SOC 2, GDPR)

## What the Workflow Does

The `legacy-mod` workflow runs a 3-phase pipeline with 5 specialized agents:

### Phase 1: LEARN (read-only — no code changes)
1. **Scan Codebase** — Commander scans repo structure, dependencies, tech stack
2. **Extract Business Logic** — Architect reads code to find domain rules and patterns
3. **Audit & Verify** — ComplianceGate audits dead code, scans security, verifies documentation accuracy
4. **Assemble Documentation** — Documenter synthesizes all findings into a customer-facing documentation package
5. **Phase Gate** — Customer reviews and validates the documentation (requires human input)

### Phase 2: PLAN (design only — no code changes)
6. **Design Architecture** — Architect designs target architecture based on customer feedback
7. **Compliance Gap Analysis** — ComplianceGate maps SOC 2 + GDPR requirements, identifies gaps
8. **Sequence Migration** — Commander creates ordered migration steps with rollback strategies
9. **Assemble Migration Plan** — Documenter produces customer-facing plan document
10. **Phase Gate** — Customer approves the migration plan (requires human input)

### Phase 3: EXECUTE (incremental code changes)
11. **Execute Migration** — Migrator rewrites modules one at a time (loop with verify-each)
12. **Verify Each Step** — ComplianceGate verifies compliance, security, tests, and reversibility
13. **Final Report** — Documenter compiles the completion report

### The Agents

| Agent | Role | Tool Access |
|-------|------|-------------|
| Commander | analysis | Read-only: scans code, sequences steps, coordinates team |
| Architect | analysis | Read-only: extracts business logic, designs architecture |
| Documenter | analysis | Read-only: assembles documentation and reports |
| ComplianceGate | verification | Read-only + test execution: audits, verifies, reviews. CANNOT modify code. |
| Migrator | coding | Full access: writes modernized code, runs tests, creates PRs |

## How to Start a Run

### Step 1: Gather Required Information

Before starting, you need:
- **Repository path**: The local path to the legacy codebase
- **Customer name**: For documentation headers
- **Compliance requirements**: Usually "soc2,gdpr" for financial companies
- **Deployment target**: "in-house" or "cloud:aws" / "cloud:azure" / "cloud:gcp"

### Step 2: Craft the Task String

The task string is the contract between you and the agents. A vague task produces bad results. Include:
- What the legacy application does (high-level)
- What the customer wants to achieve (modernize, add capabilities, comply)
- Any specific new capabilities requested (mobile, API, real-time)
- Known constraints (timeline, budget, deployment environment)

**Good task string:**
> "Modernize the ACME Financial trading platform (Java/Spring monolith, PostgreSQL).
> Customer wants: REST API layer for mobile access, SOC 2 Phase 2 + GDPR compliance,
> migration to AWS ECS. Current deployment: in-house data center. Timeline: 6 months.
> Known issues: legacy authentication uses custom session tokens, PII stored unencrypted
> in 3 tables."

**Bad task string:**
> "Modernize this app"

### Step 3: Confirm with the User

Always confirm the plan with the user before starting. Show them:
- The task string you've crafted
- The 3-phase pipeline overview
- That Phase 1 is read-only (no risk to their system)
- That customer gates exist between phases

### Step 4: Run the Workflow

```bash
legacy-mod run "<task string>" \
  --repo /path/to/codebase \
  --customer "ACME Financial" \
  --compliance "soc2,gdpr" \
  --deployment "cloud:aws"
```

## Monitoring Progress

### Check Status
```bash
legacy-mod status
```

### View Step Details
```bash
legacy-mod steps
```

### View Logs
```bash
legacy-mod logs
```

### Force-Trigger an Agent
If you don't want to wait for the next cron cycle:
```bash
legacy-mod trigger <agent-id>
```

## Handling Phase Gates

Phase gates (steps `phase1-gate` and `phase2-gate`) require human input. When the pipeline reaches a gate:

1. The step will escalate to the human (you will be notified)
2. Present the deliverable to the user:
   - Phase 1 gate: System Documentation Package
   - Phase 2 gate: Migration Plan Package
3. Ask for customer feedback and approval
4. Mark the step as complete:
   ```bash
   legacy-mod gate approve --feedback "Customer confirmed accuracy"
   ```

## Handling Failures

If a migration step fails verification:
- The Migrator's next retry gets the ComplianceGate's specific feedback
- After 2 retries, it escalates to human
- Use `legacy-mod resume` to restart from the failed step after manual intervention

## Important Notes

- Phase 1 (LEARN) is completely read-only. No risk to the legacy system.
- The ComplianceGate agent physically cannot modify code (verification role, enforced via tool deny-list).
- Every migration step in Phase 3 follows the strangler fig pattern — old and new run side by side.
- The workflow uses fresh sessions per migration step to prevent context window degradation.
- Progress is tracked in SQLite — the pipeline can resume from any failure point.
- The orchestrator runs entirely within the OpenClaw environment — no external dependencies beyond OpenClaw itself.
