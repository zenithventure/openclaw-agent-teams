#!/usr/bin/env bash

# ============================================================
# OpenClaw Team Setup — Dev Team (Claude Code Edition)
# ============================================================
# Usage:
#   ./setup.sh                    # Interactive setup
#   ./setup.sh --clean            # Wipe and reinstall
#   ./setup.sh --uninstall        # Remove everything
#   ./setup.sh --vision "text"    # Set the vision inline
#   ./setup.sh --help             # Show help
# ============================================================

if [[ "${1:-}" == "--help" ]]; then
    echo "Setup script for Dev team (bare-metal / self-hosted OpenClaw)"
    echo ""
    echo "Usage:"
    echo "  ./setup.sh                    # Interactive setup"
    echo "  ./setup.sh --clean            # Wipe and reinstall"
    echo "  ./setup.sh --uninstall        # Remove everything"
    echo "  ./setup.sh --vision \"text\"    # Set the vision inline"
    exit 0
fi

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Configuration ──────────────────────────────────────────
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AGENTS=("red-lead" "yellow-coder" "green-shipper" "blue-reviewer")
AGENT_COLORS=("${RED}" "${YELLOW}" "${GREEN}" "${BLUE}")
AGENT_NAMES=("Lead" "Coder" "Shipper" "Reviewer")
AGENT_ROLES=("Engineering Lead & Decomposer" "Implementer & Claude Code Operator" "Release Manager & Deploy Operator" "Code Reviewer & Test Auditor")

SKILLS=(
    "claude-code-spawn"
    "github-issue-pipeline"
    "team-standup"
    "daily-report"
    "vision-sync"
)

# ── Functions ──────────────────────────────────────────────

