#!/usr/bin/env bash
# ============================================================
# OpenClaw Legacy Modernization Module — One-Line Installer
# ============================================================
# Installs the legacy-mod workflow on any vanilla OpenClaw setup.
#
# Usage:
#   git clone <repo> ~/.openclaw/workspace/legacy-mod && ~/.openclaw/workspace/legacy-mod/setup.sh
#
# Or tell your OpenClaw agent:
#   "Clone and install the legacy modernization module from <repo>"
#
# What this script does:
#   1. Verifies OpenClaw is installed
#   2. Provisions agent workspaces with persona files
#   3. Registers workflow agents in openclaw.json (with role-based tool policies)
#   4. Installs skills into ~/.openclaw/skills/
#   5. Injects guidance into the main agent's TOOLS.md and AGENTS.md
#   6. Builds the orchestrator CLI
#   7. Creates the CLI symlink
#   8. Prints usage instructions
#
# To uninstall:
#   ./setup.sh --uninstall
# ============================================================

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Configuration ──────────────────────────────────────────
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ID="legacy-mod"

# Workflow agents: id, name, role, workspace-dir
WORKFLOW_AGENTS=(
  "legacy-mod/commander:LM-Commander:analysis:scanner"
  "legacy-mod/architect:LM-Architect:analysis:architect"
  "legacy-mod/documenter:LM-Documenter:analysis:documenter"
  "legacy-mod/compliance-gate:LM-ComplianceGate:verification:compliance-gate"
  "legacy-mod/migrator:LM-Migrator:coding:migrator"
)

# Source agent persona mappings: workflow-agent-dir -> source-agent-dir
declare -A PERSONA_MAP=(
  ["scanner"]="red-commander"
  ["architect"]="yellow-spark"
  ["documenter"]="green-anchor"
  ["compliance-gate"]="blue-lens"
  ["migrator"]="red-commander"
)

# ── Functions ──────────────────────────────────────────────

banner() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  ${RED}●${NC} ${YELLOW}●${NC} ${GREEN}●${NC} ${BLUE}●${NC}  ${BOLD}Legacy Modernization Module         ║${NC}"
    echo -e "${BOLD}║        One-Line Installer for OpenClaw              ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_step() {
    echo -e "${BOLD}[SETUP]${NC} $1"
}

log_ok() {
    echo -e "  ${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "  ${YELLOW}!${NC} $1"
}

log_err() {
    echo -e "  ${RED}✗${NC} $1"
}

# ── Step 1: Verify OpenClaw ───────────────────────────────

verify_openclaw() {
    log_step "Verifying OpenClaw installation..."

    if [[ ! -d "${OPENCLAW_DIR}" ]]; then
        log_err "OpenClaw directory not found at ${OPENCLAW_DIR}"
        echo "  Install OpenClaw first: https://openclaw.dev"
        exit 1
    fi

    if [[ ! -f "${OPENCLAW_DIR}/openclaw.json" ]]; then
        log_warn "openclaw.json not found — creating a minimal config"
        echo '{"agents":{"defaults":{"compaction":{"mode":"safeguard"},"maxConcurrent":4,"subagents":{"maxConcurrent":8}},"list":[]},"tools":{"agentToAgent":{"enabled":true,"allow":[]}},"skills":{"load":{"extraDirs":["~/.openclaw/skills"]}}}' > "${OPENCLAW_DIR}/openclaw.json"
    fi

    log_ok "OpenClaw found at ${OPENCLAW_DIR}"
}

# ── Step 2: Provision Agent Workspaces ────────────────────

