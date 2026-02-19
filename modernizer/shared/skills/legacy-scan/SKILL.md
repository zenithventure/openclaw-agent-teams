---
name: legacy-scan
description: Phase 1 (LEARN) protocol for analyzing a legacy codebase. Coordinates sub-agents to scan, extract business logic, audit dead code, and produce customer-ready documentation.
requirements:
  - Read access to the customer's legacy codebase
  - Read/write access to shared workspace
  - Ability to spawn sub-agents via sessions_spawn
---

# Legacy Scan Skill — Phase 1: LEARN

This skill drives Phase 1 of legacy modernization: deeply understanding the legacy system before any changes are proposed.

## When to Use

- At the start of a new legacy modernization engagement
- When the team receives a new codebase to analyze
- When re-scanning after the customer reports the documentation is inaccurate

## The Deliverable

Phase 1 produces a **System Documentation Package** that the customer validates as accurate. This is the trust-building step — no code is changed.

The package includes:
1. **System Map** — languages, frameworks, build system, entry points, tech stack inventory
2. **Dependency Graph** — module-to-module call graph, external integrations, database schemas
3. **Business Logic Specification** — domain entities, workflows, business rules, data flows per module
4. **Dead Code Report** — unused functions, unreachable paths, orphaned endpoints with confidence scores
5. **Security Posture Assessment** — OWASP Top 10 findings, secrets in code, auth patterns
6. **Modernization Opportunity Notes** — observations about where new capabilities could be added

## Scan Protocol

### Step 1: Repository Orientation (Red Commander leads)

Red Commander spawns a **codebase-scanner** sub-agent:
- Identify all languages and their relative proportions
- Map the build system and deployment configuration
- List all entry points (API routes, CLI commands, scheduled jobs, event handlers)
- Identify the database layer (ORM, raw SQL, NoSQL, etc.)
- Catalog external integrations (APIs called, message queues, file systems)
- Output: `system-map.yaml`

### Step 2: Dependency Mapping (Red Commander spawns)

Red Commander spawns a **dependency-mapper** sub-agent:
- Trace module-to-module dependencies (imports, function calls, shared state)
- Build a directed dependency graph
- Identify circular dependencies and tightly coupled clusters
- Map data flow: where does data enter, transform, and exit?
- Output: `dependency-graph.md`

### Step 3: Business Logic Extraction (Yellow Spark leads)

Yellow Spark spawns **business-logic-miner** sub-agents (one per major module):
- Read source code to extract domain entities and their relationships
- Identify business rules (validation, calculation, workflow, authorization)
- Document implicit behaviors (error handling defaults, retry logic, fallback values)
- Note integration contracts (what data format does this module expect/produce?)
- Output per module: `business-logic-[module].md`

Yellow Spark also spawns a **pattern-identifier** sub-agent:
- Identify architectural patterns in use (MVC, layered, event-driven, etc.)
- Flag anti-patterns (God classes, circular deps, feature envy, shotgun surgery)
- Output: `pattern-analysis.md`

### Step 4: Dead Code Audit (Blue Lens leads)

Blue Lens spawns **dead-code-auditor** sub-agents (one per major module):
- Static analysis for unused functions, variables, and imports
- Call graph analysis for unreachable code paths
- Endpoint analysis for orphaned API routes
- Feature flag analysis for permanently disabled features
- Assign confidence scores: HIGH (definitely dead), MEDIUM (likely dead), LOW (uncertain)
- Output per module: `dead-code-report-[module].md`

### Step 5: Security Scan (Blue Lens leads)

Blue Lens spawns **security-scanner** sub-agents:
- OWASP Top 10 vulnerability scan
- Hardcoded secrets detection
- Authentication and authorization pattern review
- PII data handling assessment (critical for GDPR)
- Output: `security-scan.md`

### Step 6: Verification (Blue Lens leads)

Blue Lens spawns **legacy-verifier** sub-agents to cross-reference documentation against source code:
- Does the documentation accurately describe the code?
- Are all code paths covered?
- Do dependency claims match actual imports?
- Output: `verification-report.md` with discrepancies flagged

### Step 7: Documentation Assembly (Green Anchor leads)

Green Anchor spawns a **documentation-assembler** sub-agent:
- Compile all module-level documents into the master System Documentation Package
- Add: table of contents, cross-references, glossary of domain terms
- Organize by business domain, not technical layer
- Format for non-technical stakeholder readability
- Output: `system-documentation.md`

### Step 8: Customer Review Gate (Red Commander drives)

Red Commander presents the documentation to the customer:
- Summarize key findings
- Highlight dead code percentages and modernization opportunities
- Ask the customer to validate accuracy
- Record feedback in `shared/VISION.md` → Customer Feedback section
- Only proceed to Phase 2 (PLAN) after customer confirms documentation is accurate

## Role Summary During Phase 1

| Agent | Primary Responsibility | Sub-Agents Spawned |
|-------|----------------------|-------------------|
| Red Commander | Coordinates scan, gates customer review | codebase-scanner, dependency-mapper |
| Yellow Spark | Extracts business logic and patterns | business-logic-miner (per module), pattern-identifier |
| Green Anchor | Assembles customer-facing documentation | module-documenter (per module), documentation-assembler |
| Blue Lens | Audits dead code, security, verifies accuracy | dead-code-auditor, security-scanner, legacy-verifier |

## Completion Criteria

Phase 1 is complete when:
- [ ] System Map delivered and verified
- [ ] Dependency Graph delivered and verified
- [ ] Business Logic documented for all major modules
- [ ] Dead Code Report delivered with confidence scores
- [ ] Security Posture Assessment delivered
- [ ] Master System Documentation Package assembled
- [ ] Customer has reviewed and confirmed accuracy
- [ ] Customer feedback recorded in VISION.md