banner() {
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  ${RED}●${NC} ${YELLOW}●${NC} ${GREEN}●${NC} ${BLUE}●${NC}  ${BOLD}OpenClaw Team Setup                  ║${NC}"
    echo -e "${BOLD}║        Dev Team — Claude Code Edition                 ║${NC}"
    echo -e "${BOLD}║                                                       ║${NC}"
    echo -e "${BOLD}║  ${DIM}Triage · Spawn · Review · Ship · via Claude Code${NC}${BOLD}    ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_step() {
    echo -e "\n${BOLD}[SETUP]${NC} $1"
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

log_agent() {
    local color=$1
    local name=$2
    local msg=$3
    echo -e "  ${color}●${NC} ${BOLD}${name}${NC}: ${msg}"
}

# ── Preflight Checks ──────────────────────────────────────

check_openclaw() {
    log_step "Checking prerequisites..."

    if ! command -v openclaw &> /dev/null; then
        log_warn "'openclaw' command not found"
        echo "    Install it first: npm install -g openclaw"
        echo "    Continuing with file deployment anyway..."
    else
        log_ok "openclaw found: $(which openclaw)"
    fi

    if command -v node &> /dev/null; then
        log_ok "node found: $(node --version)"
    else
        log_warn "node not found — JSON config merging will use cp instead"
    fi

    if command -v gh &> /dev/null; then
        log_ok "gh (GitHub CLI) found"
    else
        log_warn "gh not found — install with: brew install gh"
    fi
}

# ── Clean Install ─────────────────────────────────────────

clean_install() {
    echo -e "${RED}[WARN]${NC} This will remove ALL Dev team agent data!"
    echo "       (Existing openclaw.json will be backed up)"
    echo ""
    read -p "  Are you sure? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_step "Cleaning existing installation..."
        for agent in "${AGENTS[@]}"; do
            rm -rf "${OPENCLAW_DIR}/workspace-${agent}"
            log_ok "Removed workspace-${agent}"
        done
        for skill in "${SKILLS[@]}"; do
            rm -rf "${OPENCLAW_DIR}/skills/${skill}"
        done
        log_ok "Removed skills"
        rm -rf "${OPENCLAW_DIR}/shared"
        log_ok "Removed shared workspace"
    else
        echo "  Aborted."
        exit 0
    fi
}

# ── Uninstall ─────────────────────────────────────────────

uninstall() {
    log_step "Uninstalling Dev team..."

    # Remove agent workspaces
    for agent in "${AGENTS[@]}"; do
        rm -rf "${OPENCLAW_DIR}/workspace-${agent}"
    done
    log_ok "Removed agent workspaces"

    # Remove skills
    for skill in "${SKILLS[@]}"; do
        rm -rf "${OPENCLAW_DIR}/skills/${skill}"
    done
    log_ok "Removed skills"

    # Remove shared workspace
    rm -rf "${OPENCLAW_DIR}/shared"
    log_ok "Removed shared workspace"

    # Remove agents from openclaw.json (if node is available)
    if command -v node &> /dev/null && [[ -f "${OPENCLAW_DIR}/openclaw.json" ]]; then
        node -e "
const fs = require('fs');
const configPath = '${OPENCLAW_DIR}/openclaw.json';
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

const removeIds = ['red-lead', 'yellow-coder', 'green-shipper', 'blue-reviewer'];

if (config.agents?.list) {
    config.agents.list = config.agents.list.filter(a => !removeIds.includes(a.id));
}
if (config.tools?.agentToAgent?.allow) {
    config.tools.agentToAgent.allow = config.tools.agentToAgent.allow.filter(a => !removeIds.includes(a));
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
"
        log_ok "Removed agents from openclaw.json"
    fi

    echo ""
    echo -e "${GREEN}Uninstall complete.${NC}"
    exit 0
}

# ── Create Directory Structure ────────────────────────────

create_directories() {
    log_step "Creating directory structure..."

    mkdir -p "${OPENCLAW_DIR}"
    chmod 700 "${OPENCLAW_DIR}"

    # Agent workspaces
    for agent in "${AGENTS[@]}"; do
        mkdir -p "${OPENCLAW_DIR}/workspace-${agent}/memory"
    done

    # Shared workspace
    mkdir -p "${OPENCLAW_DIR}/shared/reports"

    # Skills directory
    mkdir -p "${OPENCLAW_DIR}/skills"

    log_ok "Directory structure created"
}

# ── Deploy openclaw.json ──────────────────────────────────

deploy_config() {
    log_step "Deploying openclaw.json..."

    local config_file="${OPENCLAW_DIR}/openclaw.json"

    if [[ -f "${config_file}" ]]; then
        # If node is available, merge into existing config (idempotent)
        if command -v node &> /dev/null; then
            cp "${config_file}" "${config_file}.backup.$(date +%Y%m%d%H%M%S)"
            log_ok "Backed up existing config"

            node -e "
const fs = require('fs');
const existing = JSON.parse(fs.readFileSync('${config_file}', 'utf8'));
const incoming = JSON.parse(fs.readFileSync('${SCRIPT_DIR}/openclaw.json', 'utf8'));

// Ensure structure
if (!existing.agents) existing.agents = {};
if (!existing.agents.defaults) existing.agents.defaults = incoming.agents.defaults;
if (!existing.agents.list) existing.agents.list = [];

// Remove any existing Dev team agents (idempotent)
const devIds = ['red-lead', 'yellow-coder', 'green-shipper', 'blue-reviewer'];
existing.agents.list = existing.agents.list.filter(a => !devIds.includes(a.id));

// Add Dev team agents
for (const agent of incoming.agents.list) {
    existing.agents.list.push(agent);
}

// Merge agent-to-agent communication
if (!existing.tools) existing.tools = {};
if (!existing.tools.agentToAgent) existing.tools.agentToAgent = { enabled: true, allow: [] };
existing.tools.agentToAgent.enabled = true;
const allow = existing.tools.agentToAgent.allow || [];
for (const id of devIds) {
    if (!allow.includes(id)) allow.push(id);
}
existing.tools.agentToAgent.allow = allow;

// Ensure skills dir
if (!existing.skills) existing.skills = {};
if (!existing.skills.load) existing.skills.load = {};
if (!existing.skills.load.extraDirs) existing.skills.load.extraDirs = [];
if (!existing.skills.load.extraDirs.includes('~/.openclaw/skills')) {
    existing.skills.load.extraDirs.push('~/.openclaw/skills');
}

fs.writeFileSync('${config_file}', JSON.stringify(existing, null, 2) + '\n');
"
            log_ok "Merged agents into existing openclaw.json"
        else
            # No node — simple copy with backup
            cp "${config_file}" "${config_file}.backup.$(date +%Y%m%d%H%M%S)"
            cp "${SCRIPT_DIR}/openclaw.json" "${config_file}"
            log_warn "No node available — replaced openclaw.json (backup saved)"
        fi
    else
        # Fresh install — just copy
        cp "${SCRIPT_DIR}/openclaw.json" "${config_file}"
        log_ok "Created openclaw.json"
    fi

    chmod 600 "${config_file}"
}

# ── Deploy Agent Files ────────────────────────────────────

deploy_agent_files() {
    log_step "Deploying agent workspaces..."

    for i in "${!AGENTS[@]}"; do
        local agent="${AGENTS[$i]}"
        local name="${AGENT_NAMES[$i]}"
        local color="${AGENT_COLORS[$i]}"
        local role="${AGENT_ROLES[$i]}"
        local workspace="${OPENCLAW_DIR}/workspace-${agent}"
        local source="${SCRIPT_DIR}/agents/${agent}"

        # Declarative files: always refresh
        for file in SOUL.md IDENTITY.md AGENTS.md HEARTBEAT.md; do
            if [[ -f "${source}/${file}" ]]; then
                cp "${source}/${file}" "${workspace}/${file}"
            fi
        done
        # USER.md: seed-once so customizations (timezone, channel, name) survive re-install
        if [[ ! -f "${workspace}/USER.md" && -f "${source}/USER.md" ]]; then
            cp "${source}/USER.md" "${workspace}/USER.md"
        fi

        # Create symlink to shared workspace
        ln -sfn "${OPENCLAW_DIR}/shared" "${workspace}/shared"

        log_agent "${color}" "${name}" "${role}"
    done

    log_ok "All agent workspaces deployed"
}

# ── Deploy Shared Files ───────────────────────────────────

deploy_shared_files() {
    log_step "Deploying shared workspace..."

    cp "${SCRIPT_DIR}/shared/VISION.md"      "${OPENCLAW_DIR}/shared/VISION.md"
    cp "${SCRIPT_DIR}/shared/standup-log.md"  "${OPENCLAW_DIR}/shared/standup-log.md"
    cp "${SCRIPT_DIR}/shared/STANDARDS.md"    "${OPENCLAW_DIR}/shared/STANDARDS.md"

    # BOOTSTRAP.md: drop only if neither the file nor the sentinel exists.
    # Agent self-deletes it on first run; sentinel prevents re-drop.
    local sentinel="${OPENCLAW_DIR}/shared/.bootstrap-deployed"
    if [[ ! -f "${OPENCLAW_DIR}/shared/BOOTSTRAP.md" && ! -f "${sentinel}" ]]; then
        cp "${SCRIPT_DIR}/shared/BOOTSTRAP.md" "${OPENCLAW_DIR}/shared/BOOTSTRAP.md"
        touch "${sentinel}"
        log_ok "BOOTSTRAP.md (first install)"
    else
        log_ok "BOOTSTRAP.md skipped (sentinel present)"
    fi

    log_ok "VISION.md"
    log_ok "standup-log.md"
    log_ok "STANDARDS.md"
}

# ── Deploy Skills ─────────────────────────────────────────

deploy_skills() {
    log_step "Installing skills..."

    for skill in "${SKILLS[@]}"; do
        local source="${SCRIPT_DIR}/shared/skills/${skill}/SKILL.md"
        local dest="${OPENCLAW_DIR}/skills/${skill}"

        if [[ -f "${source}" ]]; then
            mkdir -p "${dest}"
            cp "${source}" "${dest}/SKILL.md"
            log_ok "${skill}"
        else
            log_warn "${skill} — source not found"
        fi
    done
}

# ── Create .env Template ──────────────────────────────────

create_env_template() {
    if [[ ! -f "${OPENCLAW_DIR}/.env" ]]; then
        log_step "Creating .env template..."
        cat > "${OPENCLAW_DIR}/.env" << 'ENVEOF'
# ── OpenClaw API Keys ──────────────────────────────────────
# Uncomment and fill in the keys you need.

# Required: AI provider (Anthropic — used both by OpenClaw and by the
# Claude Code subagent runtime that Coder spawns for implementation)
# ANTHROPIC_API_KEY=sk-ant-...

# Required for autonomous Coder runs: GitHub access (read issues,
# branch, push, open PRs). Prefer a fine-grained PAT scoped only to
# the repos this team owns.
# GITHUB_TOKEN=ghp_...

# Optional: Messaging channels (notifications, daily reports)
# TELEGRAM_BOT_TOKEN=...
# DISCORD_BOT_TOKEN=...
# SLACK_APP_TOKEN=xapp-...
# SLACK_BOT_TOKEN=xoxb-...
ENVEOF
        chmod 600 "${OPENCLAW_DIR}/.env"
        log_ok "Created .env template"
    else
        log_ok ".env already exists — skipping"
    fi
}

# ── Set Vision Inline ─────────────────────────────────────

set_vision_inline() {
    local vision_text="$1"
    if [[ -z "$vision_text" ]]; then return; fi

    log_step "Setting Vision from command line..."
    local vision_file="${OPENCLAW_DIR}/shared/VISION.md"

    # Replace the mission statement placeholder
    if command -v node &> /dev/null; then
        node -e "
const fs = require('fs');
let content = fs.readFileSync('${vision_file}', 'utf8');
const oldMission = /> \*\*Operate as an autonomous AI-first engineering team[\s\S]*?> human writing code line-by-line\.\*\*/;
content = content.replace(oldMission, '> **${vision_text}**');
fs.writeFileSync('${vision_file}', content);
"
        log_ok "Vision set"
    else
        log_warn "Node not available — edit shared/VISION.md manually"
    fi
}

# ── Print Summary ─────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  Setup Complete!                                      ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Your team:${NC}"
    echo -e "  ${RED}● Lead${NC}      (Red)    — Triages issues, decomposes, assigns work"
    echo -e "  ${YELLOW}● Coder${NC}     (Yellow) — Spawns Claude Code subagents to implement"
    echo -e "  ${GREEN}● Shipper${NC}   (Green)  — CI/CD, deploys, rollbacks"
    echo -e "  ${BLUE}● Reviewer${NC}  (Blue)   — Reviews every PR line-by-line (read-only)"
    echo ""
    echo -e "${BOLD}Skills installed (5):${NC}"
    echo "  claude-code-spawn, github-issue-pipeline,"
    echo "  team-standup, daily-report, vision-sync"
    echo ""
    echo -e "${BOLD}Directory:${NC} ${OPENCLAW_DIR}/"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    echo -e "  1. Set your API key:"
    echo -e "     ${DIM}Edit ${OPENCLAW_DIR}/.env${NC}"
    echo ""
    echo -e "  2. Configure your Vision:"
    echo -e "     ${DIM}Edit ${OPENCLAW_DIR}/shared/VISION.md${NC}"
    echo ""
    echo -e "  3. Set your info in USER.md:"
    echo -e "     ${DIM}Edit any agent's workspace USER.md${NC}"
    echo ""
    echo -e "  4. Start the team:"
    echo -e "     ${DIM}openclaw start${NC}"
    echo ""
    echo -e "${BOLD}Quick Vision set:${NC}"
    echo "  ./setup.sh --vision \"Own the <repo-name> repo. Ship every issue via Claude Code.\""
    echo ""
    echo -e "${BOLD}Clean reinstall:${NC}"
    echo "  ./setup.sh --clean"
    echo ""
    echo -e "${BOLD}Uninstall:${NC}"
    echo "  ./setup.sh --uninstall"
    echo ""
}

# ── Main ──────────────────────────────────────────────────

banner

# Parse arguments
VISION_TEXT=""
DO_CLEAN=false
DO_UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            DO_CLEAN=true
            shift
            ;;
        --uninstall)
            DO_UNINSTALL=true
            shift
            ;;
        --vision)
            shift
            VISION_TEXT="${1:-}"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Handle uninstall
if [[ "$DO_UNINSTALL" == true ]]; then
    uninstall
fi

# Handle clean
if [[ "$DO_CLEAN" == true ]]; then
    clean_install
fi

# Run installation
check_openclaw
create_directories
deploy_config
deploy_agent_files
deploy_shared_files
deploy_skills
create_env_template

# Set vision if provided
if [[ -n "$VISION_TEXT" ]]; then
    set_vision_inline "$VISION_TEXT"
fi

print_summary