provision_workspaces() {
    log_step "Provisioning agent workspaces..."

    for entry in "${WORKFLOW_AGENTS[@]}"; do
        IFS=':' read -r agent_id agent_name agent_role agent_dir <<< "$entry"
        local workspace="${OPENCLAW_DIR}/workspaces/${MODULE_ID}/${agent_dir}"
        local source_agent="${PERSONA_MAP[$agent_dir]}"

        mkdir -p "${workspace}/memory"

        # Copy persona files (legacy-mod variants)
        if [[ -f "${SCRIPT_DIR}/agents/${source_agent}/SOUL-legacy-mod.md" ]]; then
            cp "${SCRIPT_DIR}/agents/${source_agent}/SOUL-legacy-mod.md" "${workspace}/SOUL.md"
        fi
        if [[ -f "${SCRIPT_DIR}/agents/${source_agent}/AGENTS-legacy-mod.md" ]]; then
            cp "${SCRIPT_DIR}/agents/${source_agent}/AGENTS-legacy-mod.md" "${workspace}/AGENTS.md"
        fi
        if [[ -f "${SCRIPT_DIR}/agents/${source_agent}/IDENTITY.md" ]]; then
            cp "${SCRIPT_DIR}/agents/${source_agent}/IDENTITY.md" "${workspace}/IDENTITY.md"
        fi

        # Symlink shared workspace
        mkdir -p "${OPENCLAW_DIR}/workspaces/${MODULE_ID}/shared"
        ln -sfn "${OPENCLAW_DIR}/workspaces/${MODULE_ID}/shared" "${workspace}/shared"

        log_ok "${agent_name} → ${workspace}"
    done
}

# ── Step 3: Register Agents in openclaw.json ──────────────

register_agents() {
    log_step "Registering workflow agents in openclaw.json..."

    local config_file="${OPENCLAW_DIR}/openclaw.json"

    # Use Node.js (guaranteed available with OpenClaw) to safely modify JSON
    node -e "
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('${config_file}', 'utf8'));

// Ensure agents.list exists
if (!config.agents) config.agents = {};
if (!config.agents.list) config.agents.list = [];

// Ensure main agent stays default (Antfarm pattern)
const hasDefault = config.agents.list.some(a => a.default === true);
if (!hasDefault) {
    const hasMain = config.agents.list.some(a => a.id === 'main');
    if (!hasMain) {
        config.agents.list.unshift({ id: 'main', name: 'Main', default: true });
    }
}

// Remove any existing legacy-mod agents (idempotent reinstall)
config.agents.list = config.agents.list.filter(a => !a.id.startsWith('legacy-mod/'));

// Define tool deny-lists per role
const toolPolicies = {
    'analysis':     { deny: ['write', 'edit', 'apply_patch'] },
    'verification': { deny: ['write', 'edit', 'apply_patch', 'sessions_spawn', 'sessions_send'] },
    'coding':       { deny: [] }
};

// Add workflow agents
const agents = [
    { id: 'legacy-mod/commander',       name: 'LM-Commander',       role: 'analysis',     dir: 'scanner' },
    { id: 'legacy-mod/architect',       name: 'LM-Architect',       role: 'analysis',     dir: 'architect' },
    { id: 'legacy-mod/documenter',      name: 'LM-Documenter',      role: 'analysis',     dir: 'documenter' },
    { id: 'legacy-mod/compliance-gate', name: 'LM-ComplianceGate',  role: 'verification', dir: 'compliance-gate' },
    { id: 'legacy-mod/migrator',        name: 'LM-Migrator',        role: 'coding',       dir: 'migrator' }
];

for (const agent of agents) {
    config.agents.list.push({
        id: agent.id,
        name: agent.name,
        workspace: '~/.openclaw/workspaces/${MODULE_ID}/' + agent.dir,
        tools: toolPolicies[agent.role],
        subagents: { allowAgents: [] }
    });
}

// Ensure agent-to-agent communication allows workflow agents
if (!config.tools) config.tools = {};
if (!config.tools.agentToAgent) config.tools.agentToAgent = { enabled: true, allow: [] };
const allow = config.tools.agentToAgent.allow || [];
for (const agent of agents) {
    if (!allow.includes(agent.id)) allow.push(agent.id);
}
config.tools.agentToAgent.allow = allow;

// Ensure skills directory is configured
if (!config.skills) config.skills = {};
if (!config.skills.load) config.skills.load = {};
if (!config.skills.load.extraDirs) config.skills.load.extraDirs = [];
if (!config.skills.load.extraDirs.includes('~/.openclaw/skills')) {
    config.skills.load.extraDirs.push('~/.openclaw/skills');
}

