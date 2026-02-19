# Main Agent Guidance Injection — Legacy Modernization Module
#
# These blocks are injected into the user's main OpenClaw agent workspace
# during `setup.sh`. They teach the main agent how to use the legacy
# modernization workflow.
#
# The blocks use HTML comment delimiters for idempotent upsert:
#   <!-- openclaw:legacy-mod --> ... <!-- /openclaw:legacy-mod -->

# ============================================================
# Block 1: Inject into TOOLS.md
# ============================================================

<!-- openclaw:legacy-mod -->
## Legacy Modernization Workflow

CLI for legacy application modernization (always use full path):
`node ~/.openclaw/workspace/legacy-mod/dist/cli.js`

Commands:
- Run:     `legacy-mod run "<task>" --repo /path --customer "Name" --compliance "soc2,gdpr" --deployment "cloud:aws"`
- Status:  `legacy-mod status`
- Steps:   `legacy-mod steps`
- Logs:    `legacy-mod logs`
- Trigger: `legacy-mod trigger <agent-id>`
- Resume:  `legacy-mod resume`
- Gate:    `legacy-mod gate approve --feedback "..."`

The workflow has 3 phases (LEARN → PLAN → EXECUTE) with customer approval gates between each. Phase 1 is read-only. Phase 3 migrates code incrementally with compliance verification at every step. Agents self-advance via cron jobs polling SQLite for pending work.
<!-- /openclaw:legacy-mod -->


# ============================================================
# Block 2: Inject into AGENTS.md
# ============================================================

<!-- openclaw:legacy-mod -->
## Legacy Modernization Workflow Policy

### When to Use
When the user asks to modernize, migrate, or document a legacy application. Also when they need compliance analysis (SOC 2, GDPR) of an existing system.

### Before Starting a Run
1. Gather: repository path, customer name, compliance requirements, deployment target
2. Craft a detailed task string with specific context (tech stack, business goals, known issues)
3. Confirm the plan with the user — show them the 3-phase pipeline
4. Emphasize: Phase 1 is read-only (no risk to their system)

### During a Run
- The pipeline is self-advancing via agent cron jobs
- Phase gates (between Phase 1→2 and Phase 2→3) require human input
- When a gate step escalates, present the deliverable to the user and ask for customer feedback
- If a migration step fails after retries, investigate and help resolve before resuming

### Agents in This Workflow
| Agent | Role | Can Modify Code? |
|-------|------|:---:|
| Commander | Scans, sequences, coordinates | No |
| Architect | Designs architecture, extracts business logic | No |
| Documenter | Assembles documentation, tracks compliance | No |
| ComplianceGate | Verifies, audits, reviews | No (enforced) |
| Migrator | Writes modernized code | Yes |
<!-- /openclaw:legacy-mod -->