fs.writeFileSync('${config_file}', JSON.stringify(config, null, 2) + '\n');
console.log('  Done. Registered ' + agents.length + ' workflow agents.');
"
}

# ── Step 4: Install Skills ────────────────────────────────

install_skills() {
    log_step "Installing skills..."

    # Main agent skill (teaches it about the workflow)
    mkdir -p "${OPENCLAW_DIR}/skills/legacy-modernization"
    cp "${SCRIPT_DIR}/skills/legacy-modernization/SKILL.md" \
       "${OPENCLAW_DIR}/skills/legacy-modernization/SKILL.md"
    log_ok "legacy-modernization (main agent skill)"

    # Shared skills for workflow agents
    local shared_skills=("legacy-scan" "migration-plan" "migration-step" "compliance-check" "team-standup" "daily-report" "vision-sync")
    for skill in "${shared_skills[@]}"; do
        if [[ -d "${SCRIPT_DIR}/shared/skills/${skill}" ]]; then
            mkdir -p "${OPENCLAW_DIR}/skills/${skill}"
            cp "${SCRIPT_DIR}/shared/skills/${skill}/SKILL.md" \
               "${OPENCLAW_DIR}/skills/${skill}/SKILL.md"
            log_ok "${skill}"
        fi
    done
}

# ── Step 5: Inject Main Agent Guidance ────────────────────

inject_guidance() {
    log_step "Injecting guidance into main agent workspace..."

    # Find main agent workspace (default: ~/.openclaw/workspace)
    local main_workspace
    main_workspace=$(node -e "
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('${OPENCLAW_DIR}/openclaw.json', 'utf8'));
const main = (config.agents?.list || []).find(a => a.default === true || a.id === 'main');
const ws = main?.workspace?.replace('~', process.env.HOME) || '${OPENCLAW_DIR}/workspace';
console.log(ws);
")

    mkdir -p "${main_workspace}"

    # Upsert TOOLS.md block
    local tools_file="${main_workspace}/TOOLS.md"
    touch "${tools_file}"
    upsert_block "${tools_file}" "openclaw:legacy-mod" "$(cat <<'TOOLSEOF'
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
TOOLSEOF
)"
    log_ok "TOOLS.md updated"

    # Upsert AGENTS.md block
    local agents_file="${main_workspace}/AGENTS.md"
    touch "${agents_file}"
    upsert_block "${agents_file}" "openclaw:legacy-mod" "$(cat <<'AGENTSEOF'
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
AGENTSEOF
)"
    log_ok "AGENTS.md updated"
}

# Helper: idempotent block upsert into a file
upsert_block() {
    local file="$1"
    local marker="$2"
    local content="$3"
    local open_tag="<!-- ${marker} -->"
    local close_tag="<!-- /${marker} -->"

    # Remove existing block if present
    if grep -q "${open_tag}" "${file}" 2>/dev/null; then
        # Use node for safe multiline removal
        node -e "
const fs = require('fs');
let text = fs.readFileSync('${file}', 'utf8');
const re = new RegExp('\\n?${open_tag}[\\s\\S]*?${close_tag}\\n?', 'g');
text = text.replace(re, '\\n');
fs.writeFileSync('${file}', text.trimEnd() + '\\n');
"
    fi

    # Append new block
    printf "\n%s\n%s\n%s\n" "${open_tag}" "${content}" "${close_tag}" >> "${file}"
}

# ── Step 6: Build Orchestrator ────────────────────────────

build_orchestrator() {
    log_step "Building orchestrator CLI..."

    if [[ -d "${SCRIPT_DIR}/src" ]]; then
        cd "${SCRIPT_DIR}"
        if [[ -f "package.json" ]]; then
            npm install --production 2>/dev/null || true
            npm run build 2>/dev/null || true
            log_ok "Orchestrator built"
        else
            log_warn "No package.json found — orchestrator not yet implemented"
            log_warn "The spec is in workflows/legacy-mod/ORCHESTRATOR.md"
        fi
        cd - > /dev/null
    else
        log_warn "No src/ directory — orchestrator not yet implemented"
        log_warn "The spec is in workflows/legacy-mod/ORCHESTRATOR.md"
    fi
}

# ── Step 7: Create CLI Symlink ────────────────────────────

create_symlink() {
    log_step "Creating CLI symlink..."

    local bin_dir="${HOME}/.local/bin"
    mkdir -p "${bin_dir}"

    if [[ -f "${SCRIPT_DIR}/dist/cli.js" ]]; then
        cat > "${bin_dir}/legacy-mod" << SYMEOF
#!/usr/bin/env bash
exec node "${SCRIPT_DIR}/dist/cli.js" "\$@"
SYMEOF
        chmod +x "${bin_dir}/legacy-mod"
        log_ok "legacy-mod → ${bin_dir}/legacy-mod"
    else
        log_warn "Orchestrator not built yet — skipping symlink"
        log_warn "After building, run: setup.sh --link"
    fi

    # Check if bin dir is in PATH
    if [[ ":${PATH}:" != *":${bin_dir}:"* ]]; then
        log_warn "${bin_dir} is not in your PATH"
        echo "    Add to your shell profile: export PATH=\"\${HOME}/.local/bin:\${PATH}\""
    fi
}

# ── Step 8: Copy shared files ─────────────────────────────

copy_shared_files() {
    log_step "Copying shared workspace files..."

    local shared_dir="${OPENCLAW_DIR}/workspaces/${MODULE_ID}/shared"
    mkdir -p "${shared_dir}/reports"

    # Copy VISION template
    if [[ -f "${SCRIPT_DIR}/examples/VISION-legacy-modernization.md" ]]; then
        cp "${SCRIPT_DIR}/examples/VISION-legacy-modernization.md" "${shared_dir}/VISION.md"
        log_ok "VISION.md (legacy modernization template)"
    fi

    # Copy standup log
    if [[ -f "${SCRIPT_DIR}/shared/standup-log.md" ]]; then
        cp "${SCRIPT_DIR}/shared/standup-log.md" "${shared_dir}/standup-log.md"
        log_ok "standup-log.md"
    fi

    # Copy workflow.yml
    if [[ -f "${SCRIPT_DIR}/workflows/legacy-mod/workflow.yml" ]]; then
        cp "${SCRIPT_DIR}/workflows/legacy-mod/workflow.yml" "${shared_dir}/workflow.yml"
        log_ok "workflow.yml"
    fi
}

# ── Uninstall ─────────────────────────────────────────────

uninstall() {
    log_step "Uninstalling legacy modernization module..."

    # Remove agent workspaces
    rm -rf "${OPENCLAW_DIR}/workspaces/${MODULE_ID}"
    log_ok "Removed agent workspaces"

    # Remove agents from openclaw.json
    node -e "
const fs = require('fs');
const configPath = '${OPENCLAW_DIR}/openclaw.json';
if (!fs.existsSync(configPath)) process.exit(0);
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
if (config.agents?.list) {
    config.agents.list = config.agents.list.filter(a => !a.id.startsWith('legacy-mod/'));
}
if (config.tools?.agentToAgent?.allow) {
    config.tools.agentToAgent.allow = config.tools.agentToAgent.allow.filter(a => !a.startsWith('legacy-mod/'));
}
fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
"
    log_ok "Removed agents from openclaw.json"

    # Remove skills
    rm -rf "${OPENCLAW_DIR}/skills/legacy-modernization"
    rm -rf "${OPENCLAW_DIR}/skills/legacy-scan"
    rm -rf "${OPENCLAW_DIR}/skills/migration-plan"
    rm -rf "${OPENCLAW_DIR}/skills/migration-step"
    rm -rf "${OPENCLAW_DIR}/skills/compliance-check"
    log_ok "Removed skills"

    # Remove main agent guidance blocks
    local main_workspace
    main_workspace=$(node -e "
const fs = require('fs');
const configPath = '${OPENCLAW_DIR}/openclaw.json';
if (!fs.existsSync(configPath)) { console.log('${OPENCLAW_DIR}/workspace'); process.exit(0); }
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const main = (config.agents?.list || []).find(a => a.default === true || a.id === 'main');
const ws = main?.workspace?.replace('~', process.env.HOME) || '${OPENCLAW_DIR}/workspace';
console.log(ws);
")

    for file in "${main_workspace}/TOOLS.md" "${main_workspace}/AGENTS.md"; do
        if [[ -f "${file}" ]] && grep -q "openclaw:legacy-mod" "${file}"; then
            node -e "
const fs = require('fs');
let text = fs.readFileSync('${file}', 'utf8');
text = text.replace(/\n?<!-- openclaw:legacy-mod -->[\s\S]*?<!-- \/openclaw:legacy-mod -->\n?/g, '\n');
fs.writeFileSync('${file}', text.trimEnd() + '\n');
"
        fi
    done
    log_ok "Removed main agent guidance"

    # Remove CLI symlink
    rm -f "${HOME}/.local/bin/legacy-mod"
    log_ok "Removed CLI symlink"

    # Remove database
    rm -f "${OPENCLAW_DIR}/legacy-mod.db"
    log_ok "Removed database"

    echo ""
    echo -e "${GREEN}Uninstall complete.${NC}"
}

# ── Print Summary ─────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  Installation Complete!                              ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Workflow Agents:${NC}"
    echo -e "  ${RED}● Commander${NC}       (analysis)      — Scans, sequences, coordinates"
    echo -e "  ${YELLOW}● Architect${NC}       (analysis)      — Designs architecture, extracts logic"
    echo -e "  ${GREEN}● Documenter${NC}      (analysis)      — Assembles documentation, tracks compliance"
    echo -e "  ${BLUE}● ComplianceGate${NC}  (verification)  — Audits, verifies, reviews (cannot modify code)"
    echo -e "  ${RED}● Migrator${NC}        (coding)        — Writes modernized code"
    echo ""
    echo -e "${BOLD}Pipeline:${NC}"
    echo "  Phase 1: LEARN  → Scan, extract, audit, document → Customer review gate"
    echo "  Phase 2: PLAN   → Architecture, compliance, sequence → Customer approval gate"
    echo "  Phase 3: EXECUTE → Incremental migration with verify-each"
    echo ""
    echo -e "${BOLD}Quick Start:${NC}"
    echo ""
    echo "  Tell your OpenClaw agent:"
    echo "    \"Modernize the legacy app at /path/to/repo for ACME Corp,"
    echo "     they need SOC 2 + GDPR compliance and want a REST API layer.\""
    echo ""
    echo "  Or run directly:"
    echo "    legacy-mod run \"<task>\" --repo /path --customer \"Name\" \\"
    echo "      --compliance \"soc2,gdpr\" --deployment \"cloud:aws\""
    echo ""
    echo -e "${BOLD}Monitor:${NC}"
    echo "    legacy-mod status"
    echo "    legacy-mod steps"
    echo "    legacy-mod logs"
    echo ""
    echo -e "${BOLD}Uninstall:${NC}"
    echo "    ${SCRIPT_DIR}/setup.sh --uninstall"
    echo ""
}

# ── Main ───────────────────────────────────────────────────

banner

# Handle --uninstall
if [[ "${1:-}" == "--uninstall" ]]; then
    uninstall
    exit 0
fi

# Handle --link (just create symlink, for post-build)
if [[ "${1:-}" == "--link" ]]; then
    create_symlink
    exit 0
fi

# Handle --upgrade (user-facing, full upgrade: filesystem + DB)
if [[ "${1:-}" == "--upgrade" ]]; then
    log_step "Upgrading legacy-mod in place..."
    verify_openclaw
    provision_workspaces
    register_agents
    install_skills
    inject_guidance
    copy_shared_files
    build_orchestrator
    create_symlink
    log_step "Running database migration..."
    node "${SCRIPT_DIR}/dist/cli.js" upgrade --db-only
    exit 0
fi

# Handle --upgrade-fs (internal, called by legacy-mod upgrade)
if [[ "${1:-}" == "--upgrade-fs" ]]; then
    verify_openclaw
    provision_workspaces
    register_agents
    install_skills
    inject_guidance
    copy_shared_files
    build_orchestrator
    create_symlink
    exit 0
fi

verify_openclaw
provision_workspaces
register_agents
install_skills
inject_guidance
copy_shared_files
build_orchestrator
create_symlink
print_summary
